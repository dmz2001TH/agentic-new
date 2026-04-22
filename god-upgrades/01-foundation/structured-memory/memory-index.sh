#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Structured Memory — JSON index สำหรับ memory files
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash memory-index.sh --build        # rebuild index
#   bash memory-index.sh --search "q"   # search index
#   bash memory-index.sh --stats        # show stats
#   bash memory-index.sh --add "file" "tags" "summary"

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GOD_ROOT="${GOD_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
MEMORY_DIR="${GOD_ROOT}/ψ/memory"
INDEX_FILE="${SCRIPT_DIR}/memory-index.json"
SEARCH_CACHE="${SCRIPT_DIR}/search-cache.json"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "$SCRIPT_DIR"

build_index() {
    echo -e "${CYAN}Building memory index...${NC}"
    local entries="[]"
    local count=0

    # Index all markdown files in memory directory
    if [ -d "$MEMORY_DIR" ]; then
        for file in "$MEMORY_DIR"/*.md "$MEMORY_DIR"/inbox/*.md "$MEMORY_DIR"/learnings/*.md "$MEMORY_DIR"/retrospective/*.md 2>/dev/null; do
            [ -f "$file" ] || continue
            local rel_path="${file#$GOD_ROOT/}"
            local filename=$(basename "$file")
            local size=$(wc -c < "$file" | tr -d ' ')
            local lines=$(wc -l < "$file" | tr -d ' ')
            local modified=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null || echo "0")
            local mod_date=$(date -d @"$modified" +%Y-%m-%d 2>/dev/null || date -r "$modified" +%Y-%m-%d 2>/dev/null || echo "unknown")
            local first_line=$(head -1 "$file" | sed 's/["\]/\\&/g' | head -c 100)

            # Extract headers as tags
            local tags=$(grep -oP '^#+\s+\K.*' "$file" 2>/dev/null | head -5 | tr '\n' ',' | sed 's/,$//')

            entries=$(echo "$entries" | jq --arg path "$rel_path" --arg name "$filename" \
                --argjson size "$size" --argjson lines "$lines" --arg modified "$mod_date" \
                --arg first "$first_line" --arg tags "$tags" \
                '. += [{"path":$path,"name":$name,"size":$size,"lines":$lines,"modified":$modified,"preview":$first,"tags":$tags}]')
            ((count++))
        done
    fi

    # Also index god-upgrades files
    for file in "$GOD_ROOT"/god-upgrades/**/*.sh "$GOD_ROOT"/god-upgrades/**/*.json "$GOD_ROOT"/god-upgrades/**/*.md 2>/dev/null; do
        [ -f "$file" ] || continue
        local rel_path="${file#$GOD_ROOT/}"
        local filename=$(basename "$file")
        local size=$(wc -c < "$file" | tr -d ' ')
        local lines=$(wc -l < "$file" | tr -d ' ')

        entries=$(echo "$entries" | jq --arg path "$rel_path" --arg name "$filename" --argjson size "$size" --argjson lines "$lines" \
            '. += [{"path":$path,"name":$name,"size":$size,"lines":$lines,"type":"upgrade"}]')
        ((count++))
    done

    echo "{\"indexed_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"total\":${count},\"entries\":${entries}}" | jq '.' > "$INDEX_FILE"
    echo -e "${GREEN}✓ Index built:${NC} ${count} entries → $INDEX_FILE"
}

search_index() {
    local query="$1"
    [ -z "$query" ] && echo "Usage: --search 'query'" && return 1
    echo -e "${CYAN}Searching: ${query}${NC}\n"
    jq -r --arg q "$query" '
        .entries[] | select(
            (.name | test($q; "i")) or
            (.tags // "" | test($q; "i")) or
            (.preview // "" | test($q; "i"))
        ) | "  📄 \(.path) (\(.lines // "?") lines)"
    ' "$INDEX_FILE" 2>/dev/null || echo "  No results"
}

show_stats() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📊 Memory Index Stats${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    if [ -f "$INDEX_FILE" ]; then
        local total=$(jq '.total' "$INDEX_FILE")
        local indexed=$(jq '.indexed_at' "$INDEX_FILE")
        echo -e "  Total files: ${GREEN}${total}${NC}"
        echo -e "  Indexed at: ${indexed}"
        echo -e "\n  By type:"
        jq -r '.entries | group_by(.type // "memory") | map("\(.[0].type // "memory"): \(length)") | .[]' "$INDEX_FILE" 2>/dev/null | while read line; do
            echo -e "    ${YELLOW}${line}${NC}"
        done
    else
        echo -e "  ${YELLOW}No index found. Run --build first.${NC}"
    fi
}

add_entry() {
    local file="$1" tags="$2" summary="$3"
    [ -z "$file" ] && echo "Usage: --add 'file' 'tags' 'summary'" && return 1
    if [ -f "$INDEX_FILE" ]; then
        local tmp=$(mktemp)
        jq --arg path "$file" --arg tags "$tags" --arg summary "$summary" \
           '.entries += [{"path":$path,"tags":$tags,"summary":$summary,"added":"'"$(date +%Y-%m-%d)"'","type":"manual"}] | .total += 1' \
           "$INDEX_FILE" > "$tmp" && mv "$tmp" "$INDEX_FILE"
        echo -e "${GREEN}✓ Added:${NC} $file"
    fi
}

case "${1:-}" in
    --build) build_index ;;
    --search) search_index "$2" ;;
    --stats) show_stats ;;
    --add) add_entry "$2" "$3" "$4" ;;
    *) echo "Usage: memory-index.sh [--build|--search|--stats|--add]" ;;
esac
