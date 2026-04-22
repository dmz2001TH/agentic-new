#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# god-status.sh — Real-time GOD status bar with countdown
# Shows what agent is doing + countdown timer
# Usage: bash scripts/god-status.sh [update|show|live|clear] [agent] [action] [target] [deadline]
# ═══════════════════════════════════════════════════════════

STATUS_FILE="/tmp/god-status.json"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── JSON parser (no jq needed) ───
json_val() {
  local key="$1"
  local file="$2"
  grep "\"$key\"" "$file" 2>/dev/null | head -1 | sed "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/"
}

# ─── Update status ───
update_status() {
  cat > "$STATUS_FILE" << EOF
{
  "agent": "$1",
  "action": "$2",
  "target": "$3",
  "deadline": "$4",
  "started_at": $(date +%s)
}
EOF
}

# ─── Countdown ───
calc_remaining() {
  local deadline="$1"
  [ -z "$deadline" ] && return

  local now=$(date +%s)
  local dl_h=${deadline%%:*}
  local dl_m=${deadline##*:}
  local dl_sec=$((10#$dl_h * 3600 + 10#$dl_m * 60))
  local now_h=$(date +%H)
  local now_m=$(date +%M)
  local now_s=$(date +%S)
  local now_sec=$((10#$now_h * 3600 + 10#$now_m * 60 + 10#$now_s))

  [ $dl_sec -lt $now_sec ] && dl_sec=$((dl_sec + 86400))
  local remaining=$((dl_sec - now_sec))

  if [ $remaining -le 0 ]; then
    echo -e "${RED}${BOLD}⏰ TIME'S UP!${NC}"
  else
    local r_m=$((remaining / 60))
    local r_s=$((remaining % 60))
    local color="$GREEN"
    [ $remaining -le 300 ] && color="$YELLOW"
    [ $remaining -le 60 ] && color="$RED"
    printf "${color}${BOLD}%d:%02d${NC}" $r_m $r_s
  fi
}

# ─── Show status bar ───
show_bar() {
  local agent="${1:-god}"
  local action="${2:-idle}"
  local target="${3:-}"
  local deadline="${4:-}"

  local emoji="●"
  case "$action" in
    edit|Edit) emoji="✏️" ;;
    read|Read|cat) emoji="📖" ;;
    fetch|Fetch) emoji="📡" ;;
    search|Search) emoji="🔍" ;;
    write|Write) emoji="📝" ;;
    test|Test) emoji="🧪" ;;
    build|Build) emoji="🔨" ;;
    learn|Learn) emoji="🧠" ;;
    think|Think) emoji="💭" ;;
    report|Report) emoji="📋" ;;
    idle) emoji="⏸️" ;;
  esac

  local line2=" │ ≡ ${BOLD}Running Agent...${NC} (ctrl+o to expand)"
  local line3=" │ ${BOLD}${emoji} ${agent}${NC} · ${action}"
  [ -n "$target" ] && line3="${line3} ${target}"

  if [ -n "$deadline" ]; then
    local rem=$(calc_remaining "$deadline")
    [ -n "$rem" ] && line3="${line3}  ${rem}"
  fi

  echo -e "╭───────────────────────────────────────────────────────────────────────────────────────╮"
  echo -e "$line2"
  echo -e "$line3"
  echo -e "╰───────────────────────────────────────────────────────────────────────────────────────╯"
}

# ─── Read from status file and show ───
show_from_file() {
  if [ -f "$STATUS_FILE" ]; then
    local agent=$(json_val agent "$STATUS_FILE")
    local action=$(json_val action "$STATUS_FILE")
    local target=$(json_val target "$STATUS_FILE")
    local deadline=$(json_val deadline "$STATUS_FILE")
    show_bar "$agent" "$action" "$target" "$deadline"
  else
    show_bar "god" "idle" "" ""
  fi
}

# ─── Main ───
case "${1:-show}" in
  update)
    update_status "$2" "$3" "$4" "$5"
    show_bar "$2" "$3" "$4" "$5"
    ;;
  show)
    show_from_file
    ;;
  live)
    while true; do
      printf "\033[4A"  # Move up 4 lines
      show_from_file
      sleep 1
    done
    ;;
  clear)
    rm -f "$STATUS_FILE"
    echo "Status cleared"
    ;;
  *)
    echo "Usage: god-status.sh [update|show|live|clear] [agent] [action] [target] [deadline]"
    echo ""
    echo "Examples:"
    echo "  god-status.sh update builder Edit 'GEMINI.md' 01:10"
    echo "  god-status.sh update god Learn 'Bun Runtime' 00:45"
    echo "  god-status.sh update god Report 'สรุปผล' 01:00"
    echo "  god-status.sh show"
    echo "  god-status.sh clear"
    ;;
esac
