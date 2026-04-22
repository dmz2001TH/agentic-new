#!/bin/bash
# Repo Indexer — index GitHub repo ที่ clone มา → query ได้โดยไม่อ่านทั้ง repo
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
INDEX="${DIR}/repo-index.json"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

index_repo() {
    local repo_path="$1"
    [ ! -d "$repo_path" ] && echo "Not found: $repo_path" && return 1
    local name=$(basename "$repo_path")
    echo -e "${CYAN}Indexing repo: ${name}${NC}"
    
    local files=$(find "$repo_path" -maxdepth 3 -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null | head -200)
    local count=0 entries="[]"
    
    echo "$files" | while read f; do
        [ -f "$f" ] || continue
        local rel="${f#$repo_path/}"
        local lines=$(wc -l < "$f" | tr -d ' ')
        local first=$(head -5 "$f" | tr '\n' ' ' | cut -c1-200)
        echo "{\"repo\":\"${name}\",\"path\":\"${rel}\",\"lines\":${lines},\"preview\":$(echo "$first" | jq -Rs .)}" >> "${DIR}/entries.jsonl"
        count=$((count+1))
    done
    
    echo -e "${GREEN}✓ Indexed: ${name} ($(wc -l < "${DIR}/entries.jsonl" | tr -d ' ') files)${NC}"
}

search_repo() {
    local query="$1"
    echo -e "${CYAN}Search: ${query}${NC}\n"
    grep -i "$query" "${DIR}/entries.jsonl" 2>/dev/null | jq -r '"  📄 \(.repo)/\(.path) (\(.lines) lines)"' | head -10 || echo "  No results"
}

case "${1:-}" in
    --index) index_repo "$2" ;;
    --search) search_repo "$2" ;;
    --stats) echo "Entries: $(wc -l < "${DIR}/entries.jsonl" 2>/dev/null || echo 0)"; echo "Repos: $(jq -r '.repo' "${DIR}/entries.jsonl" 2>/dev/null | sort -u | wc -l)";;
    *) echo "Usage: repo-indexer.sh [--index|--search|--stats]" ;;
esac
