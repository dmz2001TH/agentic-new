#!/bin/bash
# Capability Tracker — track ว่า GOD ทำสิ่งไหนได้/ไม่ได้
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; CAPS="${DIR}/capabilities.json"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$CAPS" ] && echo '{"capabilities":[]}' > "$CAPS"

add() { local name="$1" level="${2:-learning}" desc="${3:-}"; local tmp=$(mktemp); jq --arg n "$name" --arg l "$level" --arg d "$desc" '.capabilities += [{"name":$n,"level":$l,"desc":$d,"added":"'"$(date +%Y-%m-%d)"'","tests":0,"successes":0}]' "$CAPS" > "$tmp" && mv "$tmp" "$CAPS"; echo -e "${GREEN}✓ Added:${NC} $name [$level]"; }
test_cap() { local name="$1" result="${2:-success}"; local tmp=$(mktemp); jq --arg n "$name" --arg r "$result" '.capabilities = [.capabilities[] | if .name == $n then .tests += 1 | if $r == "success" then .successes += 1 | .level = "proficient" else . end else . end]' "$CAPS" > "$tmp" && mv "$tmp" "$CAPS"; echo -e "${GREEN}✓ Tested:${NC} $name → $result"; }
report() { echo -e "${CYAN}═══════════════════════════════════════${NC}"; echo -e "${CYAN}  📊 Capability Report${NC}"; echo -e "${CYAN}═══════════════════════════════════════${NC}"; jq -r '.capabilities | group_by(.level) | .[] | "  [" + .[0].level + "]\n" + (map("    \(.name) — \(.successes)/\(.tests) success rate") | join("\n"))' "$CAPS" 2>/dev/null || echo "  (empty)"; }
case "${1:-}" in --add) add "$2" "$3" "$4";; --test) test_cap "$2" "$3";; --report) report;; *) echo "Usage: capability-tracker.sh [--add|--test|--report]";; esac
