# Learning: Multi-Agent Orchestration (MAW) & Fleet Control
- **วันที่**: 2026-04-20
- **หัวข้อ**: Orchestration Tiers & Fleet Lifecycle
- **บริบท**: ศึกษาจาก Soul Brews Studio (MAW Book) & Singhasingha Guide

## สิ่งที่เรียนรู้ (Core Insights)
1. **Three Tiers of Orchestration**:
   - **In-process (Fast)**: เอเจนท์ตัวเดียวรัน Sub-tasks (Skills)
   - **Coordinated (Team)**: เอเจนท์หลายตัวในเครื่องเดียว (tmux sessions - maw style)
   - **Federated (Independent)**: เอเจนท์ข้ามเครื่อง (WireGuard/VPN)
2. **Skills vs MAW Distinction**:
   - Skills = ผู้ช่วยในห้องคุย (Internal - `/command`)
   - MAW = ผู้จัดการตึก (External - `maw command`)
3. **Visibility Principle**: มนุษย์ต้องเห็นการทำงานของ Fleet เสมอผ่านการ `peek` หรือ `overview` ไม่ใช่แค่ Black-box autonomy
4. **Fleet Lifecycle**: การปลุก (`/ตื่น` - Awakening) คือการสร้างตัวตนถาวร, การเปิด (`maw wake`) คือการเริ่มทำงานรายวัน

## การนำมาใช้ใน Oracle World
- พัฒนา ACI Layer ให้รองรับคำสั่ง `ot-hey` (ส่งสารข้าม Pane)
- ใช้ `maw done` pattern สำหรับการปิดวันอัตโนมัติ (rrr + commit + push)
- แยกแยะการใช้ Skills (สำหรับงานใน session) และ MAW (สำหรับการประสานงานข้าม repo/agent)

## แหล่งข้อมูล
- [MAW Book](https://soul-brews-studio.github.io/multi-agent-orchestration-book/)
- [Singhasingha Manual](/mnt/c/Agentic/คู่มือ-skills-vs-maw.md)
