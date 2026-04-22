#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# anti-repeat.sh — ป้องกันการพิมพ์ซ้ำ + ตรวจจับ repetition loop
#
# Usage:
#   bash anti-repeat.sh --check "text to check"
#   bash anti-repeat.sh --inject   # 输出 rules สำหรับ inject เข้า prompt
# ═══════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPEAT_LOG="${SCRIPT_DIR}/repeat-detections.jsonl"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

[ ! -f "$REPEAT_LOG" ] && touch "$REPEAT_LOG"

# ── Check for repetitive patterns ──────────────────────────
check_repeat() {
    local text="$1"
    [ -z "$text" ] && return 0

    # Split into lines and check for duplicates
    local lines
    lines=$(echo "$text" | grep -v '^$' | sort | uniq -c | sort -rn | head -5)

    local repeated=false
    while IFS= read -r line; do
        local count=$(echo "$line" | awk '{print $1}')
        if [ "$count" -ge 2 ]; then
            repeated=true
            local content=$(echo "$line" | sed 's/^ *[0-9]* //')
            echo -e "${RED}  ⚠️ Repeated ${count}x:${NC} ${content:0:80}"
        fi
    done <<< "$lines"

    # Check for keyword stuffing (same phrase appearing many times)
    local words=$(echo "$text" | tr ' ' '\n' | grep -v '^$' | sort | uniq -c | sort -rn | head -3)
    while IFS= read -r word; do
        local wcount=$(echo "$word" | awk '{print $1}')
        if [ "$wcount" -ge 5 ]; then
            repeated=true
            local wcontent=$(echo "$word" | sed 's/^ *[0-9]* //')
            echo -e "${YELLOW}  ⚠️ Keyword stuffing: '${wcontent}' appears ${wcount}x${NC}"
        fi
    done <<< "$words"

    if [ "$repeated" = true ]; then
        echo "{\"detected\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"preview\":$(echo "${text:0:100}" | jq -Rs .)}" >> "$REPEAT_LOG"
        echo -e "${RED}  ✗ REPETITION DETECTED — rewrite needed${NC}"
        return 1
    else
        echo -e "${GREEN}  ✓ No repetition detected${NC}"
        return 0
    fi
}

# ── Generate anti-repeat rules for prompt injection ────────
inject_rules() {
    cat << 'RULES'
## 🔄 ANTI-REPETITION RULES (บังคับ)

1. **ห้ามพิมพ์ประโยคเดิมซ้ำ** — ถ้าพูดไปแล้ว ไม่พูดอีก
2. **ห้ามใช้คำเดิมมากกว่า 3 ครั้ง** ในข้อความเดียวกัน
3. **ห้าม copy-paste ย่อหน้าเดิม** — เขียนใหม่ทุกครั้ง
4. **ถ้าอธิบายซ้ำ → ใช้คำอื่น** — synonym, rephrase, มุมมองใหม่
5. **หนึ่ง idea = หนึ่งย่อหน้า** — ไม่ต้องย้ำ 2-3 รอบ
6. **ตรวจสอบตัวเองก่อนส่ง** — อ่านย้อนหลัง ถ้าซ้ำ → ลบออก

เคล็ดลับ: ตอบสั้น > ตอบยาวซ้ำๆ
RULES
}

# ── Main ───────────────────────────────────────────────────
case "${1:-}" in
    --check)    check_repeat "${2:-}" ;;
    --inject)   inject_rules ;;
    *)
        echo "Usage:"
        echo "  --check 'text'   Check for repetition"
        echo "  --inject         Output rules for prompt injection"
        ;;
esac
