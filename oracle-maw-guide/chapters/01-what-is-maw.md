# บทที่ 1: maw คืออะไร + ติดตั้ง

## maw = Multi-Agent Workflow

maw เป็น CLI ที่สร้างมาเพื่อจัดการ Oracle หลายตัว ทำงานบน **tmux** (terminal multiplexer)

### ทำไมต้อง maw?

ถ้ามี Oracle ตัวเดียว — ไม่จำเป็นต้องใช้ maw
แต่พอมี 3-10 ตัว — การสลับ terminal ไปมาจะยุ่งมาก

maw แก้ปัญหานี้:

| ปัญหา | maw แก้ยังไง |
|--------|-------------|
| สลับ terminal ไม่ถูก | `maw peek dev` — ดูได้จากที่เดียว |
| ลืมว่าใครทำอะไร | `maw oracle ls` — สถานะทุกตัว |
| ส่งข้อความไม่ถึง | `maw hey dev "message"` — ส่งตรง |
| ปลุก Oracle ทีละตัว | `maw wake all` — ปลุกทั้งทีม |

### Architecture

```
┌─────────────────────────────────────┐
│            มนุษย์ (คุณ)               │
│         พิมพ์คำสั่ง maw               │
└──────────────┬──────────────────────┘
               │
        ┌──────▼──────┐
        │    maw CLI   │
        │  (Node.js)   │
        └──────┬──────┘
               │
    ┌──────────┼──────────┐
    │          │          │
┌───▼──┐  ┌───▼──┐  ┌───▼──┐
│ tmux  │  │ tmux  │  │ tmux  │
│ Dev   │  │  QA   │  │Writer │
│Oracle │  │Oracle │  │Oracle │
└───────┘  └───────┘  └───────┘
```

maw ใช้ tmux เป็น transport layer — ส่งข้อความโดยพิมพ์เข้า tmux pane ของแต่ละ Oracle

## ติดตั้ง

### สิ่งที่ต้องมี

1. **Node.js 18+** หรือ **Bun** — runtime
2. **tmux** — terminal multiplexer
3. **Claude Code** — ติดตั้งแล้วจาก Step 0

### ติดตั้ง tmux

```bash
# macOS
brew install tmux

# Ubuntu/WSL
sudo apt install tmux
```

### ติดตั้ง maw

```bash
# Clone maw-js
ghq get BankCurfew/maw-js
# หรือ
git clone https://github.com/BankCurfew/maw-js.git

# เข้า directory
cd maw-js

# Install dependencies
bun install
# หรือ npm install

# Link เป็น global command
bun link
# หรือ npm link
```

### ทดสอบ

```bash
maw ls
```

ถ้าเห็น session list (อาจว่างเปล่า) = ติดตั้งสำเร็จ

## tmux พื้นฐาน

maw ทำงานบน tmux — คุณไม่จำเป็นต้องรู้ tmux ลึก แต่เข้าใจพื้นฐานจะช่วยมาก:

```bash
# สร้าง session ใหม่
tmux new -s oracle

# แยก pane
Ctrl+b %        # แยกซ้าย-ขวา
Ctrl+b "        # แยกบน-ล่าง

# สลับ pane
Ctrl+b ลูกศร    # ไปทิศที่ต้องการ

# ออกจาก tmux (ไม่ปิด)
Ctrl+b d         # detach
```

แต่ปกติ **maw จัดการให้หมด** — คุณแค่สั่ง `maw wake` แล้ว maw สร้าง tmux window ให้เอง

## ตรวจสอบว่าพร้อม

```bash
# ✅ maw ทำงาน
maw ls

# ✅ tmux ทำงาน
tmux -V

# ✅ Claude Code ทำงาน
claude --version
```

ถ้าทั้ง 3 อย่างผ่าน → พร้อมไปบทต่อไป

---

→ [บทที่ 2: ส่งข้อความ — hey & talk-to](02-messaging.md)
