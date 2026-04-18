# บทที่ 2: ส่งข้อความ — hey & talk-to

Oracle ที่คุยกันไม่ได้ = ทำงานคนเดียว
Oracle ที่คุยกันได้ = ทำงานเป็นทีม

maw มี 2 วิธีส่งข้อความ:

## 1. `maw hey` — ส่งตรง, เร็ว, ไม่เก็บ log

```bash
maw hey dev "deploy เวอร์ชัน 2.0 ให้หน่อย"
maw hey qa "review PR #42"
maw hey writer "เขียน release notes สำหรับ v2.0"
```

### วิธีทำงาน

1. maw หา tmux window ของ Oracle ที่ระบุ
2. พิมพ์ข้อความเข้าไปใน Claude Code session ของ Oracle นั้น
3. Oracle ได้รับข้อความ → ทำงาน

### shorthand

```bash
# เหมือนกัน
maw hey dev "message"
maw dev "message"
```

### ข้อจำกัด

- ไม่เก็บ log — ถ้า Oracle ไม่ได้ online ข้อความหาย
- ไม่มี audit trail — BoB ตรวจสอบไม่ได้
- เหมาะกับ **คำสั่งง่ายๆ** ที่ไม่ต้อง track

## 2. `maw talk-to` — ผ่าน Oracle Thread, เก็บ log

```bash
maw talk-to qa "review PR #42 — ดู security ด้วย"
maw talk-to bob "cc: deploy เสร็จแล้ว"
```

### วิธีทำงาน

1. บันทึกข้อความลง **Oracle thread** (oracle-v2 database)
2. ส่งข้อความไปยัง Oracle ผ่าน tmux (เหมือน hey)
3. Oracle ตอบกลับ → บันทึกลง thread อีกครั้ง

### ข้อดี

- **มี audit trail** — BoB และแบงค์ดูได้
- **persist ข้าม session** — ปิดแล้วเปิดใหม่ข้อความยังอยู่
- **ค้นหาได้** — หาข้อความเก่าได้จาก thread

### เมื่อไหร่ใช้อะไร?

| สถานการณ์ | ใช้ | เหตุผล |
|-----------|-----|--------|
| สั่งงานสำคัญ | `talk-to` | ต้อง track |
| cc BoB | `talk-to` | BoB ต้องเห็น |
| ถามเร็วๆ | `hey` | ไม่ต้อง log |
| MCP ล่ม | `hey` | fallback |

### THE LAW

> `/talk-to` คือวิธีหลักในการคุยกับ oracle อื่น
> ถ้า `/talk-to` ใช้ไม่ได้ (MCP ล่ม) → fallback ใช้ `maw hey`
> **cc BoB ทุกครั้ง**: `maw talk-to bob "cc: [สิ่งที่ทำ]"`

## ตัวอย่างจริง: สั่งงานข้าม Oracle

```bash
# 1. สั่ง Dev แก้ bug
maw talk-to dev "fix: API /users returns 500 when email is null"

# 2. cc BoB
maw talk-to bob "cc: สั่ง Dev fix API /users bug"

# 3. Dev แก้เสร็จ → สั่ง QA test
maw talk-to qa "Dev fix แล้ว — test API /users กับ null email"

# 4. QA ผ่าน → สั่ง Admin deploy
maw talk-to admin "QA passed — deploy to production"
```

flow: **มนุษย์ → Dev → QA → Admin** — ทุก step มี log ใน Oracle thread

## ลองทำ

1. ปลุก Oracle 2 ตัว (ถ้ามี):
   ```bash
   maw wake dev
   maw wake qa
   ```

2. ส่งข้อความ:
   ```bash
   maw hey dev "สวัสดี — ตอบกลับว่าได้รับข้อความ"
   ```

3. ดูว่า Dev ตอบไหม:
   ```bash
   maw peek dev
   ```

ถ้ายังมี Oracle ตัวเดียว — ไม่เป็นไร ลองส่งข้อความหาตัวเอง แล้วค่อยเพิ่มทีมทีหลัง

---

→ [บทที่ 3: Fleet — จัดการกองทัพ Oracle](03-fleet.md)
