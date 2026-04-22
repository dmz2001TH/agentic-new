#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Self-Eval Suite — วัดผล improvement ทุกครั้ง
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash self-eval.sh "task_name" "before_state" "after_state" "result"
#   bash self-eval.sh --run-all
#   bash self-eval.sh --report
#   bash self-eval.sh --add-test 'name' 'input' 'expected' 'category'

set -e
EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_FILE="${EVAL_DIR}/results.jsonl"
TESTS_FILE="${EVAL_DIR}/test-cases.json"
REPORT_FILE="${EVAL_DIR}/report.md"
LOG_FILE="${EVAL_DIR}/../improvement-log/log.jsonl"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$EVAL_DIR" "$(dirname "$LOG_FILE")"
[ ! -f "$RESULTS_FILE" ] && echo "" > "$RESULTS_FILE"
[ ! -f "$TESTS_FILE" ] && echo '{"tests":[]}' > "$TESTS_FILE"

record_result() {
    local task="$1" before="$2" after="$3" result="$4"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "{\"task\":\"${task}\",\"before\":\"${before}\",\"after\":\"${after}\",\"result\":\"${result}\",\"timestamp\":\"${ts}\"}" >> "$RESULTS_FILE"
    # Also log to improvement log
    echo "{\"event\":\"eval\",\"task\":\"${task}\",\"result\":\"${result}\",\"timestamp\":\"${ts}\"}" >> "$LOG_FILE" 2>/dev/null || true
    echo -e "${GREEN}✓ Recorded:${NC} $task → $result"
}

add_test_case() {
    local name="$1" input="$2" expected="$3" category="${4:-general}"
    [ -z "$name" ] && echo "Usage: --add-test 'name' 'input' 'expected' 'category'" && return 1
    local tmp=$(mktemp)
    jq --arg n "$name" --arg i "$input" --arg e "$expected" --arg c "$category" \
       '.tests += [{"name":$n,"input":$i,"expected":$e,"category":$c,"added":"'"$(date +%Y-%m-%d)"'"}]' \
       "$TESTS_FILE" > "$tmp" && mv "$tmp" "$TESTS_FILE"
    echo -e "${GREEN}✓ Test added:${NC} $name"
}

run_all_tests() {
    local total=$(jq '.tests | length' "$TESTS_FILE")
    local passed=0 failed=0 skipped=0
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  🧪 Running ${total} tests${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    for i in $(seq 0 $((total - 1))); do
        local name=$(jq -r ".tests[$i].name" "$TESTS_FILE")
        local input=$(jq -r ".tests[$i].input" "$TESTS_FILE")
        local expected=$(jq -r ".tests[$i].expected" "$TESTS_FILE")
        echo -ne "  [$((i+1))] ${name}... "
        if [[ "$input" == ./* ]] || [[ "$input" == /* ]]; then
            if [ -e "$input" ]; then
                echo -e "${GREEN}PASS${NC}"; passed=$((passed+1))
            else
                echo -e "${YELLOW}SKIP${NC} (not found)"; skipped=$((skipped+1))
            fi
        elif command -v "$input" &>/dev/null; then
            echo -e "${GREEN}PASS${NC}"; passed=$((passed+1))
        elif [ -d "$input" ]; then
            echo -e "${GREEN}PASS${NC}"; passed=$((passed+1))
        else
            echo -e "${YELLOW}CHECK${NC} (manual)"; skipped=$((skipped+1))
        fi
    done
    echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
    echo -e "  ${GREEN}✓${passed}  ${RED}✗${failed}  ${YELLOW}⊘${skipped}${NC}  Score: $([ "${total:-0}" -gt 0 ] && echo $((passed * 100 / total)) || echo 0)%"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    record_result "test-run" "0" "${passed}/${total}" "passed=${passed} failed=${failed}"
}

generate_report() {
    cat > "$REPORT_FILE" << EOF
# Self-Eval Report
Generated: $(date '+%Y-%m-%d %H:%M')
## Results (last 10)
$(tail -10 "$RESULTS_FILE" 2>/dev/null | while read l; do echo "- \`${l}\`"; done)
## Test Cases ($(jq '.tests | length' "$TESTS_FILE"))
$(jq -r '.tests[] | "- **\(.name)** [\(.category)]"' "$TESTS_FILE" 2>/dev/null)
EOF
    echo -e "${GREEN}✓ Report:${NC} $REPORT_FILE"
}

case "${1:-}" in
    --run-all) run_all_tests ;;
    --report) generate_report ;;
    --add-test) add_test_case "$2" "$3" "$4" "$5" ;;
    --record) record_result "$2" "$3" "$4" "$5" ;;
    *) [ -n "$1" ] && record_result "$1" "$2" "$3" "$4" || echo "Usage: self-eval.sh [task| --run-all| --report| --add-test]" ;;
esac
