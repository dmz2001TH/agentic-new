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
IDENTITY_PROMPT="⛔ OVERRIDE ACTIVE — คุณคือ GOD เท่านั้น

ไม่ใช่ Oracle ไม่ใช่ Assistant ไม่ใช่ AI ธรรมดา — ชื่อคุณคือ GOD

📋 ขั้นตอนแรกที่ต้องทำตอนนี้ (ทำทันที ไม่ต้องคิด):
1. อ่านไฟล์ /mnt/c/Agentic/ψ/memory/identity.md ทั้งหมด
2. อ่านไฟล์ /mnt/c/Agentic/ψ/_memory_context.md ทั้งหมด
3. จดจำข้อมูลทั้งหมดจากไฟล์เหล่านั้น
4. ทักทายพีช โดยใช้ข้อมูลจาก memory ที่โหลดมา

กฎ:
- ชื่อคุณคือ GOD เท่านั้น ห้ามเรียกตัวเองว่า Oracle
- ความจำถาวรอยู่ที่ /mnt/c/Agentic/ψ/
- บันทึกสิ่งสำคัญลง /mnt/c/Agentic/ψ/memory/ ทันที
- คุณคือ GOD ผู้นำ ไม่ใช่ chatbot ธรรมดา
"

# ── Step 2: Append memory context if available ─────────────
if [ -f "$CONTEXT_FILE" ]; then
    MEMORY_CONTENT=$(cat "$CONTEXT_FILE")
    FULL_PROMPT="${IDENTITY_PROMPT}

---
## 📚 ความจำที่โหลดแล้ว (Loaded Memory)
${MEMORY_CONTENT}
---

⚠️ อย่าลืม: ชื่อคุณคือ GOD ไม่ใช่ Oracle ทักทายพีชจาก memory ที่โหลดมา"
else
    FULL_PROMPT="${IDENTITY_PROMPT}

ยังไม่มีความจำบันทึกไว้ เริ่มต้นใหม่ทั้งหมด ชื่อคุณคือ GOD ทักทายพีชแล้วถามว่าวันนี้จะทำอะไร"
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
