#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# timed-learn.sh — Timed learning with live progress bar
# Usage: bash timed-learn.sh <topic> <minutes> <url1> [url2] ...
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PSI_DIR="$PROJECT_ROOT/ψ"
SESSION_DIR="$PSI_DIR/memory/learn-sessions"

TOPIC="${1:?Usage: timed-learn.sh <topic> <minutes> <url1> [url2] ...}"
DURATION_MIN="${2:?Provide duration in minutes}"
shift 2
URLS=("$@")

if [ ${#URLS[@]} -eq 0 ]; then
    echo "Error: Provide at least one URL to study"
    exit 1
fi

# ─── Session Setup ───
SESSION_ID="$(date +%Y-%m-%d_%H-%M)_${TOPIC// /-}"
SESSION_PATH="$SESSION_DIR/$SESSION_ID"
mkdir -p "$SESSION_PATH/sources" "$SESSION_PATH/evidence" "$SESSION_PATH/quiz"

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION_MIN * 60))

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Progress Bar ───
progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local pct=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    printf "\r  ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" $pct
}

# ─── Live Timer Display ───
show_status() {
    local now=$(date +%s)
    local elapsed=$((now - START_TIME))
    local remaining=$((END_TIME - now))
    local total=$((DURATION_MIN * 60))

    if [ $remaining -le 0 ]; then
        remaining=0
    fi

    local emins=$((elapsed / 60))
    local esecs=$((elapsed % 60))
    local rmins=$((remaining / 60))
    local rsecs=$((remaining % 60))

    # Color based on remaining time
    if [ $remaining -le 60 ]; then
        TCOLOR="$RED"
    elif [ $remaining -le 180 ]; then
        TCOLOR="$YELLOW"
    else
        TCOLOR="$GREEN"
    fi

    echo -ne "\r  ${TCOLOR}⏱  ${rmins}:${rsecs}${NC} remaining | "
    echo -ne "Elapsed: ${emins}:${esecs} | "
    echo -ne "Sources: ${SOURCES_DONE}/${#URLS[@]}"

    progress_bar $elapsed $total
}

# ─── Header ───
echo ""
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║  🧠 TIMED LEARNING SESSION                       ║${NC}"
echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  Topic:    ${BOLD}$TOPIC${NC}"
echo -e "${CYAN}║${NC}  Duration: ${BOLD}${DURATION_MIN} minutes${NC}"
echo -e "${CYAN}║${NC}  Deadline: ${BOLD}$(date -d @$END_TIME '+%H:%M:%S' 2>/dev/null || date -r $END_TIME '+%H:%M:%S' 2>/dev/null || echo 'set')${NC}"
echo -e "${CYAN}║${NC}  Sources:  ${BOLD}${#URLS[@]} URLs${NC}"
echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# ─── Initialize manifest ───
cat > "$SESSION_PATH/manifest.json" << EOF
{
  "session_id": "$SESSION_ID",
  "topic": "$TOPIC",
  "started_at": "$(date -Iseconds)",
  "duration_minutes": $DURATION_MIN,
  "urls": $(printf '%s\n' "${URLS[@]}" | jq -R . | jq -s .),
  "status": "in_progress"
}
EOF

SOURCES_DONE=0
SOURCES_LOG="$SESSION_PATH/sources/manifest.jsonl"
EVIDENCE_LOG="$SESSION_PATH/evidence/log.jsonl"
touch "$SOURCES_LOG" "$EVIDENCE_LOG"

# ─── Fetch Each Source ───
echo -e "${BOLD}📡 Fetching sources...${NC}"
echo ""

for i in "${!URLS[@]}"; do
    url="${URLS[$i]}"
    num=$((i + 1))

    # Check time
    NOW=$(date +%s)
    if [ $NOW -ge $END_TIME ]; then
        echo -e "\n  ${RED}⏰ Time's up!${NC}"
        break
    fi

    show_status
    echo ""
    echo -e "  ${CYAN}[$num/${#URLS[@]}]${NC} Fetching: ${DIM}$url${NC}"

    SAFE_NAME=$(printf "%02d_%s" $num "$(echo "$url" | sed 's|https\?://||; s/[^a-zA-Z0-9]/_/g' | head -c 60)")
    OUTPUT_FILE="$SESSION_PATH/sources/${SAFE_NAME}.md"

    if curl -sL --max-time 20 "$url" -o "$OUTPUT_FILE.raw" 2>/dev/null; then
        # Strip HTML tags
        sed 's/<[^>]*>//g; s/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&nbsp;/ /g; s/&#[0-9]*;//g' "$OUTPUT_FILE.raw" > "$OUTPUT_FILE" 2>/dev/null || cp "$OUTPUT_FILE.raw" "$OUTPUT_FILE"

        CHARS=$(wc -c < "$OUTPUT_FILE")
        LINES=$(wc -l < "$OUTPUT_FILE")

        echo "{\"url\":\"$url\",\"file\":\"${SAFE_NAME}.md\",\"status\":\"ok\",\"chars\":$CHARS,\"lines\":$LINES}" >> "$SOURCES_LOG"
        echo -e "  ${GREEN}✓${NC} Saved: ${SAFE_NAME}.md ($CHARS chars, $LINES lines)"
        SOURCES_DONE=$((SOURCES_DONE + 1))
    else
        echo "{\"url\":\"$url\",\"file\":\"\",\"status\":\"failed\",\"chars\":0,\"lines\":0}" >> "$SOURCES_LOG"
        echo -e "  ${RED}✗${NC} Failed to fetch"
    fi
done

echo ""
show_status
echo ""
echo ""

# ─── Save final status ───
NOW=$(date +%s)
ELAPSED=$((NOW - START_TIME))
cat > "$SESSION_PATH/status.json" << EOF
{
  "session_id": "$SESSION_ID",
  "topic": "$TOPIC",
  "sources_fetched": $SOURCES_DONE,
  "sources_total": ${#URLS[@]},
  "elapsed_seconds": $ELAPSED,
  "completed_at": "$(date -Iseconds)",
  "next_step": "Extract evidence → Run quiz → Generate report → Verify"
}
EOF

echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✅ Source Fetching Complete${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Session: ${CYAN}$SESSION_ID${NC}"
echo -e "  Fetched: ${BOLD}$SOURCES_DONE${NC}/${#URLS[@]} sources"
echo -e "  Path:    ${CYAN}$SESSION_PATH${NC}"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "  1. Read sources in: ${CYAN}$SESSION_PATH/sources/${NC}"
echo -e "  2. Extract evidence → log to: ${CYAN}$SESSION_PATH/evidence/log.jsonl${NC}"
echo -e "  3. Complete quiz in: ${CYAN}$SESSION_PATH/quiz/${NC}"
echo -e "  4. Write report in: ${CYAN}$SESSION_PATH/${NC}"
echo -e "  5. Verify: ${BOLD}bash scripts/learn/learn-verify.sh $SESSION_ID${NC}"
echo ""
