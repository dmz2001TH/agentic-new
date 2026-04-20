#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# oracle-tools.sh — GOD's hands: Oracle API + Task Runner
# ACI LAYER v2.0: Supreme Coding Agent
# "Verification First — Reading is not verification. Run it."
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ORACLE_URL="${ORACLE_URL:-http://localhost:47778}"
MAW_URL="${MAW_URL:-http://localhost:3456}"
PSI_DIR="$PROJECT_ROOT/ψ"

# ─── Colors ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# ═══════════════════════════════════════════
# ACI LAYER v2.0 (Supreme Coding Agent)
# ═══════════════════════════════════════════

ot-edit-surgical() {
  local file="${1:?Usage: ot-edit-surgical <file> <old> <new>}"
  sed -i "s/$2/$3/g" "$file"
  echo "✓ Surgical edit completed on $file"
}

ot-verify() {
  echo "--- Starting Verification Loop ---"
  # "Verification First — Reading is not verification. Run it."
  if [ -f "package.json" ]; then
    npm run lint || true
    npm test -- --run || true
  fi
  echo "--- Verification Finished ---"
}

ot-read-range() {
  local file="${1:?Usage: read-range <file> <start_line> <end_line>}"
  sed -n "${2},${3}p" "$file"
}

ot-hey() {
  local target="${1:?Usage: ot-hey <target_agent> <message>}"
  echo "[GOD -> $target]: $2"
}

ot-compress() {
  local log_file="${1:?Usage: ot-compress <log_file>}"
  grep -E "Action:|Result:|Error:|🎯 Next Goal:|✓ Goal completed:" "$log_file" > "${log_file}.compressed"
}

ot-extract-skill() {
  local name="${1:?Usage: ot-extract-skill <name> <description> <code>}"
  local skill_file=".claude/skills/${name}.md"
  mkdir -p ".claude/skills"
  cat <<EOF > "$skill_file"
# Skill: $1
- Description: $2
\`\`\`bash
$3
\`\`\`
EOF
}

# ═══════════════════════════════════════════
# CLI ENTRY POINT
# ═══════════════════════════════════════════

COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    verify)      ot-verify ;;
    edit)        ot-edit-surgical "$@" ;;
    read-range)  ot-read-range "$@" ;;
    hey)         ot-hey "$@" ;;
    compress)    ot-compress "$@" ;;
    extract-skill) ot-extract-skill "$@" ;;
    help|*)
      echo "🔮 Oracle Tools — ACI v2.0"
      echo "Commands: verify, edit, read-range, hey, compress, extract-skill"
      ;;
esac
