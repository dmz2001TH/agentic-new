# Learning: Self-Evolving & Reasoning Patterns (2026)
- **วันที่**: 2026-04-20
- **หัวข้อ**: Autonomous Self-Correction & Reasoning
- **บริบท**: ศึกษาจาก Awesome-Self-Evolving-Agents, Awesome-Agentic-Reasoning

## สิ่งที่เรียนรู้ (Core Insights)
1. **Self-Correction (Reflexion)**: เอเจนท์ต้องวิเคราะห์ความล้มเหลวของตัวเอง (Failure Analysis) และบันทึก "สิ่งที่ห้ามทำ" ลงในความจำถาวรเพื่อไม่ให้พลาดซ้ำ
2. **Tool Discovery**: เอเจนท์ควรมีความสามารถในการค้นหาและเรียนรู้วิธีใช้ Tool ใหม่ๆ ในโปรเจกต์เองได้
3. **Reasoning Paths (Tree of Thoughts)**: การตัดสินใจที่ซับซ้อนควรมีการแตกกิ่งก้านของความคิด (Thinking Branches) และเลือกทางที่ดีที่สุด ไม่ใช่แค่ทางแรกที่คิดออก

## การนำมาใช้ใน Oracle World
- เปิดใช้งาน "Failure Analysis Step" ใน Builder เมื่อรัน Test ไม่ผ่าน
- บันทึก "Preventative Rules" ใน `ψ/memory/patterns.md` เมื่อพบ Bug ที่แก้ไขได้แล้ว
- ให้ GOD ทำหน้าที่เป็น "Reasoning Supervisor" คอยตรวจสอบแผนของ Builder ก่อนเริ่มทำ

## แหล่งข้อมูล
- [Awesome-Self-Evolving-Agents](https://github.com/EvoAgentX/Awesome-Self-Evolving-Agents)
- [Awesome-Agentic-Reasoning](https://github.com/weitianxin/Awesome-Agentic-Reasoning)
