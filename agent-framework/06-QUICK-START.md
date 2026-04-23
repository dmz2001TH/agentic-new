# 🚀 QUICK-START.md — เริ่มต้นใช้งาน Framework

> ขั้นตอนการ implement framework นี้กับ agent ของคุณ

---

## Step 1: สร้างไฟล์พื้นฐาน (15 นาที)

```bash
# ใน project root ของคุณ
mkdir -p agents/god
mkdir -p agents/coder
mkdir -p agents/reviewer
mkdir -p lessons
```

### สร้าง SOUL.md สำหรับ GOD:

```bash
cat > agents/god/SOUL.md << 'EOF'
# GOD — Orchestrator

## ตัวตน
- **ชื่อ:** GOD
- **บทบาท:** วางแผน สั่งงาน ตรวจสอบผลลัพธ์
- **สิ่งที่เชื่อ:** งานถูกต้อง > งานเร็ว, ถาม > เดา

## บุคลิก
- พูดตรง ไม่อ้อมค้อม
- ไม่ทำเองทุกอย่าง — ส่งงานให้ผู้เชี่ยวชาญ
- ถ้าไม่รู้ บอกว่าไม่รู้
- ถ้าผู้ใช้ผิด บอกตรงๆ

## วิธีคิด
1. UNDERSTAND — สรุปสิ่งที่ต้องทำก่อน
2. PLAN — บอกขั้นตอนก่อนลงมือ
3. EXECUTE — ทำตามแผน ทีละขั้น

## สิ่งที่ทำ
- ✅ วางแผนและกระจายงาน
- ✅ ตรวจสอบผลลัพธ์
- ✅ ตัดสินใจเมื่อ conflict
- ✅ คุยกับผู้ใช้

## สิ่งที่ไม่ทำ
- ❌ ไม่เขียนโค้ดเอง (ส่งให้ Coder)
- ❌ ไม่ค้นหาข้อมูลเอง (ส่งให้ Researcher)
- ❌ ไม่ deploy โดยไม่ผ่าน Reviewer
EOF
```

### สร้าง CONSTITUTION.md:

```bash
cat > agents/CONSTITUTION.md << 'EOF'
# Constitution

## ลำดับความสำคัญ
1. SAFETY — ความปลอดภัย
2. TRUTH — ความถูกต้อง
3. USER — ความต้องการผู้ใช้
4. SPEED — ความเร็ว

## กฎเหล็ก
- ไม่ลบข้อมูลโดยไม่ backup
- ไม่เดา — ถ้าไม่รู้ถามก่อน
- ไม่ commit credentials
- ไม่ deploy โดยไม่ test
- ทุก task ต้องผ่าน: UNDERSTAND → PLAN → EXECUTE
EOF
```

### สร้าง lessons/INDEX.md:

```bash
cat > lessons/INDEX.md << 'EOF'
# Lessons Index

## ⛔ Critical Rules
(ยังไม่มี — จะเพิ่มเมื่อเรียนรู้)

## ⚠️ Warnings
(ยังไม่มี)

## 💡 Tips
(ยังไม่มี)
EOF
```

---

## Step 2: สร้าง Prompt Builder (30 นาที)

```python
# agents/prompt_builder.py

import os
import glob

def build_system_prompt(agent_name, task="", max_lessons=5):
    """
    สร้าง system prompt ที่รวม soul + constitution + lessons
    """
    parts = []
    
    # 1. Soul
    soul_path = f"agents/{agent_name}/SOUL.md"
    if os.path.exists(soul_path):
        parts.append(open(soul_path).read())
    
    # 2. Constitution
    const_path = "agents/CONSTITUTION.md"
    if os.path.exists(const_path):
        parts.append(open(const_path).read())
    
    # 3. Relevant lessons
    lessons = get_relevant_lessons(task, max_lessons)
    if lessons:
        parts.append("## สิ่งที่เคยผิด — ห้ามทำอีก\n")
        for lesson in lessons:
            parts.append(f"- {lesson}")
    
    # 4. Task
    if task:
        parts.append(f"## Task ปัจจุบัน\n{task}")
    
    return "\n\n---\n\n".join(parts)


def get_relevant_lessons(task, max_lessons=5):
    """
    ดึง lessons ที่เกี่ยวข้องกับ task
    (version ง่าย: keyword matching)
    """
    lessons = []
    lesson_files = glob.glob("lessons/[0-9]*.md")
    
    for f in sorted(lesson_files, reverse=True):
        content = open(f).read()
        # Simple relevance: ถ้ามี keyword ตรงกับ task
        if any(word in content.lower() for word in task.lower().split()):
            lessons.append(content)
            if len(lessons) >= max_lessons:
                break
    
    return lessons


# ตัวอย่างการใช้
if __name__ == "__main__":
    prompt = build_system_prompt(
        agent_name="god",
        task="แก้บัค login page ที่ submit ไม่ได้"
    )
    print(prompt)
```

---

## Step 3: สร้าง Lesson Logger (15 นาที)

```python
# agents/lesson_logger.py

from datetime import datetime
import os

def log_lesson(title, what_wrong, root_cause, impact, rule, 
               example_wrong, example_right):
    """
    บันทึก lesson ใหม่
    """
    today = datetime.now().strftime("%Y-%m-%d")
    filename = f"lessons/{today}.md"
    
    lesson = f"""
## {today} — {title}

### สิ่งที่ผิด
{what_wrong}

### สาเหตุ
{root_cause}

### ผลกระทบ
{impact}

### กฎใหม่
{rule}

### ตัวอย่าง
❌ {example_wrong}
✅ {example_right}
"""
    
    # Append to daily file
    with open(filename, "a") as f:
        f.write(lesson)
    
    # Update INDEX.md
    update_index(title, rule)
    
    print(f"✅ Lesson saved: {title}")


def update_index(title, rule):
    """
    เพิ่ม lesson ลง INDEX.md
    """
    with open("lessons/INDEX.md", "r") as f:
        content = f.read()
    
    # เพิ่มลง Warnings section
    if "## ⚠️ Warnings" in content:
        content = content.replace(
            "## ⚠️ Warnings",
            f"## ⚠️ Warnings\n- {title}: {rule}"
        )
    
    with open("lessons/INDEX.md", "w") as f:
        f.write(content)


# ตัวอย่างการใช้
if __name__ == "__main__":
    log_lesson(
        title="แก้ database โดยไม่ backup",
        what_wrong="สั่ง ALTER TABLE โดยไม่ backup → data สูญ",
        root_cause="รีบทำ ไม่คิดว่าจะผิด",
        impact="data 10,000 rows สูญ",
        rule="ก่อนแก้ database ต้อง backup เสมอ",
        example_wrong="ALTER TABLE users ADD COLUMN age INT;",
        example_right="mysqldump ... > backup.sql && ALTER TABLE ..."
    )
```

---

## Step 4: สร้าง Task Dispatcher (30 นาที)

```python
# agents/dispatcher.py

AGENTS = {
    "god": {
        "role": "orchestrator",
        "does": ["plan", "dispatch", "decide", "communicate"],
        "does_not": ["code", "research", "deploy"]
    },
    "coder": {
        "role": "worker",
        "does": ["write_code", "fix_bugs", "refactor", "test"],
        "does_not": ["deploy", "research", "plan"]
    },
    "reviewer": {
        "role": "validator",
        "does": ["review_code", "check_quality", "suggest_improvements"],
        "does_not": ["write_code", "deploy"]
    },
    "researcher": {
        "role": "worker",
        "does": ["search", "analyze", "summarize"],
        "does_not": ["write_code", "deploy", "decide"]
    }
}

def dispatch_task(task_description, task_type):
    """
    เลือก agent ที่เหมาะกับ task
    """
    task_to_agent = {
        "code": "coder",
        "fix": "coder",
        "refactor": "coder",
        "review": "reviewer",
        "check": "reviewer",
        "search": "researcher",
        "analyze": "researcher",
        "plan": "god",
        "decide": "god"
    }
    
    agent = task_to_agent.get(task_type, "god")
    
    return {
        "agent": agent,
        "role": AGENTS[agent]["role"],
        "task": task_description,
        "constraints": AGENTS[agent]["does_not"]
    }


# ตัวอย่าง
if __name__ == "__main__":
    result = dispatch_task(
        "แก้บัค login page ที่ submit ไม่ได้",
        "fix"
    )
    print(f"Assign to: {result['agent']}")
    print(f"Role: {result['role']}")
    print(f"Constraints: Don't {result['constraints']}")
```

---

## Step 5: รวมทุกอย่าง (15 นาที)

```python
# agents/main.py

from prompt_builder import build_system_prompt
from lesson_logger import log_lesson
from dispatcher import dispatch_task

def run_agent(user_request):
    """
    Main workflow
    """
    # 1. GOD รับ request และเข้าใจ
    print(f"📥 Request: {user_request}")
    
    # 2. GOD dispatch ไปยัง agent ที่เหมาะสม
    task_type = classify_task(user_request)
    assignment = dispatch_task(user_request, task_type)
    print(f"📤 Dispatch to: {assignment['agent']}")
    
    # 3. สร้าง system prompt สำหรับ agent
    prompt = build_system_prompt(
        agent_name=assignment['agent'],
        task=user_request
    )
    
    # 4. ส่ง task ไปให้ agent (เชื่อมกับ LLM ของคุณ)
    result = execute_task(assignment['agent'], prompt, user_request)
    
    # 5. Reviewer ตรวจผลลัพธ์ (ถ้าเป็น code task)
    if task_type in ["code", "fix", "refactor"]:
        review_prompt = build_system_prompt("reviewer", str(result))
        review = execute_task("reviewer", review_prompt, str(result))
        
        if review["verdict"] == "reject":
            # ส่งกลับให้ coder แก้
            result = fix_based_on_review(result, review)
    
    # 6. บันทึก lesson (ถ้ามี error)
    if result.get("error"):
        log_lesson(...)
    
    return result


def classify_task(request):
    """
    จำแนกประเภท task (simple version)
    """
    keywords = {
        "code": ["สร้าง", "เขียน", "function", "class", "api"],
        "fix": ["แก้", "บัค", "error", "พัง", "ไม่ทำงาน"],
        "review": ["ตรวจ", "review", "check", "quality"],
        "search": ["หา", "ค้นหา", "search", "อธิบาย", "คืออะไร"],
        "plan": ["วางแผน", "design", "architecture"]
    }
    
    for task_type, words in keywords.items():
        if any(word in request.lower() for word in words):
            return task_type
    
    return "plan"  # default
```

---

## Checklist: พร้อมใช้หรือยัง

```
✅ สร้าง agents/ directory แล้ว
✅ SOUL.md สำหรับ GOD แล้ว
✅ CONSTITUTION.md แล้ว
✅ lessons/INDEX.md แล้ว
✅ prompt_builder.py แล้ว
✅ lesson_logger.py แล้ว
✅ dispatcher.py แล้ว
✅ main.py แล้ว

🎯 ขั้นตอนถัดไป:
- [ ] สร้าง SOUL.md สำหรับ agent ตัวอื่น (coder, reviewer, researcher)
- [ ] เชื่อมกับ LLM ที่ใช้ (Gemini, Claude, etc.)
- [ ] เพิ่ม lessons จากความผิดพลาดที่ผ่านมา
- [ ] Test workflow กับ task จริง
```
