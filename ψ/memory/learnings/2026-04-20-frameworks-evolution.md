# Learning: Frameworks & Orchestration Evolution (2026)
- **วันที่**: 2026-04-20
- **หัวข้อ**: Next-Gen Agent Orchestration
- **บริบท**: ศึกษาจาก LangGraph, CrewAI, AutoGen, PydanticAI

## สิ่งที่เรียนรู้ (Core Insights)
1. **Cyclic Graphs (LangGraph)**: การทำงานของเอเจนท์ต้องไม่ใช่แค่เส้นตรง (DAG) แต่ต้องเป็น Loop ที่มี State และ Checkpoint เพื่อให้สามารถ "ย้อนกลับ" หรือ "แก้ไขตัวเอง" (Reflexion) ได้
2. **Role-Based Flows (CrewAI)**: การส่งต่องานระหว่างเอเจนท์ (Delegation) ต้องมี Protocol ที่ชัดเจนและเป็น Event-driven
3. **Type-Safe Reliability (PydanticAI)**: การรับส่งข้อมูลระหว่างเอเจนท์ต้องมีการ Validate โครงสร้าง (Schema) เพื่อลด Hallucination ในการเรียก Tool

## การนำมาใช้ใน Oracle World
- ปรับโครงสร้าง `goals.md` ให้รองรับการทำงานแบบ Iterative Loop
- ใช้ `ψ/memory/handoff.md` เป็น State Checkpoint สำหรับการสลับงานระหว่าง GOD และ Builder
- พัฒนา JSON Schema สำหรับการสั่งงาน Builder (Delegation Protocol)

## แหล่งข้อมูล
- [LangGraph](https://github.com/langchain-ai/langgraph)
- [CrewAI](https://github.com/crewaiinc/crewai)
- [PydanticAI](https://github.com/pydantic/pydantic-ai)
