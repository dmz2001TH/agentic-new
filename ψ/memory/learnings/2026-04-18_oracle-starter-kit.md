# สิ่งที่เรียนรู้

## 2026-04-18 — เรียนรู้: opensource-nat-brain-oracle (Oracle Starter Kit)
- **บริบท**: ศึกษาโครงสร้างและปรัชญาต้นกำเนิดของระบบ Oracle เพื่อให้เข้าใจบทบาทและการทำงานของตัวเองในฐานะ "สมองภายนอก"
- **ประเภท**: Framework / Knowledge Management System / Multi-Agent Architecture
- **Architecture**: 
    - **Dual Storage**: เก็บข้อมูลในรูปแบบ Markdown (เพื่อความยืดหยุ่นและการอ่าน) ควบคู่กับ SQLite (FTS5/ChromaDB) เพื่อการค้นหาที่รวดเร็วและ Hybrid Search
    - **5 Pillars (ψ/)**: โครงสร้างโฟลเดอร์ `inbox` (สื่อสาร), `memory` (ความจำ), `writing` (งานเขียน), `lab` (ทดลอง), `active` (ปัจจุบัน)
    - **Modular Docs**: แยก `CLAUDE.md` ออกเป็นไฟล์ย่อยตามหน้าที่ (safety, workflows, subagents, lessons) เพื่อประหยัด context
- **Components หลัก**:
    - `oracle-skills-cli`: ติดตั้งความสามารถพิเศษ (slash commands)
    - `oracle-v2`: MCP server จัดการความจำและการค้นหา
    - `maw-js`: ระบบควบคุมทีม AI Agent ผ่าน tmux
    - `pulse-cli`: จัดการ Project Board และ Timeline ใน Terminal
- **Dependencies**: Bun (runtime), SQLite, GitHub CLI (`gh`), git
- **วิธีใช้**: 
    - เริ่มวันด้วย `/recap` สรุปงาน
    - ระหว่างวันใช้ `/fyi` จดจำข้อมูล หรือ `/trace` ค้นหา
    - จบเซสชันด้วย `rrr` (retrospective) และ `/forward` เพื่อส่งต่องาน
- **Patterns**: 
    - **Nothing is Deleted**: เก็บทุกอย่าง ห้ามลบ ใช้ timestamp เป็นความจริง
    - **Patterns Over Intentions**: สังเกตสิ่งที่เกิดขึ้นจริง ไม่ใช่แค่ความตั้งใจ
    - **External Brain**: AI เป็นกระจกสะท้อนข้อมูล ไม่ใช่ผู้ตัดสินใจแทนมนุษย์
    - **Context-Finder First**: ใช้ Agent ตัวเล็ก (Haiku) ค้นหาข้อมูลก่อน เพื่อประหยัด Token ของ Agent หลัก (Opus)
- **วิธีใช้ความรู้นี้**: ใช้เป็นแนวทางในการบันทึกความจำ การตัดสินใจ และการสื่อสารกับผู้ใช้ในฐานะ Oracle โดยยึดหลักการ "Keep the Human Human"
- **แท็ก**: #oracle #philosophy #architecture #learning #setup
