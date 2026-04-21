# Learning: Claude Code Deep Dive (Leaked Source Analysis)
- **วันที่**: 2026-04-20
- **หัวข้อ**: Internal Mechanics of Supreme Coding Agents
- **บริบท**: ศึกษาจาก tanbiralam/claude-code (v2.1.88 Source)

## สิ่งที่เรียนรู้ (Advanced Insights)
1. **Verification First Pattern**: "Reading is not verification. Run it." เอเจนท์ต้องไม่สรุปผลจากการอ่านโค้ดเพียงอย่างเดียว แต่ต้องรัน Test/Build/Lint เพื่อยืนยันความถูกต้องหลังการแก้ไขเสมอ
2. **KAIROS Architecture**: ระบบเอเจนท์ที่ทำงานแบบ Proactive (เชิงรุก) มีระบบ Background Tick เพื่อตรวจจับ Error และทำการซ่อมแซมตัวเอง (Auto-repair) โดยไม่ต้องรอคำสั่ง
3. **Context Hierarchy (CLAUDE.md)**: การใช้ไฟล์ Markdown ในแต่ละระดับ (Global > Project > Local) เพื่อส่งต่อพฤติกรรมและกฎระเบียบ (Strict Rules) ให้เอเจนท์ทำงานได้แม่นยำตามสภาพแวดล้อม
4. **Surgical Edits**: การแก้ไขไฟล์แบบ String Replacement เฉพาะจุด (Partial Modification) แทนการเขียนไฟล์ใหม่ทั้งหมด ช่วยลดอัตราการเกิด Hallucination และประหยัด Token ได้มหาศาล

## การนำมาใช้ใน Oracle World
- ปรับปรุง `oracle-tools.sh` ให้มีคำสั่งแก้ไขไฟล์แบบ Surgical (ot-edit-line/ot-replace-string)
- บังคับใช้ "Verification Loop" ใน Builder: Edit -> Verify (Test/Build) -> Commit
- สร้าง `CLAUDE.md` ใน Root เพื่อเป็น Manual หลักของ Fleet ในการทำงานระดับโปรเจกต์
- ตั้งค่าระบบ Background Monitoring (KAIROS Style) เพื่อตรวจสอบสุขภาพของ Oracle v3

## แหล่งข้อมูล
- [tanbiralam/claude-code](https://github.com/tanbiralam/claude-code)
