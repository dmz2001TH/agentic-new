#!/bin/bash
# Web Search — ค้น real-time (wrapper for curl search APIs)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
HISTORY="${DIR}/search-history.jsonl"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

[ ! -f "$HISTORY" ] && touch "$HISTORY"

search() {
    local query="$1" engine="${2:-duckduckgo}"
    [ -z "$query" ] && echo "Usage: --search 'query' [engine]" && return 1
    
    echo -e "${CYAN}🔍 Web Search: ${query} (${engine})${NC}\n"
    
    case "$engine" in
        duckduckgo)
            local results=$(curl -s "https://api.duckduckgo.com/?q=$(echo "$query" | sed 's/ /+/g')&format=json&no_html=1" 2>/dev/null)
            echo "$results" | jq -r '.RelatedTopics[:5][] | "  🔗 \(.Text | .[:100])\n     \(.FirstURL)"' 2>/dev/null || echo "  No API results. Use browser for full search."
            ;;
        github)
            if command -v gh &>/dev/null; then
                gh search repos "$query" --limit 5 2>/dev/null | while read line; do echo "  🔗 $line"; done
            else
                echo "  gh CLI not available"
            fi
            ;;
        local)
            grep -rli "$query" . --include="*.md" --include="*.txt" --include="*.sh" --include="*.py" 2>/dev/null | head -10 | while read f; do
                echo "  📄 $f"
            done
            ;;
    esac
    
    echo "{\"query\":$(echo "$query" | jq -Rs .),\"engine\":\"${engine}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$HISTORY"
}

case "${1:-}" in
    --search) search "$2" "$3" ;;
    --history) tail -20 "$HISTORY" | jq -r '"  [\(.timestamp)] \(.engine): \(.query)"' 2>/dev/null;;
    *) echo "Usage: web-search.sh [--search|--history]" ;;
esac
