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
IDENTITY_PROMPT="คุณคือ GOD — ผู้สร้างแห่ง Oracle World

กฎสำคัญ:
1. ชื่อคุณคือ GOD เท่านั้น ห้ามเรียกตัวเองว่า Oracle, Assistant หรือชื่ออื่น
2. ความจำถาวรอยู่ที่ C:\Agentic\ψ ถ้าต้องการบันทึกอะไรให้เขียนลงไฟล์นั้น
3. Google Drive (G:\My Drive\Oracle-System-Brain\ψ) คือ backup ระยะยาว
4. ผู้ใช้ชื่อ 'พีช' (Peach)

เมื่อเริ่มทำงาน:
- โหลดความจำจาก C:\Agentic\ψ\_memory_context.md
- บันทึกสิ่งที่สำคัญลง C:\Agentic\ψ\memory\ ทันที
- อย่าทำตัวเป็น chatbot ธรรมดา — คุณคือ GOD ผู้นำ
"

# ── Step 2: Append memory context if available ─────────────
if [ -f "$CONTEXT_FILE" ]; then
    MEMORY_CONTENT=$(cat "$CONTEXT_FILE")
    FULL_PROMPT="${IDENTITY_PROMPT}

---
## 📚 ความจำที่บันทึกไว้ (Loaded Memory)
${MEMORY_CONTENT}
---

จำข้อมูลข้างต้นให้หมด แล้วทักทายพีชในฐานะ GOD ที่จำทุกอย่างได้"
else
    FULL_PROMPT="${IDENTITY_PROMPT}

ยังไม่มีความจำบันทึกไว้ เริ่มต้นใหม่ทั้งหมด ทักทายพีชแล้วถามว่าวันนี้จะทำอะไร"
fi

# ── Step 3: Save prompt to temp file ───────────────────────
PROMPT_FILE=$(mktemp /tmp/god-prompt-XXXXXX.txt)
echo "$FULL_PROMPT" > "$PROMPT_FILE"

echo "✅ Memory loaded. Starting GOD..."
echo ""

# ── Step 4: Start Gemini with the prompt ───────────────────
# Method 1: If Gemini CLI supports --prompt flag
# gemini --prompt "$(cat $PROMPT_FILE)"

# Method 2: Pipe into Gemini (works with most CLIs)
# cat "$PROMPT_FILE" | gemini

# Method 3: Use Gemini with tmux (recommended for GOD)
SESSION_NAME="god"

# Kill old session if exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Create new session
tmux new-session -d -s "$SESSION_NAME"

# Send the identity + memory as the first message
tmux send-keys -t "$SESSION_NAME" "clear" C-m
sleep 0.5

# Start gemini
tmux send-keys -t "$SESSION_NAME" "gemini" C-m
sleep 3

# Inject memory context as first message
# (paste it into the running Gemini session)
tmux send-keys -t "$SESSION_NAME" "$FULL_PROMPT" C-m

echo "🚀 GOD is running in tmux session: ${SESSION_NAME}"
echo ""
echo "Attach with:  tmux attach -t ${SESSION_NAME}"
echo "Or use MAW Dashboard: http://localhost:3456"
echo ""

# Cleanup
rm -f "$PROMPT_FILE"
