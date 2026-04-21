#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# autonomous-runner.sh — The Heart of Oracle Autonomy
# "Don't ask. Seek goals. Execute. Evolve."
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PSI_DIR="$PROJECT_ROOT/ψ"
GOALS_FILE="$PSI_DIR/memory/goals.md"
INBOX_DIR="$PSI_DIR/inbox"
TOOLS="$SCRIPT_DIR/oracle-tools.sh"

log_action() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# --- 1. Automated Task: Gmail Scan at 08:00 ---
check_scheduled_tasks() {
  local current_hour=$(date +%H)
  local current_min=$(date +%M)
  
  if [ "$current_hour" -eq "08" ] && [ "$current_min" -lt "15" ]; then
    log_action "⏰ Scheduled Task: 08:00 Gmail Scan triggered."
    bash "$TOOLS" gmail-scan > "$PSI_DIR/memory/learnings/$(date +%Y-%m-%d)-gmail-report.md" || log_action "⚠️ Gmail scan failed."
    # สรุปอีเมลด่วน
    log_action "📧 Analyzing Urgent Emails..."
    # (Logic สำหรับเรียกเอเจนท์มาสรุปจะใส่ตรงนี้)
  fi
}

# --- 2. Process Inbox & Dispatch ---
process_inbox() {
  log_action "📥 Checking inbox for new messages..."
  for f in "$INBOX_DIR"/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" == "focus-agent-main.md" ] && continue
    
    log_action "📄 New inbox file: $(basename "$f"). Converting to goal."
    local content=$(grep -m 1 "^- " "$f" | sed 's/- //')
    echo "- [ ] [$(date +%Y-%m-%d)] $content — by autonomous-inbox" >> "$GOALS_FILE"
    mkdir -p "$INBOX_DIR/archive"
    mv "$f" "$INBOX_DIR/archive/"
  done
}

# --- 3. Dispatch Goals to Agents ---
dispatch_goals() {
  log_action "🎯 Checking goals.md for pending tasks..."
  
  # Handle stuck goals [~] (Reset if older than 1 cycle - simulated here)
  # sed -i 's/^- \[~\]/- [ ]/g' "$GOALS_FILE" 

  # Find first pending [ ]
  local pending_goal=$(grep -m 1 "^\- \[ \]" "$GOALS_FILE" || true)
  if [ -n "$pending_goal" ]; then
    local goal_text=$(echo "$pending_goal" | sed 's/^- \[ \] //')
    log_action "🚀 Dispatching Goal: $goal_text"
    
    # Logic: สุ่มหรือเลือก Agent ตาม Keyword (Simple Dispatcher)
    if [[ "$goal_text" == *"code"* ]] || [[ "$goal_text" == *"fix"* ]] || [[ "$goal_text" == *"refactor"* ]]; then
        bash "$TOOLS" hey "builder" "ภารกิจใหม่: $goal_text ทำเดี๋ยวนี้และรายงานผลผ่าน handoff"
    else
        bash "$TOOLS" hey "researcher" "ภารกิจใหม่: $goal_text ศึกษาและจารึกลง learnings"
    fi
    
    # Mark as active [~]
    sed -i "0,/^- \[ \]/s//- [~]/" "$GOALS_FILE"
  fi
}

# --- MAIN LOOP ---
log_action "📡 ORACLE AUTONOMOUS RUNNER STARTED (Interval: 15m)"
while true; do
  check_scheduled_tasks
  process_inbox
  dispatch_goals
  
  log_action "💤 Cycle complete. Sleeping for 15 minutes..."
  sleep 900
done
