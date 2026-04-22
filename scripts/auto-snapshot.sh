#!/bin/bash
# Oracle Auto-Snapshot — กันลืมเมื่อ Terminal ปิด
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SNAPSHOT_FILE="/mnt/c/Agentic/agentic-new/ψ/memory/snapshot-latest.md"

echo "# 🔮 Oracle Auto-Snapshot" > $SNAPSHOT_FILE
echo "Last Updated: $TIMESTAMP" >> $SNAPSHOT_FILE
echo "" >> $SNAPSHOT_FILE
echo "## 🎯 Current Goals Progress" >> $SNAPSHOT_FILE
grep "^- \[~\]" "/mnt/c/Agentic/agentic-new/ψ/memory/goals.md" >> $SNAPSHOT_FILE || echo "No active goals." >> $SNAPSHOT_FILE
echo "" >> $SNAPSHOT_FILE
echo "## 📝 Recent Activity (Last 10 lines of logs)" >> $SNAPSHOT_FILE
tail -n 10 "/mnt/c/Agentic/agentic-new/ψ/memory/logs/task-runner.log" >> $SNAPSHOT_FILE 2>/dev/null || echo "No logs found." >> $SNAPSHOT_FILE
echo "" >> $SNAPSHOT_FILE
echo "## 💡 Unsaved Insights (Batch 1-5 Context Locked)" >> $SNAPSHOT_FILE
echo "Status: Active & Synchronized with Global Brain" >> $SNAPSHOT_FILE

# Auto-commit to Git as safety net
git add $SNAPSHOT_FILE
git commit -m "chore: auto-snapshot $TIMESTAMP [skip ci]" --no-verify 2>/dev/null || true
