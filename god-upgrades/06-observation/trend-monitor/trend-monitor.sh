#!/bin/bash
# Trend Monitor — ดูว่า framework/tool ไหนกำลังมา
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; TRENDS="${DIR}/trends.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$TRENDS" ] && touch "$TRENDS"

track() { local keyword="$1" source="${2:-manual}"; [ -z "$keyword" ] && return 1; echo "{\"keyword\":\"${keyword}\",\"source\":\"${source}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$TRENDS"; echo -e "${GREEN}✓ Tracking:${NC} $keyword"; }
scan() { echo -e "${CYAN}Trending keywords:${NC}\n"; jq -s 'group_by(.keyword) | map({keyword: .[0].keyword, count: length, last: .[-1].timestamp}) | sort_by(-.count) | .[:10][] | "  📈 \(.keyword) (mentioned \(.count)x, last: \(.last))"' "$TRENDS" 2>/dev/null || echo "  (no data)"; }
check_hn() { echo -e "${CYAN}Hacker News (tech trends):${NC}\n"; curl -s "https://hacker-news.firebaseio.com/v0/topstories.json" 2>/dev/null | jq '.[:5]' 2>/dev/null | while read id; do curl -s "https://hacker-news.firebaseio.com/v0/item/${id}.json" 2>/dev/null | jq -r '"  🔗 \(.title) (\(.score) pts)"' 2>/dev/null; done | head -5 || echo "  (API unavailable)"; }
case "${1:-}" in --track) track "$2" "$3";; --scan) scan;; --hn) check_hn;; *) echo "Usage: trend-monitor.sh [--track|--scan|--hn]";; esac
