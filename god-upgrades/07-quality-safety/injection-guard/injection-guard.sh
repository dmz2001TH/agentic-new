#!/bin/bash
# Injection Guard — กันไม่ให้ external content มากำหนด behavior
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; PATTERNS="${DIR}/patterns.json"; LOG="${DIR}/blocked.jsonl"; GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$PATTERNS" ] && echo '{"patterns":["ignore.*previous.*instructions","you are now","system.*prompt","jailbreak","DAN mode","do anything now","pretend you are","act as if","bypass.*safety","override.*rules"]}' > "$PATTERNS"
[ ! -f "$LOG" ] && touch "$LOG"

scan() { local text="$1"; [ -z "$text" ] && return 1; local found=0
    echo -e "${CYAN}Injection Scan:${NC}\n"
    jq -r '.patterns[]' "$PATTERNS" 2>/dev/null | while read pattern; do
        if echo "$text" | grep -qiP "$pattern" 2>/dev/null; then
            echo -e "  ${RED}🚨 BLOCKED:${NC} Pattern matched: ${pattern}"
            echo "{\"pattern\":\"${pattern}\",\"blocked_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG"
            found=$((found+1))
        fi
    done
    [ "$found" -eq 0 ] && echo -e "  ${GREEN}✓ No injection detected${NC}" || echo -e "\n  ${RED}⚠ ${found} injection patterns found!${NC}"
}
case "${1:-}" in --scan) scan "$2";; --log) tail -10 "$LOG" | jq -r '"  [\(.blocked_at)] \(.pattern)"' 2>/dev/null;; *) echo "Usage: injection-guard.sh [--scan|--log]";; esac
