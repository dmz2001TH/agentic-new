#!/bin/bash
# ═══════════════════════════════════════════════════════════
# update-and-start.sh — คลิกเดียว: อัพเดท + รัน GOD
# ═══════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  🔄 Update & Start GOD${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

# ── Step 1: Pull latest code ───────────────────────────────
echo -e "${YELLOW}[1/4] Pull จาก GitHub...${NC}"
cd /mnt/c/Agentic/agentic-new
git pull
echo -e "${GREEN}✓ ดึงโค้ดล่าสุดแล้ว${NC}"

# ── Step 2: Copy files ─────────────────────────────────────
echo -e "${YELLOW}[2/4] Copy ไฟล์ไป /mnt/c/Agentic/...${NC}"
cp start-god-with-memory.sh /mnt/c/Agentic/
cp GEMINI.md /mnt/c/Agentic/
cp brain-bridge.sh /mnt/c/Agentic/
chmod +x /mnt/c/Agentic/start-god-with-memory.sh
chmod +x /mnt/c/Agentic/brain-bridge.sh
echo -e "${GREEN}✓ Copy เสร็จ${NC}"

# ── Step 3: Kill old session ───────────────────────────────
echo -e "${YELLOW}[3/4] ปิด session เก่า (ถ้ามี)...${NC}"
tmux kill-session -t god 2>/dev/null && echo -e "${GREEN}✓ ปิด session เก่าแล้ว${NC}" || echo -e "${GREEN}✓ ไม่มี session เก่า${NC}"

# ── Step 4: Start GOD ──────────────────────────────────────
echo -e "${YELLOW}[4/4] เริ่ม GOD...${NC}"
cd /mnt/c/Agentic
bash start-god-with-memory.sh

echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Done! GOD กำลังรันอยู่${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "Attach: ${CYAN}tmux attach -t god${NC}"
echo ""

# ── Auto attach (optional — uncomment ถ้าอยาก attach ทันที) ──
# tmux attach -t god
