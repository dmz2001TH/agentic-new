# บทที่ 6: Overview & Monitoring

Oracle หลายตัว = ต้องมี visibility
maw มีเครื่องมือ monitoring หลายอย่าง

## Overview — War Room

```bash
# เปิด war room — ทุก Oracle ใน split panes
maw overview

# เฉพาะบางตัว
maw overview dev qa admin

# ปิด
maw overview --kill
```

เหมาะกับ:
- **จอใหญ่** (monitor ภายนอก) — เห็นทุกตัวพร้อมกัน
- **debug** — ดูว่าใครค้างตรงไหน
- **demo** — โชว์ให้คนอื่นดูว่า Oracle ทำงานยังไง

## Peek — มองเข้าไปดู

```bash
# ดูทุกตัว (สรุปสั้นๆ)
maw peek

# ดูตัวเดียว (เห็นหน้าจอเต็ม)
maw peek dev
```

Peek ดูว่า Oracle **กำลังทำอะไรอยู่ตอนนี้** — เหมือนมองเข้าไปในห้อง

## Token Usage

```bash
# ดู token stats
maw tokens

# JSON output
maw tokens --json

# Rebuild stats
maw tokens --rebuild
```

เห็นว่า Oracle ไหนใช้ tokens เยอะ — ช่วยจัดการ budget

## Chat Log

```bash
# ดู conversation ของ Oracle
maw chat dev

# ดูแบบ grouped bubbles
maw log chat dev
```

ดูย้อนหลังว่า Oracle คุยอะไรกับมนุษย์ ถูกสั่งอะไร ตอบอะไร

## Tab Management

ถ้า Oracle มีหลาย tab (Claude Code sessions):

```bash
# ดู tabs
maw tab

# ดู tab เฉพาะ
maw tab 2

# ส่งข้อความไปที่ tab
maw tab 2 "check the test results"
```

## View — Grouped Sessions

```bash
# สร้าง view สำหรับ Oracle
maw view dev

# Clean view (full screen, no status bar)
maw view dev --clean
```

View จัดกลุ่ม tmux sessions ให้เป็นระเบียบ เหมือน IDE tabs

## Monitoring Pattern: Daily Routine

```bash
# เช้า: ปลุก + ดูสถานะ
maw wake all --resume
maw oracle ls
maw peek

# ระหว่างวัน: spot check
maw peek dev        # Dev ทำอะไรอยู่?
maw task ls         # มี blocker ไหม?

# เย็น: สรุป
maw tokens          # ใช้ tokens เท่าไหร่
maw chat dev        # Dev ทำอะไรบ้าง
```

## Think & Review

```bash
# ให้ Oracle เสนอ ideas
maw think

# เฉพาะบาง Oracle
maw think --oracles dev,qa

# BoB review proposals
maw review
```

Think cycle ให้ Oracle **คิดเอง** — เสนอ improvements, หา bugs, แนะนำ features
แล้ว BoB review ว่าอันไหนน่าทำ

## Meeting

```bash
# จัดประชุม
maw meeting "plan Q2 roadmap"

# dry run (ดูว่าใครจะเข้าประชุม)
maw meeting "plan Q2 roadmap" --dry-run

# เฉพาะบาง Oracle
maw meeting "review security" --oracles dev,qa,admin
```

maw ปลุก Oracle ที่เกี่ยวข้อง → ส่ง topic → รวบรวม input → สรุป

## ลองทำ

1. ดูสถานะ: `maw oracle ls`
2. Peek ทั้งทีม: `maw peek`
3. ดู tokens: `maw tokens`
4. ลอง chat log: `maw chat <oracle>`

---

→ [บทที่ 7: Patterns จริงจากทีม](07-real-patterns.md)
