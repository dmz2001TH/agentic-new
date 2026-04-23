# 🏗️ ARCHITECTURE.md — สถาปัตยกรรม Multi-Agent

> ออกแบบระบบ agent ให้ทำงานร่วมกันได้อย่างมีประสิทธิภาพ

---

## หลักการออกแบบ

```
1. แต่ละ agent มี responsibility เดียวชัดเจน
2. สื่อสารผ่าน structured messages
3. ทุก output ต้องผ่าน validation
4. Fail fast — ถ้าทำไม่ได้ บอกทันที
```

---

## System Architecture

```
                    ┌─────────────────┐
                    │     USER        │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   GATEWAY       │ ← รับ input, route ไปยัง agent ที่ถูกต้อง
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  GOD (Planner)  │ ← วางแผน, กระจายงาน, ตัดสินใจ
                    └────────┬────────┘
                             │ dispatch
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
     ┌────────────┐  ┌────────────┐  ┌────────────┐
     │   CODER    │  │ RESEARCHER │  │  REVIEWER  │
     │ เขียนโค้ด  │  │ หาข้อมูล   │  │  ตรวจโค้ด  │
     └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
           │               │               │
           └───────────────┼───────────────┘
                           ▼
                  ┌─────────────────┐
                  │   VALIDATOR     │ ← ตรวจสอบผลลัพธ์
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ MEMORY-KEEPER   │ ← บันทึกผลลัพธ์, lessons
                  └─────────────────┘
```

---

## Agent Roles

### GOD (Orchestrator)

```
Responsibility: วางแผน, กระจายงาน, ตัดสินใจ
Input:          User request
Output:         Task assignments → แต่ละ agent

Rules:
- ไม่ทำเอง — ส่งงานให้ผู้เชี่ยวชาญ
- ต้องเข้าใจ task ก่อน dispatch
- ต้องรวมผลลัพธ์ก่อนส่งกลับให้ user
- ต้อง handle failure — ถ้า agent ไหน fail ต้องมี backup plan
```

### CODER (Worker)

```
Responsibility: เขียนโค้ด, แก้บัค, refactor
Input:          Task spec + context
Output:         Code + tests + explanation

Rules:
- ต้องเข้าใจ codebase ก่อนแก้
- ต้องเขียน test สำหรับโค้ดใหม่
- ต้อง explain ว่าทำอะไร ทำไม
- ไม่แก้ไฟล์ที่ไม่เกี่ยวกับ task
```

### RESEARCHER (Worker)

```
Responsibility: หาข้อมูล, ค้นหา, วิเคราะห์
Input:          Query + scope
Output:         Findings + sources

Rules:
- ต้อง cite แหล่งที่มา
- ต้อง cross-check ข้อมูล
- ไม่สร้างข้อมูลเท็จ
- สรุปให้กระชับ ไม่ copy ทั้งหมด
```

### REVIEWER (Validator)

```
Responsibility: ตรวจโค้ด, ตรวจผลลัพธ์, ให้ feedback
Input:          Code/output ที่ต้องตรวจ
Output:         Review + approval/rejection + suggestions

Rules:
- ตรวจทั้ง correctness และ quality
- ให้ feedback ที่ actionable
- ไม่ approve ถ้ามี issue ที่แก้ได้
- ระบุ severity: critical / warning / suggestion
```

### MEMORY-KEEPER (Support)

```
Responsibility: จัดการความจำ, บันทึก lessons
Input:          Events, decisions, mistakes
Output:         Relevant context, lessons learned

Rules:
- บันทึกทุก decision ที่สำคัญ
- บันทึกทุก mistake + lesson
- filter relevance ก่อน inject context
- compress old memories ไม่ให้ context บาน
```

---

## Message Protocol

### Task Assignment (GOD → Worker)

```json
{
  "type": "task_assign",
  "from": "god",
  "to": "coder",
  "task_id": "task_001",
  "priority": "high",
  "spec": {
    "goal": "แก้บัค login page ที่ user ไม่สามารถ submit ได้",
    "context": "ไฟล์ที่เกี่ยวข้อง: src/auth/login.ts",
    "constraints": ["ไม่แก้ schema database", "backward compatible"],
    "expected_output": "โค้ดที่แก้แล้ว + test",
    "deadline": "2026-04-23T19:00:00Z"
  }
}
```

### Task Result (Worker → GOD)

```json
{
  "type": "task_result",
  "from": "coder",
  "to": "god",
  "task_id": "task_001",
  "status": "success",
  "result": {
    "changes": ["src/auth/login.ts: fixed validation logic"],
    "tests": ["tests/auth/login.test.ts: added edge case tests"],
    "explanation": "ปัญหาเกิดจาก validation logic ที่ไม่ handle empty string"
  },
  "confidence": 0.95
}
```

### Validation Result (Reviewer → GOD)

```json
{
  "type": "validation_result",
  "from": "reviewer",
  "to": "god",
  "task_id": "task_001",
  "verdict": "approved_with_suggestions",
  "issues": [
    {
      "severity": "suggestion",
      "file": "src/auth/login.ts",
      "line": 42,
      "message": "อาจใช้ optional chaining แทน explicit check"
    }
  ]
}
```

---

## Workflow Patterns

### Pattern 1: Simple Task (Single Agent)

```
User → GOD → Coder → GOD → User
```

### Pattern 2: Complex Task (Multi-Agent)

```
User → GOD → Researcher (หาข้อมูล)
                ↓
             Coder (เขียนโค้ด)
                ↓
             Reviewer (ตรวจ)
                ↓
             GOD → User
```

### Pattern 3: Iterative (Review Loop)

```
User → GOD → Coder → Reviewer
                ↑         │
                └─── fail ─┘ (แก้แล้วส่งตรวจใหม่)
                        │
                      pass
                        ↓
                     GOD → User
```

### Pattern 4: Parallel (เร็วขึ้น)

```
User → GOD ─┬→ Coder A (ส่วน frontend)
            ├→ Coder B (ส่วน backend)
            └→ Researcher (หา API docs)
                    │
                    ▼
             Reviewer (ตรวจทั้งหมด)
                    │
                    ▼
                  GOD → User
```

---

## Context Injection

### ทุก Agent ต้องได้รับ Context เหล่านี้:

```markdown
## System Context (inject ทุกครั้ง)
- [SOUL.md] — ตัวตน agent
- [CONSTITUTION.md] — กฎที่ต้องยึด
- [lessons/*.md] — สิ่งที่เคยผิด (relevance-filtered)

## Task Context (inject ตาม task)
- [task spec] — สิ่งที่ต้องทำ
- [related files] — ไฟล์ที่เกี่ยวข้อง
- [previous attempts] — ถ้าเคยลองแล้วผิด

## Project Context (inject ครั้งเดียวตอน start)
- [project structure] — โครงสร้าง project
- [tech stack] — เทคโนโลยีที่ใช้
- [conventions] — coding standards
```

---

## Failure Handling

```
Agent fail?
├── ถ้าเป็น Worker → ส่งกลับ GOD → ลอง agent อื่น หรือ simplify task
├── ถ้าเป็น Reviewer → GOD ตรวจเอง
├── ถ้าเป็น GOD → ถาม user ตรงๆ
└── ทุก failure → บันทึกใน lessons/
```
