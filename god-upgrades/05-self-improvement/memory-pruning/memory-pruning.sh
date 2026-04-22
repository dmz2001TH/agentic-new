#!/bin/bash
# Memory Pruning — auto clean memory ที่ไม่ relevant แล้ว (archive, don't delete)
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; ARCHIVE="${DIR}/archive"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'
mkdir -p "$ARCHIVE"

prune() { local file="$1" max_age_days="${2:-90}"; [ ! -f "$file" ] && echo "Not found: $file" && return 1
    local age_days=$(( ($(date +%s) - $(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)) / 86400 ))
    if [ "$age_days" -gt "$max_age_days" ]; then
        local archive_name="$(basename "$file").$(date +%Y%m%d).archived"
        mv "$file" "${ARCHIVE}/${archive_name}"
        echo -e "${YELLOW}📦 Archived:${NC} $(basename "$file") (${age_days} days old)"
    else
        echo -e "${GREEN}✓ Active:${NC} $(basename "$file") (${age_days} days)"
    fi
}

prune_directory() { local dir="$1" max_age="${2:-90}"; echo -e "${CYAN}Pruning: ${dir} (>${max_age} days)${NC}\n"; find "$dir" -name "*.md" -o -name "*.jsonl" 2>/dev/null | while read f; do prune "$f" "$max_age"; done; }
restore() { local name="$1"; local file=$(ls -t "${ARCHIVE}/${name}"* 2>/dev/null | head -1); [ -z "$file" ] && echo "Not found: $name" && return 1; mv "$file" "./$(basename "$file" | sed 's/\.[0-9]*\.archived//')"; echo -e "${GREEN}✓ Restored:${NC} $name"; }
case "${1:-}" in --prune) prune "$2" "$3";; --prune-dir) prune_directory "$2" "$3";; --restore) restore "$2";; --list) ls "$ARCHIVE" 2>/dev/null | while read f; do echo "  📦 $f"; done || echo "  (empty)";; *) echo "Usage: memory-pruning.sh [--prune|--prune-dir|--restore|--list]";; esac
