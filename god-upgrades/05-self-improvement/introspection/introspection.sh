#!/bin/bash
# Introspection — "What am I good at? What am I bad at?"
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; REPORT="${DIR}/introspection.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$REPORT" ] && touch "$REPORT"

generate() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  🔮 GOD Introspection Report${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    # Count experiences by outcome
    local exp_file="../02-agent-arch/learner/experiences.jsonl"
    if [ -f "$exp_file" ]; then
        local total=$(wc -l < "$exp_file" | tr -d ' ')
        local success=$(grep -c '"success"' "$exp_file" 2>/dev/null || echo 0)
        local failure=$(grep -c '"failure"' "$exp_file" 2>/dev/null || echo 0)
        echo -e "\n  ${CYAN}Experience Summary:${NC}"
        echo -e "    Total: ${total}  |  ${GREEN}Success: ${success}${NC}  |  ${RED}Failure: ${failure}${NC}"
        if [ "$total" -gt 0 ]; then
            echo -e "    Success rate: $((success * 100 / total))%"
        fi
    fi
    
    # Count tools used
    local reg_file="../04-tool-layer/tool-registry/registry.json"
    if [ -f "$reg_file" ]; then
        local tool_count=$(jq '.tools | length' "$reg_file" 2>/dev/null || echo 0)
        echo -e "\n  ${CYAN}Tools:${NC} ${tool_count} registered"
        jq -r '.tools | sort_by(-.uses) | .[:3][] | "    Most used: \(.name) (\(.uses)x)"' "$reg_file" 2>/dev/null
    fi
    
    # Count errors solved
    local err_file="../05-self-improvement/error-library/errors.jsonl"
    if [ -f "$err_file" ]; then
        local errors=$(wc -l < "$err_file" | tr -d ' ')
        echo -e "\n  ${CYAN}Errors logged:${NC} ${errors}"
    fi
    
    echo -e "\n  ${CYAN}Questions to ask:${NC}"
    echo "    1. What patterns keep repeating?"
    echo "    2. What errors am I still making?"
    echo "    3. What skills do I need to learn?"
    echo "    4. What tools am I underusing?"
    
    echo "{\"generated\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"introspection\"}" >> "$REPORT"
}

case "${1:-}" in
    --generate) generate;;
    --history) tail -5 "$REPORT" | jq -r '"  \(.generated)"' 2>/dev/null;;
    *) echo "Usage: introspection.sh [--generate|--history]";; esac
