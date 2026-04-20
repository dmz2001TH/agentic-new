#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# backup-db.sh — Backup Oracle Core SQLite database
#
# Usage: bash scripts/backup-db.sh [backup_dir]
# ═══════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="${1:-$PROJECT_ROOT/ψ/vault/backups}"
DATE=$(date '+%Y-%m-%d_%H-%M-%S')

mkdir -p "$BACKUP_DIR"

echo "🔮 Oracle Database Backup"
echo "  Date: $DATE"
echo "  Dir:  $BACKUP_DIR"
echo ""

# Find SQLite database files
DB_FILES=$(find "$PROJECT_ROOT/ψ/vault" -name "*.db" -o -name "*.sqlite" 2>/dev/null || true)

if [ -z "$DB_FILES" ]; then
  echo "⚠️  No database files found in ψ/vault/"
  echo "  (Database is created when Oracle Core runs for the first time)"
  exit 0
fi

COUNT=0
for DB in $DB_FILES; do
  BASENAME=$(basename "$DB")
  DEST="$BACKUP_DIR/${BASENAME%.db}_${DATE}.db"

  # Use SQLite backup command if available (consistent snapshot)
  if command -v sqlite3 &>/dev/null; then
    sqlite3 "$DB" ".backup '$DEST'" 2>/dev/null && {
      echo "  ✅ $BASENAME → $(basename "$DEST") ($(du -h "$DEST" | cut -f1))"
      COUNT=$((COUNT + 1))
    }
  else
    # Fallback: copy (may not be consistent if DB is being written)
    cp "$DB" "$DEST" && {
      echo "  ✅ $BASENAME → $(basename "$DEST") ($(du -h "$DEST" | cut -f1)) (cp, not sqlite backup)"
      COUNT=$((COUNT + 1))
    }
  fi
done

echo ""
echo "📦 Backed up $COUNT file(s)"

# Clean old backups (keep last 7 days)
find "$BACKUP_DIR" -name "*.db" -mtime +7 -delete 2>/dev/null || true
echo "🧹 Cleaned backups older than 7 days"
