#!/bin/bash
# Git Automation — auto commit, branch, PR
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="${DIR}/git-log.jsonl"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; NC='\033[0m'

[ ! -f "$LOG" ] && touch "$LOG"

auto_commit() {
    local msg="${1:-auto: $(date +%Y-%m-%d)}"
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    git add -A 2>/dev/null
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        git commit -m "$msg" --quiet 2>/dev/null
        echo -e "${GREEN}✓ Committed:${NC} $msg"
        echo "{\"action\":\"commit\",\"msg\":$(echo "$msg" | jq -Rs .),\"timestamp\":\"${ts}\"}" >> "$LOG"
    else
        echo -e "${YELLOW}Nothing to commit${NC}"
    fi
}

auto_branch() {
    local name="$1"
    [ -z "$name" ] && echo "Usage: --branch 'name'" && return 1
    git checkout -b "$name" 2>/dev/null || git checkout "$name" 2>/dev/null
    echo -e "${GREEN}✓ Branch:${NC} $name"
    echo "{\"action\":\"branch\",\"name\":\"${name}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$LOG"
}

auto_pr() {
    local title="$1" body="${2:-}"
    [ -z "$title" ] && echo "Usage: --pr 'title' 'body'" && return 1
    if command -v gh &>/dev/null; then
        gh pr create --title "$title" --body "$body" 2>&1 || echo "PR creation failed (check gh auth)"
    else
        echo "gh CLI not available"
    fi
}

status() {
    echo -e "${CYAN}Git Status:${NC}"
    echo -e "  Branch: $(git branch --show-current 2>/dev/null)"
    echo -e "  Modified: $(git status --porcelain 2>/dev/null | grep -c '^ M' || echo 0)"
    echo -e "  Untracked: $(git status --porcelain 2>/dev/null | grep -c '^??' || echo 0)"
    echo -e "  Last commit: $(git log -1 --oneline 2>/dev/null || echo 'none')"
}

case "${1:-}" in
    --commit) auto_commit "$2" ;;
    --branch) auto_branch "$2" ;;
    --pr) auto_pr "$2" "$3" ;;
    --status) status ;;
    --log) tail -10 "$LOG" | jq -r '"  [\(.timestamp)] \(.action): \(.msg // .name // "")"' 2>/dev/null;;
    *) echo "Usage: git-automation.sh [--commit|--branch|--pr|--status|--log]" ;;
esac
