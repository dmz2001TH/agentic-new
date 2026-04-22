#!/bin/bash
# Doc Crawler — crawl doc site แล้ว index เข้า knowledge base
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS="${DIR}/crawled-docs"
INDEX="${DIR}/doc-index.jsonl"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$DOCS"
[ ! -f "$INDEX" ] && touch "$INDEX"

crawl() {
    local url="$1" depth="${2:-1}"
    [ -z "$url" ] && echo "Usage: --crawl 'url' [depth]" && return 1
    
    local slug=$(echo "$url" | sed 's|https\?://||;s|/|_|g;s|[^a-zA-Z0-9_-]||g' | head -c 50)
    local outfile="${DOCS}/${slug}.txt"
    
    echo -e "${CYAN}Crawling: ${url}${NC}"
    curl -sL "$url" 2>/dev/null | sed 's/<[^>]*>//g; s/&nbsp;/ /g; s/&amp;/\&/g' | sed '/^$/d' | head -500 > "$outfile"
    
    local size=$(wc -c < "$outfile" | tr -d ' ')
    local lines=$(wc -l < "$outfile" | tr -d ' ')
    
    echo "{\"url\":\"${url}\",\"file\":\"${slug}.txt\",\"size\":${size},\"lines\":${lines},\"crawled\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$INDEX"
    echo -e "${GREEN}✓ Crawled:${NC} ${lines} lines → ${outfile}"
}

search() {
    local query="$1"
    echo -e "${CYAN}Doc search: ${query}${NC}\n"
    grep -rli "$query" "$DOCS" 2>/dev/null | head -5 | while read f; do
        local url=$(jq -r --arg f "$(basename "$f")" 'select(.file == $f) | .url' "$INDEX" 2>/dev/null | head -1)
        echo -e "  📄 $(basename "$f") — ${url}"
        grep -i "$query" "$f" 2>/dev/null | head -3 | while read line; do echo "      $line"; done
    done
}

case "${1:-}" in
    --crawl) crawl "$2" "$3" ;;
    --search) search "$2" ;;
    --list) echo "Crawled docs: $(wc -l < "$INDEX" | tr -d ' ')"; jq -r '"  \(.url) (\(.lines) lines)"' "$INDEX" 2>/dev/null;;
    *) echo "Usage: doc-crawler.sh [--crawl|--search|--list]" ;;
esac
