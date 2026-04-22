#!/bin/bash
# 🐺 GOD Watchdog — คอยเฝ้าระวังและปลุก GOD เมื่อตาย
SESSION_NAME="god"
START_SCRIPT="/mnt/c/Agentic/start-god-with-memory.sh"

while true; do
  if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "$(date): 🚨 GOD session is missing! Attempting resurrection..."
    bash "$START_SCRIPT"
  fi
  sleep 10
done
