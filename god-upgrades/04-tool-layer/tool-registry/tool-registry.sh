#!/bin/bash
# Tool Registry — GOD register function ได้เอง + reuse ทุก session
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
REGISTRY="${DIR}/registry.json"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

[ ! -f "$REGISTRY" ] && echo '{"tools":[]}' > "$REGISTRY"

register() {
    local name="$1" cmd="$2" desc="${3:-}" category="${4:-general}"
    [ -z "$name" ] && echo "Usage: --register 'name' 'command' 'desc' 'category'" && return 1
    local tmp=$(mktemp)
    jq --arg n "$name" --arg c "$cmd" --arg d "$desc" --arg cat "$category" \
       '.tools += [{"name":$n,"command":$c,"desc":$d,"category":$cat,"registered":"'"$(date +%Y-%m-%d)"'","uses":0}]' \
       "$REGISTRY" > "$tmp" && mv "$tmp" "$REGISTRY"
    echo -e "${GREEN}✓ Registered:${NC} $name [$category]"
}

run() {
    local name="$1"
    local cmd=$(jq -r --arg n "$name" '.tools[] | select(.name == $n) | .command' "$REGISTRY" 2>/dev/null)
    [ -z "$cmd" ] && echo "Tool not found: $name" && return 1
    
    # Increment usage
    local tmp=$(mktemp)
    jq --arg n "$name" '.tools = [.tools[] | if .name == $n then .uses += 1 else . end]' "$REGISTRY" > "$tmp" && mv "$tmp" "$REGISTRY"
    
    echo -e "${CYAN}Running: ${name}${NC}"
    eval "$cmd"
}

list() {
    echo -e "${CYAN}Tool Registry ($(jq '.tools | length' "$REGISTRY") tools)${NC}\n"
    jq -r '.tools | group_by(.category) | .[] | "  [" + .[0].category + "]\n" + (map("    \(.name) — \(.desc) (used \(.uses)x)") | join("\n"))' "$REGISTRY" 2>/dev/null || echo "  (empty)"
}

search() {
    local query="$1"
    jq -r --arg q "$query" '.tools[] | select(.name | test($q; "i") or (.desc | test($q; "i") or (.category | test($q; "i")))) | "  🔧 \(.name) [\(.category)]: \(.command)"' "$REGISTRY" 2>/dev/null || echo "  No tools found"
}

remove() {
    local name="$1"
    local tmp=$(mktemp)
    jq --arg n "$name" '.tools = [.tools[] | select(.name != $n)]' "$REGISTRY" > "$tmp" && mv "$tmp" "$REGISTRY"
    echo -e "${GREEN}✓ Removed:${NC} $name"
}

case "${1:-}" in
    --register) register "$2" "$3" "$4" "$5" ;;
    --run) run "$2" ;;
    --list) list ;;
    --search) search "$2" ;;
    --remove) remove "$2" ;;
    *) echo "Usage: tool-registry.sh [--register|--run|--list|--search|--remove]" ;;
esac
