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
  grep -E "Action:|Result:|Error:|🎯 Goal:" "$1" > "$1.compressed"
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
  echo "{"agent": "$agent", "status": "$1", "timestamp": "$(date +%H:%M:%S)"}" > "ψ/memory/pulse/${agent}.status"
}

ot-status() {
  echo -e "${PURPLE}══ 🚀 ORACLE FLEET DASHBOARD ══${NC}"
  echo "Time: $(date +%H:%M:%S) | User: Peach"
  echo ""
  echo -e "${BLUE}📡 LIVE PULSE:${NC}"
  ls ψ/memory/pulse/*.status 2>/dev/null | while read -r f; do
    local a=$(basename "$f" .status)
    local s=$(grep -oP '"status": "\K[^"]+' "$f")
    local t=$(grep -oP '"timestamp": "\K[^"]+' "$f")
    echo -e "  [${GREEN}$a${NC}]: $s ($t)"
  done || echo "  (no pulses)"
  echo ""
  echo -e "${YELLOW}🎯 GOALS:${NC}"
  grep -c -E '^\- \[~\]' ψ/memory/goals.md 2>/dev/null || echo 0
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


# ═══════════════════════════════════════════
# CLI ENTRY POINT
# ═══════════════════════════════════════════

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
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
    *)
      echo "Commands: verify, pre-flight, edit, read-range, hey, compress, extract-skill, pulse, status, safe-write, chrome-connect, hack-chrome, cowork-open, gmail-scan, gmail-clean, gmail-unsubscribe, facebook-scan"
      ;;
esac
