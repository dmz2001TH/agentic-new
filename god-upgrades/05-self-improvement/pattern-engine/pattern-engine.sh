#!/bin/bash
# Pattern Engine — auto detect ซ้ำ ≥3 → promote
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; ENGINE="${DIR}/engine.jsonl"; RULES="${DIR}/promoted-rules.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
[ ! -f "$ENGINE" ] && touch "$ENGINE"; [ ! -f "$RULES" ] && touch "$RULES"

observe() { local event="$1"; [ -z "$event" ] && return 1; echo "{\"event\":$(echo "$event"|jq -Rs .),\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$ENGINE"
    local keyword=$(echo "$event" | tr ' ' '\n' | head -2 | tr '\n' '|' | sed 's/|$//')
    local count=$(grep -ci "$keyword" "$ENGINE" 2>/dev/null || echo 0)
    count=${count:-0}
    echo -e "${GREEN}✓ Observed:${NC} $event (similar: ${count}x)"
    [ "$count" -ge 3 ] && echo -e "${YELLOW}⚡ PATTERN DETECTED! Consider promoting to rule.${NC}"; }
promote() { local rule="$1"; echo "{\"rule\":$(echo "$rule"|jq -Rs .),\"promoted\":\"$(date +%Y-%m-%d)\",\"source\":\"pattern_engine\"}" >> "$RULES"; echo -e "${GREEN}✓ Rule promoted:${NC} $rule"; }
scan() { echo -e "${CYAN}Scanning for repeated patterns...${NC}\n"; jq -s 'group_by(.event) | map(select(length >= 3)) | .[] | "  ⚡ \(length)x: \(.[0].event | .[:60])"' "$ENGINE" 2>/dev/null || echo "  No patterns found (need ≥3 occurrences)"; }
case "${1:-}" in --observe) observe "$2";; --promote) promote "$2";; --scan) scan;; --rules) echo -e "${CYAN}Promoted Rules:${NC}\n"; jq -r '"  📏 \(.rule) (promoted \(.promoted))"' "$RULES" 2>/dev/null || echo "  (none)";; *) echo "Usage: pattern-engine.sh [--observe|--promote|--scan|--rules]";; esac
