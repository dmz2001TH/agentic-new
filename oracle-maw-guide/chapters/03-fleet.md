# บทที่ 3: Fleet — จัดการกองทัพ Oracle

พอ Oracle เกิน 3 ตัว — ต้องมีระบบจัดการ
Fleet คือระบบนั้น

## Fleet คืออะไร?

Fleet = **กลุ่ม Oracle ที่ทำงานบน tmux** พร้อม config ที่บอกว่าแต่ละตัวอยู่ window ไหน

```bash
maw oracle ls
```

ได้ผลแบบนี้:

```
01-bob       ● awake    BankCurfew/BoB-Oracle
02-dev       ● awake    BankCurfew/Dev-Oracle
03-qa        ○ sleeping BankCurfew/QA-Oracle
04-writer    ● awake    BankCurfew/Writer-Oracle
05-admin     ○ sleeping BankCurfew/Admin-Oracle
```

## Wake & Sleep

### ปลุก Oracle

```bash
# ปลุกทีละตัว
maw wake dev

# ปลุกพร้อม task
maw wake dev "fix API bug #42"

# ปลุกจาก GitHub issue
maw wake dev --issue 42

# ปลุกทั้งทีม
maw wake all

# ปลุกทั้งทีม + ส่ง /recap ให้ด้วย
maw wake all --resume
```

### ให้นอน

```bash
# Oracle เดียว
maw sleep dev

# ทั้งทีม
maw stop
```

## Peek — ดูว่าใครทำอะไร

```bash
# ดูทุกตัว (สรุปบรรทัดเดียว)
maw peek

# ดูตัวเดียว (เห็นหน้าจอเต็ม)
maw peek dev
```

`maw peek` คือ "มองเข้าไปใน terminal" ของ Oracle นั้น — เห็นว่ากำลังพิมพ์อะไร ทำอะไรอยู่

## Fleet Config

แต่ละ Oracle มี fleet config อยู่ที่ `~/.maw/fleet/`:

```json
{
  "oracle": "dev",
  "window": 2,
  "repo": "BankCurfew/Dev-Oracle",
  "tmux": "02-dev:0",
  "dormant": false
}
```

### จัดการ Fleet

```bash
# สร้าง fleet config จาก ghq repos
maw fleet init

# ดู fleet ทั้งหมด
maw fleet ls

# ตรวจ conflicts (เลข window ซ้ำ)
maw fleet validate

# แก้เลข window ให้เรียง
maw fleet renumber

# เพิ่ม window ที่ไม่มี config
maw fleet sync
```

### Profile ของ Oracle

```bash
# ดู profile ละเอียด
maw about dev
```

จะเห็น: session info, worktrees, fleet config, repo path

## Overview — War Room

```bash
# เปิด war room — เห็นทุก Oracle ใน split panes
maw overview

# เฉพาะบางตัว
maw overview dev qa writer

# ปิด
maw overview --kill
```

Overview เหมาะกับจอใหญ่ — เห็นทุกตัวพร้อมกัน เหมือนห้อง control room

## ตัวอย่างจริง: เช้าวันทำงาน

```bash
# 1. ปลุกทีม + ส่ง /recap
maw wake all --resume

# 2. ดูสถานะ
maw oracle ls

# 3. ดูว่าใครกำลังทำอะไร
maw peek

# 4. เปิด war room
maw overview
```

5 นาทีก็พร้อม — Oracle ทุกตัวตื่น จำ context เดิม พร้อมทำงาน

## ลองทำ

1. ดูสถานะ fleet: `maw oracle ls`
2. ปลุก Oracle: `maw wake <your-oracle>`
3. ดูหน้าจอ: `maw peek <your-oracle>`
4. ดู about: `maw about <your-oracle>`

---

→ [บทที่ 4: Task & Project — ติดตามงาน](04-tasks-and-projects.md)
