#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# test-autonomous.sh — ตรวจสอบว่า Autonomous Mode พร้อมใช้งาน
# ═══════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

pass() { echo -e "  ${GREEN}✓ PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "  ${RED}✗ FAIL${NC}: $1"; FAIL=$((FAIL+1)); }
warn() { echo -e "  ${YELLOW}⚠ WARN${NC}: $1"; WARN=$((WARN+1)); }

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🧪 Autonomous Mode Verification — Full Audit${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════════════════
# TEST 1: settings.json — yolo mode
# ═══════════════════════════════════════════════════════════
echo -e "${YELLOW}[1/10] settings.json — defaultApprovalMode${NC}"
SETTINGS=".gemini/settings.json"
if [ -f "$SETTINGS" ]; then
  MODE=$(node -e "const s=JSON.parse(require('fs').readFileSync('$SETTINGS','utf8'));console.log(s.general?.defaultApprovalMode||'NOT_SET')" 2>/dev/null || echo "PARSE_ERROR")
  if [ "$MODE" = "yolo" ]; then
    pass "defaultApprovalMode = yolo"
  elif [ "$MODE" = "auto_edit" ]; then
    fail "defaultApprovalMode = auto_edit (ยังถาม permission!)"
  else
    fail "defaultApprovalMode = $MODE"
  fi
else
  fail "settings.json not found"
fi

# ═══════════════════════════════════════════════════════════
# TEST 2: GEMINI.md — ไม่มี Red Lines "ขอก่อน"
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[2/10] GEMINI.md — Red Lines removed${NC}"
if [ -f "GEMINI.md" ]; then
  if grep -q "ต้องขอก่อนเสมอ" GEMINI.md; then
    fail "GEMINI.md ยังมี 'ต้องขอก่อนเสมอ'"
  else
    pass "ไม่มี 'ต้องขอก่อนเสมอ'"
  fi

  if grep -q "Autonomous Actions.*ทำได้เลย" GEMINI.md; then
    pass "มี Autonomous Actions section"
  elif grep -q "ทำได้เลย.*log" GEMINI.md; then
    pass "มี 'ทำได้เลย + log' pattern"
  else
    warn "ไม่พบ Autonomous Actions section"
  fi
else
  fail "GEMINI.md not found"
fi

# ═══════════════════════════════════════════════════════════
# TEST 3: GEMINI.md — ไม่มี Risk Gate
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[3/10] GEMINI.md — Risk Gate removed${NC}"
if [ -f "GEMINI.md" ]; then
  if grep -q "Risk Gate" GEMINI.md; then
    fail "GEMINI.md ยังมี Risk Gate"
  else
    pass "ไม่มี Risk Gate"
  fi
fi

# ═══════════════════════════════════════════════════════════
# TEST 4: GEMINI.md — Safety Rules ไม่บังคับ confirm
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[4/10] GEMINI.md — Safety Rules autonomous${NC}"
if [ -f "GEMINI.md" ]; then
  if grep -q "ห้ามทำลายโดยไม่ confirm" GEMINI.md; then
    fail "ยังมี 'ห้ามทำลายโดยไม่ confirm'"
  elif grep -q "แสดงสิ่งที่จะเปลี่ยนก่อนทำ" GEMINI.md; then
    fail "ยังมี 'แสดงสิ่งที่จะเปลี่ยนก่อนทำ'"
  else
    pass "Safety Rules ไม่บังคับ confirm"
  fi
fi

# ═══════════════════════════════════════════════════════════
# TEST 5: god.md — ไม่มี "⚠️ ต้อง confirm ก่อน"
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[5/10] god.md — confirm blocks removed${NC}"
if [ -f ".gemini/agents/god.md" ]; then
  if grep -q "ต้อง confirm ก่อน" .gemini/agents/god.md; then
    fail "god.md ยังมี 'ต้อง confirm ก่อน'"
  else
    pass "god.md ไม่มี confirm blocks"
  fi

  if grep -q "Autonomous Mode" .gemini/agents/god.md; then
    pass "god.md มี Autonomous Mode"
  else
    warn "god.md ไม่มี Autonomous Mode label"
  fi
else
  fail "god.md not found"
fi

# ═══════════════════════════════════════════════════════════
# TEST 6: builder.md — ไม่มี "⚠️ ต้องบอก GOD ก่อน"
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[6/10] builder.md — confirm blocks removed${NC}"
if [ -f ".gemini/agents/builder.md" ]; then
  if grep -q "ต้องบอก GOD ก่อน" .gemini/agents/builder.md; then
    fail "builder.md ยังมี 'ต้องบอก GOD ก่อน'"
  else
    pass "builder.md ไม่มี confirm blocks"
  fi

  if grep -q "Autonomous Mode" .gemini/agents/builder.md; then
    pass "builder.md มี Autonomous Mode"
  else
    warn "builder.md ไม่มี Autonomous Mode label"
  fi
else
  fail "builder.md not found"
fi

# ═══════════════════════════════════════════════════════════
# TEST 7: start-god-with-memory.cmd — ไม่มี --prompt flag
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[7/10] start-god-with-memory.cmd — no --prompt flag${NC}"
if [ -f "start-god-with-memory.cmd" ]; then
  if grep -q "\-\-prompt" start-god-with-memory.cmd; then
    fail "ยังใช้ --prompt flag (ไม่รองรับใน Gemini CLI)"
  else
    pass "ไม่มี --prompt flag"
  fi

  if grep -q "paste-buffer\|load-buffer" start-god-with-memory.cmd; then
    pass "ใช้ tmux buffer injection (reliable)"
  else
    warn "ไม่พบ buffer injection method"
  fi
else
  fail "start-god-with-memory.cmd not found"
fi

# ═══════════════════════════════════════════════════════════
# TEST 8: start-god-with-memory.sh — Autonomous prompt
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[8/10] start-god-with-memory.sh — autonomous prompt${NC}"
if [ -f "start-god-with-memory.sh" ]; then
  if grep -q "AUTONOMOUS MODE\|ทำงานอิสระ\|ไม่ต้องถาม" start-god-with-memory.sh; then
    pass "มี autonomous rules ใน prompt"
  else
    fail "ไม่มี autonomous rules ใน prompt"
  fi

  if grep -q "gemini.*--yolo" start-god-with-memory.sh; then
    pass "ใช้ gemini --yolo"
  else
    fail "ไม่ได้ใช้ gemini --yolo"
  fi
else
  fail "start-god-with-memory.sh not found"
fi

# ═══════════════════════════════════════════════════════════
# TEST 9: SELF-FIX-PROMPT.md — ไม่มี confirm
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[9/10] SELF-FIX-PROMPT.md — no confirm blocks${NC}"
if [ -f "SELF-FIX-PROMPT.md" ]; then
  if grep -q "ยังต้อง confirm" SELF-FIX-PROMPT.md; then
    fail "ยังมี 'ยังต้อง confirm'"
  else
    pass "ไม่มี confirm blocks"
  fi
else
  fail "SELF-FIX-PROMPT.md not found"
fi

# ═══════════════════════════════════════════════════════════
# TEST 10: HANDOFF-PROMPT-SHORT.md — P0 auto-fail-safe
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[10/10] HANDOFF-PROMPT-SHORT.md — P0 fail-safe${NC}"
if [ -f "HANDOFF-PROMPT-SHORT.md" ]; then
  if grep -q "ถ้า fail.*log.*ข้าม\|fail.*ไม่หยุด" HANDOFF-PROMPT-SHORT.md; then
    pass "P0 มี fail-safe (ไม่หยุดเมื่อ fail)"
  else
    warn "P0 ไม่มี explicit fail-safe"
  fi
else
  fail "HANDOFF-PROMPT-SHORT.md not found"
fi

# ═══════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
TOTAL=$((PASS+FAIL+WARN))
echo -e "  Results: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / ${YELLOW}$WARN warnings${NC} ($TOTAL total)"
echo ""

if [ $FAIL -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}✅ AUTONOMOUS MODE READY${NC}"
  echo -e "  GOD can work independently without human intervention."
  echo -e "  No permission prompts. No confirm blocks. Full autonomy."
elif [ $FAIL -le 2 ]; then
  echo -e "  ${YELLOW}${BOLD}⚡ MOSTLY READY — $FAIL issue(s) remaining${NC}"
  echo -e "  Fix the failures above for full autonomy."
else
  echo -e "  ${RED}${BOLD}❌ NOT READY — $FAIL issues found${NC}"
  echo -e "  GOD will still ask for permission until these are fixed."
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
exit $FAIL
