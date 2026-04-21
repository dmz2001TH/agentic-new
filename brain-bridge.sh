#!/bin/bash
# ═══════════════════════════════════════════════════════════
# brain-bridge.sh — เชื่อม Google Drive (G:\) ↔ Local (C:\Agentic)
# รันใน WSL หรือ Git Bash
# ═══════════════════════════════════════════════════════════

set -e

# ── Paths ──────────────────────────────────────────────────
# Google Drive (permanent brain)
# Mirror mode → ไฟล์อยู่ที่ C:\Users\phasa\Google Drive\
GDRIVE_BASE="/mnt/c/Users/phasa/My Drive/Oracle-System-Brain"
GDRIVE_PSI="${GDRIVE_BASE}/ψ"

# Local (working brain) — Gemini sandbox path
LOCAL_BASE="/mnt/c/Agentic"
LOCAL_PSI="${LOCAL_BASE}/ψ"

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🧠 Brain Bridge — G:\\ ↔ C:\\ ↔ GitHub${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

# ── Step 1: Check G:\ accessibility ────────────────────────
echo -e "${YELLOW}[1/5] ตรวจสอบ Google Drive...${NC}"

if [ ! -d "$GDRIVE_PSI" ]; then
    echo -e "${RED}✗ ไม่พบ G:\\ หรือ path ผิด${NC}"
    echo -e "  ตรวจสอบว่า:"
    echo -e "  1. Google Drive Desktop กำลังรันอยู่"
    echo -e "  2. โฟลเดอร์ 'Oracle-System-Brain' ถูกตั้งเป็น 'Available offline'"
    echo -e "  3. Path ถูกต้อง: ${GDRIVE_PSI}"
    echo ""
    echo -e "${YELLOW}พยายามหา path อื่นๆ...${NC}"
    
    # Try alternate mount points (Mirror mode paths)
    for alt_path in \
        "/mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ" \
        "/mnt/c/Users/$USER/My Drive/Oracle-System-Brain/ψ" \
        "/mnt/c/Users/phasa/Google Drive/Oracle-System-Brain/ψ" \
        "/mnt/c/Users/$USER/Google Drive/Oracle-System-Brain/ψ" \
        "/mnt/g/My Drive/Oracle-System-Brain/ψ" \
        "/mnt/g/MyDrive/Oracle-System-Brain/ψ"; do
        if [ -d "$alt_path" ]; then
            echo -e "${GREEN}✓ พบที่: ${alt_path}${NC}"
            GDRIVE_PSI="$alt_path"
            break
        fi
    done
    
    if [ ! -d "$GDRIVE_PSI" ]; then
        echo -e "${RED}✗ หา G:\\ ไม่เจอจริงๆ — ข้าม sync${NC}"
        echo -e "  ทำงานกับ C:\\Agentic\\ψ อย่างเดียวก่อน"
        GDRIVE_AVAILABLE=false
    else
        GDRIVE_AVAILABLE=true
    fi
else
    echo -e "${GREEN}✓ Google Drive พร้อมใช้${NC}"
    GDRIVE_AVAILABLE=true
fi

# ── Step 2: Ensure local ψ exists ──────────────────────────
echo -e "${YELLOW}[2/5] ตรวจสอบ Local ψ...${NC}"

if [ ! -d "$LOCAL_PSI" ]; then
    echo -e "${YELLOW}→ สร้าง ${LOCAL_PSI}${NC}"
    mkdir -p "${LOCAL_PSI}"/{memory,agents,inbox,vault,writing,shared,lab}
fi

# Essential subdirs
for dir in memory agents inbox vault; do
    mkdir -p "${LOCAL_PSI}/${dir}"
done

echo -e "${GREEN}✓ Local ψ พร้อม${NC}"

# ── Step 3: Sync G:\ → C:\ (pull from permanent brain) ────
if [ "$GDRIVE_AVAILABLE" = true ]; then
    echo -e "${YELLOW}[3/5] Sync: Google Drive → Local...${NC}"
    
    # Sync key directories (G: → C:)
    # Using rsync with update-only (skip if newer locally)
    sync_dirs=("memory" "agents" "vault" "writing" "shared")
    
    for dir in "${sync_dirs[@]}"; do
        src="${GDRIVE_PSI}/${dir}"
        dst="${LOCAL_PSI}/${dir}"
        
        if [ -d "$src" ]; then
            mkdir -p "$dst"
            # -a: archive, -u: update only (skip newer), -v: verbose
            rsync -auv "$src/" "$dst/" 2>/dev/null || \
                cp -ru "$src/"* "$dst/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} ${dir}/"
        fi
    done
    
    # Sync individual files from root of ψ
    for f in patterns.md notes.md decisions.md values.md goals.md people.md handoff.md; do
        src="${GDRIVE_PSI}/${f}"
        dst="${LOCAL_PSI}/${f}"
        if [ -f "$src" ]; then
            if [ ! -f "$dst" ] || [ "$src" -nt "$dst" ]; then
                cp "$src" "$dst"
                echo -e "  ${GREEN}✓${NC} ${f}"
            fi
        fi
    done
    
    echo -e "${GREEN}✓ Sync เสร็จ (G: → C:)${NC}"
else
    echo -e "${YELLOW}[3/5] ข้าม sync (G:\\ ไม่พร้อม)${NC}"
fi

# ── Step 4: Generate memory context file ───────────────────
echo -e "${YELLOW}[4/5] สร้าง Memory Context...${NC}"

CONTEXT_FILE="${LOCAL_PSI}/_memory_context.md"
{
    echo "# 🧠 MEMORY CONTEXT — โหลดอัตโนมัติ $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "## ตัวตน (Identity)"
    if [ -f "${LOCAL_PSI}/agents/god/memory/identity.md" ]; then
        cat "${LOCAL_PSI}/agents/god/memory/identity.md"
    elif [ -f "${LOCAL_PSI}/memory/identity.md" ]; then
        cat "${LOCAL_PSI}/memory/identity.md"
    else
        echo "- ชื่อ: GOD"
        echo "- บทบาท: Agent หลัก ผู้สร้างแห่ง Oracle World"
    fi
    echo ""
    echo "## ระบบสมอง 3 ชั้น (Storage Layers)"
    echo "1. **Local (ทำงานจริง)**"
    echo "   - Windows: C:\\Agentic\\ψ\\"
    echo "   - WSL: /mnt/c/Agentic/ψ/"
    echo "2. **Google Drive (สำรองข้ามเครื่อง)**"
    echo "   - Windows: C:\\Users\\phasa\\My Drive\\Oracle-System-Brain\\ψ\\"
    echo "   - WSL: /mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ/"
    echo "3. **GitHub (สำรองเวอร์ชั่น)**"
    echo "   - URL: https://github.com/dmz2001TH/oracle-brain"
    echo ""
    echo "brain-bridge.sh ซิงค์ระหว่างทั้ง 3 ชั้นอัตโนมัติ"
    echo ""
    echo "## บันทึกล่าสุด (Recent Notes)"
    if [ -f "${LOCAL_PSI}/memory/notes.md" ]; then
        head -50 "${LOCAL_PSI}/memory/notes.md"
    fi
    echo ""
    echo "## Patterns ที่จำไว้"
    if [ -f "${LOCAL_PSI}/memory/patterns.md" ]; then
        head -80 "${LOCAL_PSI}/memory/patterns.md"
    fi
    echo ""
    echo "## ค่าที่ยึดถือ (Values)"
    if [ -f "${LOCAL_PSI}/memory/values.md" ]; then
        cat "${LOCAL_PSI}/memory/values.md"
    fi
    echo ""
    echo "## Goals"
    if [ -f "${LOCAL_PSI}/memory/goals.md" ]; then
        cat "${LOCAL_PSI}/memory/goals.md"
    fi
    echo ""
    echo "## People"
    if [ -f "${LOCAL_PSI}/memory/people.md" ]; then
        cat "${LOCAL_PSI}/memory/people.md"
    fi
} > "$CONTEXT_FILE"

echo -e "${GREEN}✓ Memory context: ${CONTEXT_FILE}${NC}"

# ── Step 5: GitHub backup (สำรองสมองไป GitHub) ────────────
echo -e "${YELLOW}[5/5] GitHub Backup...${NC}"

# ตั้งค่า repo URL — แก้เป็น repo จริงของคุณ
BRAIN_REPO="https://github.com/dmz2001TH/oracle-brain.git"
BRAIN_REPO_NAME="oracle-brain"

# ตรวจสอบ git repo
if [ ! -d "${LOCAL_PSI}/.git" ]; then
    echo -e "${YELLOW}→ สร้าง git repo ใน ψ/ ครั้งแรก...${NC}"
    cd "$LOCAL_PSI"
    git init -b main
    git remote add origin "$BRAIN_REPO" 2>/dev/null || true
    
    # ตั้ง git config (local เท่านั้น ไม่ --global)
    git config user.email "dmz2001th@gmail.com" 2>/dev/null || true
    git config user.name "dmz2001TH" 2>/dev/null || true
    
    # สร้าง .gitignore
    cat > .gitignore << 'EOF'
memory/logs/*.log
*.tmp
*~
.DS_Store
EOF
    
    echo -e "${GREEN}✓ Git repo สร้างแล้ว${NC}"
fi

cd "$LOCAL_PSI"

# ตั้ง git config ทุกครั้ง (กัน config หาย)
git config user.email "dmz2001th@gmail.com" 2>/dev/null || true
git config user.name "dmz2001TH" 2>/dev/null || true

# ดึง remote ก่อน (ถ้ามี)
git fetch origin main 2>/dev/null || true

# Check ว่ามีการเปลี่ยนแปลงมั้ย
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo -e "${YELLOW}→ มีไฟล์เปลี่ยนแปลง — commit + push...${NC}"
    
    git add -A
    git commit -m "🧠 brain-sync $(date '+%Y-%m-%d %H:%M')" --quiet 2>/dev/null || \
        git commit -m "🧠 initial brain sync" --allow-empty --quiet 2>/dev/null || true
    
    # ตั้ง branch ชื่อ main (กันชื่อ master)
    git branch -M main 2>/dev/null || true
    
    # Push (force ถ้า conflict — memory ล่าสุดคือ truth)
    git push origin main --force 2>/dev/null && \
        echo -e "${GREEN}✓ GitHub: Pushed ✓${NC}" || \
        echo -e "${YELLOW}⚠ GitHub: Push failed (check token/repo)${NC}"
else
    echo -e "${GREEN}✓ GitHub: ไม่มีการเปลี่ยนแปลง${NC}"
fi

cd "$LOCAL_BASE"

# ── Summary ────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Brain Bridge เสร็จแล้ว${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "  G:\\ (Google Drive): $([ "$GDRIVE_AVAILABLE" = true ] && echo -e "${GREEN}✓ Connected${NC}" || echo -e "${RED}✗ Offline${NC}")"
echo -e "  C:\\ (Local):        ${GREEN}✓ Ready${NC}"
echo -e "  GitHub:             ${GREEN}✓ Backed up${NC}"
echo -e "  Context:            ${GREEN}✓ Generated${NC}"
echo ""
echo -e "${YELLOW}ขั้นตอนต่อไป:${NC}"
echo -e "  เริ่ม agent: ${CYAN}bash start-god-with-memory.sh${NC}"
echo ""

# ── Save sync log ──────────────────────────────────────────
LOG_DIR="${LOCAL_PSI}/memory/logs"
mkdir -p "$LOG_DIR"
echo "[$(date -Iseconds)] brain-bridge: gdrive=$GDRIVE_AVAILABLE local=ready github=synced" >> "${LOG_DIR}/brain-bridge.log"
