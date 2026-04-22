#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# pre-send-check.sh — ตรวจ output ก่อนส่งให้ user
#
# Usage:
#   echo "text to check" | bash scripts/pre-send-check.sh
#   bash scripts/pre-send-check.sh --file /tmp/output.txt
#
# Exit 0 = OK to send
# Exit 1 = REPETITION DETECTED — rewrite needed
# ═══════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get input text
if [ "${1:-}" = "--file" ]; then
    TEXT=$(cat "${2:-/dev/stdin}")
else
    TEXT=$(cat)
fi

[ -z "$TEXT" ] && exit 0

ERRORS=0

# ── Check 1: Exact line duplicates ─────────────────────────
DUPES=$(echo "$TEXT" | grep -v '^$' | grep -v '^\s*$' | sort | uniq -c | sort -rn | awk '$1 >= 2 {print $1, $0}' | head -5)
if [ -n "$DUPES" ]; then
    echo -e "${RED}⛔ EXACT DUPLICATE LINES:${NC}"
    while IFS= read -r line; do
        count=$(echo "$line" | awk '{print $1}')
        content=$(echo "$line" | sed 's/^ *[0-9]* [0-9]* //' | head -c 80)
        echo -e "  ${RED}${count}x${NC}: ${content}"
    done <<< "$DUPES"
    ERRORS=$((ERRORS+1))
fi

# ── Check 2: Sentence-level similarity (fuzzy) ─────────────
# Split into sentences, check for near-duplicates
SENTENCES=$(echo "$TEXT" | tr '.' '\n' | tr '!' '\n' | tr '?' '\n' | grep -v '^$' | grep -v '^\s*$' | sed 's/^[[:space:]]*//' | head -30)
if [ $(echo "$SENTENCES" | wc -l) -gt 3 ]; then
    SIMILAR=$(echo "$SENTENCES" | sort | uniq -c | sort -rn | awk '$1 >= 2' | head -3)
    if [ -n "$SIMILAR" ]; then
        echo -e "${YELLOW}⚠️ SIMILAR SENTENCES:${NC}"
        while IFS= read -r line; do
            count=$(echo "$line" | awk '{print $1}')
            content=$(echo "$line" | sed 's/^ *[0-9]* //' | head -c 80)
            echo -e "  ${YELLOW}${count}x${NC}: ${content}"
        done <<< "$SIMILAR"
        ERRORS=$((ERRORS+1))
    fi
fi

# ── Check 3: Keyword stuffing ──────────────────────────────
STUFFED=$(echo "$TEXT" | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | grep -v '^$' | sort | uniq -c | sort -rn | awk '$1 >= 5 && length($2) > 3' | head -5)
if [ -n "$STUFFED" ]; then
    echo -e "${YELLOW}⚠️ KEYWORD STUFFING:${NC}"
    while IFS= read -r line; do
        count=$(echo "$line" | awk '{print $1}')
        word=$(echo "$line" | awk '{print $2}')
        echo -e "  ${YELLOW}${count}x${NC}: '${word}'"
    done <<< "$STUFFED"
    ERRORS=$((ERRORS+1))
fi

# ── Verdict ────────────────────────────────────────────────
echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ REPETITION DETECTED ($ERRORS issue(s)) — REWRITE BEFORE SENDING${NC}"
    exit 1
else
    echo -e "${GREEN}✅ No repetition — OK to send${NC}"
    exit 0
fi
