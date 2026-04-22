#!/bin/bash
# Change Detector — ตรวจไฟล์ที่เปลี่ยน → auto analyze impact
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; LOG="${DIR}/changes.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$LOG" ] && touch "$LOG"

detect() { local dir="${1:-.}" since="${2:-1 hour ago}"; echo -e "${CYAN}Changes since: ${since}${NC}\n"
    find "$dir" -newer <(date -d "$since" +%Y%m%d%H%M 2>/dev/null || date -v-1H +%Y%m%d%H%M 2>/dev/null || echo "200001010000") -type f 2>/dev/null | grep -v '.git/' | head -20 | while read f; do
        local mod=$(stat -c %y "$f" 2>/dev/null | cut -d'.' -f1 || stat -f %Sm "$f" 2>/dev/null)
        echo -e "  📝 ${f} (modified: ${mod})"
        echo "{\"file\":\"${f}\",\"modified\":\"${mod}\",\"detected\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG"
    done
}
impact() { local file="$1"; [ ! -f "$file" ] && return 1; echo -e "${CYAN}Impact analysis: ${file}${NC}\n"
    local name=$(basename "$file")
    echo -e "  ${YELLOW}Referenced by:${NC}"
    grep -rli "$name" . --include="*.sh" --include="*.md" --include="*.json" 2>/dev/null | grep -v "$file" | head -5 | while read f; do echo "    📄 $f"; done
    echo -e "\n  ${YELLOW}Git history:${NC}"
    git log --oneline -5 -- "$file" 2>/dev/null || echo "    (no git history)"
}
case "${1:-}" in --detect) detect "$2" "$3";; --impact) impact "$2";; --log) tail -10 "$LOG" | jq -r '"  [\(.detected)] \(.file)"' 2>/dev/null;; *) echo "Usage: change-detector.sh [--detect|--impact|--log]";; esac
