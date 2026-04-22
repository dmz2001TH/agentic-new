#!/bin/bash
# File Guard — ตรวจก่อน write ป้องกัน overwrite ไฟล์สำคัญ
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
PROTECTED="${DIR}/protected.json"
BACKUP_DIR="${DIR}/backups"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$BACKUP_DIR"
[ ! -f "$PROTECTED" ] && echo '{"protected":["GEMINI.md","brain-bridge.sh",".gitignore","README.md"],"max_backup_age_days":30}' > "$PROTECTED"

check_before_write() {
    local file="$1"
    [ -z "$file" ] && echo "Usage: --check 'file_path'" && return 1
    
    if [ -f "$file" ]; then
        local filename=$(basename "$file")
        local is_protected=$(jq -r --arg f "$filename" '.protected | index($f) != null' "$PROTECTED" 2>/dev/null)
        
        if [ "$is_protected" = "true" ]; then
            echo -e "${RED}🛡️ PROTECTED FILE:${NC} $file"
            echo -e "  This file is protected. Backup first."
            return 1
        fi
        
        # Auto-backup
        local backup_name="${filename}.$(date +%Y%m%d%H%M%S).bak"
        cp "$file" "${BACKUP_DIR}/${backup_name}"
        echo -e "${GREEN}✓ Backed up:${NC} ${BACKUP_DIR}/${backup_name}"
    fi
    return 0
}

safe_write() {
    local file="$1" content="$2"
    [ -z "$file" ] && echo "Usage: --safe-write 'file' 'content'" && return 1
    
    if check_before_write "$file"; then
        echo "$content" > "$file"
        echo -e "${GREEN}✓ Written:${NC} $file"
    else
        echo -e "${RED}✗ Write blocked (protected file)${NC}"
        return 1
    fi
}

add_protected() {
    local file="$1"
    local tmp=$(mktemp)
    jq --arg f "$(basename "$file")" '.protected += [$f] | .protected |= unique' "$PROTECTED" > "$tmp" && mv "$tmp" "$PROTECTED"
    echo -e "${GREEN}✓ Protected:${NC} $(basename "$file")"
}

restore_backup() {
    local file="$1"
    local latest=$(ls -t "${BACKUP_DIR}/$(basename "$file")."* 2>/dev/null | head -1)
    [ -z "$latest" ] && echo "No backup found for: $file" && return 1
    cp "$latest" "$file"
    echo -e "${GREEN}✓ Restored:${NC} $file ← $(basename "$latest")"
}

case "${1:-}" in
    --check) check_before_write "$2" ;;
    --safe-write) safe_write "$2" "$3" ;;
    --add-protected) add_protected "$2" ;;
    --restore) restore_backup "$2" ;;
    --list-protected) jq -r '.protected[] | "  🛡️ \(.)"' "$PROTECTED";;
    --list-backups) ls -la "$BACKUP_DIR" 2>/dev/null | tail -n +2 | while read line; do echo "  $line"; done;;
    *) echo "Usage: file-guard.sh [--check|--safe-write|--add-protected|--restore|--list-protected|--list-backups]" ;;
esac
