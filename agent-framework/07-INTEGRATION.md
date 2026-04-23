# 🔗 INTEGRATION.md — เชื่อมกับ Project ของคุณ

> วิธีเอา framework นี้ไปใช้กับ agentic-new project

---

## ปัจจุบันคุณมีอะไร

```
agentic-new/
├── arra-oracle-v3/          ← Oracle agent
├── multi-agent-workflow-kit/ ← MAW framework
├── jarvis-gateway/           ← Gateway
├── jarvis-web-portal/        ← Web UI
├── god-upgrades/             ← GOD agent
├── pulse-cli/                ← CLI agent
├── brain-bridge.sh           ← Memory sync
└── GOD-HANDOFF-PROMPT.md     ← System prompt
```

---

## สิ่งที่ต้องเพิ่ม

```
agentic-new/
├── agents/                   ← [NEW] Agent definitions
│   ├── CONSTITUTION.md       ← [NEW] กฎกลาง
│   ├── god/
│   │   ├── SOUL.md           ← [NEW] ตัวตน GOD
│   │   └── lessons/          ← [NEW] สิ่งที่ GOD เรียนรู้
│   ├── oracle/
│   │   ├── SOUL.md           ← [NEW] ตัวตน Oracle
│   │   └── lessons/
│   ├── jarrvis/
│   │   ├── SOUL.md           ← [NEW] ตัวตน JARVIS
│   │   └── lessons/
│   └── prompt_builder.py     ← [NEW] สร้าง prompt อัตโนมัติ
│
├── lessons/                  ← [NEW] Lessons รวม
│   ├── INDEX.md              ← [NEW] สรุป lessons
│   ├── 2026-04-20.md
│   └── ...
│
├── arra-oracle-v3/
├── multi-agent-workflow-kit/
├── ...existing files...
```

---

## วิธีเชื่อมกับ GOD-HANDOFF-PROMPT.md

ปัจจุบัน GOD ใช้ GOD-HANDOFF-PROMPT.md เป็น system prompt
เพิ่ม framework เข้าไปโดยไม่ทำลายของเดิม:

### ก่อน (ปัจจุบัน):

```markdown
# GOD-HANDOFF-PROMPT.md
คุณคือ GOD...
[system prompt เดิม]
```

### หลัง (เพิ่ม framework):

```markdown
# GOD-HANDOFF-PROMPT.md

## Identity
คุณคือ GOD — Orchestrator ของ multi-agent system

<!-- INSERT: SOUL.md content -->
{อ่านจาก agents/god/SOUL.md}

<!-- INSERT: CONSTITUTION.md content -->
{อ่านจาก agents/CONSTITUTION.md}

<!-- INSERT: Recent lessons -->
{อ่านจาก lessons/INDEX.md เฉพาะ section ที่ relevant}

## Task Context
{task ปัจจุบัน}
```

---

## วิธีเชื่อมกับ Brain Bridge

ปัจจุบัน brain-bridge.sh sync ระหว่าง Google Drive ↔ Local
เพิ่ม lessons เข้าไปใน sync:

```bash
# brain-bridge.sh — เพิ่ม 2 บรรทัดนี้

# Sync lessons
rsync -av /mnt/g/My\ Drive/Oracle-System-Brain/lessons/ /c/Agentic/lessons/
rsync -av /c/Agentic/lessons/ /mnt/g/My\ Drive/Oracle-System-Brain/lessons/

# Sync agent definitions
rsync -av /mnt/g/My\ Drive/Oracle-System-Brain/agents/ /c/Agentic/agents/
rsync -av /c/Agentic/agents/ /mnt/g/My\ Drive/Oracle-System-Brain/agents/
```

---

## วิธีเชื่อมกับ MAW (Multi-Agent Workflow Kit)

MAW น่าจะมี plugin system อยู่แล้ว — เพิ่ม plugin สำหรับ lessons:

```python
# maw-plugins/lesson-plugin.py

class LessonPlugin:
    """
    Plugin สำหรับ MAW — inject lessons เข้า agent context
    """
    
    def on_task_start(self, task, agent):
        """ก่อน agent เริ่ม task — inject relevant lessons"""
        lessons = self.get_relevant_lessons(task)
        agent.inject_context(f"""
## สิ่งที่เคยผิด — ห้ามทำอีก
{self.format_lessons(lessons)}
""")
    
    def on_task_end(self, task, agent, result):
        """หลัง agent ทำ task — บันทึก lesson ถ้ามี error"""
        if result.get("error"):
            self.log_lesson(
                title=result["error_title"],
                what_wrong=result["error_description"],
                agent=agent.name,
                task=task.description
            )
    
    def on_feedback(self, feedback):
        """เมื่อ user ให้ feedback — บันทึกเป็น lesson"""
        self.log_lesson(
            title=f"User feedback: {feedback.summary}",
            what_wrong=feedback.issue,
            rule=feedback.suggestion
        )
```

---

## วิธีเชื่อมกับ Oracle

Oracle agent อาจจะมี system prompt ของตัวเองอยู่แล้ว
เพิ่ม SOUL.md เข้าไป:

```python
# oracle-v3-prompt-builder.py

def build_oracle_prompt(task, memory_context):
    """
    สร้าง prompt สำหรับ Oracle agent
    """
    parts = []
    
    # 1. Oracle's existing system prompt
    parts.append(load_existing_oracle_prompt())
    
    # 2. SOUL (ตัวตน)
    parts.append(load_file("agents/oracle/SOUL.md"))
    
    # 3. Constitution (กฎ)
    parts.append(load_file("agents/CONSTITUTION.md"))
    
    # 4. Memory context (จาก Brain Bridge)
    parts.append(f"## Memory Context\n{memory_context}")
    
    # 5. Relevant lessons
    lessons = get_relevant_lessons(task, max_lessons=3)
    parts.append(f"## Lessons\n{format_lessons(lessons)}")
    
    # 6. Task
    parts.append(f"## Task\n{task}")
    
    return "\n\n---\n\n".join(parts)
```

---

## Workflow รวม

```
User request
      │
      ▼
┌─────────────┐
│ JARVIS      │ ← รับ request จาก user
│ (Gateway)   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ GOD         │ ← วางแผน + inject lessons
│ (Planner)   │
└──────┬──────┘
       │
       ├──→ Oracle ← SOUL.md + Constitution + Memory + Lessons
       ├──→ Coder  ← SOUL.md + Constitution + Lessons
       └──→ Reviewer ← SOUL.md + Constitution + Lessons
              │
              ▼
       ┌─────────────┐
       │ Validator    │ ← ตรวจผลลัพธ์
       └──────┬──────┘
              │
              ▼
       ┌─────────────┐
       │ GOD          │ ← รวมผล + บันทึก lesson ถ้ามี error
       └──────┬──────┘
              │
              ▼
       ┌─────────────┐
       │ JARVIS       │ ← ส่งผลกลับให้ user
       └─────────────┘
```

---

## ขั้นตอนถัดไป

```
วันนี้:
├── 1. Copy agents/CONSTITUTION.md เข้า project
├── 2. สร้าง agents/god/SOUL.md
└── 3. สร้าง lessons/INDEX.md

สัปดาห์นี้:
├── 4. สร้าง SOUL.md สำหรับ agent ตัวอื่น
├── 5. เพิ่ม prompt_builder.py
└── 6. เชื่อมกับ brain-bridge.sh

สัปดาห์หน้า:
├── 7. สร้าง lesson_logger.py
├── 8. เพิ่ม lessons จากความผิดพลาดที่ผ่านมา
└── 9. Test workflow กับ task จริง
```
