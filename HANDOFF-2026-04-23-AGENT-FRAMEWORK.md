# 🤝 HANDOFF — Agent Framework Implementation
**วันที่:** 2026-04-23 18:32 GMT+8
**ผู้สร้าง:** OpenClaw Agent (CLI session)
**Branch:** master
**Commit:** agent-framework v1.0

---

## 📋 สรุปสิ่งที่ทำ

สร้าง **Agent Framework** สำหรับ agentic-new project — ระบบทำให้ agent เก่งขึ้นผ่าน:
1. SOUL — ตัวตน/บุคลิกที่ชัดเจน
2. CONSTITUTION — กฎที่ไม่แหก
3. ARCHITECTURE — multi-agent design
4. LESSONS — เรียนรู้จากความผิดพลาด
5. PROMPT ENGINEERING — วิธีเขียน prompt ให้ดี

---

## ✅ สิ่งที่เสร็จแล้ว

### 1. Framework Files (7 ไฟล์)
```
agent-framework/
├── 01-SOUL-TEMPLATE.md        ✅ Template สำหรับสร้าง SOUL agent ทุกตัว
├── 02-CONSTITUTION.md          ✅ กฎรัฐธรรมนูญ 6 หมวด (Safety > Truth > User > ...)
├── 03-ARCHITECTURE.md          ✅ Multi-agent architecture + message protocol
├── 04-LESSONS-SYSTEM.md        ✅ ระบบบันทึก/เรียนรู้จากความผิดพลาด
├── 05-PROMPT-ENGINEERING.md    ✅ วิธีเขียน prompt + templates
├── 06-QUICK-START.md           ✅ Python code พร้อมใช้ (prompt_builder, lesson_logger, dispatcher)
└── 07-INTEGRATION.md           ✅ วิธีเชื่อมกับ project ที่มีอยู่แล้ว
```

### 2. Agent Definitions
```
agents/
├── CONSTITUTION.md             ✅ กฎกลางของ agent system ทั้งหมด
├── god/
│   └── SOUL.md                 ✅ ตัวตน GOD agent — Orchestrator
├── oracle/                     📁 สร้างไว้ ยังไม่มี SOUL.md
└── jarvis/                     📁 สร้างไว้ ยังไม่มี SOUL.md
```

### 3. Lessons System
```
lessons/
└── INDEX.md                    ✅ สรุป lessons + critical rules
```

---

## 🔄 Flow การทำงาน

```
┌──────────────────────────────────────────────────────────────┐
│                     WORKFLOW ปัจจุบัน                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  User Request                                                │
│       │                                                      │
│       ▼                                                      │
│  ┌─────────┐     ┌──────────────┐     ┌──────────────┐      │
│  │ JARVIS  │ ──→ │    GOD       │ ──→ │   Oracle     │      │
│  │ Gateway │     │ Orchestrator │     │  Worker      │      │
│  └─────────┘     └──────┬───────┘     └──────────────┘      │
│                         │                                    │
│                         ▼                                    │
│                  ┌──────────────┐                            │
│                  │  Reviewer    │  ← ตรวจผลลัพธ์              │
│                  └──────┬───────┘                            │
│                         │                                    │
│                         ▼                                    │
│                  ┌──────────────┐                            │
│                  │ GOD → User   │  ← สรุปผล                  │
│                  └──────────────┘                            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### GOD Agent Workflow (3-Step Protocol):
```
1. UNDERSTAND → สรุป task ให้ฟังก่อน
2. PLAN       → บอกขั้นตอน + agent ที่จะส่งงาน
3. EXECUTE    → ทำตามแผน + ตรวจผลแต่ละขั้น
```

### Message Format:
```json
{
  "type": "task_assign",
  "from": "god",
  "to": "oracle",
  "task_id": "task_001",
  "spec": {
    "goal": "...",
    "context": "...",
    "constraints": ["..."],
    "expected_output": "..."
  }
}
```

---

## 📂 สิ่งที่ต้องทำต่อ (TODO)

### Priority 1 — ทำทันที (สัปดาห์นี้)

| # | Task | สถานะ | หมายเหตุ |
|---|------|--------|---------|
| 1 | สร้าง SOUL.md สำหรับ Oracle agent | ✅ เสร็จแล้ว | agents/oracle/SOUL.md |
| 2 | สร้าง SOUL.md สำหรับ JARVIS agent | ✅ เสร็จแล้ว | agents/jarvis/SOUL.md |
| 3 | สร้าง SOUL.md สำหรับ Researcher agent | ✅ เสร็จแล้ว | agents/researcher/SOUL.md |
| 4 | สร้าง SOUL.md สำหรับ Reviewer agent | ✅ เสร็จแล้ว | agents/reviewer/SOUL.md |
| 5 | สร้าง prompt_builder.py | ✅ เสร็จแล้ว | ใช้ template จาก 06-QUICK-START.md |
| 6 | สร้าง lesson_logger.py | ✅ เสร็จแล้ว | ใช้ template จาก 06-QUICK-START.md |

### Priority 2 — ทำสัปดาห์หน้า

| # | Task | สถานะ | หมายเหตุ |
|---|------|--------|---------|
| 7 | เชื่อม prompt_builder กับ GOD-HANDOFF-PROMPT.md | ✅ เสร็จแล้ว | inject SOUL + CONSTITUTION + LESSONS เข้า prompt |
| 8 | เชื่อม lessons กับ brain-bridge.sh | ✅ เสร็จแล้ว | sync lessons ระหว่าง Google Drive ↔ Local |
| 9 | สร้าง MAW plugin สำหรับ lessons | ⏳ ยังไม่ทำ | maw-plugins/lesson-plugin.py |
| 10 | เพิ่ม lessons จากความผิดพลาดที่ผ่านมา | ⏳ ยังไม่ทำ | ดู HANDOFF เก่า + error logs |

### Priority 3 — ทำเมื่อมีเวลา

| # | Task | สถานะ | หมายเหตุ |
|---|------|--------|---------|
| 11 | สร้าง validation step ใน workflow | ⏳ ยังไม่ทำ | ทุก output จาก worker ต้องผ่าน reviewer |
| 12 | สร้าง confidence check | ⏳ ยังไม่ทำ | ถ้า agent ไม่แน่ใจ ให้ถาม user |
| 13 | สร้าง self-reflection loop | ⏳ ยังไม่ทำ | agent วิเคราะห์ performance ตัวเอง |
| 14 | สร้าง category lessons | ⏳ ยังไม่ทำ | lessons/categories/ (code-quality, security, etc.) |

---

## 🧠 สิ่งที่ Agent ตัวถัดไปต้องรู้

### 1. โครงสร้างไฟล์
```
agent-framework/     ← Framework หลัก (7 ไฟล์)
agents/              ← Agent definitions (SOUL + CONSTITUTION)
lessons/             ← ระบบเรียนรู้ (INDEX + daily logs)
```

### 2. สิ่งที่เชื่อมกับ project เดิม
- **GOD-HANDOFF-PROMPT.md** — ต้องเพิ่ม SOUL + CONSTITUTION + LESSONS เข้าไป
- **brain-bridge.sh** — ต้องเพิ่ม sync สำหรับ agents/ และ lessons/
- **multi-agent-workflow-kit** — ต้องเพิ่ม lesson plugin
- **arra-oracle-v3** — ต้องสร้าง SOUL.md สำหรับ Oracle

### 3. Key Design Decisions
- **ลำดับความสำคัญ:** Safety > Truth > User > Speed > Elegance
- **3-Step Protocol:** Understand → Plan → Execute (ห้าม skip)
- **Lesson System:** ทุกความผิดพลาด → บันทึก → inject เข้า prompt ครั้งถัดไป
- **Multi-Agent:** GOD ไม่ทำเอง — ส่งงานให้ specialist

### 4. สิ่งที่ห้ามทำ
- ❌ ไม่ลบ framework files
- ❌ ไม่แก้ CONSTITUTION.md โดยไม่คิดดีๆ (กฎมีลำดับความสำคัญ)
- ❌ ไม่ข้าม 3-Step Protocol
- ❌ ไม่ลืมบันทึก lesson เมื่อทำผิด

---

## 📊 Progress Summary

```
Total tasks:     14
Completed:        3  (Framework files + GOD SOUL + Lessons INDEX)
In progress:      0
Not started:     11

Progress: ████░░░░░░░░░░ 21%
```

---

## 🔗 References

- Framework docs: `agent-framework/01-07`
- GOD SOUL: `agents/god/SOUL.md`
- Constitution: `agents/CONSTITUTION.md`
- Lessons Index: `lessons/INDEX.md`
- Integration guide: `agent-framework/07-INTEGRATION.md`

---

**หมายเหตุถึง Agent ตัวถัดไป:**
Framework นี้ออกแบบมาให้ต่อยอดได้ ไม่ต้องเริ่มใหม่
อ่าน `agent-framework/06-QUICK-START.md` เพื่อดู code ที่พร้อมใช้
อ่าน `agent-framework/07-INTEGRATION.md` เพื่อดูวิธีเชื่อมกับ project เดิม

**สิ่งที่สำคัญที่สุดที่ต้องทำต่อ:** สร้าง SOUL.md สำหรับ Oracle agent เพราะเป็น worker หลัก
