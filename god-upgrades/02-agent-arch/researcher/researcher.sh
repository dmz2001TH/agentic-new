#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Researcher Agent — ค้น GitHub, docs, web → หา solution
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash researcher.sh --github "query"
#   bash researcher.sh --docs "query" "url"
#   bash researcher.sh --error "error_message"
#   bash researcher.sh --research "topic"
#   bash researcher.sh --history

set -e
RES_DIR="$(cd "$(dirname "$0")" && pwd)"
HISTORY_FILE="${RES_DIR}/research-history.jsonl"
KNOWLEDGE_FILE="${RES_DIR}/knowledge-base.json"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "$RES_DIR"
[ ! -f "$HISTORY_FILE" ] && touch "$HISTORY_FILE"
[ ! -f "$KNOWLEDGE_FILE" ] && echo '{"solutions":[],"errors":[],"docs":[]}' > "$KNOWLEDGE_FILE"

log_research() {
    local type="$1" query="$2" result="$3"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "{\"type\":\"${type}\",\"query\":$(echo "$query" | jq -Rs .),\"result\":$(echo "$result" | jq -Rs .),\"timestamp\":\"${ts}\"}" >> "$HISTORY_FILE"
}

# Search GitHub repos/issues
search_github() {
    local query="$1"
    [ -z "$query" ] && echo "Usage: --github 'query'" && return 1
    
    echo -e "${CYAN}🔍 GitHub Search: ${query}${NC}\n"
    
    # Search in cloned repos first
    echo -e "${YELLOW}Local repos:${NC}"
    find /tmp/god-repo -name "*.md" -o -name "*.sh" -o -name "*.py" -o -name "*.js" 2>/dev/null | head -20 | while read f; do
        if grep -li "$query" "$f" 2>/dev/null | head -1 >/dev/null; then
            local matches=$(grep -c "$query" "$f" 2>/dev/null || echo 0)
            echo -e "  📄 ${f} (${matches} matches)"
            grep -n "$query" "$f" 2>/dev/null | head -3 | while read line; do
                echo -e "      ${line}"
            done
        fi
    done
    
    # Search online (if gh CLI available)
    if command -v gh &>/dev/null; then
        echo -e "\n${YELLOW}GitHub API:${NC}"
        gh search repos "$query" --limit 5 2>/dev/null | while read line; do
            echo -e "  🔗 ${line}"
        done || echo "  (gh not authenticated)"
    fi
    
    log_research "github" "$query" "search completed"
}

# Search documentation
search_docs() {
    local query="$1" url="${2:-}"
    [ -z "$query" ] && echo "Usage: --docs 'query' [url]" && return 1
    
    echo -e "${CYAN}📚 Doc Search: ${query}${NC}\n"
    
    if [ -n "$url" ]; then
        echo -e "  Fetching: ${url}"
        # Fetch and search within the page
        local content=$(curl -sL "$url" 2>/dev/null | sed 's/<[^>]*>//g' | grep -i "$query" | head -10)
        if [ -n "$content" ]; then
            echo "$content" | while read line; do
                echo -e "  📄 ${line}"
            done
        else
            echo "  No results found on page"
        fi
    fi
    
    # Search local docs
    echo -e "\n${YELLOW}Local docs:${NC}"
    find . -name "*.md" -exec grep -li "$query" {} \; 2>/dev/null | head -10 | while read f; do
        echo -e "  📄 ${f}"
    done
    
    log_research "docs" "$query" "doc search completed"
}

# Research error message
research_error() {
    local error="$1"
    [ -z "$error" ] && echo "Usage: --error 'error_message'" && return 1
    
    echo -e "${CYAN}🔬 Error Research: ${error}${NC}\n"
    
    # Check knowledge base first
    echo -e "${YELLOW}Known solutions:${NC}"
    jq -r --arg e "$error" '.errors[] | select(.pattern | test($e; "i")) | "  ✓ \(.solution) (seen \(.count) times)"' "$KNOWLEDGE_FILE" 2>/dev/null || echo "  (none found)"
    
    # Search in project files
    echo -e "\n${YELLOW}Project references:${NC}"
    grep -rli "$error" . 2>/dev/null | head -5 | while read f; do
        local ctx=$(grep -A2 -B2 "$error" "$f" 2>/dev/null | head -5)
        echo -e "  📄 ${f}:"
        echo "$ctx" | while read l; do echo -e "      ${l}"; done
    done
    
    # Search GitHub issues
    if command -v gh &>/dev/null; then
        echo -e "\n${YELLOW}GitHub Issues:${NC}"
        gh search issues "$error" --limit 3 2>/dev/null | while read line; do
            echo -e "  🐛 ${line}"
        done || true
    fi
    
    log_research "error" "$error" "error research completed"
}

# General research
research_topic() {
    local topic="$1"
    [ -z "$topic" ] && echo "Usage: --research 'topic'" && return 1
    
    echo -e "${CYAN}📖 Research: ${topic}${NC}\n"
    
    echo -e "${YELLOW}1. Local codebase:${NC}"
    grep -r "$topic" . --include="*.sh" --include="*.py" --include="*.js" --include="*.md" 2>/dev/null | head -10 | while read line; do
        echo -e "  ${line}"
    done
    
    echo -e "\n${YELLOW}2. Known patterns:${NC}"
    jq -r --arg t "$topic" '.solutions[] | select(.topic | test($t; "i")) | "  💡 \(.solution)"' "$KNOWLEDGE_FILE" 2>/dev/null || echo "  (none)"
    
    echo -e "\n${YELLOW}3. Documentation:${NC}"
    find . -name "*.md" -exec grep -li "$topic" {} \; 2>/dev/null | head -5 | while read f; do
        echo -e "  📄 ${f}"
    done
    
    log_research "topic" "$topic" "research completed"
}

# Show research history
show_history() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📋 Research History${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    jq -r '"  [\(.timestamp)] [\(.type)] \(.query | .[:80])"' "$HISTORY_FILE" 2>/dev/null | tail -20 || echo "  (empty)"
}

# Add solution to knowledge base
add_solution() {
    local topic="$1" solution="$2"
    [ -z "$topic" ] && echo "Usage: --add-solution 'topic' 'solution'" && return 1
    local tmp=$(mktemp)
    jq --arg t "$topic" --arg s "$solution" '.solutions += [{"topic":$t,"solution":$s,"added":"'"$(date +%Y-%m-%d)"'"}]' "$KNOWLEDGE_FILE" > "$tmp" && mv "$tmp" "$KNOWLEDGE_FILE"
    echo -e "${GREEN}✓ Solution added:${NC} $topic"
}

case "${1:-}" in
    --github) search_github "$2" ;;
    --docs) search_docs "$2" "$3" ;;
    --error) research_error "$2" ;;
    --research) research_topic "$2" ;;
    --history) show_history ;;
    --add-solution) add_solution "$2" "$3" ;;
    *) echo "Usage: researcher.sh [--github|--docs|--error|--research|--history|--add-solution]" ;;
esac
