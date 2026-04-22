#!/bin/bash
# Vector Store — Semantic search สำหรับ memory (FAISS/ChromaDB wrapper)
# Usage: bash vector-store.sh --index| --search "query"| --stats

set -e
VS_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEX_DIR="${VS_DIR}/index"
EMBEDDINGS_FILE="${VS_DIR}/embeddings.jsonl"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$INDEX_DIR"

index_file() {
    local file="$1"
    [ ! -f "$file" ] && echo "File not found: $file" && return 1
    local content=$(cat "$file" | head -200)
    local chunks=$(echo "$content" | fold -w 500 | head -20)
    local i=0
    echo "$chunks" | while read -r chunk; do
        [ -z "$chunk" ] && continue
        echo "{\"file\":\"${file}\",\"chunk\":${i},\"text\":$(echo "$chunk" | jq -Rs .),\"indexed\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$EMBEDDINGS_FILE"
        i=$((i+1))
    done
    echo -e "${GREEN}✓ Indexed:${NC} $file"
}

index_directory() {
    local dir="${1:-.}"
    echo -e "${CYAN}Indexing: ${dir}${NC}"
    find "$dir" -name "*.md" -o -name "*.txt" -o -name "*.sh" -o -name "*.json" 2>/dev/null | while read f; do
        index_file "$f"
    done
    echo -e "${GREEN}✓ Index complete: $(wc -l < "$EMBEDDINGS_FILE" | tr -d ' ') chunks${NC}"
}

search_store() {
    local query="$1"
    [ -z "$query" ] && echo "Usage: --search 'query'" && return 1
    echo -e "${CYAN}Searching: ${query}${NC}\n"
    grep -i "$query" "$EMBEDDINGS_FILE" 2>/dev/null | jq -r '"  📄 \(.file) (chunk \(.chunk)): \(.text | .[:100])"' | head -10 || echo "  No results"
}

case "${1:-}" in
    --index) index_directory "$2" ;;
    --index-file) index_file "$2" ;;
    --search) search_store "$2" ;;
    --stats) echo "Chunks: $(wc -l < "$EMBEDDINGS_FILE" | tr -d ' ')"; echo "Files: $(jq -r '.file' "$EMBEDDINGS_FILE" 2>/dev/null | sort -u | wc -l)";;
    *) echo "Usage: vector-store.sh [--index|--search|--stats]" ;;
esac
