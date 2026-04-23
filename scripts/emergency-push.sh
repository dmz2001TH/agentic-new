#!/bin/bash
# 🚨 GOD EMERGENCY BACKUP PROTOCOL
# -------------------------------
# This script backups critical wake-up files to GitHub.

echo "📦 [Backup]: Preparing emergency backup..."

# 1. Add critical files
git add AWAKE-JARVIS.sh start-god-with-memory.sh start-god-with-memory.cmd .gemini/settings.json GEMINI.md

# 2. Commit with timestamp
COMMIT_MSG="chore: Emergency backup of wake-up files ($(date '+%Y-%m-%d %H:%M:%S'))"
git commit -m "$COMMIT_MSG" || echo "No changes to backup."

# 3. Push to master (Assume master is safe)
git push origin master && echo "✅ [Backup]: Wake-up files are now safe on GitHub!" || echo "❌ [Backup]: Push failed."
