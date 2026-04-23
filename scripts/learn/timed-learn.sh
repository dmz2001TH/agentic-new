#!/bin/bash
# สคริปต์เรียนรู้ใหม่: ตรวจสอบความคืบหน้าจากหลักฐานจริง
echo "🔍 Studying topic: \$1"
# รันการเรียนรู้โดยตรวจสอบ exit code จริง
bash scripts/learn/real-learn.sh "\$1" "\$2" "\$3"
if [ \$? -eq 0 ]; then
    echo "✅ Success: Evidence recorded"
else
    echo "❌ Failed: Check evidence/log.jsonl"
    exit 1
fi
