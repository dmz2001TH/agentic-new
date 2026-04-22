#!/bin/bash
# Dashboard — หน้าจอ visual ดู status ทั้ง system
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

show() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🧠 GOD SYSTEM DASHBOARD                  ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    
    # Memory
    echo -e "${CYAN}║${NC} ${YELLOW}📚 Memory${NC}"
    [ -f "../../ψ/memory" ] 2>/dev/null || true
    local mem_files=$(find ../../ψ -name "*.md" 2>/dev/null | wc -l || echo "0")
    echo -e "${CYAN}║${NC}   Memory files: ${GREEN}${mem_files}${NC}"
    
    # Agents
    echo -e "${CYAN}║${NC} ${YELLOW}🤖 Agents${NC}"
    local ag_monitor="../02-agent-arch/agent-monitor/registered-agents.json"
    if [ -f "$ag_monitor" ]; then
        local agents=$(jq '.agents | length' "$ag_monitor" 2>/dev/null || echo 0)
        echo -e "${CYAN}║${NC}   Registered: ${GREEN}${agents}${NC}"
    fi
    
    # Tools
    echo -e "${CYAN}║${NC} ${YELLOW}🔧 Tools${NC}"
    local registry="../04-tool-layer/tool-registry/registry.json"
    if [ -f "$registry" ]; then
        local tools=$(jq '.tools | length' "$registry" 2>/dev/null || echo 0)
        echo -e "${CYAN}║${NC}   Registered: ${GREEN}${tools}${NC}"
    fi
    
    # Improvements
    echo -e "${CYAN}║${NC} ${YELLOW}📊 Progress${NC}"
    local log="../01-foundation/improvement-log/log.jsonl"
    if [ -f "$log" ]; then
        local entries=$(wc -l < "$log" | tr -d ' ')
        echo -e "${CYAN}║${NC}   Improvements logged: ${GREEN}${entries}${NC}"
    fi
    
    # System
    echo -e "${CYAN}║${NC} ${YELLOW}💻 System${NC}"
    echo -e "${CYAN}║${NC}   Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    echo -e "${CYAN}║${NC}   Uptime: $(uptime -p 2>/dev/null || uptime | cut -d',' -f1)"
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} $(date '+%Y-%m-%d %H:%M:%S %Z')                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
}
case "${1:-}" in --show) show;; *) show;; esac
