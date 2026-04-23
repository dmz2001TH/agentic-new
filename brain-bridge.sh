#!/bin/bash
# ═══════════════════════════════════════════════════════════
# brain-bridge.sh — Memory sync system
# Google Drive = สมองถาวร, Local = cache, GitHub = สำรอง
# Cross-platform: Linux, macOS, WSL, Git Bash
# ═══════════════════════════════════════════════════════════

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Auto-detect platform and paths ─────────────────────────
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  # Windows (Git Bash)
  GDRIVE_PSI="${USERPROFILE:-C:\\Users\\$USER}/My Drive/Oracle-System-Brain/ψ"
  LOCAL_PSI="C:/Agentic/ψ"
elif [[ -d "/mnt/c" ]]; then
  # WSL
  GDRIVE_PSI="/mnt/c/Users/${USER}/My Drive/Oracle-System-Brain/ψ"
  LOCAL_PSI="/mnt/c/Agentic/ψ"
else
  # Linux / macOS — use local paths
  GDRIVE_PSI="${GDRIVE_PSI:-}"  # Set externally if available
  LOCAL_PSI="${LOCAL_PSI:-$SCRIPT_DIR/ψ}"
fi

BRAIN_REPO="${BRAIN_REPO:-https://github.com/dmz2001TH/oracle-brain.git}"

# ── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🧠 Brain Bridge — Memory Sync System${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "  Platform: $(uname -s)"
echo -e "  Local:    $LOCAL_PSI"
echo -e "  GDrive:   ${GDRIVE_PSI:-'(not configured)'}"
echo ""

# ── Step 1: Check Google Drive availability ────────────────
echo -e "${YELLOW}[1/5] ตรวจสอบ Google Drive...${NC}"

GDRIVE_AVAILABLE=false
if [ -n "$GDRIVE_PSI" ] && [ -d "$GDRIVE_PSI" ]; then
  echo -e "${GREEN}✓ Google Drive พร้อมใช้${NC}"
  GDRIVE_AVAILABLE=true
else
  echo -e "${YELLOW}⚠ Google Drive ไม่พร้อม — ใช้ Local เท่านั้น${NC}"
  echo -e "  ตั้ง GDRIVE_PSI environment variable ถ้าต้องการ sync"
fi

# ── Step 2: Ensure directories exist ───────────────────────
echo -e "${YELLOW}[2/5] สร้างโครงสร้างโฟลเดอร์...${NC}"

if [ "$GDRIVE_AVAILABLE" = true ]; then
  for dir in memory agents inbox vault writing shared lab lessons; do
    mkdir -p "${GDRIVE_PSI}/${dir}"
  done
  echo -e "${GREEN}✓ Google Drive ψ/ พร้อม${NC}"
fi

mkdir -p "${LOCAL_PSI}"
for dir in memory agents inbox vault lessons; do
  mkdir -p "${LOCAL_PSI}/${dir}"
done
echo -e "${GREEN}✓ Local cache พร้อม${NC}"

# ── Step 3: Sync GDrive → Local ────────────────────────────
if [ "$GDRIVE_AVAILABLE" = true ]; then
  echo -e "${YELLOW}[3/5] Sync: Google Drive → Local...${NC}"

  sync_dirs=("memory" "agents" "vault" "writing" "shared" "lessons")

  for dir in "${sync_dirs[@]}"; do
    src="${GDRIVE_PSI}/${dir}"
    dst="${LOCAL_PSI}/${dir}"
    if [ -d "$src" ]; then
      mkdir -p "$dst"
      rsync -auv "$src/" "$dst/" 2>/dev/null || cp -ru "$src/"* "$dst/" 2>/dev/null || true
      echo -e "  ${GREEN}✓${NC} ${dir}/"
    fi
  done

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

  echo -e "${GREEN}✓ Sync เสร็จ${NC}"

  # ── Step 3.5: Sync Project Agents & Lessons → Google Drive ──
  echo -e "${YELLOW}[3.5/5] Sync: Project agents/ & lessons/ → Google Drive...${NC}"
  
  PROJECT_ROOT="/mnt/c/Agentic/agentic-new"
  GDRIVE_ROOT="/mnt/c/Users/${USER}/My Drive/Oracle-System-Brain"

  # Sync project agents
  if [ -d "$PROJECT_ROOT/agents" ]; then
    mkdir -p "$GDRIVE_ROOT/agents"
    rsync -auv "$PROJECT_ROOT/agents/" "$GDRIVE_ROOT/agents/" 2>/dev/null || cp -ru "$PROJECT_ROOT/agents/"* "$GDRIVE_ROOT/agents/" 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Project agents/ -> GDrive"
  fi

  # Sync project lessons
  if [ -d "$PROJECT_ROOT/lessons" ]; then
    mkdir -p "$GDRIVE_ROOT/lessons"
    rsync -auv "$PROJECT_ROOT/lessons/" "$GDRIVE_ROOT/lessons/" 2>/dev/null || cp -ru "$PROJECT_ROOT/lessons/"* "$GDRIVE_ROOT/lessons/" 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Project lessons/ -> GDrive"
  fi

else
  echo -e "${YELLOW}[3/5] ข้าม sync (ไม่มี Google Drive)${NC}"
fi

# ── Step 4: Generate memory context ───────────────────────
echo -e "${YELLOW}[4/5] สร้าง Memory Context...${NC}"

READ_PSI=$([ "$GDRIVE_AVAILABLE" = true ] && echo "$GDRIVE_PSI" || echo "$LOCAL_PSI")
CONTEXT_FILE="${LOCAL_PSI}/_memory_context.md"

{
  echo "# 🧠 MEMORY CONTEXT — $(date '+%Y-%m-%d %H:%M')"
  echo ""
  echo "## ตัวตน"
  if [ -f "${READ_PSI}/agents/god/memory/identity.md" ]; then
    cat "${READ_PSI}/agents/god/memory/identity.md"
  elif [ -f "${READ_PSI}/memory/identity.md" ]; then
    cat "${READ_PSI}/memory/identity.md"
  else
    echo "- ชื่อ: GOD"
    echo "- บทบาท: Agent หลัก"
  fi
  echo ""
  echo "## Notes ล่าสุด"
  [ -f "${READ_PSI}/memory/notes.md" ] && head -50 "${READ_PSI}/memory/notes.md"
  echo ""
  echo "## Patterns"
  [ -f "${READ_PSI}/memory/patterns.md" ] && head -80 "${READ_PSI}/memory/patterns.md"
  echo ""
  echo "## Goals"
  [ -f "${READ_PSI}/memory/goals.md" ] && cat "${READ_PSI}/memory/goals.md"
} > "$CONTEXT_FILE"

echo -e "${GREEN}✓ Context: ${CONTEXT_FILE}${NC}"

# ── Step 5: GitHub backup ──────────────────────────────────
echo -e "${YELLOW}[5/5] GitHub Backup...${NC}"

if [ ! -d "${LOCAL_PSI}/.git" ]; then
  cd "$LOCAL_PSI"
  git init -b main
  git remote add origin "$BRAIN_REPO" 2>/dev/null || true
  cat > .gitignore << 'EOF'
memory/logs/*.log
*.tmp
*~
.DS_Store
EOF
  echo -e "${GREEN}✓ Git repo สร้างแล้ว${NC}"
fi

cd "$LOCAL_PSI"
git fetch origin main 2>/dev/null || true

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  git add -A
  git commit -m "🧠 brain-sync $(date '+%Y-%m-%d %H:%M')" --quiet 2>/dev/null || true
  git push origin main 2>/dev/null && \
    echo -e "${GREEN}✓ GitHub: Pushed${NC}" || \
    echo -e "${YELLOW}⚠ GitHub: Push failed (check token/repo)${NC}"
else
  echo -e "${GREEN}✓ GitHub: ไม่มีการเปลี่ยนแปลง${NC}"
fi

# ── Summary ────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Brain Bridge เสร็จ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "  Google Drive: $([ "$GDRIVE_AVAILABLE" = true ] && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}offline${NC}")"
echo -e "  Local:        ${GREEN}✓${NC}"
echo -e "  GitHub:       ${GREEN}✓${NC}"
echo ""

mkdir -p "${LOCAL_PSI}/memory/logs"
echo "[$(date -Iseconds)] brain-bridge: gdrive=$GDRIVE_AVAILABLE local=ready" >> "${LOCAL_PSI}/memory/logs/brain-bridge.log"
