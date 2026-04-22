#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Agent Health Monitor — ตรวจ agent ไหน hang/crash/หลุด identity
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash agent-monitor.sh --check
#   bash agent-monitor.sh --heartbeat "agent_name"
#   bash agent-monitor.sh --register "agent_name" "pid"
#   bash agent-monitor.sh --deregister "agent_name"
#   bash agent-monitor.sh --dashboard
#   bash agent-monitor.sh --alerts

set -e
MON_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_FILE="${MON_DIR}/registered-agents.json"
HEALTH_LOG="${MON_DIR}/health-log.jsonl"
ALERTS_FILE="${MON_DIR}/alerts.log"
IDENTITY_RULES="${MON_DIR}/identity-rules.json"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$MON_DIR"
[ ! -f "$HEALTH_LOG" ] && touch "$HEALTH_LOG"
[ ! -f "$ALERTS_FILE" ] && touch "$ALERTS_FILE"

if [ ! -f "$IDENTITY_RULES" ]; then
    cat > "$IDENTITY_RULES" << 'EOF'
{
  "must_contain": ["GOD"],
  "must_not_contain": ["I am an AI assistant", "As an AI", "I'm Claude", "I am Gemini"],
  "check_interval_seconds": 300,
  "max_heartbeat_age_seconds": 600
}
EOF
fi

if [ ! -f "$AGENTS_FILE" ]; then
    echo '{"agents":{}}' > "$AGENTS_FILE"
fi

# Register agent
register_agent() {
    local name="$1" pid="${2:-0}"
    [ -z "$name" ] && echo "Usage: --register 'name' [pid]" && return 1
    
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local tmp=$(mktemp)
    jq --arg n "$name" --arg p "$pid" --arg ts "$ts" \
       '.agents[$n] = {"pid":$p,"registered":$ts,"last_heartbeat":$ts,"status":"active","restarts":0}' \
       "$AGENTS_FILE" > "$tmp" && mv "$tmp" "$AGENTS_FILE"
    
    echo -e "${GREEN}✓ Registered:${NC} ${name} (pid: ${pid})"
}

# Heartbeat
heartbeat() {
    local name="$1"
    [ -z "$name" ] && echo "Usage: --heartbeat 'agent_name'" && return 1
    
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local tmp=$(mktemp)
    jq --arg n "$name" --arg ts "$ts" \
       '.agents[$n].last_heartbeat = $ts | .agents[$n].status = "active"' \
       "$AGENTS_FILE" > "$tmp" && mv "$tmp" "$AGENTS_FILE"
    
    # Log
    echo "{\"agent\":\"${name}\",\"event\":\"heartbeat\",\"timestamp\":\"${ts}\"}" >> "$HEALTH_LOG"
}

# Check all agents
check_health() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  🏥 Agent Health Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    local now=$(date +%s)
    local max_age=$(jq -r '.max_heartbeat_age_seconds' "$IDENTITY_RULES")
    local issues=0
    
    jq -r '.agents | to_entries[] | "\(.key)|\(.value.pid)|\(.value.last_heartbeat)|\(.value.status)"' "$AGENTS_FILE" 2>/dev/null | while IFS='|' read name pid last_hb status; do
        local hb_epoch=$(date -d "$last_hb" +%s 2>/dev/null || echo "0")
        local age=$((now - hb_epoch))
        
        local status_icon="${GREEN}🟢${NC}"
        local status_text="healthy"
        
        if [ "$age" -gt "$max_age" ]; then
            status_icon="${RED}🔴${NC}"
            status_text="STALE (${age}s since heartbeat)"
            echo "$(date) ALERT: ${name} is stale (${age}s)" >> "$ALERTS_FILE"
        elif [ "$status" = "error" ]; then
            status_icon="${RED}🔴${NC}"
            status_text="ERROR"
        fi
        
        # Check if PID is alive
        if [ "$pid" != "0" ] && [ "$pid" != "null" ]; then
            if ! kill -0 "$pid" 2>/dev/null; then
                status_icon="${RED}💀${NC}"
                status_text="PROCESS DEAD (pid: ${pid})"
                echo "$(date) ALERT: ${name} process dead (pid: ${pid})" >> "$ALERTS_FILE"
            fi
        fi
        
        echo -e "  ${status_icon} ${name}: ${status_text} (last: ${last_hb})"
    done
    
    # Check for missing heartbeats
    local agent_count=$(jq '.agents | length' "$AGENTS_FILE" 2>/dev/null || echo 0)
    echo -e "\n  Registered agents: ${agent_count}"
}

# Check identity drift
check_identity() {
    local text="$1"
    [ -z "$text" ] && echo "Usage: --check-identity 'text_to_check'" && return 1
    
    echo -e "${CYAN}Identity check:${NC}"
    
    # Check must_contain
    local must_contain=$(jq -r '.must_contain[]' "$IDENTITY_RULES" 2>/dev/null)
    for word in $must_contain; do
        if echo "$text" | grep -qi "$word"; then
            echo -e "  ${GREEN}✓ Contains '${word}'${NC}"
        else
            echo -e "  ${RED}✗ Missing '${word}' — IDENTITY DRIFT!${NC}"
            echo "$(date) IDENTITY_DRIFT: missing '${word}'" >> "$ALERTS_FILE"
        fi
    done
    
    # Check must_not_contain
    local must_not=$(jq -r '.must_not_contain[]' "$IDENTITY_RULES" 2>/dev/null)
    for phrase in $must_not; do
        if echo "$text" | grep -qi "$phrase"; then
            echo -e "  ${RED}✗ Contains forbidden: '${phrase}' — IDENTITY DRIFT!${NC}"
            echo "$(date) IDENTITY_DRIFT: contains forbidden '${phrase}'" >> "$ALERTS_FILE"
        else
            echo -e "  ${GREEN}✓ No forbidden phrase: '${phrase}'${NC}"
        fi
    done
}

# Dashboard
dashboard() {
    local now=$(date +%s)
    local total=$(jq '.agents | length' "$AGENTS_FILE" 2>/dev/null || echo 0)
    local active=0 stale=0 error=0
    
    while IFS='|' read name pid last_hb status; do
        local hb_epoch=$(date -d "$last_hb" +%s 2>/dev/null || echo "0")
        local age=$((now - hb_epoch))
        if [ "$age" -gt 600 ]; then ((stale++)); elif [ "$status" = "error" ]; then ((error++)); else ((active++)); fi
    done < <(jq -r '.agents | to_entries[] | "\(.key)|\(.value.pid)|\(.value.last_heartbeat)|\(.value.status)"' "$AGENTS_FILE" 2>/dev/null)
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📊 Agent Dashboard${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "  Total: ${total}  ${GREEN}Active: ${active}${NC}  ${YELLOW}Stale: ${stale}${NC}  ${RED}Error: ${error}${NC}"
    echo -e "  Alerts: $(wc -l < "$ALERTS_FILE" | tr -d ' ') total"
}

# Show alerts
show_alerts() {
    echo -e "${CYAN}Recent Alerts:${NC}"
    tail -20 "$ALERTS_FILE" 2>/dev/null | while read line; do
        echo -e "  ${RED}⚠${NC} ${line}"
    done
}

deregister_agent() {
    local name="$1"
    [ -z "$name" ] && echo "Usage: --deregister 'name'" && return 1
    local tmp=$(mktemp)
    jq --arg n "$name" 'del(.agents[$n])' "$AGENTS_FILE" > "$tmp" && mv "$tmp" "$AGENTS_FILE"
    echo -e "${GREEN}✓ Deregistered:${NC} $name"
}

case "${1:-}" in
    --check) check_health ;;
    --heartbeat) heartbeat "$2" ;;
    --register) register_agent "$2" "$3" ;;
    --deregister) deregister_agent "$2" ;;
    --dashboard) dashboard ;;
    --alerts) show_alerts ;;
    --check-identity) check_identity "$2" ;;
    *) echo "Usage: agent-monitor.sh [--check|--heartbeat|--register|--deregister|--dashboard|--alerts|--check-identity]" ;;
esac
