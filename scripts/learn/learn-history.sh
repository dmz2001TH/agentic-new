#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# learn-history.sh — Show learning session history & trends
# Tracks improvement over time
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SESSION_DIR="$PROJECT_ROOT/ψ/memory/learn-sessions"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

if [ ! -d "$SESSION_DIR" ]; then
    echo "No learning sessions found."
    exit 0
fi

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}  📊 LEARNING SESSION HISTORY${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

TOTAL=0
VERIFIED=0
AVG_SCORE=0
TOPICS=()

for session_dir in "$SESSION_DIR"/*/; do
    [ -d "$session_dir" ] || continue
    TOTAL=$((TOTAL + 1))

    SESSION_ID=$(basename "$session_dir")
    TOPIC=$(echo "$SESSION_ID" | sed 's/^[0-9-]*_[0-9-]*_//' | tr '-' ' ')

    # Check verification
    VER_FILE="$session_dir/verification.json"
    if [ -f "$VER_FILE" ]; then
        VERIFIED=$((VERIFIED + 1))
        SCORE=$(grep -o '"percentage":[0-9]*' "$VER_FILE" | cut -d: -f2)
        GRADE=$(grep -o '"grade":"[^"]*"' "$VER_FILE" | cut -d'"' -f4)
        AVG_SCORE=$((AVG_SCORE + SCORE))

        if [ "$SCORE" -ge 80 ]; then
            GCOLOR="$GREEN"
        elif [ "$SCORE" -ge 60 ]; then
            GCOLOR="$YELLOW"
        else
            GCOLOR="$RED"
        fi

        echo -e "  ${GCOLOR}[$GRADE]${NC} $TOPIC — ${SCORE}%"
    else
        echo -e "  ${DIM}[?]${NC} $TOPIC — not verified"
    fi

    # Check sources
    SOURCES_FILE="$session_dir/sources/manifest.jsonl"
    if [ -f "$SOURCES_FILE" ]; then
        SRC_COUNT=$(wc -l < "$SOURCES_FILE")
        echo -e "         ${DIM}Sources: $SRC_COUNT${NC}"
    fi
done

echo ""
echo -e "${BOLD}Summary:${NC}"
echo -e "  Total sessions:   $TOTAL"
echo -e "  Verified:         $VERIFIED"
if [ "$VERIFIED" -gt 0 ]; then
    AVG=$((AVG_SCORE / VERIFIED))
    echo -e "  Average score:    ${BOLD}${AVG}%${NC}"
fi
echo ""
