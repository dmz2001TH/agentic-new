#!/bin/bash
# Snippet Library — เก็บ code pattern ที่ reuse ได้
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
LIBRARY="${DIR}/snippets.json"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

[ ! -f "$LIBRARY" ] && echo '{"snippets":[]}' > "$LIBRARY"

add() {
    local name="$1" lang="$2" code="$3" desc="${4:-}"
    [ -z "$name" ] && echo "Usage: --add 'name' 'lang' 'code' 'desc'" && return 1
    local tmp=$(mktemp)
    jq --arg n "$name" --arg l "$lang" --arg c "$code" --arg d "$desc" \
       '.snippets += [{"name":$n,"lang":$l,"code":$c,"desc":$d,"added":"'"$(date +%Y-%m-%d)"'","uses":0}]' \
       "$LIBRARY" > "$tmp" && mv "$tmp" "$LIBRARY"
    echo -e "${GREEN}✓ Added:${NC} $name [$lang]"
}

search() {
    local query="$1"
    echo -e "${CYAN}Snippets matching: ${query}${NC}\n"
    jq -r --arg q "$query" '.snippets[] | select(.name | test($q; "i") or (.desc | test($q; "i"))) | "  📦 \(.name) [\(.lang)] — \(.desc)\n     Uses: \(.uses)"' "$LIBRARY" 2>/dev/null || echo "  No results"
}

get() {
    local name="$1"
    jq -r --arg n "$name" '.snippets[] | select(.name == $n) | "## \(.name) [\(.lang)]\n\(.desc)\n\n```\`\`\(.lang)\n\(.code)\n```\`\`"' "$LIBRARY" 2>/dev/null || echo "Not found: $name"
}

list() {
    echo -e "${CYAN}Snippet Library ($(jq '.snippets | length' "$LIBRARY") snippets)${NC}\n"
    jq -r '.snippets[] | "  \(.name) [\(.lang)] — \(.desc) (used \(.uses)x)"' "$LIBRARY" 2>/dev/null || echo "  (empty)"
}

case "${1:-}" in
    --add) add "$2" "$3" "$4" "$5" ;;
    --search) search "$2" ;;
    --get) get "$2" ;;
    --list) list ;;
    *) echo "Usage: snippet-library.sh [--add|--search|--get|--list]" ;;
esac
