# Learning: Skills vs MAW (Singhasingha's Manual)
- **วันที่**: 2026-04-20
- **หัวข้อ**: Internal Skills vs External Fleet Infrastructure
- **บริบท**: ศึกษาจากคู่มือ Singhasingha (ท่านกอล์ฟ)

## สิ่งที่เรียนรู้ (Core Insights)
1. **Skills (ผู้ช่วยในห้อง)**:
   - คือไฟล์ Markdown (`SKILL.md`) ที่เก็บคำสั่งสอน Claude ภายใน session
   - เรียกใช้ด้วย `/ชื่อสกิล` (เช่น `/สรุป`, `/ตอนนี้`)
   - Claude เป็นคนรันเองภายใน session context
2. **MAW (ผู้จัดการตึก)**:
   - คือเครื่องมือจัดการ Oracle ทั้งฝูงจากภายนอก (CLI Terminal)
   - เรียกใช้ด้วย `maw <verb>` (เช่น `maw wake`, `maw hey`)
   - จัดการ tmux sessions, git worktrees, และการสื่อสารข้าม Oracles
3. **Coexistence Strategy**:
   - Skills เหมาะกับงาน 95% ใน session เดียว
   - MAW เหมาะกับการประสานงานหลาย Oracles ข้าม project/session
   - `maw done` คือการรวบรวม `/สรุป` + Git Commit + Push ไว้ในคำสั่งเดียว

## การนำมาใช้ใน Oracle World
- พัฒนา `scripts/oracle-tools.sh` ให้เป็นสะพานเชื่อมระหว่าง Skills และ MAW
- ให้ GOD ทำหน้าที่เป็น "ผู้จัดการตึก (MAW)" คุม Fleet ผ่าน Terminal
- ให้ Oracles ในห้องคุยใช้ Skills เพื่อความรวดเร็วและประหยัด Token

## แหล่งข้อมูล
- [คู่มือ Skills vs maw](/mnt/c/Agentic/คู่มือ-skills-vs-maw.md)
