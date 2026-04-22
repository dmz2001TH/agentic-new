#!/bin/bash
# Skill Acquisition — เจอ skill ใหม่ → เรียนรู้ + test + register
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; SKILLS="${DIR}/skills.json"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$SKILLS" ] && echo '{"skills":[]}' > "$SKILLS"

discover() { local source="$1" name="$2" desc="${3:-}"; local tmp=$(mktemp); jq --arg s "$source" --arg n "$name" --arg d "$desc" '.skills += [{"name":$n,"source":$s,"desc":$d,"status":"discovered","learned":"'"$(date +%Y-%m-%d)"'"}]' "$SKILLS" > "$tmp" && mv "$tmp" "$SKILLS"; echo -e "${GREEN}✓ Discovered:${NC} $name from $source"; }
learn() { local name="$1"; local tmp=$(mktemp); jq --arg n "$name" '.skills = [.skills[] | if .name == $n then .status = "learned" else . end]' "$SKILLS" > "$tmp" && mv "$tmp" "$SKILLS"; echo -e "${GREEN}✓ Learned:${NC} $name"; }
master() { local name="$1"; local tmp=$(mktemp); jq --arg n "$name" '.skills = [.skills[] | if .name == $n then .status = "mastered" else . end]' "$SKILLS" > "$tmp" && mv "$tmp" "$SKILLS"; echo -e "${GREEN}✓ Mastered:${NC} $name"; }
list_skills() { echo -e "${CYAN}Skills:${NC}\n"; jq -r '.skills | group_by(.status) | .[] | "  " + (if .[0].status == "discovered" then "🔍" elif .[0].status == "learned" then "📖" else "⭐" end) + " [" + .[0].status + "]\n" + (map("    \(.name) — \(.desc)") | join("\n"))' "$SKILLS" 2>/dev/null || echo "  (empty)"; }
case "${1:-}" in --discover) discover "$2" "$3" "$4";; --learn) learn "$2";; --master) master "$2";; --list) list_skills;; *) echo "Usage: skill-acquisition.sh [--discover|--learn|--master|--list]";; esac
