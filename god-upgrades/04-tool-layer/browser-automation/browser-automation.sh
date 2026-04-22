#!/bin/bash
# Browser Automation — scrape web, test UI, screenshot (wrapper)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE="${DIR}/cache"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$CACHE"

fetch() {
    local url="$1" extract="${2:-text}"
    [ -z "$url" ] && echo "Usage: --fetch 'url' [text|html|links]" && return 1
    
    local slug=$(echo "$url" | sed 's|https\?://||;s|[^a-zA-Z0-9]||g' | head -c 30)
    local cached="${CACHE}/${slug}.html"
    
    # Fetch if not cached or >1hr old
    if [ ! -f "$cached" ] || [ $(find "$cached" -mmin +60 2>/dev/null | wc -l) -gt 0 ]; then
        curl -sL -o "$cached" "$url" 2>/dev/null
    fi
    
    case "$extract" in
        text) cat "$cached" | sed 's/<[^>]*>//g; s/&nbsp;/ /g' | sed '/^$/d' | head -100;;
        html) cat "$cached" | head -100;;
        links) grep -oP 'href="[^"]*"' "$cached" 2>/dev/null | sed 's/href="//;s/"$//' | sort -u | head -20;;
        title) grep -oP '<title>[^<]*' "$cached" 2>/dev/null | sed 's/<title>//' | head -1;;
    esac
}

screenshot() {
    echo "Screenshot requires browser automation tool (Playwright/Puppeteer)"
    echo "Use with: playwright screenshot --url '\$1' --output '\$2'"
}

test_page() {
    local url="$1"
    [ -z "$url" ] && echo "Usage: --test 'url'" && return 1
    
    echo -e "${CYAN}Testing: ${url}${NC}\n"
    local code=$(curl -s -o /dev/null -w '%{http_code}' "$url" 2>/dev/null)
    local time=$(curl -s -o /dev/null -w '%{time_total}' "$url" 2>/dev/null)
    local title=$(fetch "$url" "title")
    
    echo -e "  Status: $([ "$code" = "200" ] && echo "${GREEN}${code} OK${NC}" || echo "${CYAN}${code}${NC}")"
    echo -e "  Load time: ${time}s"
    echo -e "  Title: ${title}"
}

case "${1:-}" in
    --fetch) fetch "$2" "$3" ;;
    --screenshot) screenshot "$2" ;;
    --test) test_page "$2" ;;
    --clear-cache) rm -f "$CACHE"/* && echo "Cache cleared";;
    *) echo "Usage: browser-automation.sh [--fetch|--screenshot|--test|--clear-cache]" ;;
esac
