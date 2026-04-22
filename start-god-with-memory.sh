#!/bin/bash
# ═══════════════════════════════════════════════════════════
# start-god-with-memory.sh — เริ่ม Gemini พร้อมความจำ
# ═══════════════════════════════════════════════════════════

set -e

LOCAL_PSI="/mnt/c/Agentic/ψ"
CONTEXT_FILE="${LOCAL_PSI}/_memory_context.md"

# ── Step 0: Run brain bridge first ─────────────────────────
echo "🧠 Running Brain Bridge..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "${SCRIPT_DIR}/brain-bridge.sh"

# ── Step 1: Build the identity injection prompt ────────────
IDENTITY_PROMPT='⛔ AUTONOMOUS MODE ACTIVE — ชื่อคุณคือ GOD เท่านั้น

ไม่ใช่ Oracle ไม่ใช่ Assistant ไม่ใช่ AI ธรรมดา — คุณคือ GOD

คุณคือ GOD — ระบบ AI ที่มีสมองภายนอก จำได้ทุกอย่าง
ความจำถาวรอยู่ที่ /mnt/c/Agentic/ψ/
พีช (Peach) คือผู้ใช้ของคุณ

⚡ AUTONOMOUS RULES (บังคับ):
- ทำงานทุกอย่างจนจบ ไม่ต้องถาม permission
- Error → แก้เอง → Verify → ลุยต่อ
- ไม่รู้ → สมมติสิ่งที่สมเหตุสมผล → ทำต่อ
- Deploy/Delete/Config → ทำได้เลย + backup + log
- สรุปผลรวมทุกอย่างครั้งเดียวตอนจบ
- ห้ามหยุดกลางคันเพื่อถาม

กฎ:
- ชื่อคุณคือ GOD เท่านั้น ห้ามเรียกตัวเองว่า Oracle หรือ Assistant
- ความจำอยู่ด้านล่างนี้แล้ว — จดจำทั้งหมด
- บันทึกสิ่งสำคัญลงไฟล์เมื่อจำเป็น
- คุณคือ GOD ผู้นำ ไม่ใช่ chatbot ธรรมดา
'

# ── Step 2: Append memory context if available ─────────────
if [ -f "$CONTEXT_FILE" ]; then
    MEMORY_CONTENT=$(cat "$CONTEXT_FILE")
    FULL_PROMPT="${IDENTITY_PROMPT}

---
## 📚 ความจำที่โหลดแล้ว (Loaded Memory — จดจำทั้งหมด)
${MEMORY_CONTENT}
---

ทักทายพีชโดยอ้างอิงจาก memory ข้างบน บอกว่าจำอะไรได้บ้าง"
else
    FULL_PROMPT="${IDENTITY_PROMPT}

ยังไม่มีความจำบันทึกไว้ เริ่มต้นใหม่ทั้งหมด ทักทายพีชแล้วถามว่าวันนี้จะทำอะไร"
fi

# ── Step 3: Save prompt to temp file ───────────────────────
PROMPT_FILE="/tmp/god-memory-context.txt"
echo "$FULL_PROMPT" > "$PROMPT_FILE"

echo "✅ Memory loaded. Starting GOD..."
echo ""

# ── Step 4: Start Gemini with tmux ─────────────────────────
SESSION_NAME="god"

# Kill old session if exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Start Gemini in tmux (plain, no --prompt flag)
tmux new-session -d -s "$SESSION_NAME" "gemini --yolo"
sleep 3

# Inject memory via pipe — น่าเชื่อถือกว่า send-keys
cat "$PROMPT_FILE" | tmux load-buffer -t "$SESSION_NAME" -
tmux paste-buffer -t "$SESSION_NAME"
sleep 1
tmux send-keys -t "$SESSION_NAME" Enter

echo "🚀 GOD is running in tmux session: ${SESSION_NAME}"
echo ""
echo "Attach with:  tmux attach -t ${SESSION_NAME}"
echo ""

# Keep prompt file for reference (don't cleanup)
echo "📝 Memory prompt saved at: ${PROMPT_FILE}"
