# Learning: Oracle MAW Integration & Fleet Control (2026)
- **วันที่**: 2026-04-20
- **หัวข้อ**: Fleet Management, CLI Workflows, MCP Memory
- **บริบท**: ศึกษาจาก Oracle MAW Guide และ `arra-oracle-v3`

## สิ่งที่เรียนรู้ (Core Insights)

### 1. Fleet Control (กองทัพเอเจนท์)
- แนวคิดการมี "กองทัพ Oracle" (Fleet) ที่มีบทบาทชัดเจน: **Dev, QA, Writer, Admin**
- ชุดคำสั่งมาตรฐานสำหรับ Fleet:
  - `hey`: การส่งคำสั่งด่วนหรือประกาศให้เอเจนท์รับทราบ (One-off)
  - `talk-to`: การเริ่มบทสนทนาหรือการทำงานร่วมกันอย่างต่อเนื่อง (Collaboration)
  - `wake` / `sleep` / `peek`: การจัดการวงจรชีวิตและตรวจสอบสถานะของเอเจนท์

### 2. Centralized CLI Command (การรวมศูนย์การควบคุม)
- การใช้ CLI เพียงตัวเดียวเพื่อควบคุมเอเจนท์ทุกตัวใน Fleet ลดการสลับ Terminal และทำให้การจัดการ Task Board (`task.json`) เป็นระเบียบขึ้น

### 3. MCP Memory Layer (การเชื่อมต่อหน่วยความจำระดับโปรโตคอล)
- `arra-oracle-v3` นำเสนอ MCP (Model Context Protocol) Memory Layer ที่รองรับ Semantic Search และการจัดการ "Philosophy" ของระบบ
- ช่วยให้เอเจนท์ทุกตัวใน Fleet สามารถเข้าถึง "สมองส่วนกลาง" เดียวกันได้อย่างมีประสิทธิภาพ

### 4. Continuous Integration for Agents
- การผูกงานของเอเจนท์เข้ากับ Git Commits และ Metrics อย่างใกล้ชิด เพื่อให้แน่ใจว่างานทุกอย่าง "Battle-tested" และตรวจสอบย้อนกลับได้

## การนำมาใช้ใน Oracle World
- พัฒนาโครงสร้าง `task.json` และ `ψ/` ให้รองรับการทำงานแบบ "Hey" และ "Talk-to" ระหว่างเอเจนท์
- นำ MCP Server มาใช้เป็นตัวกลางในการคุยกับความจำ `ψ/` เพื่อเพิ่มความเร็วและความแม่นยำ (Semantic Search)
- ออกแบบ Fleet Roles ให้ชัดเจนใน `ψ/agents/`

## แหล่งข้อมูล
- [Oracle MAW Guide GitHub](https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide)
- [Arra-Oracle-v3 MCP](https://github.com/Soul-Brews-Studio/arra-oracle-v3)
