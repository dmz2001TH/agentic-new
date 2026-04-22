#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Critic Agent — Review code ของ builder ก่อน merge
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash critic.sh --review "file_path"
#   bash critic.sh --review-dir "directory"
#   bash critic.sh --diff [branch]
#   bash critic.sh --approve "review_id"
#   bash critic.sh --reject "review_id" "reason"

set -e
CRITIC_DIR="$(cd "$(dirname "$0")" && pwd)"
REVIEWS_FILE="${CRITIC_DIR}/reviews.jsonl"
RULES_FILE="${CRITIC_DIR}/rules.json"
SCORES_FILE="${CRITIC_DIR}/scores.json"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$CRITIC_DIR"

# Default review rules
if [ ! -f "$RULES_FILE" ]; then
    cat > "$RULES_FILE" << 'EOF'
{
  "rules": [
    {"id":"r01","name":"no-hardcoded-secrets","pattern":"(password|secret|token|api_key)\\s*=\\s*['\"][^'\"]+['\"]","severity":"critical","desc":"No hardcoded secrets"},
    {"id":"r02","name":"no-rm-rf","pattern":"rm\\s+-rf\\s+/","severity":"critical","desc":"No rm -rf /"},
    {"id":"r03","name":"has-shebang","pattern":"^#!","severity":"warning","desc":"Shell scripts should have shebang","applies_to":"*.sh"},
    {"id":"r04","name":"no-curl-pipe-bash","pattern":"curl.*\\|\\s*bash","severity":"warning","desc":"Avoid curl | bash pattern"},
    {"id":"r05","name":"file-size","max_bytes":50000,"severity":"warning","desc":"File too large (>50KB)"},
    {"id":"r06","name":"has-error-handling","pattern":"set -e|trap|if.*then","severity":"info","desc":"Consider error handling","applies_to":"*.sh"},
    {"id":"r07","name":"no-infinite-loop","pattern":"while\\s+true|while\\s+1","severity":"warning","desc":"Potential infinite loop"},
    {"id":"r08","name":"proper-quoting","pattern":"\\$[A-Z_]+(?!\\\")","severity":"info","desc":"Consider quoting variables"}
  ]
}
EOF
fi

[ ! -f "$REVIEWS_FILE" ] && touch "$REVIEWS_FILE"
[ ! -f "$SCORES_FILE" ] && echo '{}' > "$SCORES_FILE"

review_file() {
    local file="$1"
    [ ! -f "$file" ] && echo -e "${RED}File not found:${NC} $file" && return 1
    
    local filename=$(basename "$file")
    local size=$(wc -c < "$file" | tr -d ' ')
    local ext="${file##*.}"
    local review_id="review-$(date +%Y%m%d%H%M%S)-$(echo "$file" | md5sum | head -c 6)"
    local issues=()
    local critical=0 warning=0 info=0
    local score=100
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  🔍 Critic Review: ${filename}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "  File: ${file}"
    echo -e "  Size: ${size} bytes"
    echo -e "  Review ID: ${review_id}"
    echo ""
    
    # Check file size
    local max_size=$(jq -r '.rules[] | select(.id == "r05") | .max_bytes' "$RULES_FILE")
    if [ "$size" -gt "$max_size" ]; then
        echo -e "  ${YELLOW}⚠ r05: File too large (${size} > ${max_size} bytes)${NC}"
        warning=$((warning+1))
        score=$((score - 5))
    fi
    
    # Run pattern-based rules
    while IFS= read -r rule; do
        local rid=$(echo "$rule" | jq -r '.id')
        local pattern=$(echo "$rule" | jq -r '.pattern // empty')
        local severity=$(echo "$rule" | jq -r '.severity')
        local desc=$(echo "$rule" | jq -r '.desc')
        local applies=$(echo "$rule" | jq -r '.applies_to // "all"')
        
        # Skip if rule doesn't apply to this file type
        if [ "$applies" != "all" ] && [ "$applies" != "*.${ext}" ]; then
            continue
        fi
        
        if [ -n "$pattern" ]; then
            local matches=$(grep -cP "$pattern" "$file" 2>/dev/null || true)
            [ -z "$matches" ] && matches=0
            if [ "$matches" -gt 0 ]; then
                local match_lines=$(grep -nP "$pattern" "$file" 2>/dev/null | head -3)
                case "$severity" in
                    critical)
                        echo -e "  ${RED}🔴 ${rid}: ${desc}${NC} (${matches} occurrences)"
                        critical=$((critical+1))
                        score=$((score - 20))
                        ;;
                    warning)
                        echo -e "  ${YELLOW}🟡 ${rid}: ${desc}${NC} (${matches} occurrences)"
                        warning=$((warning+1))
                        score=$((score - 5))
                        ;;
                    info)
                        echo -e "  ${CYAN}ℹ️  ${rid}: ${desc}${NC}"
                        info=$((info+1))
                        score=$((score - 1))
                        ;;
                esac
                echo "$match_lines" | while read ml; do
                    echo -e "      ${ml}"
                done
            fi
        fi
    done < <(jq -c '.rules[]' "$RULES_FILE")
    
    # Final verdict
    echo ""
    echo -e "${CYAN}── Review Summary ──${NC}"
    echo -e "  ${RED}Critical: ${critical}${NC}  ${YELLOW}Warning: ${warning}${NC}  ${CYAN}Info: ${info}${NC}"
    
    if [ "$score" -lt 0 ]; then score=0; fi
    local verdict="APPROVED"
    local verdict_color="${GREEN}"
    if [ "$critical" -gt 0 ]; then
        verdict="REJECTED"
        verdict_color="${RED}"
    elif [ "$warning" -gt 3 ]; then
        verdict="NEEDS_WORK"
        verdict_color="${YELLOW}"
    fi
    
    echo -e "  Score: ${verdict_color}${score}/100${NC}"
    echo -e "  Verdict: ${verdict_color}${verdict}${NC}"
    
    # Record review
    echo "{\"id\":\"${review_id}\",\"file\":\"${file}\",\"critical\":${critical},\"warning\":${warning},\"info\":${info},\"score\":${score},\"verdict\":\"${verdict}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$REVIEWS_FILE"
    
    return $([ "$critical" -gt 0 ] && echo 1 || echo 0)
}

review_dir() {
    local dir="$1"
    [ ! -d "$dir" ] && echo "Directory not found: $dir" && return 1
    
    echo -e "${CYAN}Reviewing directory: ${dir}${NC}\n"
    local total=0 passed=0 failed=0
    
    while IFS= read -r -d "" file; do
        [ -f "$file" ] || continue
        total=$((total+1))
        if review_file "$file"; then
            passed=$((passed+1))
        else
            failed=$((failed+1))
        fi
        echo ""
    done < <(find "$dir" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.json" -o -name "*.md" \) -print0 2>/dev/null)
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "  Total: ${total}  ${GREEN}Passed: ${passed}${NC}  ${RED}Failed: ${failed}${NC}"
}

review_diff() {
    local branch="${1:-HEAD~1}"
    echo -e "${CYAN}Reviewing changes since ${branch}...${NC}\n"
    
    local changed_files=$(git diff --name-only "$branch" 2>/dev/null || echo "")
    if [ -z "$changed_files" ]; then
        echo "No changes found"
        return
    fi
    
    echo "$changed_files" | while read file; do
        [ -f "$file" ] && review_file "$file"
        echo ""
    done
}

approve_review() {
    local rid="$1"
    [ -z "$rid" ] && echo "Usage: --approve 'review_id'" && return 1
    local tmp=$(mktemp)
    jq --arg id "$rid" '. + {($id): {"status":"approved","timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}}' "$SCORES_FILE" > "$tmp" && mv "$tmp" "$SCORES_FILE"
    echo -e "${GREEN}✓ Approved:${NC} $rid"
}

reject_review() {
    local rid="$1" reason="$2"
    [ -z "$rid" ] && echo "Usage: --reject 'review_id' 'reason'" && return 1
    local tmp=$(mktemp)
    jq --arg id "$rid" --arg reason "$reason" '. + {($id): {"status":"rejected","reason":$reason,"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}}' "$SCORES_FILE" > "$tmp" && mv "$tmp" "$SCORES_FILE"
    echo -e "${RED}✗ Rejected:${NC} $rid — $reason"
}

case "${1:-}" in
    --review) review_file "$2" ;;
    --review-dir) review_dir "$2" ;;
    --diff) review_diff "$2" ;;
    --approve) approve_review "$2" ;;
    --reject) reject_review "$2" "$3" ;;
    *) echo "Usage: critic.sh [--review|--review-dir|--diff|--approve|--reject]" ;;
esac
