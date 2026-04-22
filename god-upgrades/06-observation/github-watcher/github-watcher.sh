#!/bin/bash
# GitHub Watcher — ติดตาม repo → แจ้ง release/update
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; WATCH="${DIR}/watching.json"; LOG="${DIR}/updates.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$WATCH" ] && echo '{"repos":[]}' > "$WATCH"; [ ! -f "$LOG" ] && touch "$LOG"

watch() { local repo="$1"; [ -z "$repo" ] && return 1; local tmp=$(mktemp); jq --arg r "$repo" '.repos += [{"repo":$r,"added":"'"$(date +%Y-%m-%d)"'","last_check":"'"$(date +%Y-%m-%d)"'","releases":0}]' "$WATCH" > "$tmp" && mv "$tmp" "$WATCH"; echo -e "${GREEN}✓ Watching:${NC} $repo"; }
check() { echo -e "${CYAN}Checking repos...${NC}\n"; jq -r '.repos[].repo' "$WATCH" 2>/dev/null | while read repo; do
    if command -v gh &>/dev/null; then
        local latest=$(gh release view "$repo" --json tagName -q '.tagName' 2>/dev/null || echo "none")
        echo -e "  📦 ${repo}: latest = ${latest}"
        echo "{\"repo\":\"${repo}\",\"latest\":\"${latest}\",\"checked\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG"
    else echo -e "  📦 ${repo}: (gh not available)"; fi
done; }
case "${1:-}" in --watch) watch "$2";; --check) check;; --list) jq -r '.repos[] | "  👁️ \(.repo) (since \(.added))"' "$WATCH" 2>/dev/null;; *) echo "Usage: github-watcher.sh [--watch|--check|--list]";; esac
