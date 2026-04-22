#!/bin/bash
# A/B Test Framework — ทดสอบ 2 approach แล้วเทียบผล
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; TESTS="${DIR}/ab-tests.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$TESTS" ] && touch "$TESTS"

create_test() { local name="$1" a="$2" b="$3"; [ -z "$name" ] && return 1; echo "{\"name\":\"${name}\",\"variant_a\":$(echo "$a"|jq -Rs .),\"variant_b\":$(echo "$b"|jq -Rs .),\"result_a\":null,\"result_b\":null,\"winner\":null,\"status\":\"pending\",\"created\":\"$(date +%Y-%m-%d)\"}" >> "$TESTS"; echo -e "${GREEN}✓ A/B Test:${NC} $name"; }
record_result() { local name="$1" variant="$2" result="$3"; local tmp=$(mktemp); while read line; do echo "$line" | grep -q "$name" && echo "$line" | jq --arg v "$variant" --arg r "$result" "if .name == \"$name\" then if \$v == \"a\" then .result_a = \$r else .result_b = \$r end else . end" || echo "$line"; done < "$TESTS" > "$tmp" && mv "$tmp" "$TESTS"; echo -e "${GREEN}✓ Recorded:${NC} $name variant $variant → $result"; }
list_tests() { echo -e "${CYAN}A/B Tests:${NC}\n"; jq -r '"  \(.status | if . == "pending" then "⏳" elif . == "completed" then "✅" else "🔄" end) \(.name): A=\(.result_a // "?") vs B=\(.result_b // "?")"' "$TESTS" 2>/dev/null; }
case "${1:-}" in --create) create_test "$2" "$3" "$4";; --result) record_result "$2" "$3" "$4";; --list) list_tests;; *) echo "Usage: ab-test.sh [--create|--result|--list]";; esac
