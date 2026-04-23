# 📚 LESSONS-SYSTEM.md — ระบบเรียนรู้จากความผิดพลาด

> Agent ที่ไม่ learn from mistakes = agent ที่ทำผิดซ้ำๆ
> ระบบนี้ทำให้ agent จำและไม่ทำผิดแบบเดิมอีก

---

## โครงสร้างไฟล์

```
lessons/
├── INDEX.md              ← สรุป lessons ทั้งหมด (inject เข้า prompt)
├── 2026-04-20.md         ← บันทึกตามวัน
├── 2026-04-21.md
└── categories/
    ├── code-quality.md   ← จัดกลุ่มตามหมวด
    ├── security.md
    └── communication.md
```

---

## รูปแบบการบันทึก

### ทุก Lesson ต้องมี:

```markdown
## [วันที่] — [หัวข้อสั้นๆ]

### สิ่งที่ผิด
[อธิบายสั้นๆ ว่าทำอะไรผิด]

### สาเหตุ
[ทำไมถึงผิด — root cause]

### ผลกระทบ
[ผิดแล้วเกิดอะไรขึ้น]

### กฎใหม่
[กฎที่ต้องเพิ่ม — เขียนเป็น instruction ชัดเจน]

### ตัวอย่าง
❌ [สิ่งที่ผิด]
✅ [สิ่งที่ถูก]
```

---

## ตัวอย่าง Lesson

```markdown
## 2026-04-20 — แก้ database โดยไม่ backup

### สิ่งที่ผิด
สั่ง ALTER TABLE โดยไม่ backup ก่อน → data สูญหาย

### สาเหตุ
รีบทำ ไม่คิดว่าจะผิด

### ผลกระทบ
- data 10,000 rows สูญ
- ต้อง restore จาก backup เก่า 3 วัน
- user ไม่พอใจ

### กฎใหม่
ก่อนแก้ database structure ต้อง backup เสมอ
ไม่มีข้อยกเว้น

### ตัวอย่าง
❌ ALTER TABLE users ADD COLUMN age INT;
✅ 
   1. mysqldump -u root -p mydb > backup_2026-04-20.sql
   2. ALTER TABLE users ADD COLUMN age INT;
   3. ตรวจสอบ backup ว่า restore ได้
```

---

## INDEX.md — สรุปสำหรับ Inject

```markdown
# Lessons Index

## ⛔ Critical Rules (ห้ามแหก)
1. ต้อง backup ก่อนแก้ database
2. ไม่ commit credentials
3. ไม่ deploy โดยไม่ผ่าน test

## ⚠️ Warnings (ระวัง)
1. เช็ค API version ก่อนใช้ — เคยใช้ deprecated แล้วพัง
2. ไม่ assume input format — เคยเจอ unexpected null แล้ว crash
3. เช็ค edge cases — เคยเจอ empty array แล้ว error

## 💡 Tips (ช่วยได้)
1. ใช้ optional chaining แทน explicit null check
2. เขียน test ก่อนเขียนโค้ด (TDD) — ได้โค้ดที่ดีกว่า
3. Break task ใหญ่เป็น task เล็ก — จัดการง่ายกว่า
```

---

## Workflow: เมื่อไหร่ต้องบันทึก

```
Event happens
├── Agent ทำผิด → บันทึก lesson
├── User แก้ไขสิ่งที่ agent ทำ → บันทึก lesson
├── Agent ค้นพบวิธีที่ดีกว่า → บันทึก lesson
├── Task สำเร็จด้วยวิธีใหม่ → บันทึก best practice
└── Feedback จาก user → บันทึก preference
```

---

## Inject เข้า System Prompt

```python
def build_system_prompt(agent_soul, constitution, current_task):
    # 1. Soul (ตัวตน)
    prompt = read("SOUL.md")
    
    # 2. Constitution (กฎ)
    prompt += read("CONSTITUTION.md")
    
    # 3. Relevant lessons (เฉพาะที่เกี่ยวข้อง)
    lessons = get_relevant_lessons(
        task=current_task,
        max_lessons=5,
        categories=get_task_categories(current_task)
    )
    prompt += f"""
## สิ่งที่เคยผิด — ห้ามทำอีก
{format_lessons(lessons)}
"""
    
    # 4. Task context
    prompt += f"""
## Task ปัจจุบัน
{current_task}
"""
    return prompt
```

---

## Relevance Filter

```python
def get_relevant_lessons(task, max_lessons=5, categories=None):
    """
    เลือกเฉพาะ lessons ที่เกี่ยวข้องกับ task ปัจจุบัน
    ไม่ inject ทุก lesson — แค่ที่ relevant
    """
    all_lessons = load_all_lessons()
    
    # Filter by category
    if categories:
        all_lessons = [l for l in all_lessons if l.category in categories]
    
    # Filter by recency (ให้ lesson ใหม่มาก่อน)
    all_lessons.sort(key=lambda l: l.date, reverse=True)
    
    # Filter by relevance (keyword matching + semantic similarity)
    scored = []
    for lesson in all_lessons:
        score = calculate_relevance(task, lesson)
        scored.append((score, lesson))
    
    scored.sort(reverse=True)
    return [lesson for _, lesson in scored[:max_lessons]]
```

---

## Maintenance

### ทุกสัปดาห์:
- Review lessons ที่บันทึกมา
- ย้าย lessons ที่ยังไม่ได้ categorized ไป categories/
- Update INDEX.md

### ทุกเดือน:
- ลบ lessons ที่ไม่ relevant แล้ว
- รวม lessons ที่คล้ายกัน
- สรุป pattern ที่เห็นบ่อย
