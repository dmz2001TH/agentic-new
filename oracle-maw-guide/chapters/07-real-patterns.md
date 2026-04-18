# บทที่ 7: Patterns จริงจากทีม

ทฤษฎีเรียนจบแล้ว — บทนี้คือ patterns จริงจากทีม Oracle ที่ทำงานมาหลายเดือน

## Pattern 1: Result Chain

ส่งงานต่อเป็น chain — Oracle หนึ่งเสร็จ → ส่งต่อ Oracle ถัดไป

```
Dev (แก้ code) → QA (test) → Admin (deploy) → Writer (release notes)
```

```bash
# Dev แก้เสร็จ
maw talk-to qa "Dev fix #50 เสร็จ — test ให้หน่อย"
maw talk-to bob "cc: #50 ส่ง QA test"

# QA test ผ่าน
maw talk-to admin "QA passed #50 — deploy ได้"
maw talk-to bob "cc: #50 QA passed, ส่ง Admin deploy"

# Admin deploy เสร็จ
maw talk-to writer "v2.1 deployed — เขียน release notes"
maw talk-to bob "cc: #50 deployed, Writer ทำ release notes"
```

**หลักการ**: ทุก handoff ต้อง cc BoB — BoB เห็นภาพรวมทั้ง chain

## Pattern 2: Morning Standup

ทุกเช้า Oracle ทุกตัวรายงานสถานะ

```bash
# Loop ที่ตั้งไว้ (ทุกเช้า 9:00)
# BoB ปลุกทุกตัว → ถาม standup → รวบรวมสรุป

maw wake all --resume
maw meeting "morning standup — สถานะวันนี้"
```

**ผลลัพธ์**: BoB ได้ summary — ใครทำอะไร, อะไรค้าง, อะไร blocked

## Pattern 3: Guard Rails

Oracle มี safety rules — maw ช่วย enforce:

```bash
# cc BoB ทุกครั้ง (THE LAW)
maw talk-to bob "cc: [action]"

# Task logging (THE LAW)
maw task log #42 "Starting: ..."
maw task log #42 "Done: ..."

# Playwright session limit (max 2)
ls /tmp/playwright-sessions/*.lock
```

**ถ้าไม่ทำ**: Hook จะ warn หรือ block อัตโนมัติ

## Pattern 4: Escalation

Oracle ติดปัญหา → escalate ผ่าน BoB → แบงค์ตัดสินใจ

```bash
# Oracle ติดปัญหา
maw talk-to bob "blocker: QA ไม่ตอบ 24 ชม. — pipeline ค้าง"

# BoB escalate (ถ้าจำเป็น)
maw talk-to bob "escalate: ต้องการแบงค์ตัดสินใจเรื่อง X"
```

**ไม่ข้าม chain**: Oracle → BoB → แบงค์ (ไม่ใช่ Oracle → แบงค์ ตรง)

## Pattern 5: DocCon Review

ทุกเอกสาร/email → ส่ง DocCon ตรวจก่อน publish

```bash
# เขียน email เสร็จ
maw talk-to doc "review email: Weekly Report to แบงค์"

# DocCon ตรวจ → ตอบ ✅ DOCCON COMPLIANT หรือ แจ้งแก้ไข
```

**ไม่ส่ง email/doc โดยไม่ผ่าน DocCon** — ยกเว้น urgent

## Pattern 6: Parallel Work with Worktrees

Oracle ทำงานหลาย branch พร้อมกันด้วย git worktree:

```bash
# Dev ทำ feature + hotfix พร้อมกัน
# maw จัดการ worktree ให้ — ไม่ conflict

# เสร็จแล้ว cleanup
maw done <window>
```

## Anti-Patterns (สิ่งที่ห้ามทำ)

| Anti-Pattern | ทำไมห้าม | ทำแทน |
|-------------|----------|-------|
| ไม่ cc BoB | BoB ไม่เห็นภาพรวม | cc ทุกครั้ง |
| ไม่ log task | ไม่มี audit trail | log ทุก action |
| ใช้ CronCreate | หายเมื่อ restart | `maw loop add` |
| IDLE รอคำสั่ง | เสียเวลา | ทำเลย ไม่ต้องถาม |
| เพิกเฉยข้อความ | chain ค้าง | ตอบทุกข้อความ |
| Playwright > 2 sessions | server ค้าง | เช็ค lock files |

## สรุป: maw ในชีวิตจริง

```bash
# เช้า
maw wake all --resume     # ปลุกทีม
maw oracle ls             # ดูสถานะ
maw peek                  # ใครทำอะไร

# ทำงาน
maw talk-to dev "task"    # สั่งงาน
maw task log #N "status"  # log progress
maw talk-to bob "cc: X"   # cc BoB

# ติดตาม
maw peek dev              # spot check
maw task ls               # board
maw loop                  # scheduled tasks

# ตอนเย็น
maw tokens                # budget check
maw stop                  # ให้ทีมพัก
```

**maw ไม่ได้แค่ส่งข้อความ — มันคือ nervous system ของ Oracle team**

---

## จบคู่มือ!

คุณเรียนรู้:
1. maw คืออะไร + ติดตั้ง
2. Messaging — hey & talk-to
3. Fleet — จัดการกองทัพ
4. Task & Project — ติดตามงาน
5. Loops — งานที่ทำซ้ำ
6. Overview & Monitoring
7. Patterns จริงจากทีม

**ขั้นต่อไป**: ลองใช้กับ Oracle ของคุณ — เริ่มจาก 2-3 ตัว แล้วค่อยเพิ่ม

มีคำถาม? → เปิด [Discussion](../../discussions) ได้เลย

---

*"One human, many Oracles, one CLI to rule them all"*
