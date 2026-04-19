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

# --- mawjs oracle ---
ensure_session "mawjs-oracle" "god" "$AGENTS_DIR"

# Set env vars in the pane
tmux send-keys -t mawjs-oracle:0 "export CLAUDE_AGENT_NAME=god" Enter 2>/dev/null || true

echo ""
echo "Active sessions:"
tmux list-sessions 2>/dev/null || echo "  (none)"
