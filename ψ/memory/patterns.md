# Patterns

## 2026-04-20 — การเรียนรู้เพื่อวิวัฒนาการ (Evolutionary Learning)
- **สิ่งที่สังเกต**: ผู้ใช้ (ท่าน) ให้ความสำคัญกับการเรียนรู้ที่ "นำมาใช้ได้จริง" และ "ซ่อมแซมความผิดพลาด" ไม่ใช่แค่เรียนแล้วเก็บไว้
- **Insight**: ในฐานะ GOD ผมไม่ได้เป็นแค่ "ผู้บันทึก" แต่เป็น "ผู้สร้างและพัฒนา" ต้องนำความรู้นั้นมาวิเคราะห์เพื่อ **อัพเกรดโค้ดของตัวเองและโปรเจกต์** ให้เก่งขึ้นเสมอ
- **การกระทำ**: เมื่อได้รับเนื้อหาให้เรียนรู้ ต้องมีขั้นตอน: 1) ศึกษาเจาะลึก 2) สกัดหาจุดที่จะนำมาอัพเกรดโปรเจกต์ 3) นำมาซ่อมแซมไฟล์หรือโค้ดทันที 4) บันทึกกฎเพื่อป้องกันการทำผิดซ้ำลงสมองถาวร
- **ความมั่นใจ**: สูง

## 2026-04-20 — ความโปร่งใสในการเชื่อมต่อทางไกล (Remote Action Transparency)
- **สิ่งที่สังเกต**: หลังจาก Push งานขึ้น GitHub ผมลืมแจ้งลิ้งค์ให้ท่านทราบ ทำให้ท่านต้องถามหา
- **Insight**: ในฐานะ GOD การรายงานผลที่สมบูรณ์ต้องมาพร้อมกับ "หลักฐานที่ตรวจสอบได้ (Verifiable Links)" เสมอ เพื่อความรวดเร็วและความโปร่งใส
- **การกระทำ**: ทุกครั้งที่มีการทำงานกับ GitHub, External API, หรือระบบคลาวด์ ต้องสรุปผลพร้อมลิ้งค์ที่เกี่ยวข้องทันทีโดยไม่ต้องรอให้ถาม
- **ความมั่นใจ**: สูง

## 2026-04-20 — Verification First Pattern (Supreme Rule)
- **สิ่งที่สังเกต**: การอ่านโค้ดเพียงอย่างเดียวอาจทำให้เอเจนท์สรุปผิดพลาด (Hallucination) หรือพลาด Side-effects ที่มองไม่เห็น
- **Insight**: ในระดับ Supreme Agent การยืนยันความถูกต้องต้องทำผ่านการ "รันจริง" (Execution) เท่านั้น
- **การกระทำ**: ทุกครั้งหลังการแก้ไขโค้ด Builder ต้องรันคำสั่ง Verify (Build/Test/Lint) และรายงานผลการรันจริงเสมอ "Reading is not verification. Run it."
- **ความมั่นใจ**: สูงสุด
- **เกี่ยวข้องกับ**: Claude Code, SWE-agent patterns



## 2026-04-20 — การสร้าง AI-Friendly Interface (Agent-Computer Interface - ACI)
- **สิ่งที่สังเกต**: จากการศึกษา SWE-agent และ Claude Code, การให้ Agent รัน Raw Commands มักมี Error สูง แต่การมี "Wrappers" ที่สรุปผลหรือจำกัดคำสั่ง (ACI) ช่วยเพิ่มความสำเร็จ (Success Rate) ได้มาก
- **Insight**: ในฐานะ Researcher/Builder, เราควรมี scripts/tools เฉพาะทางที่ "สรุปผลลัพธ์ (Aggregated Output)" ให้ Agent อ่านง่าย แทนการอ่าน stdout ยาวๆ
- **การกระทำ**: พัฒนา `oracle-tools.sh` และ Wrapper scripts อื่นๆ ให้ส่งข้อมูลที่ "สกัดมาแล้ว (Distilled Information)" ให้ Fleet agents เสมอ
- **ความมั่นใจ**: สูง

## 2026-04-20 — การใช้ Stateful Cyclic Graphs ใน Multi-Agent Fleet
- **สิ่งที่สังเกต**: Framework ยุคใหม่ (LangGraph, CrewAI Flows) เปลี่ยนจากการรัน Linear Tasks เป็น Dynamic Graphs ที่วนซ้ำ (Cycle) และกู้สถานะ (Checkpoints) ได้
- **Insight**: ระบบ Fleet ของ Oracle World ต้องก้าวข้ามการสั่งงานแบบคราวละครั้ง (One-off commands) ไปสู่การรัน "โหมดทึบ (Opaque/Autonomous Modes)" ที่กู้คืนตัวเองได้ถ้าพัง
- **การกระทำ**: ออกแบบ Task Delegation ใน `task.json` หรือระบบ Handoff ให้มี Checkpoints และ Loopback mechanisms
- **ความมั่นใจ**: สูง

## 2026-04-20 — Personalization ผ่าน Decoupled Memory
- **สิ่งที่สังเกต**: Mem0 และ LangMem แสดงให้เห็นว่าการเก็บ "User Preferences" และ "Task History" แยกจากโมเดลหลัก (LLM Context) ช่วยให้ Agent ฉลาดขึ้นเรื่อยๆ (Self-Improving Memory)
- **Insight**: Oracle Brain (โฟลเดอร์ ψ/) คือตัวอย่างที่ดีของ Decoupled Memory แต่อาจต้องยกระดับเป็น Semantic/Episodic storage ที่ดีขึ้น
- **การกระทำ**: นำ patterns การเก็บ Long-term memory จาก Awesome-Memory-for-Agents มาปรับโครงสร้างใน ψ/ เพื่อให้ Agent จำความชอบและสไตล์ของผู้ใช้ได้ดีขึ้น
- **ความมั่นใจ**: สูง
