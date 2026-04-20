#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# launch-agent.sh — Gemini CLI launcher with per-agent context
#
# Usage: launch-agent.sh <agent-name>
# Reads .gemini/agents/<agent-name>.md if it exists,
# falls back to .gemini/GEMINI.md (default).
# Temporarily patches settings.json to point at the right file.
# ═══════════════════════════════════════════════════════════
set -euo pipefail

AGENT_NAME="${1:-default}"
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

# --- Patch settings.json (preserve original) ---
BACKUP="$SETTINGS.bak"
cp "$SETTINGS" "$BACKUP"

# Use node to patch JSON safely (handles all edge cases)
node -e "
  const fs = require('fs');
  const s = JSON.parse(fs.readFileSync('$SETTINGS', 'utf-8'));
  s.contextFileName = '$CONTEXT_FILE';
  fs.writeFileSync('$SETTINGS', JSON.stringify(s, null, 2) + '\n');
"

# --- Restore settings on exit (any exit: normal, error, signal) ---
cleanup() {
  cp "$BACKUP" "$SETTINGS"
  rm -f "$BACKUP"
}
trap cleanup EXIT

# --- Launch Gemini CLI ---
export CLAUDE_AGENT_NAME="${AGENT_NAME}"
exec gemini --yolo "$@"
