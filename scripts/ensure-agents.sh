#!/usr/bin/env bash
# ensure-agents.sh — สร้าง tmux sessions ที่จำเป็นถ้ายังไม่มี
# เรียกตอน server boot หรือ manual: bash scripts/ensure-agents.sh

set -euo pipefail
AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ensure_session() {
  local name="$1"
  local window="$2"
  local cwd="${3:-$AGENTS_DIR}"

  if tmux has-session -t "$name" 2>/dev/null; then
    echo "✓ $name already running"
  else
    tmux new-session -d -s "$name" -c "$cwd"
    tmux rename-window -t "$name:0" "$window"
    echo "+ created session $name (window: $window)"
  fi
}

# --- mawjs oracle (GOD agent) ---
ensure_session "mawjs-oracle" "god" "$AGENTS_DIR"

# Launch GOD agent with proper identity and context
# - CLAUDE_AGENT_NAME is set via tmux environment (not send-keys export)
# - launch-agent.sh patches settings.json to use agents/god.md as context
# - The agent context (god.md) includes memory references so it remembers learnings
tmux set-environment -t mawjs-oracle CLAUDE_AGENT_NAME god 2>/dev/null || true
tmux send-keys -t mawjs-oracle:0 "export CLAUDE_AGENT_NAME=god" Enter 2>/dev/null || true

# Only launch Gemini if it's not already running in the pane
PANE_CMD=$(tmux list-panes -t mawjs-oracle:0 -F "#{pane_current_command}" 2>/dev/null | head -1)
if echo "$PANE_CMD" | grep -qiE "^(bash|sh|zsh|fish)$"; then
  echo "+ launching Gemini CLI as GOD agent..."
  tmux send-keys -t mawjs-oracle:0 "cd '$AGENTS_DIR' && bash .gemini/launch-agent.sh god" Enter
else
  echo "✓ Gemini already running in mawjs-oracle:0 (command: $PANE_CMD)"
fi

echo ""
echo "Active sessions:"
tmux list-sessions 2>/dev/null || echo "  (none)"
