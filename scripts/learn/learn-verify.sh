#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# learn-verify.sh — Verify a learning session was real
# Checks evidence, scores quality, catches theater
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PSI_DIR="$PROJECT_ROOT/ψ"
SESSION_DIR="$PSI_DIR/memory/learn-sessions"

SESSION_ID="${1:?Usage: learn-verify.sh <session_id>}"
SESSION_PATH="$SESSION_DIR/$SESSION_ID"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

if [ ! -d "$SESSION_PATH" ]; then
    echo -e "${RED}Session not found: $SESSION_ID${NC}"
    exit 1
fi

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}  🔍 LEARNING SESSION VERIFICATION${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

SCORE=0
MAX_SCORE=0
ISSUES=()

# ─── Check 1: Sources Manifest ───
echo -e "${BOLD}1. Source Verification${NC}"
SOURCES_LOG="$SESSION_PATH/sources/manifest.jsonl"
if [ -f "$SOURCES_LOG" ] && [ -s "$SOURCES_LOG" ]; then
    TOTAL=$(wc -l < "$SOURCES_LOG")
    FETCHED=$(grep -cE '"status":"(fetched|ok)"' "$SOURCES_LOG" 2>/dev/null || echo 0)
    FAILED=$(grep -c '"status":"failed"' "$SOURCES_LOG" 2>/dev/null || echo 0)
    TOTAL_CHARS=$(grep -E '"status":"(fetched|ok)"' "$SOURCES_LOG" | grep -oE '"chars(_fetched)?"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | awk '{s+=$1}END{print s+0}')

    echo -e "  Total URLs: $TOTAL"
    echo -e "  Fetched:    ${GREEN}$FETCHED${NC}"
    echo -e "  Failed:     ${RED}$FAILED${NC}"
    echo -e "  Total chars: $TOTAL_CHARS"

    MAX_SCORE=$((MAX_SCORE + 20))
    if [ "$FETCHED" -gt 0 ]; then
        SCORE=$((SCORE + 10))
        echo -e "  ${GREEN}✓${NC} Sources were actually fetched"
    else
        ISSUES+=("No sources were successfully fetched")
    fi

    if [ "$TOTAL_CHARS" -gt 1000 ]; then
        SCORE=$((SCORE + 10))
        echo -e "  ${GREEN}✓${NC} Substantial content fetched ($TOTAL_CHARS chars)"
    else
        ISSUES+=("Very little content fetched ($TOTAL_CHARS chars)")
    fi
else
    ISSUES+=("No source manifest found — nothing was fetched")
    MAX_SCORE=$((MAX_SCORE + 20))
fi
echo ""

# ─── Check 2: Evidence Log ───
echo -e "${BOLD}2. Evidence Verification${NC}"
EVIDENCE_LOG="$SESSION_PATH/evidence/log.jsonl"
if [ -f "$EVIDENCE_LOG" ] && [ -s "$EVIDENCE_LOG" ]; then
    TOTAL_EVIDENCE=$(wc -l < "$EVIDENCE_LOG")
    FACTS=$(grep -c '"type":"fact"' "$EVIDENCE_LOG" 2>/dev/null || echo 0)
    CODE=$(grep -c '"type":"code"' "$EVIDENCE_LOG" 2>/dev/null || echo 0)
    QUOTES=$(grep -c '"type":"quote"' "$EVIDENCE_LOG" 2>/dev/null || echo 0)
    INSIGHTS=$(grep -c '"type":"insight"' "$EVIDENCE_LOG" 2>/dev/null || echo 0)

    echo -e "  Total evidence items: $TOTAL_EVIDENCE"
    echo -e "  Facts:    $FACTS"
    echo -e "  Code:     $CODE"
    echo -e "  Quotes:   $QUOTES"
    echo -e "  Insights: $INSIGHTS"

    MAX_SCORE=$((MAX_SCORE + 30))
    if [ "$TOTAL_EVIDENCE" -ge 5 ]; then
        SCORE=$((SCORE + 15))
        echo -e "  ${GREEN}✓${NC} Good amount of evidence ($TOTAL_EVIDENCE items)"
    elif [ "$TOTAL_EVIDENCE" -ge 1 ]; then
        SCORE=$((SCORE + 5))
        echo -e "  ${YELLOW}⚠${NC} Little evidence ($TOTAL_EVIDENCE items)"
    else
        ISSUES+=("Evidence log is empty")
    fi

    # Check if evidence references actual sources
    REFS_SOURCES=$(grep -o '"source":"[^"]*"' "$EVIDENCE_LOG" | sort -u | wc -l)
    if [ "$REFS_SOURCES" -ge 1 ]; then
        SCORE=$((SCORE + 10))
        echo -e "  ${GREEN}✓${NC} Evidence references $REFS_SOURCES distinct sources"
    else
        ISSUES+=("Evidence doesn't reference any sources")
    fi

    # Check for high-confidence items
    HIGH_CONF=$(grep -c '"confidence":"high"' "$EVIDENCE_LOG" 2>/dev/null || echo 0)
    if [ "$HIGH_CONF" -ge 3 ]; then
        SCORE=$((SCORE + 5))
        echo -e "  ${GREEN}✓${NC} $HIGH_CONF high-confidence items"
    fi
else
    ISSUES+=("No evidence log found — nothing was extracted")
    MAX_SCORE=$((MAX_SCORE + 30))
fi
echo ""

# ─── Check 3: Quiz Completion ───
echo -e "${BOLD}3. Knowledge Test${NC}"
QUIZ_DIR="$SESSION_PATH/quiz"
QUIZ_FILES=$(find "$QUIZ_DIR" -name "*.md" ! -name "quiz-template.md" 2>/dev/null | wc -l)
if [ "$QUIZ_FILES" -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} Quiz completed ($QUIZ_FILES files)"
    MAX_SCORE=$((MAX_SCORE + 25))
    SCORE=$((SCORE + 20))

    # Check for self-assessment
    if grep -r "Self-Assessment\|self-assessment\|ความมั่นใจ" "$QUIZ_DIR" 2>/dev/null | head -1 | grep -q .; then
        SCORE=$((SCORE + 5))
        echo -e "  ${GREEN}✓${NC} Self-assessment included"
    fi
else
    ISSUES+=("No quiz completed — knowledge not tested")
    MAX_SCORE=$((MAX_SCORE + 25))
fi
echo ""

# ─── Check 4: Report Quality ───
echo -e "${BOLD}4. Report Quality${NC}"
REPORT_FILE=$(find "$SESSION_PATH" -name "*report*" -o -name "*summary*" 2>/dev/null | head -1)
if [ -n "$REPORT_FILE" ]; then
    REPORT_SIZE=$(wc -c < "$REPORT_FILE")
    echo -e "  ${GREEN}✓${NC} Report exists: $(basename "$REPORT_FILE") ($REPORT_SIZE bytes)"

    MAX_SCORE=$((MAX_SCORE + 25))

    # Check for honest assessment sections
    if grep -qi "honest\|จริง\|superficial\|ผิวเผิน\|don't know\|ไม่รู้" "$REPORT_FILE" 2>/dev/null; then
        SCORE=$((SCORE + 10))
        echo -e "  ${GREEN}✓${NC} Contains honest self-assessment"
    else
        ISSUES+=("Report lacks honest self-assessment")
    fi

    # Check for specific evidence references
    if grep -q "sources/\|\.md\|http" "$REPORT_FILE" 2>/dev/null; then
        SCORE=$((SCORE + 10))
        echo -e "  ${GREEN}✓${NC} References specific sources"
    else
        ISSUES+=("Report doesn't reference specific sources")
    fi

    # Check for "what I don't know" section
    if grep -qi "don't know\|ไม่รู้\|needs more\|ยังไม่\|superficial" "$REPORT_FILE" 2>/dev/null; then
        SCORE=$((SCORE + 5))
        echo -e "  ${GREEN}✓${NC} Acknowledges gaps in knowledge"
    fi
else
    ISSUES+=("No report found")
    MAX_SCORE=$((MAX_SCORE + 25))
fi
echo ""

# ─── Final Score ───
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
PCT=$((SCORE * 100 / MAX_SCORE))

if [ $PCT -ge 80 ]; then
    GRADE="A"
    COLOR="$GREEN"
    VERDICT="REAL learning session ✅"
elif [ $PCT -ge 60 ]; then
    GRADE="B"
    COLOR="$YELLOW"
    VERDICT="Decent, but could be deeper ⚠️"
elif [ $PCT -ge 40 ]; then
    GRADE="C"
    COLOR="$YELLOW"
    VERDICT="Superficial — mostly theater 🎭"
else
    GRADE="F"
    COLOR="$RED"
    VERDICT="FAKE learning session ❌"
fi

echo -e "  Score: ${COLOR}${BOLD}$SCORE/$MAX_SCORE ($PCT%) — Grade: $GRADE${NC}"
echo -e "  Verdict: ${COLOR}${BOLD}$VERDICT${NC}"
echo ""

if [ ${#ISSUES[@]} -gt 0 ]; then
    echo -e "  ${RED}Issues found:${NC}"
    for issue in "${ISSUES[@]}"; do
        echo -e "    ${RED}✗${NC} $issue"
    done
    echo ""
fi

# ─── Save verification result ───
cat > "$SESSION_PATH/verification.json" << EOF
{
  "session_id": "$SESSION_ID",
  "verified_at": "$(date -Iseconds)",
  "score": $SCORE,
  "max_score": $MAX_SCORE,
  "percentage": $PCT,
  "grade": "$GRADE",
  "verdict": "$VERDICT",
  "issues": $(printf '%s\n' "${ISSUES[@]:-}" | jq -R . | jq -s .)
}
EOF

echo -e "  Verification saved: ${CYAN}$SESSION_PATH/verification.json${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
