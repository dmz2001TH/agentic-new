#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# tmux-god-status.sh — Integrate GOD status into tmux status bar
# Shows real-time agent activity + countdown in tmux
# ═══════════════════════════════════════════════════════════

STATUS_FILE="/tmp/god-status.json"

# ─── Generate tmux status string ───
generate_status() {
  if [ ! -f "$STATUS_FILE" ]; then
    echo "🧠 GOD · idle"
    return
  fi

  local agent=$(cat "$STATUS_FILE" | grep -o '"agent":"[^"]*"' | cut -d'"' -f4)
  local action=$(cat "$STATUS_FILE" | grep -o '"action":"[^"]*"' | cut -d'"' -f4)
  local target=$(cat "$STATUS_FILE" | grep -o '"target":"[^"]*"' | cut -d'"' -f4)
  local deadline=$(cat "$STATUS_FILE" | grep -o '"deadline":"[^"]*"' | cut -d'"' -f4)

  local status="🧠 ${agent} · ${action}"

  if [ -n "$target" ]; then
    # Truncate target for tmux
    local short_target=$(echo "$target" | head -c 40)
    status="${status} ${short_target}"
  fi

  if [ -n "$deadline" ]; then
    local now_h=$(date +%H)
    local now_m=$(date +%M)
    local now_s=$(date +%S)
    local now_total=$((10#$now_h * 3600 + 10#$now_m * 60 + 10#$now_s))

    local dl_h=$(echo "$deadline" | cut -d: -f1)
    local dl_m=$(echo "$deadline" | cut -d: -f2)
    local dl_total=$((10#$dl_h * 3600 + 10#$dl_m * 60))

    if [ $dl_total -lt $now_total ]; then
      dl_total=$((dl_total + 86400))
    fi

    local remaining=$((dl_total - now_total))
    local r_mins=$((remaining / 60))
    local r_secs=$((remaining % 60))

    if [ $remaining -le 0 ]; then
      status="${status} ⏰ TIME'S UP!"
    elif [ $remaining -le 60 ]; then
      status="${status} 🔴 ${r_mins}:$(printf '%02d' $r_secs)"
    elif [ $remaining -le 300 ]; then
      status="${status} 🟡 ${r_mins}:$(printf '%02d' $r_secs)"
    else
      status="${status} 🟢 ${r_mins}:$(printf '%02d' $r_secs)"
    fi
  fi

  echo "$status"
}

# ─── Apply to tmux ───
apply_to_tmux() {
  local status=$(generate_status)

  if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null 2>&1; then
    # Set right status to show GOD activity
    tmux set-option -g status-right "#[fg=cyan]${status} #[fg=white]| %H:%M:%S"
    tmux set-option -g status-right-length 120
    echo "✅ tmux status updated: $status"
  else
    echo "⚠️ tmux not running — showing status directly:"
    echo "$status"
  fi
}

# ─── Watch mode (update every second) ───
watch_mode() {
  while true; do
    apply_to_tmux
    sleep 1
  done
}

# ─── Main ───
case "${1:-show}" in
  show)
    generate_status
    ;;
  apply)
    apply_to_tmux
    ;;
  watch)
    watch_mode
    ;;
  *)
    echo "Usage: tmux-god-status.sh [show|apply|watch]"
    ;;
esac
