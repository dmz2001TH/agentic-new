#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Learner Agent — อ่าน error + success pattern → knowledge base
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash learner.sh --learn "event" "outcome" "context"
#   bash learner.sh --pattern "keyword"
#   bash learner.sh --promote "pattern_id"
#   bash learner.sh --knowledge
#   bash learner.sh --weekly-review

set -e
LEARN_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPERIENCES_FILE="${LEARN_DIR}/experiences.jsonl"
PATTERNS_FILE="${LEARN_DIR}/patterns.json"
KNOWLEDGE_FILE="${LEARN_DIR}/knowledge.json"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "$LEARN_DIR"
[ ! -f "$EXPERIENCES_FILE" ] && touch "$EXPERIENCES_FILE"
[ ! -f "$PATTERNS_FILE" ] && echo '{"patterns":[]}' > "$PATTERNS_FILE"
[ ! -f "$KNOWLEDGE_FILE" ] && echo '{"rules":[],"stats":{"total_experiences":0,"patterns_promoted":0}}' > "$KNOWLEDGE_FILE"

# Log experience
learn() {
    local event="$1" outcome="${2:-success}" context="${3:-}"
    [ -z "$event" ] && echo "Usage: --learn 'event' 'outcome' 'context'" && return 1
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local date_str=$(date +%Y-%m-%d)
    
    echo "{\"event\":$(echo "$event" | jq -Rs .),\"outcome\":\"${outcome}\",\"context\":$(echo "$context" | jq -Rs .),\"date\":\"${date_str}\",\"timestamp\":\"${ts}\"}" >> "$EXPERIENCES_FILE"
    
    # Auto-detect pattern: check if similar event happened before
    local keyword=$(echo "$event" | tr ' ' '\n' | head -3 | tr '\n' '|' | sed 's/|$//')
    local similar_count=$(grep -ci "$keyword" "$EXPERIENCES_FILE" 2>/dev/null || true)
    similar_count=${similar_count:-0}
    
    echo -e "${GREEN}✓ Learned:${NC} [${outcome}] ${event}"
    
    if [ "$similar_count" -ge 3 ]; then
        echo -e "${YELLOW}  ⚡ Pattern detected (${similar_count}x)! Consider: bash learner.sh --promote${NC}"
    fi
    
    # Update stats
    local tmp=$(mktemp)
    jq '.stats.total_experiences += 1' "$KNOWLEDGE_FILE" > "$tmp" && mv "$tmp" "$KNOWLEDGE_FILE"
}

# Find patterns
find_patterns() {
    local keyword="$1"
    [ -z "$keyword" ] && echo "Usage: --pattern 'keyword'" && return 1
    
    echo -e "${CYAN}🔍 Pattern search: ${keyword}${NC}\n"
    
    echo -e "${YELLOW}Experiences:${NC}"
    grep -i "$keyword" "$EXPERIENCES_FILE" 2>/dev/null | jq -r '"  [\(.date)] [\(.outcome)] \(.event | .[:80])"' | tail -10 || echo "  (none)"
    
    echo -e "\n${YELLOW}Known patterns:${NC}"
    jq -r --arg k "$keyword" '.patterns[] | select(.keyword | test($k; "i")) | "  ⚡ \(.name) (seen \(.count) times, confidence: \(.confidence))"' "$PATTERNS_FILE" 2>/dev/null || echo "  (none)"
}

# Promote pattern to rule
promote_pattern() {
    local pattern_desc="$1"
    [ -z "$pattern_desc" ] && echo "Usage: --promote 'description'" && return 1
    
    local pattern_id="pat-$(date +%Y%m%d%H%M%S)"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Add pattern
    local tmp=$(mktemp)
    jq --arg id "$pattern_id" --arg desc "$pattern_desc" --arg ts "$ts" \
       '.patterns += [{"id":$id,"name":$desc,"count":3,"confidence":"medium","promoted_at":$ts,"status":"active"}]' \
       "$PATTERNS_FILE" > "$tmp" && mv "$tmp" "$PATTERNS_FILE"
    
    # Add to knowledge as rule
    tmp=$(mktemp)
    jq --arg desc "$pattern_desc" --arg ts "$ts" \
       '.rules += [{"rule":$desc,"source":"pattern_promotion","promoted":$ts}] | .stats.patterns_promoted += 1' \
       "$KNOWLEDGE_FILE" > "$tmp" && mv "$tmp" "$KNOWLEDGE_FILE"
    
    echo -e "${GREEN}✓ Pattern promoted:${NC} $pattern_desc → Rule"
}

# Show knowledge base
show_knowledge() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📚 Knowledge Base${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    local total=$(jq '.stats.total_experiences' "$KNOWLEDGE_FILE")
    local promoted=$(jq '.stats.patterns_promoted' "$KNOWLEDGE_FILE")
    
    echo -e "  Experiences: ${total}  |  Rules promoted: ${promoted}"
    echo ""
    
    echo -e "${YELLOW}Rules:${NC}"
    jq -r '.rules[] | "  📏 \(.rule)"' "$KNOWLEDGE_FILE" 2>/dev/null || echo "  (none yet)"
    
    echo -e "\n${YELLOW}Active patterns:${NC}"
    jq -r '.patterns[] | select(.status == "active") | "  ⚡ \(.name) (confidence: \(.confidence))"' "$PATTERNS_FILE" 2>/dev/null || echo "  (none yet)"
}

# Weekly review
weekly_review() {
    local week_ago=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null || echo "2000-01-01")
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📊 Weekly Review${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    local total=$(jq -s "[.[] | select(.date >= \"${week_ago}\")] | length" "$EXPERIENCES_FILE" 2>/dev/null)
    local successes=$(jq -s "[.[] | select(.date >= \"${week_ago}\" and .outcome == \"success\")] | length" "$EXPERIENCES_FILE" 2>/dev/null)
    local failures=$(jq -s "[.[] | select(.date >= \"${week_ago}\" and .outcome == \"failure\")] | length" "$EXPERIENCES_FILE" 2>/dev/null)
    
    echo -e "  Period: ${week_ago} → today"
    echo -e "  Experiences: ${total}  |  ${GREEN}Success: ${successes}${NC}  |  ${RED}Failure: ${failures}${NC}"
    
    echo -e "\n${YELLOW}Top events:${NC}"
    jq -s "[.[] | select(.date >= \"${week_ago}\")] | group_by(.event) | map({event: .[0].event, count: length, outcomes: map(.outcome)}) | sort_by(-.length) | .[:5][] | \"  \(.count)x: \(.event | .[:60])\"" "$EXPERIENCES_FILE" 2>/dev/null || echo "  (none)"
    
    echo -e "\n${YELLOW}Failure patterns to investigate:${NC}"
    jq -s "[.[] | select(.date >= \"${week_ago}\" and .outcome == \"failure\")] | .[:5][] | \"  ✗ \(.event | .[:80])\"" "$EXPERIENCES_FILE" 2>/dev/null || echo "  (none)"
}

case "${1:-}" in
    --learn) learn "$2" "$3" "$4" ;;
    --pattern) find_patterns "$2" ;;
    --promote) promote_pattern "$2" ;;
    --knowledge) show_knowledge ;;
    --weekly-review) weekly_review ;;
    *) echo "Usage: learner.sh [--learn|--pattern|--promote|--knowledge|--weekly-review]" ;;
esac
