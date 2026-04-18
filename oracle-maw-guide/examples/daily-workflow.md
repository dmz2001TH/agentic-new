# ตัวอย่าง: Daily Workflow

> วันทำงานจริงของทีม Oracle — ตั้งแต่เช้าถึงเย็น

## 07:00 — PA ส่ง Morning Briefing

```bash
# Loop trigger อัตโนมัติ
# PA scan Gmail + Calendar → สรุปเป็น email ส่งแบงค์

# แบงค์ได้ email:
# - 3 urgent emails
# - 2 meetings today
# - 5 tasks pending
```

## 09:00 — BoB ปลุกทีม

```bash
maw wake all --resume

# ทุก Oracle ตื่น → /recap → จำ context → พร้อมทำงาน
# BoB ดูสถานะ:
maw oracle ls
maw peek
```

## 09:30 — แบงค์สั่งงาน

```bash
# แบงค์เห็น bug report → สร้าง issue
# BoB assign:
maw talk-to dev "fix #50 — API timeout on large queries"
maw talk-to bob "cc: assigned #50 to Dev"
```

## 10:00 — Dev ทำงาน

```bash
# Dev เริ่ม
maw task log #50 "Starting: investigating timeout"

# Dev หา root cause
maw task log #50 "Found: missing index on users.email"

# Dev fix + commit
maw task log #50 --commit "abc123 add index on users.email"

# Dev เสร็จ → ส่งต่อ
maw talk-to qa "test #50 — API timeout fix"
maw talk-to bob "cc: #50 fixed, ส่ง QA"
```

## 11:00 — QA Test

```bash
# QA ได้ข้อความ → test
maw task comment #50 "Testing: API /users with 10K records"

# QA ผ่าน
maw task comment #50 "✅ PASS — response 200ms → 50ms"
maw talk-to admin "deploy #50 to production"
maw talk-to bob "cc: #50 QA passed"
```

## 12:00 — AIA Scan Email

```bash
# Loop trigger อัตโนมัติ
# AIA scan Gmail → categorize → draft replies
# cc BoB กับ urgent items
maw talk-to bob "cc: 2 urgent emails — SAM invoice + client inquiry"
```

## 14:00 — Admin Deploy

```bash
# Admin deploy
maw task log #50 "Deployed to production"
maw talk-to bob "cc: #50 live on production"

# Writer ทำ release notes
maw talk-to writer "เขียน changelog สำหรับ API timeout fix"
```

## 17:00 — BoB สรุป

```bash
# BoB review วันนี้
maw task ls         # อะไรเสร็จ อะไรค้าง
maw tokens          # ใช้ tokens เท่าไหร่
maw peek            # ใครยังทำอยู่

# สรุปให้แบงค์
maw talk-to bob "daily summary: #50 fixed + deployed, 3 emails handled"
```

## 20:00 — PA ส่ง Evening Summary

```bash
# Loop trigger อัตโนมัติ
# PA สรุปวันนี้ → email แบงค์
# ทีมพัก
maw stop
```

---

**ทั้งวัน**: 1 bug fix — ผ่าน 4 Oracle (Dev → QA → Admin → Writer) + PA + AIA + BoB monitoring
**ทุก step มี log** — แบงค์ดูย้อนหลังได้ทุกเมื่อ
