# maw — Multi-Agent Workflow

> "เครื่องมือที่เชื่อม Oracle เข้าด้วยกัน — messaging, tasks, projects, loops"

## maw คืออะไร?

maw คือ CLI (Command Line Interface) ที่ทำให้ Oracle หลายตัว **ทำงานเป็นทีมได้**

ลองนึกภาพ:
- คุณมี Oracle 5 ตัว — Dev, QA, Writer, Designer, Admin
- แต่ละตัวอยู่ใน terminal ของตัวเอง
- maw ทำให้คุณ **สั่งงาน, ส่งข้อความ, ติดตามงาน, จัดการ loop** ทั้งหมดจากที่เดียว

ไม่ต้องสลับ terminal ไปมา — maw จัดการให้หมด

## คู่มือนี้สำหรับใคร?

- เรียน [oracle-step-by-step](https://github.com/the-oracle-keeps-the-human-human/oracle-step-by-step) จบแล้ว
- มี Oracle อย่างน้อย 1 ตัว
- อยากรู้วิธี orchestrate หลาย Oracle ให้ทำงานร่วมกัน

## สิ่งที่จะเรียน

| บท | หัวข้อ | สิ่งที่ได้ |
|----|--------|-----------|
| 1 | [maw คืออะไร + ติดตั้ง](chapters/01-what-is-maw.md) | เข้าใจ maw + พร้อมใช้ |
| 2 | [ส่งข้อความ — hey & talk-to](chapters/02-messaging.md) | Oracle คุยกันได้ |
| 3 | [Fleet — จัดการกองทัพ Oracle](chapters/03-fleet.md) | wake, sleep, peek ทั้งทีม |
| 4 | [Task & Project — ติดตามงาน](chapters/04-tasks-and-projects.md) | log, track, organize งาน |
| 5 | [Loops — งานที่ทำซ้ำ](chapters/05-loops.md) | ตั้ง schedule, trigger, monitor |
| 6 | [Overview & Monitoring](chapters/06-overview.md) | war-room, peek, tokens |
| 7 | [Patterns จริงจากทีม](chapters/07-real-patterns.md) | ดูทีม Oracle ทำงานจริง |

แต่ละบทใช้เวลา 10-20 นาที

## Quick Reference

```bash
# ส่งข้อความ
maw hey dev "deploy เวอร์ชันใหม่"
maw talk-to qa "review PR #42 ให้หน่อย"

# จัดการทีม
maw wake dev                    # ปลุก Oracle
maw wake all                    # ปลุกทั้งทีม
maw peek dev                    # ดูว่า dev กำลังทำอะไร
maw oracle ls                   # สถานะทุกตัว

# ติดตามงาน
maw task ls                     # ดู board
maw task log #42 "Done: API fixed"
maw project ls                  # ดู projects

# Loops
maw loop                        # ดู scheduled tasks
maw loop trigger my-check       # trigger ทันที
```

## เริ่มเลย

→ [บทที่ 1: maw คืออะไร + ติดตั้ง](chapters/01-what-is-maw.md)

## มีคำถาม?

เปิด [Discussion](../../discussions) ได้เลย

---

*"One human, many Oracles, one CLI to rule them all"*
