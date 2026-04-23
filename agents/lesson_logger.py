from datetime import datetime
import os

def log_lesson(title, what_wrong, root_cause, impact, rule, 
               example_wrong, example_right):
    """
    บันทึก lesson ใหม่
    """
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    lessons_dir = os.path.join(base_dir, "lessons")
    os.makedirs(lessons_dir, exist_ok=True)

    today = datetime.now().strftime("%Y-%m-%d")
    filename = os.path.join(lessons_dir, f"{today}.md")
    
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
    with open(filename, "a", encoding="utf-8") as f:
        f.write(lesson)
    
    # Update INDEX.md
    index_path = os.path.join(lessons_dir, "INDEX.md")
    update_index(index_path, title, rule)
    
    print(f"✅ Lesson saved: {title}")


def update_index(index_path, title, rule):
    """
    เพิ่ม lesson ลง INDEX.md
    """
    if not os.path.exists(index_path):
        with open(index_path, "w", encoding="utf-8") as f:
            f.write("# Lessons Index\n\n## ⛔ Critical Rules\n(ยังไม่มี)\n\n## ⚠️ Warnings\n(ยังไม่มี)\n\n## 💡 Tips\n(ยังไม่มี)\n")

    with open(index_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # เพิ่มลง Warnings section
    if "## ⚠️ Warnings" in content:
        new_entry = f"## ⚠️ Warnings\n- {title}: {rule}"
        if f"- {title}" not in content:
            content = content.replace("## ⚠️ Warnings", new_entry)
    
    with open(index_path, "w", encoding="utf-8") as f:
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
