import os
import glob

def build_system_prompt(agent_name, task="", max_lessons=5):
    """
    สร้าง system prompt ที่รวม soul + constitution + lessons
    """
    parts = []
    
    # Base directory for agents and lessons
    # Since this file is in 'agents/', we look for files relative to project root
    # assuming this script is run from project root or handles paths correctly.
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    agents_dir = os.path.join(base_dir, "agents")
    lessons_dir = os.path.join(base_dir, "lessons")

    # 1. Soul
    soul_path = os.path.join(agents_dir, agent_name, "SOUL.md")
    if os.path.exists(soul_path):
        with open(soul_path, "r", encoding="utf-8") as f:
            parts.append(f.read())
    
    # 2. Constitution
    const_path = os.path.join(agents_dir, "CONSTITUTION.md")
    if os.path.exists(const_path):
        with open(const_path, "r", encoding="utf-8") as f:
            parts.append(f.read())
    
    # 3. Relevant lessons
    lessons = get_relevant_lessons(task, max_lessons, lessons_dir)
    if lessons:
        parts.append("## สิ่งที่เคยผิด — ห้ามทำอีก\n")
        for lesson in lessons:
            parts.append(f"- {lesson}")
    
    # 4. Task
    if task:
        parts.append(f"## Task ปัจจุบัน\n{task}")
    
    return "\n\n---\n\n".join(parts)


def get_relevant_lessons(task, max_lessons=5, lessons_dir="lessons"):
    """
    ดึง lessons ที่เกี่ยวข้องกับ task
    (version ง่าย: keyword matching)
    """
    lessons = []
    lesson_files = glob.glob(os.path.join(lessons_dir, "[0-9]*.md"))
    
    for f in sorted(lesson_files, reverse=True):
        with open(f, "r", encoding="utf-8") as file:
            content = f.read()
            # Simple relevance: ถ้ามี keyword ตรงกับ task
            if task and any(word.lower() in content.lower() for word in task.split()):
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
