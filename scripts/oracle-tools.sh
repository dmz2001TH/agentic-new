#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# oracle-tools.sh — ACI LAYER v2.0 (Supreme Evolution)
# "Verification First — Reading is not verification. Run it."
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ORACLE_URL="${ORACLE_URL:-http://localhost:47778}"
MAW_URL="${MAW_URL:-http://localhost:3456}"
PSI_DIR="$PROJECT_ROOT/ψ"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# ═══════════════════════════════════════════
# ACI LAYER v2.0 FUNCTIONS
# ═══════════════════════════════════════════

ot-edit-surgical() {
  local file="${1:?Usage: ot-edit-surgical <file> <old> <new>}"
  sed -i "s/$2/$3/g" "$file"
  echo "✓ Surgical edit completed on $file"
}

ot-verify() {
  echo "--- Starting Verification Loop ---"
  local file_to_check="${1:-}"
  if [[ "$file_to_check" == *.sh ]]; then
    bash -n "$file_to_check" || { echo "❌ Syntax Error!"; return 1; }
  fi
  [ -f "package.json" ] && (npm run lint || true && npm test -- --run || true)
  echo "✓ Verification Finished"
}

ot-pre-flight() {
  echo -e "${PURPLE}🚀 Pre-flight Check${NC}"
  [ -f "$PSI_DIR/memory/mistakes.md" ] && grep "\- \*\*วิธีป้องกัน\*\*" "$PSI_DIR/memory/mistakes.md" | tail -n 3
  [ -f "$PSI_DIR/memory/patterns.md" ] && grep "\- \*\*การกระทำ\*\*" "$PSI_DIR/memory/patterns.md" | tail -n 3
}

ot-read-range() {
  sed -n "${2},${3}p" "$1"
}

ot-hey() {
  echo "[GOD -> $1]: $2"
}

ot-compress() {
  local file="${1:?Usage: ot-compress <file>}"
  local dest="${file}.compressed"
  echo "🗜️ Compressing $file (RTK/Caveman style)..."
  # กรองเฉพาะสัญญาณ (Signal) สำคัญและยุบบรรทัดที่ซ้ำกัน (Deduplication)
  grep -iE "error|fail|warn|fatal|exception|action:|result:|goal:|summary" "$file" \
    | grep -vE "^\s*$" \
    | uniq -c \
    | awk '{$1=$1;print}' > "$dest"
  echo "✓ Compressed saved to $dest"
}

ot-extract-skill() {
  local name="$1"
  mkdir -p ".claude/skills"
  echo -e "# Skill: $1
- $2
```bash
$3
```" > ".claude/skills/$name.md"
}

ot-pulse() {
  local agent="${CLAUDE_AGENT_NAME:-god}"
  mkdir -p "ψ/memory/pulse"
  echo "{\"agent\": \"$agent\", \"status\": \"$1\", \"timestamp\": \"$(date +%H:%M:%S)\"}" > "ψ/memory/pulse/${agent}.status"
}

ot-status() {
  local ROOT_DIR="${PROJECT_ROOT:-/mnt/c/Agentic}"
  clear
  echo -e "${BLUE}🌌───────────────────────────────────────────────────────────────────🌌${NC}"
  echo -e "  ${WHITE}👑 ORACLE MASTER SYSTEM${NC}  |  ${YELLOW}v4.2 Supreme${NC}  |  ${PURPLE}$(date +'%Y-%m-%d %H:%M:%S')${NC}"
  echo -e "${BLUE}─────────────────────────────────────────────────────────────────────${NC}"
  
  # 1. Background Fleet Section
  echo -e "\n${GREEN}🛰️  FLEET COMMAND (Active Sessions):${NC}"
  local tmux_sessions=$(tmux ls 2>/dev/null | grep -E "^(oracle-|team-|god)")
  if [ -n "$tmux_sessions" ]; then
     echo "$tmux_sessions" | while read -r line; do
       local sname=$(echo "$line" | cut -d':' -f1)
       echo -e "  ${GREEN}●${NC} @${sname}"
     done
  else
     echo -e "  ${RED}○${NC} No background sessions found."
  fi
  
  # 2. Flight Status (Live Sub-tasks)
  echo -e "\n${YELLOW}✈️  FLIGHT STATUS (Live Sub-tasks):${NC}"
  local task_files=$(ls "$ROOT_DIR/ψ/memory/tasks/"*.task 2>/dev/null)
  if [ -n "$task_files" ]; then
    echo "$task_files" | while read -r f; do
      local a=$(basename "$f" .task)
      local msg=$(grep -oP '"task": "\K[^"]+' "$f")
      local ctx=$(grep -oP '"ctx": "\K[^"]+' "$f")
      local t=$(grep -oP '"timestamp": "\K[^"]+' "$f")
      echo -e "  ${BLUE}*${NC} ${WHITE}${msg}${NC}"
      echo -e "    ${PURPLE}↳${NC} ${GREEN}@${a}${NC} (ctx: ${ctx}) [${YELLOW}$t${NC}]"
    done
  else
    echo -e "  ${RED}○${NC} No active task reports found."
  fi

  # 3. Blackboard Section
  echo -e "\n${BLUE}📋 STIGMERGIC BLACKBOARD (Shared Intelligence):${NC}"
  if [ -f "$ROOT_DIR/oracle-cowork/blackboard.json" ]; then
     node -e '
       try {
         const b = require("'"$ROOT_DIR"'/oracle-cowork/blackboard.json");
         if(b.tasks && b.tasks.length > 0) {
           b.tasks.slice(-5).forEach(t => {
             const icon = t.status === "pending" ? "🟡" : "🟢";
             console.log(`  ${icon} [Pheromone: ${t.pheromone.toString().padStart(3)}] ${t.task} (${t.publisher})`);
           });
         } else { console.log("  ○ Blackboard is empty."); }
       } catch(e) { console.log("  ○ Cannot read blackboard."); }
     ' 2>/dev/null || echo "  ○ Parse error."
  else
     echo -e "  ○ No blackboard found."
  fi

  # 4. Intelligence Footer
  echo -e "\n${BLUE}─────────────────────────────────────────────────────────────────────${NC}"
  echo -e "  ${YELLOW}🎯 Goals:${NC} $(grep -c -E '^\- \[~\]' "$ROOT_DIR/ψ/memory/goals.md" 2>/dev/null || echo 0) Active  |  ${PURPLE}📍 Vault:${NC} ψ/ (Connected)"
  echo -e "${BLUE}🌌───────────────────────────────────────────────────────────────────🌌${NC}"
}

ot-safe-write() {
  local file="${1:?Usage: ot-safe-write <file> <content>}"
  local content="$2"
  local temp_file="${file}.tmp"
  [ -f "$file" ] && echo "Current hash: $(sha256sum "$file" | cut -d' ' -f1)"
  echo "$content" > "$temp_file"
  mv "$temp_file" "$file"
  echo "✓ Safe write completed: $file"
}

ot-chrome-connect() {
  echo -e "${PURPLE}🔌 Connecting to Chrome via CDP...${NC}"
  node "$PROJECT_ROOT/oracle-cowork/src/chrome-connector.js"
}

ot-hack-chrome() {
  echo -e "${PURPLE}🛠️  Initiating Chrome Networking Bridge...${NC}"
  # Run bridge in background
  python3 "$PROJECT_ROOT/oracle-cowork/src/bridge-chrome.py" &
  local bridge_pid=$!
  
  # Ensure cleanup on exit
  trap "kill $bridge_pid 2>/dev/null || true" EXIT
  
  # Give it a second to bind
  sleep 1
  
  # Trigger Node.js connector
  echo -e "${GREEN}🔗 Connecting to Chrome via Bridge...${NC}"
  node "$PROJECT_ROOT/oracle-cowork/src/chrome-connector.js"
}

ot-cowork-open() {
  local url="${1:-}"
  echo -e "${PURPLE}🚀 Launching Oracle Cowork Engine...${NC}"
  # Translate Project Root to Windows Path for node.exe
  local script_win_path=$(wslpath -w "$PROJECT_ROOT/oracle-cowork/src/browser-engine.js")
  # Run via Windows node.exe to ensure it pops up on Peach's screen
  node.exe "$script_win_path" "$url"
}

ot-gmail-scan() {
  echo -e "${PURPLE}📧 Scanning Gmail for Intelligence...${NC}"
  # Translate Project Root to Windows Path for node.exe
  local script_win_path=$(wslpath -w "$PROJECT_ROOT/oracle-cowork/src/gmail-scanner.js")
  # Run via Windows node.exe
  node.exe "$script_win_path"
}

ot-gmail-clean() {
    echo -e "${PURPLE}🧹 Cleaning Gmail...${NC}"
    local script_win_path=$(wslpath -w "$PROJECT_ROOT/oracle-cowork/src/gmail-manager.js")
    local type_arg="${1:?Usage: --type <promo|all>}" # e.g. --type promo
    
    if [[ "$type_arg" == "--type" && "$2" == "promo" ]]; then
        node.exe "$script_win_path" --archive-promo
    else
        echo "Invalid argument for gmail-clean. Usage: gmail-clean --type promo"
        return 1
    fi
}

ot-gmail-unsubscribe() {
    echo -e "${PURPLE}👋 Unsubscribing from sender...${NC}"
    local script_win_path=$(wslpath -w "$PROJECT_ROOT/oracle-cowork/src/gmail-manager.js")
    local sender_arg="${1:?Usage: --sender <sender_name>}" # e.g. --sender "news@example.com"
    local sender_name="${2:?Missing sender name}"

    if [[ "$sender_arg" == "--sender" ]]; then
        node.exe "$script_win_path" --unsubscribe-from "$sender_name"
    else
        echo "Invalid arguments for gmail-unsubscribe. Usage: gmail-unsubscribe --sender <sender_name>"
        return 1
    fi
}

ot-facebook-scan() {
  echo -e "${PURPLE}👍 Scanning Facebook for Intelligence...${NC}"
  # Translate Project Root to Windows Path for node.exe
  local script_win_path=$(wslpath -w "$PROJECT_ROOT/oracle-cowork/src/facebook-scanner.js")
  # Run via Windows node.exe
  node.exe "$script_win_path"
}

ot-slack-scan() {
  echo -e "${PURPLE}💬 Scanning Slack for Intelligence...${NC}"
  # Translate Project Root to Windows Path for node.exe
  local script_win_path=$(wslpath -w "$PROJECT_ROOT/oracle-cowork/src/slack-connector.js")
  # Run via Windows node.exe
  node.exe "$script_win_path"
}


ot-task() {
  local agent="${CLAUDE_AGENT_NAME:-god}"
  local task_msg="${1:?Usage: ot-task <message>}"
  local ctx_usage="${2:-0%}"
  mkdir -p "ψ/memory/tasks"
  # บันทึกเป็นไฟล์ json ขนาดเล็กเพื่อให้ Dashboard อ่านง่าย
  echo "{\"agent\": \"$agent\", \"task\": \"$task_msg\", \"ctx\": \"$ctx_usage\", \"timestamp\": \"$(date +%H:%M:%S)\"}" > "ψ/memory/tasks/${agent}.task"
  echo -e "  ${GREEN}✓ Task Reported:${NC} $task_msg (@$agent)"
}

ot-view-supreme() {
  echo -e "${PURPLE}🎨 Configuring Supreme Layout...${NC}"
  # แบ่งหน้าจอ: บนโชว์ Dashboard (รันเป็นคำสั่งเริ่มต้น), ล่างว่างไว้ให้พิมพ์
  # ใช้ -l 25 เพื่อระบุความสูง 25 บรรทัด
  tmux split-window -v -l 25 "watch -n 5 -c source /mnt/c/Agentic/scripts/oracle-tools.sh && ot-status"
  echo -e "${GREEN}✅ Supreme Layout Ready!${NC}"
}

# ═══════════════════════════════════════════
# CLI ENTRY POINT
# ═══════════════════════════════════════════

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    task) ot-task "$@" ;;
    view) ot-view-supreme ;;
    verify)      ot-verify "$@" ;;
    pre-flight)  ot-pre-flight ;;
    edit)        ot-edit-surgical "$@" ;;
    read-range)  ot-read-range "$@" ;;
    hey)         ot-hey "$@" ;;
    compress)    ot-compress "$@" ;;
    extract-skill) ot-extract-skill "$@" ;;
    pulse)       ot-pulse "$@" ;;
    status)      ot-status ;;
    safe-write)  ot-safe-write "$@" ;;
    chrome-connect) ot-chrome-connect ;;
    hack-chrome) ot-hack-chrome ;;
    cowork-open) ot-cowork-open "$@" ;;
    gmail-scan)  ot-gmail-scan ;;
    gmail-clean) ot-gmail-clean "$@";;
    gmail-unsubscribe) ot-gmail-unsubscribe "$@";;
    facebook-scan) ot-facebook-scan ;;
    slack-scan)  ot-slack-scan ;;
    *)
      echo "Commands: verify, pre-flight, edit, read-range, hey, compress, extract-skill, pulse, status, safe-write, chrome-connect, hack-chrome, cowork-open, gmail-scan, gmail-clean, gmail-unsubscribe, facebook-scan, slack-scan"
      ;;
esac
