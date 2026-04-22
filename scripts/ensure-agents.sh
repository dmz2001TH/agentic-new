#!/usr/bin/env bash
# ensure-agents.sh — สร้าง tmux sessions สำหรับทุก agent
# เรียกตอน server boot หรือ manual:
#   bash scripts/ensure-agents.sh              # รันทุก agent ที่ลงทะเบียน
#   bash scripts/ensure-agents.sh god        # รันเฉพาะตัวที่ระบุ
#   bash scripts/ensure-agents.sh --list       # ดู agent ที่ลงทะเบียนไว้

set -euo pipefail
AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GEMINI_DIR="$AGENTS_DIR/.gemini"

# ═══════════════════════════════════════════
# REGISTERED AGENTS — เพิ่ม agent ใหม่ที่นี่
# Format: "agent_name:tmux_session:window_name"
# ═══════════════════════════════════════════
REGISTERED_AGENTS=(
  "god:mawjs-oracle:god"
  "builder:mawjs-builder:builder"
  # เพิ่ม agent ใหม่ที่นี่:
  # "researcher:mawjs-researcher:researcher"
  # "zeus:mawjs-zeus:zeus"
)

# --- Helper: ensure tmux session + launch agent ---
ensure_agent() {
  local agent_name="$1"
  local session_name="$2"
  local window_name="$3"

  echo ""
  echo "── $agent_name ($session_name:$window_name) ──"

  # 1. Create tmux session if not exists
  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "  ✓ session exists"
  else
    tmux new-session -d -s "$session_name" -c "$AGENTS_DIR"
    tmux rename-window -t "$session_name" "$window_name"
    echo "  + created session"
  fi

  # 2. Set CLAUDE_AGENT_NAME in tmux environment (persists across commands)
  tmux set-environment -t "$session_name" CLAUDE_AGENT_NAME "$agent_name" 2>/dev/null || true
  tmux send-keys -t "$session_name" "export CLAUDE_AGENT_NAME=$agent_name" Enter 2>/dev/null || true

  # 3. Check if Gemini CLI is already running in the pane
  local pane_cmd
  pane_cmd=$(tmux list-panes -t "$session_name" -F "#{pane_current_command}" 2>/dev/null | head -1)

  if echo "$pane_cmd" | grep -qiE "^(bash|sh|zsh|fish)$"; then
    # 4. Launch Gemini CLI with proper agent context
    #    launch-agent.sh will:
    #    - Look for .gemini/agents/<name>.md (agent-specific context)
    #    - Fall back to GEMINI.md (default context with memory system)
    #    - Export CLAUDE_AGENT_NAME to the Gemini process
    #    - Both contexts include MEMORY SYSTEM instructions
    echo "  + launching Gemini CLI as '$agent_name'..."
    tmux send-keys -t "$session_name" "cd '$AGENTS_DIR' && bash '$GEMINI_DIR/launch-agent.sh' $agent_name" Enter
  else
    echo "  ✓ Gemini already running (command: $pane_cmd)"
  fi
}

# --- Parse arguments ---
if [ "${1:-}" = "--list" ] || [ "${1:-}" = "-l" ]; then
  echo "Registered agents:"
  for entry in "${REGISTERED_AGENTS[@]}"; do
    IFS=':' read -r agent session window <<< "$entry"
    # Check if context file exists
    if [ -f "$GEMINI_DIR/agents/${agent}.md" ]; then
      ctx="agents/${agent}.md"
    else
      ctx="GEMINI.md (default)"
    fi
    # Check if running
    if tmux has-session -t "$session" 2>/dev/null; then
      status="🟢 running"
    else
      status="⚪ stopped"
    fi
    echo "  $status $agent (session: $session, context: $ctx)"
  done
  exit 0
fi

# --- Determine which agents to run ---
if [ $# -gt 0 ]; then
  # Run specific agents
  AGENTS_TO_RUN=("$@")
else
  # Run all registered agents
  AGENTS_TO_RUN=()
  for entry in "${REGISTERED_AGENTS[@]}"; do
    IFS=':' read -r agent _ _ <<< "$entry"
    AGENTS_TO_RUN+=("$agent")
  done
fi

echo "🔮 Oracle Agent Launcher"
echo "   Working dir: $AGENTS_DIR"

for agent_name in "${AGENTS_TO_RUN[@]}"; do
  # Find agent in registry
  found=false
  for entry in "${REGISTERED_AGENTS[@]}"; do
    IFS=':' read -r agent session window <<< "$entry"
    if [ "$agent" = "$agent_name" ]; then
      ensure_agent "$agent" "$session" "$window"
      found=true
      break
    fi
  done

  if [ "$found" = false ]; then
    echo ""
    echo "── $agent_name ──"
    echo "  ⚠ agent not in REGISTERED_AGENTS, creating auto session..."
    # Auto-create: session = mawjs-<name>, window = <name>
    ensure_agent "$agent_name" "mawjs-$agent_name" "$agent_name"
  fi
done

echo ""
echo "════════════════════════════"
echo "Active tmux sessions:"
tmux list-sessions 2>/dev/null || echo "  (none)"
echo ""
echo "Tips:"
echo "  tmux attach -t <session>   # เข้าดู agent"
echo "  Ctrl+b, d                  # ออก (ไม่ปิด)"
echo "  tmux kill-server           # ปิดทั้งหมด"
