#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Session Summarizer — สรุปอัตโนมัติก่อน context เต็ม
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash session-summarizer.sh --capture "session_id" "message" "role"
#   bash session-summarizer.sh --summarize "session_id"
#   bash session-summarizer.sh --context-check
#   bash session-summarizer.sh --handoff "session_id"

set -e
SUM_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSIONS_DIR="${SUM_DIR}/sessions"
HANDOFF_DIR="${SUM_DIR}/handoffs"
CONFIG="${SUM_DIR}/config.json"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

mkdir -p "$SESSIONS_DIR" "$HANDOFF_DIR"

# Default config
if [ ! -f "$CONFIG" ]; then
    cat > "$CONFIG" << 'EOF'
{
  "max_messages_per_session": 100,
  "context_warning_pct": 60,
  "context_critical_pct": 80,
  "auto_summarize_at": 80,
  "max_summary_tokens": 2000,
  "keep_last_n_messages": 10
}
EOF
fi

# Capture a message
capture_message() {
    local session_id="${1:-default}"
    local message="$2"
    local role="${3:-user}"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local session_file="${SESSIONS_DIR}/${session_id}.jsonl"
    
    [ -z "$message" ] && echo "Usage: --capture 'session_id' 'message' 'role'" && return 1
    
    echo "{\"role\":\"${role}\",\"content\":$(echo "$message" | jq -Rs .),\"timestamp\":\"${ts}\"}" >> "$session_file"
    
    local count=$(wc -l < "$session_file" | tr -d ' ')
    local max=$(jq -r '.max_messages_per_session' "$CONFIG")
    local pct=$((count * 100 / max))
    
    echo -e "${GREEN}✓ Captured:${NC} [${session_id}] msg #${count} (${pct}% context)"
    
    # Auto-check context
    if [ "$pct" -ge "$(jq -r '.auto_summarize_at' "$CONFIG")" ]; then
        echo -e "${YELLOW}⚠ Context at ${pct}% — auto-summarizing...${NC}"
        summarize_session "$session_id"
    elif [ "$pct" -ge "$(jq -r '.context_warning_pct' "$CONFIG")" ]; then
        echo -e "${YELLOW}⚠ Context at ${pct}% — approaching limit${NC}"
    fi
}

# Summarize a session
summarize_session() {
    local session_id="${1:-default}"
    local session_file="${SESSIONS_DIR}/${session_id}.jsonl"
    local summary_file="${SESSIONS_DIR}/${session_id}-summary.md"
    local keep_n=$(jq -r '.keep_last_n_messages' "$CONFIG")
    
    [ ! -f "$session_file" ] && echo "No session found: $session_id" && return 1
    
    local total=$(wc -l < "$session_file" | tr -d ' ')
    local user_msgs=$(grep -c '"role":"user"' "$session_file" 2>/dev/null || echo 0)
    local assistant_msgs=$(grep -c '"role":"assistant"' "$session_file" 2>/dev/null || echo 0)
    
    # Extract key topics (first line of user messages)
    local topics=$(jq -r 'select(.role == "user") | .content' "$session_file" 2>/dev/null | head -20 | cut -c1-80 | head -10)
    
    # Generate summary
    cat > "$summary_file" << EOF
# Session Summary: ${session_id}
Generated: $(date '+%Y-%m-%d %H:%M')

## Stats
- Total messages: ${total} (${user_msgs} user / ${assistant_msgs} assistant)
- Session file: ${session_file}

## Topics Discussed
$(echo "$topics" | while read line; do echo "- ${line}"; done)

## Key Messages (first 5)
$(jq -r 'select(.role == "user") | "- " + (.content | .[:100])' "$session_file" 2>/dev/null | head -5)

## Last ${keep_n} Messages (preserved)
$(tail -${keep_n} "$session_file" | jq -r '"[\(.role)] \(.content | .[:120])"' 2>/dev/null)

---
_Summary preserves context for future sessions. Original: ${total} messages_
EOF

    # Trim session file — keep only last N messages
    local trim_to=$((total - keep_n))
    if [ "$trim_to" -gt 0 ]; then
        local tmp=$(mktemp)
        tail -${keep_n} "$session_file" > "$tmp"
        mv "$tmp" "$session_file"
    fi
    
    echo -e "${GREEN}✓ Summarized:${NC} ${total} msgs → ${summary_file} (kept last ${keep_n})"
    echo -e "  Summary tokens: ~$(wc -c < "$summary_file" | tr -d ' ') bytes"
}

# Context check
context_check() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📊 Context Status${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    for session_file in "$SESSIONS_DIR"/*.jsonl; do
        [ -f "$session_file" ] || continue
        local name=$(basename "$session_file" .jsonl)
        local count=$(wc -l < "$session_file" | tr -d ' ')
        local max=$(jq -r '.max_messages_per_session' "$CONFIG")
        local pct=$((count * 100 / max))
        local status="${GREEN}🟢${NC}"
        [ "$pct" -ge 60 ] && status="${YELLOW}🟡${NC}"
        [ "$pct" -ge 80 ] && status="${RED}🔴${NC}"
        echo -e "  ${status} ${name}: ${count}/${max} (${pct}%)"
    done
}

# Create handoff from session
create_handoff() {
    local session_id="${1:-default}"
    local handoff_file="${HANDOFF_DIR}/${session_id}-$(date +%Y%m%d).md"
    local session_file="${SESSIONS_DIR}/${session_id}.jsonl"
    
    [ ! -f "$session_file" ] && echo "No session: $session_id" && return 1
    
    local total=$(wc -l < "$session_file" | tr -d ' ')
    
    cat > "$handoff_file" << EOF
# Handoff: ${session_id}
Created: $(date '+%Y-%m-%d %H:%M')

## Session Stats
- Messages: ${total}
- Last activity: $(tail -1 "$session_file" | jq -r '.timestamp' 2>/dev/null)

## Last 10 Messages
$(tail -10 "$session_file" | jq -r '"[\(.role)] \(.content | .[:150])"' 2>/dev/null)

## Carry Forward
- [ ] (fill in tasks to continue)
- [ ] (fill in context for next session)

---
_Generated by Session Summarizer v1.0_
EOF
    
    echo -e "${GREEN}✓ Handoff created:${NC} $handoff_file"
}

case "${1:-}" in
    --capture) capture_message "$2" "$3" "$4" ;;
    --summarize) summarize_session "$2" ;;
    --context-check) context_check ;;
    --handoff) create_handoff "$2" ;;
    *) echo "Usage: session-summarizer.sh [--capture|--summarize|--context-check|--handoff]" ;;
esac
