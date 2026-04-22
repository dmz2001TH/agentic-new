#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# mistake-tracker.sh — จำความผิดพลาด + ค้นหาวิธีแก้ + ไม่ทำซ้ำ
#
# Usage:
#   bash mistake-tracker.sh --log "error description" "context"
#   bash mistake-tracker.sh --check "action about to do"
#   bash mistake-tracker.sh --webfix "error description"
#   bash mistake-tracker.sh --rules
#   bash mistake-tracker.sh --stats
# ═══════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MISTAKES_FILE="${SCRIPT_DIR}/mistakes.jsonl"
RULES_FILE="${SCRIPT_DIR}/avoid-rules.jsonl"
SOLUTIONS_FILE="${SCRIPT_DIR}/solutions.jsonl"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p "$(dirname "$MISTAKES_FILE")"
[ ! -f "$MISTAKES_FILE" ] && touch "$MISTAKES_FILE"
[ ! -f "$RULES_FILE" ] && touch "$RULES_FILE"
[ ! -f "$SOLUTIONS_FILE" ] && touch "$SOLUTIONS_FILE"

# ── Log a mistake ──────────────────────────────────────────
log_mistake() {
    local error="$1"
    local context="${2:-}"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local date_str=$(date +%Y-%m-%d)

    echo "{\"error\":$(echo "$error" | jq -Rs .),\"context\":$(echo "$context" | jq -Rs .),\"date\":\"${date_str}\",\"timestamp\":\"${ts}\",\"resolved\":false}" >> "$MISTAKES_FILE"

    # Count how many times this error happened
    local keyword=$(echo "$error" | tr ' ' '\n' | head -3 | tr '\n' ' ' | sed 's/ *$//')
    local count=$(grep -cF "$keyword" "$MISTAKES_FILE" 2>/dev/null || echo 0)
    count=$(echo "$count" | tr -d ' \n')
    [ -z "$count" ] && count=0

    echo -e "${RED}✗ Mistake logged:${NC} $error (total similar: ${count}x)"

    if [ "$count" -ge 2 ]; then
        echo -e "${YELLOW}⚡ Same mistake ${count}x! Should search for fix.${NC}"
        echo -e "${YELLOW}  Run: bash mistake-tracker.sh --webfix \"$error\"${NC}"
        return 1  # signal: needs web fix
    fi
    return 0
}

# ── Check if action matches a known mistake ────────────────
check_action() {
    local action="$1"
    [ -z "$action" ] && echo "Usage: --check 'action'" && return 1

    echo -e "${CYAN}🔍 Checking against known mistakes...${NC}"

    # Check rules
    local found=0
    while IFS= read -r line; do
        local rule=$(echo "$line" | jq -r '.rule' 2>/dev/null)
        if [ -n "$rule" ] && echo "$action" | grep -qi "$(echo "$rule" | head -c 30)"; then
            echo -e "${RED}  ⛔ MATCH: $rule${NC}"
            found=$((found+1))
        fi
    done < "$RULES_FILE"

    if [ "$found" -eq 0 ]; then
        echo -e "${GREEN}  ✓ No known mistakes match — safe to proceed${NC}"
    else
        echo -e "${RED}  ⚠️ ${found} rule(s) matched — adjust action!${NC}"
    fi
    return $found
}

# ── Get rules to inject into prompt ────────────────────────
get_rules() {
    if [ ! -s "$RULES_FILE" ]; then
        echo "(no rules yet)"
        return
    fi

    echo "## ⛔ MISTAKES TO AVOID (จำแล้วห้ามทำซ้ำ)"
    echo ""
    local i=1
    while IFS= read -r line; do
        local rule=$(echo "$line" | jq -r '.rule' 2>/dev/null)
        local source=$(echo "$line" | jq -r '.source' 2>/dev/null)
        local date=$(echo "$line" | jq -r '.promoted' 2>/dev/null)
        if [ -n "$rule" ]; then
            echo "${i}. ❌ ${rule} (source: ${source}, ${date})"
            i=$((i+1))
        fi
    done < "$RULES_FILE"
}

# ── Promote mistake to rule ────────────────────────────────
promote_rule() {
    local rule="$1"
    local source="${2:-manual}"
    local ts=$(date +%Y-%m-%d)

    echo "{\"rule\":$(echo "$rule" | jq -Rs .),\"source\":\"${source}\",\"promoted\":\"${ts}\"}" >> "$RULES_FILE"
    echo -e "${GREEN}✓ Rule promoted:${NC} $rule"
}

# ── Save solution from web search ──────────────────────────
save_solution() {
    local error="$1"
    local solution="$2"
    local url="${3:-}"
    local ts=$(date +%Y-%m-%d)

    echo "{\"error\":$(echo "$error" | jq -Rs .),\"solution\":$(echo "$solution" | jq -Rs .),\"url\":$(echo "$url" | jq -Rs .),\"date\":\"${ts}\"}" >> "$SOLUTIONS_FILE"

    # Auto-promote to rule
    promote_rule "$solution" "web_search"

    echo -e "${GREEN}✓ Solution saved + rule promoted${NC}"
}

# ── Stats ──────────────────────────────────────────────────
show_stats() {
    local mistakes=$(wc -l < "$MISTAKES_FILE" | tr -d ' ')
    local rules=$(wc -l < "$RULES_FILE" | tr -d ' ')
    local solutions=$(wc -l < "$SOLUTIONS_FILE" | tr -d ' ')

    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  🧠 Mistake Tracker Stats${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "  Mistakes logged: ${mistakes}"
    echo -e "  Rules (avoid):   ${rules}"
    echo -e "  Solutions:       ${solutions}"
    echo ""

    if [ "$rules" -gt 0 ]; then
        echo -e "${YELLOW}Active Rules:${NC}"
        local i=1
        while IFS= read -r line; do
            local rule=$(echo "$line" | jq -r '.rule' 2>/dev/null)
            echo -e "  ${i}. ${rule}"
            i=$((i+1))
        done < "$RULES_FILE"
    fi
}

# ── Main ───────────────────────────────────────────────────
case "${1:-}" in
    --log)      log_mistake "${2:-}" "${3:-}" ;;
    --check)    check_action "${2:-}" ;;
    --webfix)   echo "Search for fix: ${2:-}" ;;
    --rules)    get_rules ;;
    --promote)  promote_rule "${2:-}" "${3:-manual}" ;;
    --solution) save_solution "${2:-}" "${3:-}" "${4:-}" ;;
    --stats)    show_stats ;;
    *)
        echo "Usage:"
        echo "  --log 'error' 'context'     Log a mistake"
        echo "  --check 'action'            Check if action matches known mistake"
        echo "  --webfix 'error'            Search web for fix"
        echo "  --rules                     Show rules to avoid"
        echo "  --promote 'rule' [source]   Promote to rule"
        echo "  --solution 'error' 'fix'    Save solution"
        echo "  --stats                     Show stats"
        ;;
esac
