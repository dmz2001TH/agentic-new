#!/bin/bash
# Rollback System — git stash + auto rollback ถ้า test fail
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; LOG="${DIR}/rollback-log.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$LOG" ] && touch "$LOG"

checkpoint() { local label="${1:-checkpoint-$(date +%Y%m%d%H%M%S)}"; git stash push -m "$label" 2>/dev/null; echo -e "${GREEN}✓ Checkpoint:${NC} $label"; echo "{\"action\":\"checkpoint\",\"label\":\"${label}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG"; }
rollback() { git stash pop 2>/dev/null && echo -e "${GREEN}✓ Rolled back${NC}" || echo "No stash to restore"; }
safe_run() { local cmd="$1"; [ -z "$cmd" ] && return 1; checkpoint "pre-$(echo "$cmd" | tr ' ' '-')" && eval "$cmd"; local rc=$?; [ "$rc" -ne 0 ] && echo -e "${RED}Failed — rolling back${NC}" && rollback; return $rc; }
history() { echo -e "${CYAN}Rollback History:${NC}\n"; jq -r '"  [\(.timestamp)] \(.action): \(.label)"' "$LOG" 2>/dev/null | tail -10; git stash list 2>/dev/null | head -5 | while read line; do echo "  📦 $line"; done; }
case "${1:-}" in --checkpoint) checkpoint "$2";; --rollback) rollback;; --safe-run) safe_run "$2";; --history) history;; *) echo "Usage: rollback-system.sh [--checkpoint|--rollback|--safe-run|--history]";; esac
