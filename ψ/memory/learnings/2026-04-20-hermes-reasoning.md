# Learning: Hermes Reasoning & Autonomous Skills
- **วันที่**: 2026-04-20
- **หัวข้อ**: Trajectory Compression & Skill Extraction
- **บริบท**: ศึกษาจาก nousresearch/hermes-agent

## สิ่งที่เรียนรู้ (Core Insights)
1. **Trajectory Compression**: การย่อสรุป "เส้นทางการตัดสินใจ (Trajectory)" ของเอเจนท์ เพื่อลด Context noise และเก็บเฉพาะใจความสำคัญในการแก้ปัญหา
2. **Autonomous Skill Extraction**: เอเจนท์ควรมีความสามารถในการเปลี่ยน "วิธีแก้ปัญหาที่สำเร็จ" ให้กลายเป็น "Skill (Markdown format)" เพื่อนำมาใช้ซ้ำในอนาคต
3. **Reasoning Integrity**: การรักษาความสม่ำเสมอของเหตุผล (Chain of Thought) แม้จะมีการข้าม session

## การนำมาใช้ใน Oracle World
- ให้ Builder ทำการสรุปผลการแก้ปัญหา (Root Cause + Solution) เป็น Skill ใหม่ใน `.claude/skills/` อัตโนมัติเมื่อเจอปัญหาซ้ำ
- ใช้ระบบ Recap ใน `ψ/memory/retrospectives/` เป็น Trajectory Compression สำหรับ GOD

## แหล่งข้อมูล
- [Hermes Agent](https://github.com/nousresearch/hermes-agent)
