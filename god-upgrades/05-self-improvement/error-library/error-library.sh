#!/bin/bash
# Error Library — เก็บ error + solution pattern แยกจาก decisions
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; LIB="${DIR}/errors.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$LIB" ] && touch "$LIB"

log_error() { local err="$1" sol="$2" cat="${3:-general}"; [ -z "$err" ] && return 1; echo "{\"error\":$(echo "$err"|jq -Rs .),\"solution\":$(echo "$sol"|jq -Rs .),\"category\":\"${cat}\",\"date\":\"$(date +%Y-%m-%d)\",\"count\":1}" >> "$LIB"; echo -e "${GREEN}✓ Error logged:${NC} $(echo "$err"|head -c 60)"; }
find_solution() { local q="$1"; echo -e "${CYAN}Error lookup: ${q}${NC}\n"; grep -i "$q" "$LIB" 2>/dev/null | jq -r '"  ✗ \(.error | .[:60])\n  ✓ \(.solution | .[:80]) (seen \(.count)x)"' | head -20 || echo "  No known solution"; }
list_errors() { echo -e "${CYAN}Error Library ($(wc -l < "$LIB"|tr -d ' ') entries)${NC}\n"; jq -s 'group_by(.category) | .[] | "  [" + .[0].category + "] " + (length|tostring) + " errors"' "$LIB" 2>/dev/null; }
case "${1:-}" in --log) log_error "$2" "$3" "$4";; --find) find_solution "$2";; --list) list_errors;; *) echo "Usage: error-library.sh [--log|--find|--list]";; esac
