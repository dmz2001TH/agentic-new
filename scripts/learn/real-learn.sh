#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# real-learn.sh — REAL Timed Learning System
# No theater. No fake timelines. Actual work with proof.
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PSI_DIR="$PROJECT_ROOT/ψ"
SESSION_DIR="$PSI_DIR/memory/learn-sessions"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Args ───
TOPIC="${1:?Usage: real-learn.sh <topic> [duration_minutes] [urls...]}"
DURATION_MIN="${2:-10}"
shift 2 2>/dev/null || shift $# 2>/dev/null
URLS=("$@")

# ─── Session Setup ───
SESSION_ID="$(date +%Y-%m-%d_%H-%M)_${TOPIC// /-}"
SESSION_PATH="$SESSION_DIR/$SESSION_ID"
mkdir -p "$SESSION_PATH/sources" "$SESSION_PATH/evidence" "$SESSION_PATH/quiz"

START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION_MIN * 60))

# ─── Session Manifest ───
cat > "$SESSION_PATH/manifest.json" << EOF
{
  "session_id": "$SESSION_ID",
  "topic": "$TOPIC",
  "started_at": "$(date -Iseconds)",
  "duration_minutes": $DURATION_MIN,
  "deadline": "$(date -d @$END_TIME -Iseconds 2>/dev/null || date -r $END_TIME -Iseconds 2>/dev/null || echo $END_TIME)",
  "urls_to_study": $(printf '%s\n' "${URLS[@]}" | jq -R . | jq -s .),
  "status": "in_progress"
}
EOF

echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}  🧠 REAL LEARNING SESSION${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "  Topic:    ${BOLD}$TOPIC${NC}"
echo -e "  Duration: ${BOLD}${DURATION_MIN} minutes${NC}"
echo -e "  Deadline: ${BOLD}$(date -d @$END_TIME '+%H:%M:%S' 2>/dev/null || date -r $END_TIME '+%H:%M:%S' 2>/dev/null || echo "$END_TIME")${NC}"
echo -e "  Session:  ${CYAN}$SESSION_ID${NC}"
echo -e "  Sources:  ${BOLD}${#URLS[@]} URLs${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

# ─── Timer Display (runs in background) ───
TIMER_PID_FILE="$SESSION_PATH/.timer_pid"

start_timer() {
    while true; do
        NOW=$(date +%s)
        REMAINING=$((END_TIME - NOW))
        if [ $REMAINING -le 0 ]; then
            echo -e "\r${RED}${BOLD}  ⏰ TIME'S UP!${NC}                    "
            break
        fi
        MINS=$((REMAINING / 60))
        SECS=$((REMAINING % 60))
        if [ $REMAINING -le 60 ]; then
            COLOR="$RED"
        elif [ $REMAINING -le 180 ]; then
            COLOR="$YELLOW"
        else
            COLOR="$GREEN"
        fi
        printf "\r  ${COLOR}⏱  %02d:%02d remaining${NC}  " $MINS $SECS
        sleep 1
    done
}

start_timer &
echo $! > "$TIMER_PID_FILE"
TIMER_PID=$(cat "$TIMER_PID_FILE")

# ─── Cleanup on exit ───
cleanup() {
    kill $TIMER_PID 2>/dev/null || true
    rm -f "$TIMER_PID_FILE"
}
trap cleanup EXIT

# ─── Source Tracking ───
SOURCES_LOG="$SESSION_PATH/sources/manifest.jsonl"
EVIDENCE_LOG="$SESSION_PATH/evidence/log.jsonl"
touch "$SOURCES_LOG" "$EVIDENCE_LOG"

log_source() {
    local url="$1"
    local status="$2"
    local chars="${3:-0}"
    local timestamp=$(date -Iseconds)
    echo "{\"url\":\"$url\",\"status\":\"$status\",\"chars_fetched\":$chars,\"timestamp\":\"$timestamp\"}" >> "$SOURCES_LOG"
    echo -e "  ${GREEN}✓${NC} Fetched: $url ($chars chars)"
}

log_evidence() {
    local source="$1"
    local type="$2"  # quote, code, fact, insight
    local content="$3"
    local timestamp=$(date -Iseconds)
    # Escape content for JSON
    local escaped=$(echo "$content" | jq -Rs .)
    echo "{\"source\":\"$source\",\"type\":\"$type\",\"content\":$escaped,\"timestamp\":\"$timestamp\"}" >> "$EVIDENCE_LOG"
}

# ─── Fetch Sources ───
echo -e "${BOLD}📡 Phase 1: Fetching Sources${NC}"
echo ""

TOTAL_CHARS=0
SOURCES_FETCHED=0

for url in "${URLS[@]}"; do
    NOW=$(date +%s)
    if [ $NOW -ge $END_TIME ]; then
        echo -e "  ${RED}⏰ Time's up — stopping source fetch${NC}"
        break
    fi

    # Fetch and save raw content
    SAFE_NAME=$(echo "$url" | sed 's/[^a-zA-Z0-9]/_/g' | head -c 80)
    OUTPUT_FILE="$SESSION_PATH/sources/${SAFE_NAME}.md"

    if curl -sL --max-time 15 "$url" -o "$OUTPUT_FILE.raw" 2>/dev/null; then
        # Convert to readable text (strip HTML if needed)
        if command -v pandoc &>/dev/null; then
            pandoc -f html -t markdown "$OUTPUT_FILE.raw" -o "$OUTPUT_FILE" 2>/dev/null || cp "$OUTPUT_FILE.raw" "$OUTPUT_FILE"
        else
            # Basic HTML strip
            sed 's/<[^>]*>//g; s/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&nbsp;/ /g' "$OUTPUT_FILE.raw" > "$OUTPUT_FILE" 2>/dev/null || cp "$OUTPUT_FILE.raw" "$OUTPUT_FILE"
        fi

        CHARS=$(wc -c < "$OUTPUT_FILE")
        TOTAL_CHARS=$((TOTAL_CHARS + CHARS))
        SOURCES_FETCHED=$((SOURCES_FETCHED + 1))
        log_source "$url" "fetched" "$CHARS"
    else
        log_source "$url" "failed" 0
        echo -e "  ${RED}✗${NC} Failed: $url"
    fi
done

echo ""
echo -e "  📊 Fetched: ${BOLD}$SOURCES_FETCHED${NC}/${#URLS[@]} sources, ${BOLD}$TOTAL_CHARS${NC} chars total"
echo ""

# ─── Phase 2: Extract Evidence ───
echo -e "${BOLD}📝 Phase 2: Extracting Evidence${NC}"
echo ""

# Save extraction instructions for the agent
cat > "$SESSION_PATH/extraction-prompt.md" << 'PROMPT'
# Extraction Instructions

For each source in sources/, extract:

1. **Key Facts** (type: fact) — verifiable claims with evidence
2. **Code Snippets** (type: code) — actual code examples that work
3. **Direct Quotes** (type: quote) — important passages word-for-word
4. **Insights** (type: insight) — your analysis connecting multiple sources

## Rules:
- Every extraction MUST reference the source file
- Code must be complete enough to verify (not fragments)
- Facts must be verifiable (include where to check)
- No paraphrasing as "summary" — extract actual content
- Rate your confidence: high/medium/low for each item

## Output format for evidence/log.jsonl:
Each line: {"source":"filename","type":"fact|code|quote|insight","content":"...","confidence":"high|medium|low"}
PROMPT

echo -e "  Evidence extraction prompt saved."
echo -e "  ${CYAN}→ Agent must extract real evidence, not summaries${NC}"
echo ""

# ─── Phase 3: Knowledge Test ───
echo -e "${BOLD}🧪 Phase 3: Knowledge Verification${NC}"
echo ""

# Generate quiz template
cat > "$SESSION_PATH/quiz/quiz-template.md" << QUIZ
# Knowledge Test: $TOPIC

## Instructions
Answer each question using ONLY what you learned from the sources.
Reference specific source files for each answer.
If you can't answer, say "I don't know" — don't make things up.

## Questions

### Factual Recall (from sources)
1. [Generate 3-5 factual questions based on the sources]

### Code Application
2. [Generate 2-3 questions requiring code examples from sources]

### Synthesis
3. [Generate 1-2 questions requiring connecting multiple sources]

## Self-Assessment

After answering:
- How many questions could you answer with evidence? ___/10
- What was the most surprising thing you learned?
- What would you study next to deepen understanding?
- Confidence level in this learning session: high/medium/low

QUIZ

echo -e "  Quiz template saved."
echo ""

# ─── Phase 4: Deadline Report ───
echo -e "${BOLD}📋 Phase 4: Report Structure${NC}"
echo ""

cat > "$SESSION_PATH/report-template.md" << REPORT
# Learning Report: $TOPIC
Session: $SESSION_ID
Duration: ${DURATION_MIN} minutes

## 1. Sources Actually Read
| # | URL | Status | Chars | Key Finding |
|---|-----|--------|-------|-------------|
$(for url in "${URLS[@]}"; do echo "| - | $url | pending | - | - |"; done)

## 2. Evidence Collected
- [ ] Facts verified: ___
- [ ] Code snippets extracted: ___
- [ ] Direct quotes: ___
- [ ] Cross-source insights: ___

## 3. Knowledge Test Results
- Questions answered correctly: ___/10
- Sources referenced in answers: ___
- Confidence: ___

## 4. What Actually Changed
- New concepts understood:
- New skills acquired:
- Connections to existing knowledge:

## 5. Honest Assessment
- What went well:
- What was superficial:
- What needs more time:
- Next steps:

## 6. Self-Improvement
- Did the learning method work?
- What would I do differently?
- Time management assessment:
REPORT

echo -e "  Report template saved."
echo ""

# ─── Wait for deadline or user signal ───
echo -e "${YELLOW}${BOLD}⏳ Learning in progress...${NC}"
echo -e "  Work in: ${CYAN}$SESSION_PATH${NC}"
echo -e "  When done, run: ${BOLD}bash scripts/learn/learn-verify.sh $SESSION_ID${NC}"
echo ""

# ─── Summary of what's different ───
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✅ REAL Learning System Active${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}vs Fake Learning:${NC}"
echo -e "  ✗ Before: 'สรุปว่าเรียนรู้แล้ว' (no proof)"
echo -e "  ✓ Now: Every source tracked, evidence required"
echo ""
echo -e "  ${GREEN}What's enforced:${NC}"
echo -e "  1. Source manifest (what was actually fetched)"
echo -e "  2. Evidence log (quotes, code, facts extracted)"
echo -e "  3. Knowledge quiz (can you answer questions?)"
echo -e "  4. Honest assessment (what was superficial)"
echo -e "  5. Timer (real deadline, not fake timeline)"
echo ""
