#!/bin/bash
# GOD's Final Upgrade: Fleet Autonomous Verification

echo "================================================="
echo "🚀 GOD's Fleet Autonomous Verification"
echo "================================================="

echo ""
echo "[1] Checking Agent Status (Fleet Readiness)..."
# Check common agent ports or tmux sessions
if command -v tmux >/dev/null 2>&1; then
  tmux ls 2>/dev/null | grep -i -E "agent|god|oracle|builder" || echo "  ⚠️  No active Fleet agents found in tmux."
else
  echo "  ⚠️  tmux is not installed or available."
fi

# Check if Oracle server is running on typical ports
if lsof -i :3456 >/dev/null 2>&1; then
  echo "  ✅ Oracle Brain Server is RUNNING (Port 3456)"
else
  echo "  ⚠️  Oracle Brain Server is NOT RUNNING on port 3456"
fi

echo ""
echo "[2] Checking Memory Sync Status..."
MEMORY_DIR="/mnt/c/Agentic/ψ"
if [ -d "$MEMORY_DIR" ]; then
  echo "  ✅ Local Memory Cache found at $MEMORY_DIR"
  cd "$MEMORY_DIR" || exit
  
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CHANGES=$(git status --porcelain)
    if [ -z "$CHANGES" ]; then
      echo "  ✅ Memory is fully synced and clean."
    else
      echo "  ⚠️  Uncommitted memory changes detected:"
      echo "$CHANGES" | sed 's/^/      /'
    fi
  else
    echo "  ⚠️  Memory directory is not a Git repository."
  fi
else
  echo "  ❌ Local Memory Cache NOT FOUND at $MEMORY_DIR"
fi

echo ""
echo "================================================="
echo "✅ GOD's Verification Complete!"
echo "================================================="
