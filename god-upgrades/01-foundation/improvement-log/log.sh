#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Improvement Log — เก็บ history ว่าแก้อะไร + ผลเป็นไง
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash log.sh "description" "category" "status"
#   bash log.sh --list [category]
#   bash log.sh --stats
#   bash log.sh --export

set -e
LOG_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${LOG_DIR}/log.jsonl"
STATS_FILE="${LOG_DIR}/stats.json"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "$LOG_DIR"
[ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"

log_entry() {
    local desc="$1" category="${2:-general}" status="${3:-completed}"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local date_str=$(date +%Y-%m-%d)
    local count=$(wc -l < "$LOG_FILE" | tr -d ' ')
    
    echo "{\"id\":$((count+1)),\"description\":\"${desc}\",\"category\":\"${category}\",\"status\":\"${status}\",\"timestamp\":\"${ts}\",\"date\":\"${date_str}\"}" >> "$LOG_FILE"
    echo -e "${GREEN}✓ Logged:${NC} [$category] $desc ($status)"
}

list_entries() {
    local filter="${1:-}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📋 Improvement Log${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    if [ -n "$filter" ]; then
        echo -e "  Filter: ${YELLOW}${filter}${NC}\n"
        jq -r "select(.category == \"${filter}\") | \"  [\(.date)] [\(.status)] \(.description)\"" "$LOG_FILE" 2>/dev/null || echo "  (empty)"
    else
        jq -r '"  [\(.date)] [\(.category)] [\(.status)] \(.description)"' "$LOG_FILE" 2>/dev/null || echo "  (empty)"
    fi
    echo ""
}

show_stats() {
    local total=$(wc -l < "$LOG_FILE" | tr -d ' ')
    local categories=$(jq -r '.category' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn)
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📊 Improvement Stats${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "  Total entries: ${GREEN}${total}${NC}"
    echo -e "\n  By category:"
    echo "$categories" | while read count cat; do
        echo -e "    ${YELLOW}${cat}${NC}: ${count}"
    done
    # Save stats
    jq -s '{total: length, categories: (group_by(.category) | map({(.[0].category): length}) | add)}' "$LOG_FILE" > "$STATS_FILE" 2>/dev/null || true
}

case "${1:-}" in
    --list) list_entries "$2" ;;
    --stats) show_stats ;;
    --export) cat "$LOG_FILE" ;;
    *) [ -n "$1" ] && log_entry "$1" "$2" "$3" || echo "Usage: log.sh 'desc' 'category' 'status'" ;;
esac
