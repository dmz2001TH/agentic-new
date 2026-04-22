#!/bin/bash
# Backup Strategy — auto backup ก่อน destructive action
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; BACKUP="${DIR}/backups"; LOG="${DIR}/backup-log.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
mkdir -p "$BACKUP"; [ ! -f "$LOG" ] && touch "$LOG"

backup_file() { local file="$1"; [ ! -f "$file" ] && return 1; local name="$(basename "$file").$(date +%Y%m%d%H%M%S).bak"; cp "$file" "${BACKUP}/${name}"; echo -e "${GREEN}✓ Backed up:${NC} $name"; echo "{\"file\":\"${file}\",\"backup\":\"${name}\",\"size\":$(wc -c < "$file"|tr -d ' '),\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG"; }
backup_dir() { local dir="$1"; local archive="backup-$(date +%Y%m%d%H%M%S).tar.gz"; tar czf "${BACKUP}/${archive}" "$dir" 2>/dev/null; echo -e "${GREEN}✓ Backed up dir:${NC} $archive ($(du -h "${BACKUP}/${archive}" | cut -f1))"; }
restore() { local name="$1"; local file=$(ls -t "${BACKUP}/${name}"* 2>/dev/null | head -1); [ -z "$file" ] && echo "Not found" && return 1; local original=$(echo "$name" | sed 's/\.[0-9]*\.bak$//'); cp "$file" "./${original}"; echo -e "${GREEN}✓ Restored:${NC} ${original}"; }
case "${1:-}" in --file) backup_file "$2";; --dir) backup_dir "$2";; --restore) restore "$2";; --list) ls -lh "$BACKUP" 2>/dev/null | tail -n +2 | while read l; do echo "  $l"; done;; *) echo "Usage: backup-strategy.sh [--file|--dir|--restore|--list]";; esac
