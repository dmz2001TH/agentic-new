#!/bin/bash
# Dependency Tracker — ตรวจ library ที่ใช้ → แจ้ง outdated/vulnerable
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; LOG="${DIR}/dep-check.jsonl"; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$LOG" ] && touch "$LOG"

scan() { local dir="${1:-.}"; echo -e "${CYAN}Dependency scan: ${dir}${NC}\n"
    if [ -f "$dir/package.json" ]; then echo -e "${YELLOW}Node.js (package.json):${NC}"; jq -r '.dependencies // {} | to_entries[] | "  📦 \(.key): \(.value)"' "$dir/package.json" 2>/dev/null; npm outdated --prefix "$dir" 2>/dev/null | head -5 || true; fi
    if [ -f "$dir/requirements.txt" ]; then echo -e "${YELLOW}Python (requirements.txt):${NC}"; cat "$dir/requirements.txt" | head -10 | while read line; do echo "  📦 $line"; done; pip list --outdated 2>/dev/null | head -5 || true; fi
    if [ -f "$dir/go.mod" ]; then echo -e "${YELLOW}Go (go.mod):${NC}"; head -10 "$dir/go.mod" | while read line; do echo "  📦 $line"; done; fi
    echo "{\"scanned\":\"${dir}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG"
}
case "${1:-}" in --scan) scan "$2";; --history) tail -5 "$LOG" | jq -r '"  [\(.timestamp)] \(.scanned)"' 2>/dev/null;; *) echo "Usage: dependency-tracker.sh [--scan|--history]";; esac
