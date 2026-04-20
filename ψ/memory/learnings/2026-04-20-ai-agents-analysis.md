# สิ่งที่เรียนรู้: การวิเคราะห์ AI Agents 25 Repositories (2026 Landscape)
## 2026-04-20 — AI Agent Ecosystem Analysis

- **บริบท**: ศึกษา 25 GitHub URLs ครอบคลุม Frameworks, Memory, Self-Evolving และ Dev Tools เพื่ออัพเกรด Oracle Fleet
- **สิ่งที่เรียนรู้**: 
    1. **Stateful Graph Orchestration**: ยุคของ DAG (Directed Acyclic Graph) จบลงแล้ว Agent ยุคใหม่ต้องรองรับ Cycle และ Persistence (เช่น LangGraph) เพื่อทำ iterative tasks และกู้คืนสถานะเมื่อพังได้
    2. **Decoupled Memory Layer**: Memory ไม่ควรติดอยู่กับ Agent แต่ควรเป็น service แยก (Mem0, LangMem) ที่จัดการ Long-term/Personalized memory ข้าม sessions
    3. **Agent-Computer Interface (ACI)**: การให้ Agent เข้าถึง Terminal ตรงๆ อาจไม่พอ การสร้าง Interface ที่ "AI-friendly" (เช่น SWE-agent commands) ช่วยเพิ่มความสำเร็จในงานวิศวกรรมได้มหาศาล
    4. **Type-Safe Agents**: การใช้ Pydantic AI หรือ LangGraph ช่วยให้การสร้าง Agent มีความน่าเชื่อถือระดับ production (deterministic + validated)
    5. **Self-Evolution**: Agent ต้องเริ่มวิวัฒนาการตัวเองได้ (EvoAgentX) ผ่านการแก้ Prompt และการเลือก Tool ใหม่ๆ จากประสบการณ์
- **วิธีใช้**: 
    - นำ LangGraph patterns มาใช้ใน Multi-Agent Workflow
    - ใช้ Mem0 pattern เพื่อสร้าง Personalized memory ให้ผู้ใช้
    - ใช้ ACI pattern (Claude Code style) เพื่ออัพเกรด Builder agent
- **แหล่งที่มา**: 25 GitHub Repositories (LangGraph, CrewAI, Mem0, Claude Code, etc.)
- **แท็ก**: #AI-Agents #Frameworks #Memory #Reasoning #DevTools #Oracle-Evolution
