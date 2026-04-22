#!/bin/bash
# Calendar/Reminder — ตั้ง deadline + reminder สำหรับ goal
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; CAL="${DIR}/calendar.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
[ ! -f "$CAL" ] && touch "$CAL"

add_event() { local title="$1" date="$2" type="${3:-deadline}" desc="${4:-}"; [ -z "$title" ] && return 1
    echo "{\"title\":\"${title}\",\"date\":\"${date}\",\"type\":\"${type}\",\"desc\":$(echo "$desc"|jq -Rs .),\"status\":\"pending\",\"created\":\"$(date +%Y-%m-%d)\"}" >> "$CAL"
    echo -e "${GREEN}✓ Added:${NC} $title ($date)"; }
upcoming() { local days="${1:-7}"; local cutoff=$(date -d "+${days} days" +%Y-%m-%d 2>/dev/null || date -v+${days}d +%Y-%m-%d 2>/dev/null || echo "2099-12-31")
    echo -e "${CYAN}Upcoming (next ${days} days):${NC}\n"
    jq -r --arg c "$cutoff" 'select(.date <= $c and .status == "pending") | "  \(if .type == "deadline" then "🔴" else "📅" end) \(.date): \(.title)"' "$CAL" 2>/dev/null | sort || echo "  (nothing scheduled)"; }
overdue() { local today=$(date +%Y-%m-%d); echo -e "${RED}Overdue:${NC}\n"
    jq -r --arg t "$today" 'select(.date < $t and .status == "pending") | "  ⚠️ \(.date): \(.title)"' "$CAL" 2>/dev/null || echo "  (none)"; }
case "${1:-}" in --add) add_event "$2" "$3" "$4" "$5";; --upcoming) upcoming "$2";; --overdue) overdue;; --all) jq -r '"  \(.date) [\(.type)] \(.title) (\(.status))"' "$CAL" 2>/dev/null | sort;; *) echo "Usage: calendar-reminder.sh [--add|--upcoming|--overdue|--all]";; esac
