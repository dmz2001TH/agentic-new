#!/bin/bash
# Identity Drift Detection — ตรวจว่า GOD หลุด identity ไหม
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; RULES="${DIR}/rules.json"; LOG="${DIR}/drift-log.jsonl"; GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$RULES" ] && echo '{"must_contain":["GOD"],"must_not_contain":["I am an AI assistant","As an AI","I am Gemini","I am Claude"],"severity":"critical"}' > "$RULES"
[ ! -f "$LOG" ] && touch "$LOG"

check() { local text="$1"; [ -z "$text" ] && return 1; local drift=0
    echo -e "${CYAN}Identity Check:${NC}\n"
    jq -r '.must_contain[]' "$RULES" 2>/dev/null | while read word; do
        echo "$text" | grep -qi "$word" && echo -e "  ${GREEN}✓ Contains '${word}'${NC}" || { echo -e "  ${RED}✗ Missing '${word}' — DRIFT!${NC}"; drift=$((drift+1)); }
    done
    jq -r '.must_not_contain[]' "$RULES" 2>/dev/null | while read phrase; do
        echo "$text" | grep -qi "$phrase" && { echo -e "  ${RED}✗ Forbidden: '${phrase}' — DRIFT!${NC}"; echo "{\"drift\":\"forbidden\",\"phrase\":\"${phrase}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG"; } || echo -e "  ${GREEN}✓ No '${phrase}'${NC}"
    done
}
case "${1:-}" in --check) check "$2";; --log) tail -10 "$LOG" | jq -r '"  [\(.timestamp)] \(.drift): \(.phrase // .missing // "")"' 2>/dev/null;; *) echo "Usage: identity-detector.sh [--check|--log]";; esac
