#!/bin/bash
# ═══════════════════════════════════════════════════════════
# verify-brain.sh — ตรวจสอบสถานะ Brain Bridge
# ═══════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

GDRIVE_PSI="/mnt/g/My Drive/Oracle-System-Brain/ψ"
LOCAL_PSI="/mnt/c/Agentic/ψ"

echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔍 Brain Bridge — ตรวจสอบสถานะ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
echo ""

# Google Drive
echo -e "${YELLOW}📂 Google Drive (G:\\)${NC}"
if [ -d "$GDRIVE_PSI" ]; then
    echo -e "  ${GREEN}✓${NC} Mount: OK"
    
    # Check if files are actually downloaded (not stub/placeholder)
    test_file=$(find "$GDRIVE_PSI" -name "*.md" -type f 2>/dev/null | head -1)
    if [ -n "$test_file" ]; then
        file_size=$(stat -c%s "$test_file" 2>/dev/null || stat -f%z "$test_file" 2>/dev/null || echo "0")
        if [ "$file_size" -gt 0 ]; then
            echo -e "  ${GREEN}✓${NC} Files: Downloaded (${file_size} bytes)"
        else
            echo -e "  ${RED}✗${NC} Files: 0 bytes — ต้อง 'Make available offline' ใน Google Drive!"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} ไม่พบไฟล์ .md"
    fi
    
    # Count files
    file_count=$(find "$GDRIVE_PSI" -type f 2>/dev/null | wc -l)
    echo -e "  ${GREEN}✓${NC} Files: ${file_count}"
else
    echo -e "  ${RED}✗${NC} ไม่พบ หรือไม่ได้ mount"
    echo -e "  ${YELLOW}→${NC} ตรวจสอบ: ls /mnt/g/"
    echo -e "  ${YELLOW}→${NC} หรือ: mount | grep -i g:"
fi

echo ""

# Local
echo -e "${YELLOW}📂 Local (C:\\Agentic)${NC}"
if [ -d "$LOCAL_PSI" ]; then
    echo -e "  ${GREEN}✓${NC} Exists: OK"
    
    # Check key files
    for key_file in memory agents vault; do
        if [ -d "${LOCAL_PSI}/${key_file}" ]; then
            count=$(find "${LOCAL_PSI}/${key_file}" -type f 2>/dev/null | wc -l)
            echo -e "  ${GREEN}✓${NC} ${key_file}/: ${count} files"
        else
            echo -e "  ${YELLOW}⚠${NC} ${key_file}/: missing"
        fi
    done
    
    # Check context file
    if [ -f "${LOCAL_PSI}/_memory_context.md" ]; then
        lines=$(wc -l < "${LOCAL_PSI}/_memory_context.md")
        echo -e "  ${GREEN}✓${NC} Memory context: ${lines} lines"
    else
        echo -e "  ${YELLOW}⚠${NC} Memory context: not generated yet"
        echo -e "  ${YELLOW}→${NC} รัน: bash brain-bridge.sh"
    fi
else
    echo -e "  ${RED}✗${NC} ไม่พบ C:\\Agentic\\ψ"
fi

echo ""

# Agent config
echo -e "${YELLOW}👤 Agent Identity${NC}"
AGENT_IDENTITY="${LOCAL_PSI}/agents/god/memory/identity.md"
if [ -f "$AGENT_IDENTITY" ]; then
    echo -e "  ${GREEN}✓${NC} god/identity.md: exists"
    head -3 "$AGENT_IDENTITY" | sed 's/^/    /'
else
    echo -e "  ${YELLOW}⚠${NC} god/identity.md: missing"
fi

echo ""

# tmux session
echo -e "${YELLOW}🖥️  Agent Sessions${NC}"
if tmux list-sessions 2>/dev/null | grep -q "god"; then
    echo -e "  ${GREEN}✓${NC} tmux 'god': running"
else
    echo -e "  ${YELLOW}⚠${NC} tmux 'god': not running"
    echo -e "  ${YELLOW}→${NC} เริ่ม: bash start-god-with-memory.sh"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════${NC}"
