#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# oracle-tools.sh — GOD's hands: Oracle API + Task Runner
# Cross-platform: works on Linux, macOS, WSL, Git Bash
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ORACLE_URL="${ORACLE_URL:-http://localhost:47778}"
MAW_URL="${MAW_URL:-http://localhost:3456}"
PSI_DIR="$PROJECT_ROOT/ψ"

# ─── Cross-platform detection ───
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  CURL="curl.exe"
  JQ="$SCRIPT_DIR/jq.exe"
else
  CURL="curl"
  JQ="jq"
fi

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ═══════════════════════════════════════════
# ORACLE API FUNCTIONS (with verification)
# ═══════════════════════════════════════════

# บันทึกสิ่งที่เรียนรู้ลง Oracle
# Usage: oracle_learn "title" "content" ["type"]
oracle_learn() {
  local title="${1:?Usage: oracle_learn <title> <content> [type]}"
  local content="${2:?Usage: oracle_learn <title> <content> [type]}"
  local type="${3:-learning}"

  local pattern="# $title\n\n$content"

  local response
  response=$($CURL -s -X POST "${ORACLE_URL}/api/learn" \
    -H "Content-Type: application/json" \
    -d "$($JQ -n --arg p "$pattern" '{"pattern": $p}')" 2>/dev/null) || true

  if [ -n "$response" ] && echo "$response" | $JQ -e '.id // .success // .ok' >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Learned: $title"
    return 0
  else
    echo -e "${YELLOW}⚠${NC} Oracle API unreachable — saved locally only"
    # Fallback: save to local file
    echo -e "\n## $(date +%Y-%m-%d) — $title\n- Type: $type\n- Content: $content" >> "$PSI_DIR/memory/learnings.md"
    return 0
  fi
}

# ค้นหาความรู้ใน Oracle
# Usage: oracle_search "query" ["mode"] ["limit"]
oracle_search() {
  local query="${1:?Usage: oracle_search <query> [mode] [limit]}"
  local mode="${2:-hybrid}"
  local limit="${3:-10}"

  local encoded_query
  encoded_query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))" 2>/dev/null || echo "$query" | sed 's/ /%20/g')

  $CURL -s "${ORACLE_URL}/api/search?q=${encoded_query}&mode=${mode}&limit=${limit}" 2>/dev/null || \
    echo "{\"results\":[],\"error\":\"Oracle API unreachable\"}"
}

# เช็คสถานะ Oracle
oracle_stats() {
  $CURL -s "${ORACLE_URL}/api/stats" 2>/dev/null || echo "{\"error\":\"unreachable\"}"
}

# เช็คสุขภาพระบบ
oracle_health() {
  $CURL -s "${ORACLE_URL}/api/health" 2>/dev/null || echo "{\"status\":\"unreachable\"}"
}

# บันทึก decision
# Usage: oracle_decide "title" "decision" "rationale"
oracle_decide() {
  local title="${1:?Usage: oracle_decide <title> <decision> <rationale>}"
  local decision="${2:?Usage: oracle_decide <title> <decision> <rationale>}"
  local rationale="${3:?Usage: oracle_decide <title> <decision> <rationale>}"

  oracle_learn "$title" "Decision: $decision\nRationale: $rationale" "decision"
}

# บันทึก pattern
# Usage: oracle_pattern "title" "pattern_description"
oracle_pattern() {
  local title="${1:?Usage: oracle_pattern <title> <description>}"
  local desc="${2:?Usage: oracle_pattern <title> <description>}"

  oracle_learn "$title" "$desc" "pattern"
}

# Reflect — ทบทวน
oracle_reflect() {
  $CURL -s "${ORACLE_URL}/api/reflect" 2>/dev/null || echo "{\"error\":\"unreachable\"}"
}

# ═══════════════════════════════════════════
# FILE OPERATIONS (safe wrappers with verification)
# ═══════════════════════════════════════════

# อ่านไฟล์ (relative to project root)
# Usage: read_file "path/to/file"
read_file() {
  local path="${1:?Usage: read_file <path>}"
  local full_path="$PROJECT_ROOT/$path"
  if [ -f "$full_path" ]; then
    cat "$full_path"
  else
    echo "ERROR: File not found: $path" >&2
    return 1
  fi
}

# เขียนไฟล์ with verification
# Usage: write_file "path/to/file" "content"
write_file() {
  local path="${1:?Usage: write_file <path> <content>}"
  local content="${2:?Usage: write_file <path> <content>}"
  local full_path="$PROJECT_ROOT/$path"
  mkdir -p "$(dirname "$full_path")"
  echo "$content" > "$full_path"

  # Verify
  if [ -f "$full_path" ] && [ -s "$full_path" ]; then
    local chars=$(wc -c < "$full_path")
    echo -e "${GREEN}✓${NC} Written: $path ($chars bytes)"
  else
    echo -e "${RED}✗${NC} FAILED to write: $path" >&2
    return 1
  fi
}

# เพิ่มบรรทัดท้ายไฟล์ with verification
# Usage: append_file "path/to/file" "new line"
append_file() {
  local path="${1:?Usage: append_file <path> <line>}"
  local line="${2:?Usage: append_file <path> <line>}"
  local full_path="$PROJECT_ROOT/$path"
  echo "$line" >> "$full_path"

  # Verify last line matches
  if tail -1 "$full_path" | grep -qF "$line"; then
    echo -e "${GREEN}✓${NC} Appended to: $path"
  else
    echo -e "${RED}✗${NC} FAILED to append: $path" >&2
    return 1
  fi
}

# ═══════════════════════════════════════════
# GOAL MANAGEMENT (with verification)
# ═══════════════════════════════════════════

# อ่าน goals ที่ยังไม่เสร็จ
# Usage: list_goals ["status"]
list_goals() {
  local status="${1:-all}"
  local goals_file="$PSI_DIR/memory/goals.md"

  if [ ! -f "$goals_file" ]; then
    echo "No goals file found" >&2
    return 1
  fi

  case "$status" in
    pending) grep -E '^\- \[ \]' "$goals_file" || echo "(no pending goals)" ;;
    active)  grep -E '^\- \[~\]' "$goals_file" || echo "(no active goals)" ;;
    done)    grep -E '^\- \[x\]' "$goals_file" || echo "(no completed goals)" ;;
    blocked) grep -E '^\- \[!\]' "$goals_file" || echo "(no blocked goals)" ;;
    all)
      echo "=== Pending ==="
      grep -E '^\- \[ \]' "$goals_file" || echo "(none)"
      echo "=== Active ==="
      grep -E '^\- \[~\]' "$goals_file" || echo "(none)"
      echo "=== Done ==="
      grep -E '^\- \[x\]' "$goals_file" || echo "(none)"
      echo "=== Blocked ==="
      grep -E '^\- \[!\]' "$goals_file" || echo "(none)"
      ;;
  esac
}

# เพิ่ม goal ใหม่ with verification
# Usage: add_goal "description"
add_goal() {
  local desc="${1:?Usage: add_goal <description>}"
  local date=$(date +%Y-%m-%d)
  local agent="${CLAUDE_AGENT_NAME:-god}"
  local line="- [ ] [$date] $desc — by $agent"

  echo "$line" >> "$PSI_DIR/memory/goals.md"

  # Verify
  if tail -1 "$PSI_DIR/memory/goals.md" | grep -qF "$desc"; then
    echo -e "${GREEN}✓${NC} Goal added: $desc"
  else
    echo -e "${RED}✗${NC} Failed to add goal" >&2
    return 1
  fi
}

# อัพเดทสถานะ goal with verification
update_goal() {
  local old_status="${1:?Usage: update_goal <old> <new> <search_text>}"
  local new_status="${2:?Usage: update_goal <old> <new> <search_text>}"
  local search="${3:?Usage: update_goal <old> <new> <search_text>}"
  local goals_file="$PSI_DIR/memory/goals.md"

  if grep -q "$search" "$goals_file"; then
    sed -i "s/^\(- \)${old_status//[/\\[}\(.*\)${search}/\1${new_status}\2${search}/" "$goals_file"

    # Verify
    if grep -q "$new_status.*$search" "$goals_file"; then
      echo -e "${GREEN}✓${NC} Goal updated: $old_status → $new_status ($search)"
    else
      echo -e "${RED}✗${NC} Update verification failed" >&2
      return 1
    fi
  else
    echo -e "${RED}✗${NC} Goal not found: $search" >&2
    return 1
  fi
}

# ═══════════════════════════════════════════
# MEMORY OPERATIONS (with verification)
# ═══════════════════════════════════════════

# Lock protocol for shared memory
memory_lock() {
  local file="${1:?Usage: memory_lock <filename>}"
  local lock_file="$PSI_DIR/memory/locks/${file}.lock"
  local agent="${CLAUDE_AGENT_NAME:-god}"
  mkdir -p "$PSI_DIR/memory/locks"
  echo "$agent:$(date +%s)" > "$lock_file"
}

memory_unlock() {
  local file="${1:?Usage: memory_unlock <filename>}"
  local lock_file="$PSI_DIR/memory/locks/${file}.lock"
  rm -f "$lock_file"
}

# เขียนลง shared memory (with lock + verification)
memory_write() {
  local file="${1:?Usage: memory_write <file> <content>}"
  local content="${2:?Usage: memory_write <file> <content>}"
  local target="$PSI_DIR/memory/$file"

  memory_lock "$file"
  echo "$content" >> "$target"
  memory_unlock "$file"

  # Verify
  if tail -1 "$target" | grep -qF "$content"; then
    echo -e "${GREEN}✓${NC} Memory updated: $file"
  else
    echo -e "${RED}✗${NC} Memory write failed: $file" >&2
    return 1
  fi
}

# อ่าน shared memory
memory_read() {
  local file="${1:?Usage: memory_read <filename>}"
  local target="$PSI_DIR/memory/$file"
  if [ -f "$target" ]; then
    cat "$target"
  else
    echo "(empty: $file)" >&2
    return 1
  fi
}

# ═══════════════════════════════════════════
# TASK RUNNER (Goal Execution Engine)
# ═══════════════════════════════════════════

# Run next pending goal
run_next_goal() {
  local goals_file="$PSI_DIR/memory/goals.md"

  local goal_line
  goal_line=$(grep -n -m 1 -E '^\- \[ \]' "$goals_file" 2>/dev/null || true)

  if [ -z "$goal_line" ]; then
    echo -e "${GREEN}✓${NC} No pending goals — all done or none exist"
    return 0
  fi

  local line_num=$(echo "$goal_line" | cut -d: -f1)
  local goal_text=$(echo "$goal_line" | cut -d: -f2- | sed 's/^- \[ \] //')

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎯 Next Goal: $goal_text"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  sed -i "${line_num}s/^\(- \)\[ \]/\1[~]/" "$goals_file"

  # Verify
  if grep -q "\[~\].*$(echo "$goal_text" | head -c 30)" "$goals_file"; then
    echo -e "${GREEN}✓${NC} Status: [~] → Active"
  else
    echo -e "${RED}✗${NC} Failed to mark goal as active" >&2
    return 1
  fi

  mkdir -p "$PSI_DIR/memory/logs"
  echo "[$(date +%Y-%m-%d_%H-%M)] Started goal: $goal_text" >> "$PSI_DIR/memory/logs/task-runner.log"
}

# Complete a goal
complete_goal() {
  local search="${1:?Usage: complete_goal <search_text>}"
  local goals_file="$PSI_DIR/memory/goals.md"

  sed -i "s/^\(- \)\[~\]\(.*${search}\)/\1[x]\2/" "$goals_file"

  # Verify
  if grep -q "\[x\].*$search" "$goals_file"; then
    echo -e "${GREEN}✓${NC} Goal completed: $search"
  else
    echo -e "${YELLOW}⚠${NC} Goal may not have been updated — check manually"
  fi

  mkdir -p "$PSI_DIR/memory/logs"
  echo "[$(date +%Y-%m-%d_%H-%M)] Completed: $search" >> "$PSI_DIR/memory/logs/task-runner.log"

  oracle_learn "Goal Completed" "$search — completed on $(date +%Y-%m-%d)" "goal-completion" 2>/dev/null || true
}

# Mark goal as blocked
block_goal() {
  local search="${1:?Usage: block_goal <search_text> <reason>}"
  local reason="${2:-no reason given}"
  local goals_file="$PSI_DIR/memory/goals.md"

  sed -i "s/^\(- \)\[~\]\(.*${search}\)/\1[!]\2/" "$goals_file"

  if grep -q "\[!\].*$search" "$goals_file"; then
    echo -e "${YELLOW}⚠${NC} Goal blocked: $search"
    echo "  Reason: $reason"
  else
    echo -e "${RED}✗${NC} Failed to mark goal as blocked" >&2
  fi
}

# ═══════════════════════════════════════════
# AGENT COMMUNICATION
# ═══════════════════════════════════════════

# ส่ง message ให้ agent ผ่าน tmux
send_to_agent() {
  local agent="${1:?Usage: send_to_agent <agent> <message>}"
  local message="${2:?Usage: send_to_agent <agent> <message>}"
  local session="mawjs-${agent}"

  if tmux has-session -t "$session" 2>/dev/null; then
    tmux send-keys -t "$session" "$message" Enter
    echo -e "${GREEN}✓${NC} Sent to $agent: $message"
  else
    echo -e "${RED}✗${NC} Agent $agent not found (session: $session)" >&2
    return 1
  fi
}

# ส่ง message ผ่าน Maw API
ask_agent() {
  local agent="${1:?Usage: ask_agent <agent> <message>}"
  local message="${2:?Usage: ask_agent <agent> <message>}"

  $CURL -s -X POST "${MAW_URL}/api/asks" \
    -H "Content-Type: application/json" \
    -d "{\"to\": \"${agent}\", \"message\": $(echo "$message" | $JQ -Rs .), \"from\": \"${CLAUDE_AGENT_NAME:-god}\"}" 2>/dev/null || \
    echo "{\"error\":\"Maw API unreachable\"}"
}

# ═══════════════════════════════════════════
# REFLECTION (with verification)
# ═══════════════════════════════════════════

reflect() {
  local task="${1:?Usage: reflect <task> <result> <good> <improve> <lesson>}"
  local result="${2:-partial}"
  local good="${3:-}"
  local improve="${4:-}"
  local lesson="${5:-}"
  local agent="${CLAUDE_AGENT_NAME:-god}"
  local date=$(date +%Y-%m-%d_%H-%M)
  local file="$PSI_DIR/memory/reflections/${date}_${task// /-}.md"

  mkdir -p "$PSI_DIR/memory/reflections"
  cat > "$file" << EOF
# Reflection
Agent: $agent | Task: $task
Date: $(date +%Y-%m-%d\ %H:%M)

## Result: $result

## Good: ${good:-none noted}

## Improve: ${improve:-none noted}

## Lesson: ${lesson:-none noted}
EOF

  # Verify
  if [ -f "$file" ] && [ -s "$file" ]; then
    echo -e "${GREEN}✓${NC} Reflection saved: $file"
  else
    echo -e "${RED}✗${NC} Failed to save reflection" >&2
    return 1
  fi

  if [ -n "$lesson" ]; then
    oracle_learn "Lesson: $task" "$lesson" "learning" 2>/dev/null || true
  fi
}

# ═══════════════════════════════════════════
# FLEET STATUS (real checks, not theater)
# ═══════════════════════════════════════════

fleet_status() {
  echo "══ Fleet Status ══"
  echo ""

  # Tmux sessions
  echo "📡 Tmux Sessions:"
  local sessions=$(tmux list-sessions 2>/dev/null || true)
  if [ -n "$sessions" ]; then
    echo "$sessions" | while read -r line; do echo "  $line"; done
  else
    echo "  (no sessions)"
  fi

  echo ""

  # Oracle health (real check)
  echo "🧠 Oracle Core:"
  local oracle_status=$(oracle_health 2>/dev/null | $JQ -r '.status // "unreachable"' 2>/dev/null || echo "unreachable")
  if [ "$oracle_status" = "unreachable" ]; then
    echo -e "  ${RED}unreachable${NC} (port 47778)"
  else
    echo -e "  ${GREEN}$oracle_status${NC}"
  fi

  echo ""

  # Maw health (real check)
  echo "🔧 Maw API:"
  local maw_status=$($CURL -s "${MAW_URL}/api/health" 2>/dev/null | $JQ -r '.status // "unreachable"' 2>/dev/null || echo "unreachable")
  if [ "$maw_status" = "unreachable" ]; then
    echo -e "  ${RED}unreachable${NC} (port 3456)"
  else
    echo -e "  ${GREEN}$maw_status${NC}"
  fi

  echo ""

  # Goals summary (real count)
  echo "🎯 Goals:"
  local pending=$(grep -c -E '^\- \[ \]' "$PSI_DIR/memory/goals.md" 2>/dev/null || echo 0)
  local active=$(grep -c -E '^\- \[~\]' "$PSI_DIR/memory/goals.md" 2>/dev/null || echo 0)
  local done=$(grep -c -E '^\- \[x\]' "$PSI_DIR/memory/goals.md" 2>/dev/null || echo 0)
  echo "  Pending: $pending | Active: $active | Done: $done"
}

# ═══════════════════════════════════════════
# AUTONOMOUS CYCLE
# ═══════════════════════════════════════════

autonomous_check() {
  echo "══ Autonomous Check $(date +%H:%M) ══"

  # 1. Check inbox (real count)
  local inbox_count=$(ls "$PSI_DIR/inbox/" 2>/dev/null | wc -l || echo 0)
  echo "📥 Inbox: $inbox_count items"
  if [ "$inbox_count" -gt 0 ]; then
    ls -1 "$PSI_DIR/inbox/" 2>/dev/null | head -5 | while read f; do echo "  - $f"; done
  fi

  # 2. Check pending goals (real count)
  local pending=$(grep -c -E '^\- \[ \]' "$PSI_DIR/memory/goals.md" 2>/dev/null || echo 0)
  echo "🎯 Pending goals: $pending"

  # 3. Check active goals (real count)
  local active=$(grep -c -E '^\- \[~\]' "$PSI_DIR/memory/goals.md" 2>/dev/null || echo 0)
  if [ "$active" -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC} Active goals ($active) — may be stuck:"
    grep -E '^\- \[~\]' "$PSI_DIR/memory/goals.md" 2>/dev/null | while read l; do echo "  $l"; done
  fi

  # 4. Oracle stats (real check)
  echo ""
  local stats=$(oracle_stats 2>/dev/null)
  if echo "$stats" | $JQ -e '.totalEntries' >/dev/null 2>&1; then
    local entries=$(echo "$stats" | $JQ -r '.totalEntries // 0')
    echo "🧠 Oracle: $entries entries"
  else
    echo "🧠 Oracle: unreachable"
  fi
}

# ═══════════════════════════════════════════
# CLI ENTRY POINT
# ═══════════════════════════════════════════

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  COMMAND="${1:-help}"
  shift || true

  case "$COMMAND" in
    learn)       oracle_learn "$@" ;;
    search)      oracle_search "$@" ;;
    stats)       oracle_stats ;;
    health)      oracle_health ;;
    decide)      oracle_decide "$@" ;;
    pattern)     oracle_pattern "$@" ;;
    reflect)     oracle_reflect ;;
    read)        read_file "$@" ;;
    write)       write_file "$@" ;;
    append)      append_file "$@" ;;
    goals)       list_goals "$@" ;;
    add-goal)    add_goal "$@" ;;
    next-goal)   run_next_goal ;;
    done-goal)   complete_goal "$@" ;;
    block-goal)  block_goal "$@" ;;
    send)        send_to_agent "$@" ;;
    ask)         ask_agent "$@" ;;
    retro)       reflect "$@" ;;
    fleet)       fleet_status ;;
    check)       autonomous_check ;;
    help|*)
      echo "🔮 Oracle Tools — GOD's hands"
      echo ""
      echo "Oracle API:"
      echo "  learn <title> <content> [type]   — Learn something"
      echo "  search <query> [mode] [limit]    — Search knowledge"
      echo "  stats                            — Oracle stats"
      echo "  health                           — System health"
      echo "  decide <title> <decision> <why>  — Record decision"
      echo "  pattern <title> <description>    — Record pattern"
      echo ""
      echo "Files:"
      echo "  read <path>                      — Read file"
      echo "  write <path> <content>           — Write file"
      echo "  append <path> <line>             — Append to file"
      echo ""
      echo "Goals:"
      echo "  goals [status]                   — List goals"
      echo "  add-goal <description>           — Add goal"
      echo "  next-goal                        — Run next pending goal"
      echo "  done-goal <search>               — Complete goal"
      echo "  block-goal <search> <reason>     — Block goal"
      echo ""
      echo "Communication:"
      echo "  send <agent> <message>           — Send to agent (tmux)"
      echo "  ask <agent> <message>            — Ask agent (API)"
      echo ""
      echo "Reflection:"
      echo "  retro <task> <result> <good> <improve> <lesson>"
      echo ""
      echo "System:"
      echo "  fleet                            — Fleet status"
      echo "  check                            — Autonomous check"
      echo ""
      echo "Platform: $(uname -s) | Curl: $CURL | JQ: $JQ"
      ;;
  esac
fi
