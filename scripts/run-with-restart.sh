#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# run-with-restart.sh — Run a command with auto-restart on crash
#
# Usage: bash scripts/run-with-restart.sh <name> <command> [max_restarts] [cooldown_sec]
# Example: bash scripts/run-with-restart.sh maw "bun server.ts" 10 5
# ═══════════════════════════════════════════════════════════
set -euo pipefail

NAME="${1:?Usage: run-with-restart.sh <name> <command> [max_restarts] [cooldown]}"
CMD="${2:?Usage: run-with-restart.sh <name> <command> [max_restarts] [cooldown]}"
MAX_RESTARTS="${3:-10}"
COOLDOWN="${4:-5}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/ψ/memory/logs"
PID_FILE="$PROJECT_ROOT/.tmp/${NAME}.pid"
RESTART_COUNT=0

mkdir -p "$LOG_DIR" "$PROJECT_ROOT/.tmp"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$NAME] $*" | tee -a "$LOG_DIR/${NAME}.log"
}

cleanup() {
  log "Shutting down (signal received)"
  rm -f "$PID_FILE"
  exit 0
}

trap cleanup SIGTERM SIGINT

log "Starting: $CMD (max restarts: $MAX_RESTARTS, cooldown: ${COOLDOWN}s)"

while true; do
  START_TIME=$(date +%s)
  log "Run #$((RESTART_COUNT + 1))"

  # Run the command
  cd "$PROJECT_ROOT"
  eval "$CMD" 2>&1 | tee -a "$LOG_DIR/${NAME}.log" &
  PID=$!
  echo "$PID" > "$PID_FILE"

  # Wait for it to exit
  wait "$PID" || true
  EXIT_CODE=$?
  END_TIME=$(date +%s)
  DURATION=$((END_TIME - START_TIME))

  rm -f "$PID_FILE"
  log "Exited with code $EXIT_CODE after ${DURATION}s"

  # If it ran for more than 60 seconds, reset restart counter
  if [ "$DURATION" -gt 60 ]; then
    RESTART_COUNT=0
    log "Ran for >60s — reset restart counter"
  fi

  RESTART_COUNT=$((RESTART_COUNT + 1))

  if [ "$RESTART_COUNT" -ge "$MAX_RESTARTS" ]; then
    log "Max restarts ($MAX_RESTARTS) reached — giving up"
    exit 1
  fi

  log "Restarting in ${COOLDOWN}s... (attempt $RESTART_COUNT/$MAX_RESTARTS)"
  sleep "$COOLDOWN"
done
