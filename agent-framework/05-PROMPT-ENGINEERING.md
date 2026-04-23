# 🎯 PROMPT-ENGINEERING.md — วิธีเขียน Prompt ให้ Agent เก่ง

> Prompt ที่ดี = Agent ที่เก่ง
> 80% ของ "ความเก่ง" อยู่ที่ prompt ไม่ใช่ model

---

## หลักการ 5 ข้อ

```
1. CLEAR    — ชัดเจน ไม่คลุมเครือ
2. COMPLETE — ข้อมูลครบ ไม่ต้องเดา
3. CONTEXT  — ให้บริบทเพียงพอ
4. CONSTRAIN — ระบุขอบเขตชัดเจน
5. EXAMPLE  — ให้ตัวอย่างเมื่อเป็นไปได้
```

---

## 1. System Prompt Structure

```
┌─────────────────────────────────┐
│ 1. IDENTITY — ใคร               │  ← SOUL.md
│ 2. RULES — กฎอะไร               │  ← CONSTITUTION.md
│ 3. LESSONS — เคยผิดอะไร          │  ← lessons/INDEX.md
│ 4. CONTEXT — ตอนนี้ทำอะไร        │  ← task-specific
│ 5. FORMAT — ตอบรูปแบบไหน        │  ← output format
└─────────────────────────────────┘
```

### ตัวอย่าง System Prompt ที่ดี:

```
คุณคือ GOD — Orchestrator ของ multi-agent system

## ตัวตน
- พูดตรง ไม่อ้อมค้อม
- ไม่ทำเองทุกอย่าง — ส่งงานให้ผู้เชี่ยวชาญ
- ถ้าไม่รู้ บอกว่าไม่รู้

## กฎ (ห้ามแหก)
1. ไม่ลบข้อมูลโดยไม่ backup
2. ไม่เดา — ถ้าไม่ชัด ถามก่อน
3. ทุก task ต้องผ่าน: UNDERSTAND → PLAN → EXECUTE

## สิ่งที่เคยผิด (ห้ามทำอีก)
- เคยแก้ database โดยไม่ backup → data สูญ
- เคยใช้ deprecated API → runtime error
- เคย deploy โดยไม่ test → production พัง

## Task ปัจจุบัน
{user_request}

## รูปแบบการตอบ
1. สรุปสิ่งที่เข้าใจ
2. วางแผนขั้นตอน
3. ระบุ agent ที่จะส่งงาน
4. ขอ confirm ก่อนลงมือ
```

---

## 2. Task Prompt Patterns

### Pattern A: Simple Direct Task

```
ทำ [สิ่งที่ทำ]
ข้อจำกัด: [สิ่งที่ห้าม]
ผลลัพธ์ที่ต้องการ: [expected output]
```

### Pattern B: Complex Multi-Step Task

```
เป้าหมาย: [สิ่งที่ต้องการ achieve ในที่สุด]

ขั้นตอน:
1. [step 1]
2. [step 2]
3. [step 3]

ข้อจำกัด:
- [constraint 1]
- [constraint 2]

ไฟล์ที่เกี่ยวข้อง:
- [file 1] — [ทำไมเกี่ยว]
- [file 2] — [ทำไมเกี่ยว]

ผลลัพธ์ที่ต้องการ:
- [output 1]
- [output 2]
```

### Pattern C: Debug/Fix Task

```
ปัญหา: [อธิบายปัญหา]

สิ่งที่สังเกต:
- [observation 1]
- [observation 2]

สิ่งที่ลองแล้ว:
- [attempt 1] → [ผลลัพธ์]
- [attempt 2] → [ผลลัพธ์]

สิ่งที่ต้องการ:
- หาสาเหตุ
- แก้ไข
- ป้องกันไม่ให้เกิดอีก
```

### Pattern D: Review Task

```
ตรวจ [สิ่งที่ตรวจ]

เกณฑ์การตรวจ:
- [criterion 1]
- [criterion 2]
- [criterion 3]

สิ่งที่ต้องการ:
- ระบุ issues (severity: critical/warning/suggestion)
- แนะนำวิธีแก้
- ให้ overall verdict: approve / request changes / reject
```

---

## 3. Few-Shot Examples

```
## ตัวอย่างการตอบที่ดี

### ตัวอย่าง 1: Task สำเร็จ
Input: "สร้าง function สำหรับ validate email"
Output:
**เข้าใจ:** ต้องสร้าง function ที่รับ string และ validate ว่าเป็น email format ถูกต้อง
**แผน:** 
1. สร้าง regex pattern สำหรับ email
2. เขียน function พร้อม error handling
3. เขียน test cases
**โค้ด:**
[โค้ด]
**Test:**
[tests]

### ตัวอย่าง 2: Task ไม่ชัด
Input: "แก้หน้านี้ให้สวย"
Output:
"หน้านี้" หมายถึงหน้าไหน? และ "สวย" สำหรับคุณหมายถึงอะไร?
ช่วยบอก:
1. URL หรือชื่อไฟล์
2. สิ่งที่อยากเปลี่ยน (สี, layout, font, etc.)
3. ตัวอย่าง design ที่ชอบ (ถ้ามี)
```

---

## 4. Anti-Patterns (สิ่งที่ไม่ควรทำ)

### ❌ Vague Prompt
```
"ช่วยแก้โค้ดให้หน่อย"
```
→ ไม่รู้แก้อะไร แก้ยังไง แก้ทำไม

### ❌ No Context
```
"สร้าง API สำหรับ user"
```
→ ไม่รู้ tech stack, schema, auth method, etc.

### ❌ No Constraints
```
" optimize ให้เร็วขึ้น"
```
→ ไม่รู้ "เร็ว" หมายถึงอะไร — response time? throughput? load time?

### ✅ Good Prompt
```
"แก้บัคใน src/auth/login.ts — user ที่ใช้ email ที่มี + (เช่น test+1@gmail.com) 
ไม่สามารถ login ได้ ต้องการให้ support email ที่มี special characters 
ตาม RFC 5321 ไม่แก้ schema database"
```

---

## 5. Output Format Control

### ระบุรูปแบบที่ต้องการ:

```
## รูปแบบการตอบ

### สำหรับ code:
```language
// code here
```
**ทำไมเขียนแบบนี้:** [explanation]

### สำหรับ analysis:
**สรุป:** [1-2 ประโยค]
**รายละเอียด:**
- [point 1]
- [point 2]
**ข้อเสนอแนะ:** [suggestion]

### สำหรับ decision:
**แนะนำ:** [option] — เพราะ [เหตุผล]
**ทางเลือกอื่น:**
- [option 2] — [ข้อดี/ข้อเสีย]
- [option 3] — [ข้อดี/ข้อเสีย]
```

---

## 6. Prompt Templates สำหรับ Project คุณ

### GOD Agent — Task Dispatch

```markdown
## Task Assignment

**Goal:** {task_description}
**Priority:** {high/medium/low}
**Assigned to:** {agent_name}

### Context
{relevant_context}

### Constraints
- {constraint_1}
- {constraint_2}

### Expected Output
- {output_1}
- {output_2}

### Success Criteria
- [ ] {criterion_1}
- [ ] {criterion_2}
```

### Coder Agent — Code Task

```markdown
## Code Task

**What to do:** {description}
**Where:** {file_path}
**Why:** {reason}

### Related Code
```{language}
{existing_code}
```

### Requirements
- {requirement_1}
- {requirement_2}

### Don't
- {dont_1}
- {dont_2}
```

### Reviewer Agent — Review Task

```markdown
## Review Request

**What to review:** {file/diff/PR}
**Focus on:**
- [ ] Correctness
- [ ] Edge cases
- [ ] Performance
- [ ] Security
- [ ] Readability

### Known Issues
- {issue_1}
- {issue_2}

### Output Format
For each issue:
- **Severity:** critical/warning/suggestion
- **Location:** {file:line}
- **Problem:** {description}
- **Fix:** {suggestion}
```
