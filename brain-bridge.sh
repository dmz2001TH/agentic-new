#!/bin/bash
# ═══════════════════════════════════════════════════════════
# brain-bridge.sh — Google Drive = สมองถาวร (5TB)
# Local C:\Agentic\ψ = cache ชั่วคราว (90GB เหลือน้อย)
# GitHub = สำรองเวอร์ชั่น
# ═══════════════════════════════════════════════════════════

set -e

# ── Paths ──────────────────────────────────────────────────
# Google Drive = สมองหลัก (5TB) — Mirror mode
GDRIVE_BASE="/mnt/c/Users/phasa/My Drive/Oracle-System-Brain"
GDRIVE_PSI="${GDRIVE_BASE}/ψ"

# Local = cache ชั่วคราว (เหลือ ~90GB)
LOCAL_BASE="/mnt/c/Agentic"
LOCAL_PSI="${LOCAL_BASE}/ψ"

# GitHub = สำรองเวอร์ชั่น
BRAIN_REPO="https://github.com/dmz2001TH/oracle-brain.git"

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🧠 Brain Bridge — Google Drive = สมองหลัก${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

# ── Step 1: Check Google Drive availability ────────────────
echo -e "${YELLOW}[1/5] ตรวจสอบ Google Drive (สมองหลัก 5TB)...${NC}"

if [ ! -d "$GDRIVE_PSI" ]; then
    echo -e "${RED}✗ ไม่พบ Google Drive${NC}"
    echo -e "  Path ที่เช็ค: ${GDRIVE_PSI}"
    echo -e "  ตรวจสอบว่า Google Drive Desktop กำลังรันอยู่"
    echo ""
    echo -e "${YELLOW}พยายามหา path อื่นๆ...${NC}"
    
    for alt_path in \
        "/mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ" \
        "/mnt/c/Users/$USER/My Drive/Oracle-System-Brain/ψ" \
        "/mnt/c/Users/phasa/Google Drive/Oracle-System-Brain/ψ" \
        "/mnt/c/Users/$USER/Google Drive/Oracle-System-Brain/ψ"; do
        if [ -d "$alt_path" ]; then
            echo -e "${GREEN}✓ พบที่: ${alt_path}${NC}"
            GDRIVE_PSI="$alt_path"
            break
        fi
    done
    
    if [ ! -d "$GDRIVE_PSI" ]; then
        echo -e "${RED}✗ หา Google Drive ไม่เจอ — ใช้ Local cache แทน${NC}"
        GDRIVE_AVAILABLE=false
    else
        GDRIVE_AVAILABLE=true
    fi
else
    echo -e "${GREEN}✓ Google Drive พร้อมใช้ (5TB)${NC}"
    GDRIVE_AVAILABLE=true
fi

# ── Step 2: Ensure directories exist ───────────────────────
echo -e "${YELLOW}[2/5] สร้างโครงสร้างโฟลเดอร์...${NC}"

# สร้างใน Google Drive (สมองหลัก)
if [ "$GDRIVE_AVAILABLE" = true ]; then
    for dir in memory agents inbox vault writing shared lab; do
        mkdir -p "${GDRIVE_PSI}/${dir}"
    done
    echo -e "${GREEN}✓ Google Drive ψ/ พร้อม${NC}"
fi

# สร้างใน Local (cache)
mkdir -p "${LOCAL_PSI}"
for dir in memory agents inbox vault; do
    mkdir -p "${LOCAL_PSI}/${dir}"
done
echo -e "${GREEN}✓ Local cache พร้อม${NC}"

# ── Step 3: Sync GDrive → Local (pull สมองลง cache) ──────
if [ "$GDRIVE_AVAILABLE" = true ]; then
    echo -e "${YELLOW}[3/5] Sync: Google Drive → Local cache...${NC}"
    
    sync_dirs=("memory" "agents" "vault" "writing" "shared")
    
    for dir in "${sync_dirs[@]}"; do
        src="${GDRIVE_PSI}/${dir}"
        dst="${LOCAL_PSI}/${dir}"
        
        if [ -d "$src" ]; then
            mkdir -p "$dst"
            rsync -auv "$src/" "$dst/" 2>/dev/null || \
                cp -ru "$src/"* "$dst/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} ${dir}/"
        fi
    done
    
    # Sync ไฟล์เดี่ยว
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
    
    echo -e "${GREEN}✓ Sync เสร็จ (GDrive → Local)${NC}"
else
    echo -e "${YELLOW}[3/5] ข้าม sync (Google Drive ไม่พร้อม)${NC}"
fi

# ── Step 4: Generate memory context ───────────────────────
echo -e "${YELLOW}[4/5] สร้าง Memory Context...${NC}"

# อ่านจาก Google Drive ถ้าพร้อม ไม่งั้นอ่านจาก Local
if [ "$GDRIVE_AVAILABLE" = true ]; then
    READ_PSI="$GDRIVE_PSI"
else
    READ_PSI="$LOCAL_PSI"
fi

CONTEXT_FILE="${LOCAL_PSI}/_memory_context.md"
{
    echo "# 🧠 MEMORY CONTEXT — โหลดอัตโนมัติ $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "## ตัวตน (Identity)"
    if [ -f "${READ_PSI}/agents/god/memory/identity.md" ]; then
        cat "${READ_PSI}/agents/god/memory/identity.md"
    elif [ -f "${READ_PSI}/memory/identity.md" ]; then
        cat "${READ_PSI}/memory/identity.md"
    else
        echo "- ชื่อ: GOD"
        echo "- บทบาท: Agent หลัก ผู้สร้างแห่ง Oracle World"
    fi
    echo ""
    echo "## ระบบสมอง 3 ชั้น (Storage Layers)"
    echo "1. **Google Drive = สมองหลัก (5TB)** ⭐"
    echo "   - Windows: C:\\Users\\phasa\\My Drive\\Oracle-System-Brain\\ψ\\"
    echo "   - WSL: /mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ/"
    echo "2. **Local = cache ชั่วคราว (~90GB)**"
    echo "   - Windows: C:\\Agentic\\ψ\\"
    echo "   - WSL: /mnt/c/Agentic/ψ/"
    echo "3. **GitHub = สำรองเวอร์ชั่น**"
    echo "   - URL: https://github.com/dmz2001TH/oracle-brain"
    echo ""
    echo "**สำคัญ:** Google Drive คือสมองหลัก บันทึกทุกอย่างลงนั้น Local แค่ cache"
    echo ""
    echo "## บันทึกล่าสุด (Recent Notes)"
    if [ -f "${READ_PSI}/memory/notes.md" ]; then
        head -50 "${READ_PSI}/memory/notes.md"
    fi
    echo ""
    echo "## Patterns ที่จำไว้"
    if [ -f "${READ_PSI}/memory/patterns.md" ]; then
        head -80 "${READ_PSI}/memory/patterns.md"
    fi
    echo ""
    echo "## ค่าที่ยึดถือ (Values)"
    if [ -f "${READ_PSI}/memory/values.md" ]; then
        cat "${READ_PSI}/memory/values.md"
    fi
    echo ""
    echo "## Goals"
    if [ -f "${READ_PSI}/memory/goals.md" ]; then
        cat "${READ_PSI}/memory/goals.md"
    fi
    echo ""
    echo "## People"
    if [ -f "${READ_PSI}/memory/people.md" ]; then
        cat "${READ_PSI}/memory/people.md"
    fi
} > "$CONTEXT_FILE"

echo -e "${GREEN}✓ Memory context: ${CONTEXT_FILE}${NC}"

# ── Step 5: GitHub backup ──────────────────────────────────
echo -e "${YELLOW}[5/5] GitHub Backup...${NC}"

if [ ! -d "${LOCAL_PSI}/.git" ]; then
    echo -e "${YELLOW}→ สร้าง git repo ครั้งแรก...${NC}"
    cd "$LOCAL_PSI"
    git init -b main
    git remote add origin "$BRAIN_REPO" 2>/dev/null || true
    git config user.email "dmz2001th@gmail.com" 2>/dev/null || true
    git config user.name "dmz2001TH" 2>/dev/null || true
    
    cat > .gitignore << 'EOF'
memory/logs/*.log
*.tmp
*~
.DS_Store
EOF
    echo -e "${GREEN}✓ Git repo สร้างแล้ว${NC}"
fi

cd "$LOCAL_PSI"
git config user.email "dmz2001th@gmail.com" 2>/dev/null || true
git config user.name "dmz2001TH" 2>/dev/null || true
git fetch origin main 2>/dev/null || true

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo -e "${YELLOW}→ มีไฟล์เปลี่ยนแปลง — commit + push...${NC}"
    git add -A
    git commit -m "🧠 brain-sync $(date '+%Y-%m-%d %H:%M')" --quiet 2>/dev/null || \
        git commit -m "🧠 initial brain sync" --allow-empty --quiet 2>/dev/null || true
    git branch -M main 2>/dev/null || true
    git push origin main --force 2>/dev/null && \
        echo -e "${GREEN}✓ GitHub: Pushed ✓${NC}" || \
        echo -e "${YELLOW}⚠ GitHub: Push failed (check token/repo)${NC}"
else
    echo -e "${GREEN}✓ GitHub: ไม่มีการเปลี่ยนแปลง${NC}"
fi

# ── Step 6: Sync Local → GDrive (push cache กลับสมอง) ────
if [ "$GDRIVE_AVAILABLE" = true ]; then
    echo -e "${YELLOW}[6/6] Sync: Local → Google Drive (push กลับ)...${NC}"
    
    for dir in "${sync_dirs[@]}"; do
        src="${LOCAL_PSI}/${dir}"
        dst="${GDRIVE_PSI}/${dir}"
        
        if [ -d "$src" ]; then
            mkdir -p "$dst"
            rsync -auv "$src/" "$dst/" 2>/dev/null || \
                cp -ru "$src/"* "$dst/" 2>/dev/null || true
        fi
    done
    
    # Sync ไฟล์เดี่ยวกลับ
    for f in patterns.md notes.md decisions.md values.md goals.md people.md handoff.md; do
        src="${LOCAL_PSI}/${f}"
        dst="${GDRIVE_PSI}/${f}"
        if [ -f "$src" ]; then
            if [ ! -f "$dst" ] || [ "$src" -nt "$dst" ]; then
                cp "$src" "$dst"
            fi
        fi
    done
    
    echo -e "${GREEN}✓ Push กลับ Google Drive เสร็จ${NC}"
fi

cd "$LOCAL_BASE"

# ── Summary ────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Brain Bridge เสร็จแล้ว${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "  Google Drive (5TB): $([ "$GDRIVE_AVAILABLE" = true ] && echo -e "${GREEN}✓ สมองหลัก${NC}" || echo -e "${RED}✗ Offline${NC}")"
echo -e "  Local (~90GB):      ${GREEN}✓ Cache${NC}"
echo -e "  GitHub:             ${GREEN}✓ Backup${NC}"
echo ""

# ── Save sync log ──────────────────────────────────────────
LOG_DIR="${LOCAL_PSI}/memory/logs"
mkdir -p "$LOG_DIR"
echo "[$(date -Iseconds)] brain-bridge: gdrive=$GDRIVE_AVAILABLE local=ready github=synced" >> "${LOG_DIR}/brain-bridge.log"
