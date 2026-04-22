#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# launch-agent.sh — Gemini CLI launcher with per-agent context
#
# Usage: launch-agent.sh <agent-name> [prompt-file]
# ═══════════════════════════════════════════════════════════
set -euo pipefail

AGENT_NAME="${1:-default}"
PROMPT_FILE="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$SCRIPT_DIR/settings.json"

# --- Resolve context file ---
if [ -f "$SCRIPT_DIR/agents/${AGENT_NAME}.md" ]; then
  CONTEXT_FILE="agents/${AGENT_NAME}.md"
  echo "🔮 Loading agent context: $CONTEXT_FILE"
else
  CONTEXT_FILE="agents/god.md"
  echo "🔮 No agent-specific context for '$AGENT_NAME', using default: $CONTEXT_FILE"
fi

# --- Patch settings.json safely with flock ---
LOCKFILE="$SCRIPT_DIR/settings.lock"
exec 200>"$LOCKFILE"
flock -x 200

BACKUP="$SETTINGS.bak"
cp "$SETTINGS" "$BACKUP"

node -e "
  const fs = require('fs');
  const s = JSON.parse(fs.readFileSync('$SETTINGS', 'utf-8'));
  s.contextFileName = '$CONTEXT_FILE';
  fs.writeFileSync('$SETTINGS', JSON.stringify(s, null, 2) + '\n');
"

flock -u 200

# --- Restore settings on exit ---
cleanup() {
  exec 200>"$LOCKFILE"
  flock -x 200
  if [ -f "$BACKUP" ]; then
    cp "$BACKUP" "$SETTINGS"
    rm -f "$BACKUP"
  fi
  flock -u 200
}
trap cleanup EXIT

# --- Launch Gemini CLI ---
export CLAUDE_AGENT_NAME="${AGENT_NAME}"

echo "🤖 Agent $AGENT_NAME is starting..."

if [ -n "$PROMPT_FILE" ] && [ -f "$PROMPT_FILE" ]; then
  # ใช้ -i (prompt-interactive) เพื่อให้รัน prompt แล้วรอคำสั่งต่อไปได้ถ้ายังไม่จบ
  PROMPT_CONTENT=$(cat "$PROMPT_FILE")
  exec gemini --yolo -i "$PROMPT_CONTENT"
else
  exec gemini --yolo
fi

