#!/bin/bash
# Permission System — แบ่งระดับ permission
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; PERMS="${DIR}/permissions.json"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$PERMS" ] && echo '{"levels":{"read":{"desc":"Read files, search, index","allowed":["read","search","index","list"]},"write":{"desc":"Create/edit files","allowed":["read","search","index","list","write","edit","create"]},"delete":{"desc":"Delete files","allowed":["read","search","index","list","write","edit","create","delete","archive"]},"deploy":{"desc":"Deploy/push code","allowed":["read","search","index","list","write","edit","create","delete","archive","push","deploy","publish"]}},"default_level":"write"}' > "$PERMS"

check() { local action="$1" level="${2:-write}"; local allowed=$(jq -r --arg l "$level" '.levels[$l].allowed | join(" ")' "$PERMS" 2>/dev/null)
    echo "$allowed" | grep -qw "$action" && echo -e "${GREEN}✓ ALLOWED:${NC} $action [$level]" || echo -e "${RED}✗ DENIED:${NC} $action [$level]"; }
case "${1:-}" in --check) check "$2" "$3";; --levels) jq -r '.levels | to_entries[] | "  \(.key): \(.value.desc)"' "$PERMS";; *) echo "Usage: permission-system.sh [--check 'action' 'level']";; esac
