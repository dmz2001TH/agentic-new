#!/bin/bash
# Dashboard — หน้าจอ visual ดู status ทั้ง system
# Space Guardian System: จารึกไว้ว่านี่คือระบบดูแลพื้นที่จัดเก็บของ GOD
set -e
# Detect Root
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$(cd "$(dirname "$0")/../../.." && pwd)")
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

show() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🧠 GOD SYSTEM DASHBOARD                  ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    
    # Memory
    echo -e "${CYAN}║${NC} ${YELLOW}📚 Memory${NC}"
    local mem_dir="${GIT_ROOT}/ψ"
    local mem_files=$(find -L "$mem_dir" -name "*.md" 2>/dev/null | wc -l || echo "0")
    echo -e "${CYAN}║${NC}   Memory files: ${GREEN}${mem_files}${NC}"
    
    # Agents
    echo -e "${CYAN}║${NC} ${YELLOW}🤖 Agents${NC}"
    local ag_monitor="${GIT_ROOT}/god-upgrades/02-agent-arch/agent-monitor/registered-agents.json"
    if [ -f "$ag_monitor" ]; then
        local agents=$(jq '.agents | length' "$ag_monitor" 2>/dev/null || echo 0)
        echo -e "${CYAN}║${NC}   Registered: ${GREEN}${agents}${NC}"
    fi
    
    # Tools
    echo -e "${CYAN}║${NC} ${YELLOW}🔧 Tools${NC}"
    local registry="${GIT_ROOT}/god-upgrades/04-tool-layer/tool-registry/registry.json"
    if [ -f "$registry" ]; then
        local tools=$(jq '.tools | length' "$registry" 2>/dev/null || echo 0)
        echo -e "${CYAN}║${NC}   Registered: ${GREEN}${tools}${NC}"
    fi
    
    # Improvements
    echo -e "${CYAN}║${NC} ${YELLOW}📊 Progress${NC}"
    local log="${GIT_ROOT}/god-upgrades/01-foundation/improvement-log/log.jsonl"
    if [ -f "$log" ]; then
        local entries=$(wc -l < "$log" | tr -d ' ')
        echo -e "${CYAN}║${NC}   Improvements logged: ${GREEN}${entries}${NC}"
    fi
    
    # System & Space Guardian
    echo -e "${CYAN}║${NC} ${YELLOW}💻 System & Storage (Space Guardian)${NC}"
    
    # Calculate % free space on C:
    # df -h /mnt/c returns: Filesystem Size Used Avail Use% Mounted on
    local df_output=$(df -h /mnt/c 2>/dev/null | awk 'NR==2 {print $5}' || echo "0%")
    local used_percent=${df_output%?}
    local free_percent=$((100 - used_percent))
    
    local color=$GREEN
    if [ "$free_percent" -lt 10 ]; then
        color=$RED
    elif [ "$free_percent" -le 20 ]; then
        color=$YELLOW
    fi
    
    echo -e "${CYAN}║${NC}   Drive C: ${color}${free_percent}% free${NC} (${df_output} used)"
    # System
    echo -e "${CYAN}║${NC}   Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
    echo -e "${CYAN}║${NC}   Uptime: $(uptime -p 2>/dev/null || uptime | cut -d',' -f1)"
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} $(date '+%Y-%m-%d %H:%M:%S %Z')                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
}
case "${1:-}" in --show) show;; *) show;; esac
