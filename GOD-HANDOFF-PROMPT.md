# GOD Handoff Prompt — Real Learning System Upgrade

ก่อนเริ่มทำงาน รันคำสั่งนี้ก่อน:

```bash
cd /path/to/agentic-new  # เปลี่ยนเป็น path จริง
git pull origin master
```

## สิ่งที่เปลี่ยนไป (ต้องรู้)

### 1. Commands ที่แก้ไขแล้ว (9 ตัว)

ทุก command ต่อไปนี้มี **verification** แล้ว — ห้าม summarize ลอยๆ ต้อง verify ทุกครั้ง:

| Command | สิ่งที่เปลี่ยน |
|---------|---------------|
| `/learn` | ต้องใช้ `scripts/learn/timed-learn.sh` → fetch จริง → evidence → quiz → `learn-verify.sh` → grade ≥ B |
| `/rrr` | ต้องสร้างจาก data จริง (inbox, notes, learnings) → verify ≥ 200 chars, ≥ 3 sections |
| `/recap` | ต้อง `cat` ไฟล์จริง (handoff.md, retro, inbox, notes) → ห้ามเดา |
| `/fyi` | ต้อง `echo >>` ลงไฟล์จริง → `tail -1` verify ว่าบันทึกสำเร็จ |
| `/feel` | ต้อง `echo >>` ลง notes.md + user-preferences.md → verify |
| `/forward` | ต้องรวบรวมจาก inbox/learnings/decisions จริง → verify ≥ 300 chars |
| `/execute` | ต้อง `sed` เปลี่ยนสถานะไฟล์จริง → `grep` verify |
| `/review` | ต้องตรวจไฟล์จริง + นับ subtasks + verify output |
| `/full-install` | ต้อง `mkdir`, `echo` จริง + verify ทุกขั้นตอน |

### 2. Scripts ใหม่ (ต้องใช้)

```bash
# Learning system (แทน /learn เดิม)
bash scripts/learn/timed-learn.sh "topic" 10 https://url1 https://url2
bash scripts/learn/learn-verify.sh <session_id>
bash scripts/learn/learn-history.sh

# Status bar (แสดง real-time ว่ากำลังทำอะไร)
bash scripts/god-status.sh update god Learn "topic" 01:10
bash scripts/god-status.sh update builder Edit "file" 01:05
bash scripts/god-status.sh show
bash scripts/god-status.sh clear

# Oracle tools (cross-platform แล้ว)
source scripts/oracle-tools.sh
oracle_health
fleet_status
```

### 3. กฎใหม่ (บังคับทุก command)

**ห้าม:**
- ❌ summarize ลอยๆ โดยไม่มี evidence
- ❌ บอก "เสร็จ" ก่อน verify
- ❌ fake timeline หรือ fake countdown
- ❌ บอก "บันทึกแล้ว" ถ้าไม่ได้ echo ลงไฟล์จริง
- ❌ บอก "อ่านแล้ว" ถ้าไม่ได้ cat ไฟล์จริง

**ต้อง:**
- ✅ ทำจริง (echo/sed/cat ลงไฟล์)
- ✅ verify ทุกครั้ง (grep/tail/wc ตรวจผล)
- ✅ มี evidence (source reference, ข้อมูลจริง)
- ✅ ซื่อสัตย์ (บอก "ไม่มี" ถ้าไม่มี)

### 4. Status Bar (ต้องใช้เมื่อทำงาน)

ทุกครั้งที่เริ่มงาน ต้องอัพเดท status:

```bash
# เริ่มงาน
bash scripts/god-status.sh update <agent> <action> "<target>" <deadline>

# ตัวอย่าง
bash scripts/god-status.sh update god Learn "React Server Components" 01:15
bash scripts/god-status.sh update builder Edit "maw-js/src/api/server.ts" 01:10

# เสร็จงาน
bash scripts/god-status.sh update god idle "" ""
```

### 5. Learning Flow ใหม่ (ต้องทำตาม)

```
1. bash scripts/learn/timed-learn.sh "topic" 10 https://urls...
2. อ่าน sources/ ที่ fetch มา
3. บันทึก evidence → evidence/log.jsonl
4. ทำ quiz → quiz/quiz.md
5. เขียน report → report.md (honest assessment)
6. bash scripts/learn/learn-verify.sh <session_id>
7. ต้องได้ grade ≥ B ถึงถือว่าเรียนเสร็จ
```

### 6. Documentation

อ่านไฟล์นี้เพื่อเข้าใจระบบทั้งหมด:
```
REAL-LEARNING-UPGRADE.md
```

---

## ⚡ Quick Start หลัง git pull

```bash
# 1. Source tools
source scripts/oracle-tools.sh

# 2. ดูสถานะ
bash scripts/god-status.sh show
bash scripts/oracle-tools.sh fleet

# 3. ดู goals ค้าง
bash scripts/oracle-tools.sh goals

# 4. ดู learning sessions ที่ผ่านมา
bash scripts/learn/learn-history.sh

# 5. เริ่มทำงาน — อัพเดท status ก่อน!
bash scripts/god-status.sh update god Think "planning next steps" ""
```

---

**สำคัญที่สุด:** ทุก command ที่เคย "summarize and pretend" ตอนนี้ต้อง **ทำจริง + verify** แล้ว ไม่มี theater เหลือแล้ว

อ่าน `REAL-LEARNING-UPGRADE.md` เพื่อดูรายละเอียดทั้งหมด
