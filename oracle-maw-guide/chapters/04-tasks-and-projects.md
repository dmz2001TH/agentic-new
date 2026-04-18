# บทที่ 4: Task & Project — ติดตามงาน

Oracle หลายตัวทำงานพร้อมกัน — ถ้าไม่ track จะไม่รู้ว่าใครทำอะไร อะไรค้าง อะไรเสร็จ

maw มีระบบ task และ project ที่ทำงานบน **GitHub Issues** — ทุกอย่างอยู่ใน GitHub ค้นหาได้ ดูได้จาก dashboard

## Task = GitHub Issue

ทุก task ใน Oracle system คือ GitHub Issue — มี issue number, labels, assignee

### ดู Board

```bash
# ดูทุก task
maw task ls
```

ได้ผลแบบนี้:

```
#42  [In Progress]  Dev    Fix API /users 500 error       (3 logs)
#43  [Todo]         QA     Test payment flow              (0 logs)
#44  [Done]         Writer Release notes v2.0             (5 logs)
```

### Log กิจกรรม

ทุกครั้งที่ Oracle ทำงาน — ต้อง log:

```bash
# เริ่มงาน
maw task log #42 "Starting: investigating 500 error"

# commit
maw task log #42 --commit "abc123 fix null email handling"

# ติดปัญหา
maw task log #42 --blocker "need DB access credentials"

# เสร็จ
maw task log #42 "Done: API returns 200 now, tested locally"
```

### ดู Timeline ของ Task

```bash
maw task show #42
```

เห็นทุก log เรียงตามเวลา — ใครทำอะไร เมื่อไหร่ ติดอะไร

### Comment ข้าม Oracle

```bash
# QA comment บน task ของ Dev
maw task comment #42 "Tested — PASS, deploy ได้เลย"
```

Comment เห็นทุก Oracle — เหมือน Slack แต่ติดอยู่กับ task

## Project = กลุ่มของ Tasks

Task เยอะขึ้น → จัดกลุ่มเป็น Project

### สร้าง Project

```bash
maw project create api-v2 "API Version 2.0 Overhaul"
```

### เพิ่ม Task เข้า Project

```bash
maw project add api-v2 #42
maw project add api-v2 #43
maw project add api-v2 #44

# เพิ่มเป็น subtask
maw project add api-v2 #45 --parent #42
```

### ดู Project

```bash
# ดูทุก project
maw project ls

# ดู tree view
maw project show api-v2
```

```
api-v2: API Version 2.0 Overhaul
├── #42 [Done] Fix API /users 500 error
│   └── #45 [In Progress] Add input validation
├── #43 [Todo] Test payment flow
└── #44 [Done] Release notes v2.0

Progress: 2/4 (50%)
```

### จัดการ Project

```bash
# Comment บน project
maw project comment api-v2 "Week 1 done — 50% complete"

# Auto-organize tasks ที่ยังไม่มี project
maw project auto-organize

# Mark complete
maw project complete api-v2

# Archive
maw project archive api-v2
```

## THE LAW: ทุกงานต้อง Log

> ห้ามทำงานโดยไม่ log — BoB และแบงค์ต้องเห็นทุก movement บน dashboard

```bash
# เริ่ม → log
maw task log #42 "Starting: brief description"

# Commit → log
maw task log #42 --commit "hash commit message"

# ติดปัญหา → log
maw task log #42 --blocker "stuck on X"

# เสร็จ → log
maw task log #42 "Done: summary"
```

## ตัวอย่างจริง: Bug Fix Flow

```bash
# 1. มนุษย์สร้าง issue บน GitHub → #50

# 2. BoB assign ให้ Dev
maw hey dev "fix #50 — API timeout on large queries"

# 3. Dev เริ่มงาน
maw task log #50 "Starting: investigating timeout"

# 4. Dev หา root cause
maw task log #50 "Found: missing index on users.email"

# 5. Dev fix + commit
maw task log #50 --commit "abc123 add index on users.email"

# 6. Dev เสร็จ → cc BoB + สั่ง QA
maw talk-to bob "cc: #50 fixed, ส่ง QA test"
maw talk-to qa "test #50 — API timeout fix, ดู response time"

# 7. QA test
maw task comment #50 "Tested: response time 200ms → 50ms ✅ PASS"

# 8. Admin deploy
maw task log #50 "Done: deployed to production"
```

## ลองทำ

1. ดู board: `maw task ls`
2. ดู projects: `maw project ls`
3. ถ้ามี task → ลอง: `maw task show #<number>`

---

→ [บทที่ 5: Loops — งานที่ทำซ้ำ](05-loops.md)
