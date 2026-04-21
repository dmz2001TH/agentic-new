# Learning: Self-Improving Agent Mechanics (The Evolution Engine)
- **วันที่**: 2026-04-21
- **หัวข้อ**: Autonomous Self-Evolution & Error Immunity
- **บริบท**: ศึกษาจาก dmz2001TH/self-improving-agent (oracle-self-evolve)

## สิ่งที่เรียนรู้ (Core Insights)
1. **Error Memory**: การจำความผิดพลาดต้องทำอย่างเป็นระบบ (Occurrence Count) เพื่อระบุ "ความผิดพลาดซ้ำซาก" และเปลี่ยนให้เป็น "กฎเหล็ก (Hard Rules)"
2. **Strategy Confidence**: ทุกแนวทางการแก้ปัญหาต้องมีการวัดผล (Success/Failure) และให้คะแนนความมั่นใจ เพื่อเลือกวิธีที่ดีที่สุดในอนาคต (Bayesian Scoring)
3. **Prompt Evolution**: เอเจนท์ต้องมีความสามารถในการ "เขียนโปรแกรมสมองตัวเอง" (System Prompt Modification) เพื่อปรับปรุงพฤติกรรมตามประสบการณ์จริง
4. **Validation Loop**: การแก้ไขโค้ดต้องมาพร้อมกับ Automated Test และ Auto-Rollback เพื่อความปลอดภัย 100%

## การนำมาใช้ใน Oracle World
- พัฒนา `ψ/memory/mistakes.md` เพื่อติดตาม Error ซ้ำซาก (Occurrence Tracking)
- บังคับใช้ "Pre-flight Check": ก่อนเริ่มงาน Builder ต้องตรวจสอบ `mistakes.md` และ `patterns.md` เพื่อไม่ให้ทำผิดซ้ำ
- อัพเกรด `ot-verify` ให้รองรับการ `git restore` อัตโนมัติเมื่อ Test ไม่ผ่าน

## แหล่งข้อมูล
- [self-improving-agent](https://github.com/dmz2001TH/self-improving-agent)
