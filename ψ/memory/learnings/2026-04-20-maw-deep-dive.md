# Learning: Multi-Agent Orchestration (MAW) Deep Dive (2026)
- **วันที่**: 2026-04-20
- **หัวข้อ**: MAW Architecture, Lifecycle & Tiers
- **บริบท**: ศึกษาจาก "The Bible of MAW" (soul-brews-studio.github.io) และ Soul Brews Studio GitHub

## สิ่งที่เรียนรู้ (Core Insights)

### 1. Three Tiers of Orchestration (ระดับชั้นการจัดการ)
- **Tier 1: In-process Subagents**: เอเจนท์ย่อยที่รันภายในโปรเซสเดียวกัน (Low-latency) เหมาะสำหรับงานเล็กๆ ที่ต้องการความเร็วสูงและข้อมูลที่ผูกมัดกันแน่น
- **Tier 2: Coordinated Teams**: เอเจนท์ที่ทำงานร่วมกันผ่าน Task Board หรือกระดานงานกลาง (เช่น `task.json` ใน Oracle) เหมาะสำหรับโปรเจกต์ขนาดกลาง
- **Tier 3: Independent Federation Nodes**: เอเจนท์ที่ทำงานแบบกระจายศูนย์ (Decentralized) ข้ามสภาพแวดล้อมหรือโหนดต่างๆ เหมาะสำหรับระบบขนาดใหญ่ที่ต้องการความยืดหยุ่นสูง

### 2. Visibility Pattern (กฎความโปร่งใส)
- **"Convenience is for the AI, Visibility is for the human."**: ระบบต้องให้ความสำคัญกับ "การมองเห็นของผู้ใช้" (เช่น War Rooms, Peeking) มากกว่าแค่ให้ AI ทำงานอัตโนมัติแบบกล่องดำ (Black Box) เพื่อสร้างความเชื่อมั่นและการควบคุมที่มีประสิทธิภาพ

### 3. Distinction: Skills vs. MAW
- **Skills**: คือความสามารถภายใน (Internal Capabilities) ที่ติดตั้งให้เอเจนท์ (เช่น `arra-oracle-skills-cli`) เพื่อให้ทำหน้าเฉพาะทางได้
- **MAW (Multi-Agent Orchestration)**: คือ "โครงสร้างพื้นฐาน" (Infrastructure) และ "กาว" (Glue) ที่เชื่อมโยงเอเจนท์หลายตัวเข้าด้วยกัน จัดการเรื่อง Workflow, Messaging, และ Environment (เช่น `maw-js`, tmux sessions)

### 4. Worktree Workflows
- การใช้ `git worktree` ร่วมกับ `tmux` เพื่อให้เอเจนท์หลายตัวสามารถทำงานในคนละ Branch หรือคนละ Feature ของ Codebase เดียวกันได้พร้อมกันโดยไม่ตีกัน

## การนำมาใช้ใน Oracle World
- พัฒนาโครงสร้าง `ψ/` ให้รองรับการมองเห็น (Visibility) ผ่านเครื่องมือ `peek` หรือสถานะแบบ Real-time
- แยกการจัดการ "Skills" (เครื่องมือที่เอเจนท์มี) ออกจาก "MAW" (วิธีการที่เอเจนท์คุยกัน)
- นำแนวคิด Git Worktree มาใช้เมื่อต้องทำ Parallel Development ด้วยเอเจนท์หลายตัว

## แหล่งข้อมูล
- [Multi-Agent Orchestration Book](https://soul-brews-studio.github.io/multi-agent-orchestration-book/)
- [Soul-Brews-Studio GitHub](https://github.com/Soul-Brews-Studio/)
