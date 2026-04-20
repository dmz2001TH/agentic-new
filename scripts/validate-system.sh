#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# validate-system.sh — Check if the agentic system is wired correctly
# Usage: bash scripts/validate-system.sh
# ═══════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
WARN=0

pass() { echo "  ✅ $1"; PASS=$((PASS+1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ⚠️  $1"; WARN=$((WARN+1)); }

echo "🔮 Oracle v3 System Validation"
echo "================================"
echo ""

# --- Scripts ---
echo "📜 Scripts:"
[ -f "$PROJECT_ROOT/scripts/oracle-tools.sh" ] && pass "oracle-tools.sh exists" || fail "oracle-tools.sh MISSING"
[ -x "$PROJECT_ROOT/scripts/oracle-tools.sh" ] && pass "oracle-tools.sh executable" || warn "oracle-tools.sh not executable (chmod +x)"
[ -f "$PROJECT_ROOT/scripts/ensure-agents.sh" ] && pass "ensure-agents.sh exists" || fail "ensure-agents.sh MISSING"
echo ""

# --- Agent Contexts ---
echo "🤖 Agent Contexts:"
[ -f "$PROJECT_ROOT/.gemini/agents/god.md" ] && pass "god.md exists" || fail "god.md MISSING"
[ -f "$PROJECT_ROOT/.gemini/agents/builder.md" ] && pass "builder.md exists" || fail "builder.md MISSING"
[ -f "$PROJECT_ROOT/.gemini/agents/researcher.md" ] && pass "researcher.md exists" || warn "researcher.md MISSING"
[ -f "$PROJECT_ROOT/.gemini/launch-agent.sh" ] && pass "launch-agent.sh exists" || fail "launch-agent.sh MISSING"
[ -f "$PROJECT_ROOT/.gemini/settings.json" ] && pass "settings.json exists" || fail "settings.json MISSING"
echo ""

# --- Memory System ---
echo "🧠 Memory System:"
[ -f "$PROJECT_ROOT/ψ/memory/identity.md" ] && pass "ψ/memory/identity.md" || fail "identity.md MISSING"
[ -f "$PROJECT_ROOT/ψ/memory/goals.md" ] && pass "ψ/memory/goals.md" || fail "goals.md MISSING"
[ -f "$PROJECT_ROOT/ψ/memory/people.md" ] && pass "ψ/memory/people.md" || fail "people.md MISSING"
[ -f "$PROJECT_ROOT/ψ/memory/patterns.md" ] && pass "ψ/memory/patterns.md" || fail "patterns.md MISSING"
[ -f "$PROJECT_ROOT/ψ/memory/decisions.md" ] && pass "ψ/memory/decisions.md" || fail "decisions.md MISSING"
[ -f "$PROJECT_ROOT/ψ/memory/handoff.md" ] && pass "ψ/memory/handoff.md" || fail "handoff.md MISSING"
[ -d "$PROJECT_ROOT/ψ/memory/locks" ] && pass "ψ/memory/locks/ directory" || fail "locks/ MISSING"
[ -d "$PROJECT_ROOT/ψ/memory/reflections" ] && pass "ψ/memory/reflections/ directory" || fail "reflections/ MISSING"
echo ""

# --- Agent Memory ---
echo "🧠 Agent Memory:"
[ -f "$PROJECT_ROOT/ψ/agents/god/memory/identity.md" ] && pass "god memory" || fail "god memory MISSING"
[ -f "$PROJECT_ROOT/ψ/agents/builder/memory/identity.md" ] && pass "builder memory" || fail "builder memory MISSING"
[ -d "$PROJECT_ROOT/ψ/agents/researcher/memory" ] && pass "researcher memory dir" || warn "researcher memory dir MISSING"
echo ""

# --- Start Scripts ---
echo "🚀 Start Scripts:"
[ -f "$PROJECT_ROOT/start-oracle.cmd" ] && pass "start-oracle.cmd" || fail "start-oracle.cmd MISSING"
[ -f "$PROJECT_ROOT/start-god.cmd" ] && pass "start-god.cmd" || fail "start-god.cmd MISSING"
[ -f "$PROJECT_ROOT/start-builder.cmd" ] && pass "start-builder.cmd" || fail "start-builder.cmd MISSING"
echo ""

# --- Key Source Files ---
echo "📦 Source Files:"
[ -f "$PROJECT_ROOT/maw-js/server.ts" ] && pass "maw-js/server.ts" || fail "maw-js/server.ts MISSING"
[ -f "$PROJECT_ROOT/maw-js/.env.json" ] && pass "maw-js/.env.json" || fail ".env.json MISSING"
[ -f "$PROJECT_ROOT/maw-js/src/api/deprecated.ts" ] && pass "deprecated.ts proxy" || fail "deprecated.ts MISSING"
[ -f "$PROJECT_ROOT/maw-js/src/api/asks.ts" ] && pass "asks.ts (inter-agent)" || fail "asks.ts MISSING"
[ -f "$PROJECT_ROOT/arra-oracle-v3/src/server.ts" ] && pass "oracle server.ts" || fail "oracle server.ts MISSING"
echo ""

# --- Tool Integration Check ---
echo "🔧 Tool Integration (god.md):"
if grep -q "oracle-tools.sh" "$PROJECT_ROOT/.gemini/agents/god.md" 2>/dev/null; then
  pass "god.md references oracle-tools.sh"
else
  fail "god.md does NOT reference oracle-tools.sh"
fi
if grep -q "oracle_learn" "$PROJECT_ROOT/.gemini/agents/god.md" 2>/dev/null; then
  pass "god.md has oracle_learn instructions"
else
  fail "god.md missing oracle_learn instructions"
fi
if grep -q "WORK CYCLE" "$PROJECT_ROOT/.gemini/agents/god.md" 2>/dev/null; then
  pass "god.md has WORK CYCLE section"
else
  fail "god.md missing WORK CYCLE section"
fi
if grep -q "AUTONOMOUS MODE" "$PROJECT_ROOT/.gemini/agents/god.md" 2>/dev/null; then
  pass "god.md has AUTONOMOUS MODE section"
else
  fail "god.md missing AUTONOMOUS MODE section"
fi
echo ""

# --- Summary ---
echo "================================"
echo "📊 Results: ✅ $PASS passed | ❌ $FAIL failed | ⚠️ $WARN warnings"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "🎉 System is ready!"
  echo ""
  echo "Next steps:"
  echo "  1. bun install (in maw-js/ and arra-oracle-v3/)"
  echo "  2. ./start-oracle.cmd (or start services individually)"
  echo "  3. tmux new-session -s god 'gemini --yolo'"
  echo "  4. Open http://localhost:5173"
else
  echo "⚠️ $FAIL issue(s) need fixing before the system is ready."
fi

exit "$FAIL"
