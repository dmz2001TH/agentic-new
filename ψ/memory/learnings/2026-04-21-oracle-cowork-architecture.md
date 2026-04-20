# Learning: Oracle Cowork Architecture (Collaborative AI OS)
- **วันที่**: 2026-04-21
- **หัวข้อ**: Multi-Agent Collaboration & Shared Context
- **บริบท**: ศึกษาจาก Claude Cowork, Claude Projects, and Teams patterns

## สิ่งที่เรียนรู้ (Core Insights)
1. **Shared Brain (Project Context)**: ความสำเร็จของทีม AI อยู่ที่การมี "พื้นที่ความจำร่วม" (Shared Memory) ที่ทุกคนเข้าถึงได้ทันที (ใช้ระบบ ψ/ เป็นศูนย์กลาง)
2. **Pulse & Heartbeat**: เอเจนท์ต้องรายงานสถานะ (Live Status) ลงในไฟล์ชีพจรส่วนกลาง เพื่อให้คนและเอเจนท์ตัวอื่นเห็น "Work-in-Progress"
3. **Mailbox Pattern (Async Coordination)**: การส่งต่องานผ่าน Inbox/Outbox ช่วยลดการขัดจังหวะ (Interruption) และทำให้ Context ของแต่ละเอเจนท์ไม่ปนเปื้อน
4. **Generator-Verifier**: การแยกคนเขียนโค้ดและคนตรวจโค้ด (Independent Verification) ช่วยเพิ่มคุณภาพของระบบได้อย่างมหาศาล

## การนำมาใช้ใน Oracle World
- ใช้ `ψ/memory/pulse/` เก็บสถานะปัจจุบันของเอเจนท์ทุกตัว (Heartbeat)
- ใช้ `ψ/memory/mailbox/` เป็นระบบส่งต่องานที่เป็นทางการ (Task Queue)
- พัฒนา `ot-status` Dashboard สำหรับท่านพีช (The Master View)

## แหล่งข้อมูล
- Claude Projects & Teams (Anthropic Patterns)
