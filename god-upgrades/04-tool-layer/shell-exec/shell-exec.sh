#!/bin/bash
# Shell Executor — sandboxed execution with logging + timeout
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="${DIR}/exec-log.jsonl"
SANDBOX="${DIR}/sandbox"
GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$SANDBOX"
[ ! -f "$LOG" ] && touch "$LOG"

execute() {
    local cmd="$1" timeout="${2:-30}" sandbox="${3:-true}"
    [ -z "$cmd" ] && echo "Usage: --exec 'command' [timeout] [sandbox:true/false]" && return 1
    
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo -e "${CYAN}⚡ Executing (timeout: ${timeout}s):${NC} ${cmd}"
    
    local output exit_code
    if [ "$sandbox" = "true" ]; then
        output=$(cd "$SANDBOX" && timeout "$timeout" bash -c "$cmd" 2>&1) && exit_code=0 || exit_code=$?
    else
        output=$(timeout "$timeout" bash -c "$cmd" 2>&1) && exit_code=0 || exit_code=$?
    fi
    
    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}✓ Exit: 0${NC}"
    else
        echo -e "${RED}✗ Exit: ${exit_code}${NC}"
    fi
    echo "$output" | head -50
    
    # Log
    echo "{\"cmd\":$(echo "$cmd" | jq -Rs .),\"exit_code\":${exit_code},\"output\":$(echo "$output" | head -20 | jq -Rs .),\"sandbox\":${sandbox},\"timestamp\":\"${ts}\"}" >> "$LOG"
    
    return $exit_code
}

safe_eval() {
    local code="$1"
    echo -e "${CYAN}Safe eval:${NC}"
    # Write to temp file, execute, cleanup
    local tmp="${SANDBOX}/eval_$$.sh"
    echo "$code" > "$tmp"
    chmod +x "$tmp"
    timeout 30 bash "$tmp" 2>&1 | head -50
    local rc=$?
    rm -f "$tmp"
    return $rc
}

history() {
    echo -e "${CYAN}Execution History (last 10):${NC}\n"
    tail -10 "$LOG" | jq -r '"  [\(.timestamp)] exit:\(.exit_code) → \(.cmd | .[:80])"' 2>/dev/null
}

case "${1:-}" in
    --exec) execute "$2" "$3" "$4" ;;
    --eval) safe_eval "$2" ;;
    --history) history ;;
    --sandbox-ls) ls "$SANDBOX" 2>/dev/null || echo "(empty)";;
    *) echo "Usage: shell-exec.sh [--exec|--eval|--history|--sandbox-ls]" ;;
esac
