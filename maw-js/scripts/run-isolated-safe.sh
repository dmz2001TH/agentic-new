#!/bin/bash
# Run isolated tests: conflicting files in separate processes, rest together.
# Bun's mock.module is process-global, so files that mock the same modules
# (especially config/ssh/peers) must run in separate Bun processes.
set -uo pipefail
export PATH="$HOME/.bun/bin:$PATH"

cd "$(dirname "$0")/.."

PASS=0 FAIL=0 TOTAL=0
FAILED=""

run_file() {
  local result rc=0
  result=$(bun test "$1" 2>&1) || rc=$?
  local p f t
  p=$(echo "$result" | grep -oP '^\s*\K\d+(?= pass$)') || p=0
  f=$(echo "$result" | grep -oP '^\s*\K\d+(?= fail$)') || f=0
  t=$(echo "$result" | grep -oP 'Ran \K\d+') || t=0
  [ -z "$p" ] && p=0; [ -z "$f" ] && f=0; [ -z "$t" ] && t=0
  PASS=$((PASS + p))
  FAIL=$((FAIL + f))
  TOTAL=$((TOTAL + t))
  if [ "$f" -gt 0 ] || [ "$rc" -ne 0 ]; then
    FAILED="$FAILED $1"
    echo "FAIL: $1 ($f failures)"
  else
    echo "OK:   $1 ($p pass)"
  fi
}

# Files that mock config/ssh/peers — must run separately to avoid
# Bun mock.module pollution (process-global, no real restore).
CONFLICT_FILES=(
  test/isolated/engine.test.ts
  test/isolated/peers.test.ts
  test/isolated/peers-send.test.ts
  test/isolated/peers-reachable.test.ts
  test/isolated/bud-init.test.ts
  test/isolated/bud-repo.test.ts
  test/isolated/bud-wake.test.ts
  src/commands/plugins/oracle/oracle.test.ts
)

echo "=== Running ${#CONFLICT_FILES[@]} conflict files individually ==="
for f in "${CONFLICT_FILES[@]}"; do
  [ -f "$f" ] && run_file "$f"
done

# Collect remaining files (only from test/isolated/)
REMAINING=()
for f in test/isolated/*.test.ts; do
  skip=false
  for cf in "${CONFLICT_FILES[@]}"; do
    [ "$f" = "$cf" ] && skip=true && break
  done
  $skip || REMAINING+=("$f")
done

if [ ${#REMAINING[@]} -gt 0 ]; then
  echo ""
  echo "=== Running ${#REMAINING[@]} non-conflicting files together ==="
  result=$(bun test "${REMAINING[@]}" 2>&1) || true
  p=$(echo "$result" | grep -oP '^\s*\K\d+(?= pass$)') || p=0
  f=$(echo "$result" | grep -oP '^\s*\K\d+(?= fail$)') || f=0
  t=$(echo "$result" | grep -oP 'Ran \K\d+') || t=0
  [ -z "$p" ] && p=0; [ -z "$f" ] && f=0; [ -z "$t" ] && t=0
  PASS=$((PASS + p))
  FAIL=$((FAIL + f))
  TOTAL=$((TOTAL + t))
  if [ "$f" -gt 0 ]; then
    FAILED="$FAILED (group)"
    echo "GROUP FAIL: $f failures"
  else
    echo "GROUP OK: $p pass"
  fi
fi

echo ""
echo "=== TOTAL: ${PASS} pass, ${FAIL} fail, ${TOTAL} tests ==="
if [ -n "$FAILED" ]; then
  echo "Failed:$FAILED"
  exit 1
fi
exit 0
