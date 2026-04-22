#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Agent Communication Protocol — JSON message queue
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash agent-comm.sh --send "from" "to" "type" "payload"
#   bash agent-comm.sh --receive "agent_name"
#   bash agent-comm.sh --broadcast "from" "type" "payload"
#   bash agent-comm.sh --queue "agent_name"
#   bash agent-comm.sh --status

set -e
COMM_DIR="$(cd "$(dirname "$0")" && pwd)"
QUEUE_DIR="${COMM_DIR}/queues"
LOG_FILE="${COMM_DIR}/message-log.jsonl"
AGENTS_FILE="${COMM_DIR}/agents.json"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

mkdir -p "$QUEUE_DIR"
[ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"
[ ! -f "$AGENTS_FILE" ] && echo '{"agents":["god","builder","critic","researcher","planner","learner"]}' > "$AGENTS_FILE"

# Send message to specific agent
send_message() {
    local from="$1" to="$2" type="$3" payload="$4"
    [ -z "$from" ] || [ -z "$to" ] || [ -z "$type" ] && echo "Usage: --send 'from' 'to' 'type' 'payload'" && return 1
    
    local msg_id="msg-$(date +%Y%m%d%H%M%S)-$(shuf -i 1000-9999 -n1)"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local msg="{\"id\":\"${msg_id}\",\"from\":\"${from}\",\"to\":\"${to}\",\"type\":\"${type}\",\"payload\":$(echo "$payload" | jq -Rs .),\"timestamp\":\"${ts}\",\"status\":\"pending\"}"
    
    # Add to recipient's queue
    mkdir -p "$QUEUE_DIR"
    echo "$msg" >> "${QUEUE_DIR}/${to}.jsonl"
    
    # Log
    echo "$msg" >> "$LOG_FILE"
    
    echo -e "${GREEN}✓ Sent:${NC} ${from} → ${to} [${type}] (${msg_id})"
}

# Receive messages for an agent
receive_messages() {
    local agent="$1"
    [ -z "$agent" ] && echo "Usage: --receive 'agent_name'" && return 1
    
    local queue_file="${QUEUE_DIR}/${agent}.jsonl"
    [ ! -f "$queue_file" ] && echo -e "${YELLOW}No messages for ${agent}${NC}" && return
    
    local count=$(wc -l < "$queue_file" | tr -d ' ')
    echo -e "${CYAN}📨 Messages for ${agent} (${count} pending)${NC}\n"
    
    while IFS= read -r msg; do
        [ -z "$msg" ] && continue
        local id=$(echo "$msg" | jq -r '.id')
        local from=$(echo "$msg" | jq -r '.from')
        local type=$(echo "$msg" | jq -r '.type')
        local payload=$(echo "$msg" | jq -r '.payload')
        local ts=$(echo "$msg" | jq -r '.timestamp')
        
        echo -e "  ${YELLOW}[${type}]${NC} from ${from} (${ts})"
        echo -e "    ${payload}"
        echo ""
    done < "$queue_file"
    
    # Clear queue after reading
    > "$queue_file"
    echo -e "${GREEN}✓ Queue cleared${NC}"
}

# Broadcast to all agents
broadcast() {
    local from="$1" type="$2" payload="$3"
    [ -z "$from" ] && echo "Usage: --broadcast 'from' 'type' 'payload'" && return 1
    
    local agents=$(jq -r '.agents[]' "$AGENTS_FILE" 2>/dev/null)
    local count=0
    
    for agent in $agents; do
        [ "$agent" = "$from" ] && continue
        send_message "$from" "$agent" "$type" "$payload"
        ((count++))
    done
    
    echo -e "${GREEN}✓ Broadcast sent to ${count} agents${NC}"
}

# Show queue status
show_status() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📡 Agent Communication Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    local total_msgs=$(wc -l < "$LOG_FILE" | tr -d ' ')
    echo -e "  Total messages sent: ${total_msgs}"
    echo -e "\n  Queue sizes:"
    
    for queue in "$QUEUE_DIR"/*.jsonl; do
        [ -f "$queue" ] || continue
        local name=$(basename "$queue" .jsonl)
        local count=$(wc -l < "$queue" | tr -d ' ')
        [ "$count" -gt 0 ] && echo -e "    ${YELLOW}${name}${NC}: ${count} pending"
    done
    
    echo -e "\n  ${YELLOW}Registered agents:${NC}"
    jq -r '.agents[] | "    - \(.)"' "$AGENTS_FILE" 2>/dev/null
}

# Message types reference
show_types() {
    echo -e "${CYAN}Message Types:${NC}"
    echo "  task      — assign task to agent"
    echo "  result    — deliver task result"
    echo "  question  — ask another agent"
    echo "  answer    — respond to question"
    echo "  alert     — warning or error"
    echo "  handoff   — transfer context"
    echo "  status    — status update"
    echo "  learn     — share knowledge"
}

case "${1:-}" in
    --send) send_message "$2" "$3" "$4" "$5" ;;
    --receive) receive_messages "$2" ;;
    --broadcast) broadcast "$2" "$3" "$4" ;;
    --queue) receive_messages "$2" ;;
    --status) show_status ;;
    --types) show_types ;;
    *) echo "Usage: agent-comm.sh [--send|--receive|--broadcast|--queue|--status|--types]" ;;
esac
