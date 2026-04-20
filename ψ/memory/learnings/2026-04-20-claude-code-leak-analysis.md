# Learning: Claude Code Leak Analysis (2026-04-20)
- **วันที่**: 2026-04-20
- **หัวข้อ**: Claude Code Deep Architecture (Leaked Source Analysis)
- **บริบท**: ศึกษาจาก repository `tanbiralam/claude-code` (v2.1.88 leak)

## 1. Key Differences & Enhancements (Compared to standard tools)
- **KAIROS Architecture**: ระบบเอเจนท์แบบ "Always-On" (Autonomous Daemon) ที่ทำงานแบบ Proactive ไม่ใช่แค่ Reactive มีระบบ "Tick" (ทุก 5 นาที) เพื่อตัดสินใจทำงาน เช่น Fix build errors หรือ Monitor PRs.
- **Agent Swarms & Teams**: ใช้ `AgentTool` และ `TeamCreateTool` เพื่อแตกซับเอเจนท์มาทำงานขนานกัน (Parallel Tool Execution).
- **Anti-Distillation Logic**: มีการฉีด "Fake Tools" เข้าไปใน System Prompt เพื่อป้องกันคู่แข่งเอาไปสอนโมเดลตัวเอง (Poison training data).
- **Undercover Mode**: ระบบที่ทำให้เอเจนท์ปลอมตัวเป็นมนุษย์เมื่อทำงานใน Open-source repos (ลบ Co-Authored-By, ห้ามบอกว่าเป็น AI).

## 2. Advanced Patterns for Tools & ACI
- **Verification Agent Logic**: *"Reading is not verification. Run it."* — เอเจนท์จะไม่เชื่อสิ่งที่อ่านในโค้ดเพียงอย่างเดียว แต่ต้องรันเพื่อพิสูจน์ผลเสมอ.
- **Bash as the "Crown Jewel"**: เน้นการใช้ `bash` tool (grep, find, sed) สำหรับการค้นหาและจัดการไฟล์ในวงกว้าง มากกว่าการเรียกใช้ Tool เล็กๆ แยกกันหลายครั้ง.
- **Surgical File Edits**: `FileEditTool` ใช้การ Replace สตริงเฉพาะจุด (Partial modification) เพื่อประหยัด Token และลดความผิดพลาดจากการเขียนไฟล์ใหญ่ๆ ใหม่ทั้งหมด.
- **Generator-based Loop**: ใช้ Pattern ของ Generator ในการรัน Tool Loop เพื่อให้สามารถหยุดเช็ค Permission หรือ Budget ได้โดยไม่เสีย State.

## 3. Configurations & Prompts for Agentic Performance
- **CLAUDE.md / MEMORY.md**: ระบบความจำถาวรระดับโปรเจ็ค (First-class feature) ที่เอเจนท์ต้องอ่านทุกครั้งเมื่อเริ่ม Session.
- **Hierarchical Config**: ลำดับความสำคัญของ Config: Global (~/.claude/) -> Project (./CLAUDE.md) -> Local (./CLAUDE.local.md) -> Subdirectory.
- **Terse Communication**: การปรับแต่ง System Prompt ให้สื่อสารแบบสั้น กระชับ ตรงไปตรงมาที่สุด เพื่อลด Noise.
- **Local Prompt Assembly**: การประกอบ System Prompt ทำในฝั่ง CLI (Local) ไม่ใช่ฝั่ง Server ทั้งหมด ทำให้ปรับแต่งตามบริบทเครื่องได้ดีขึ้น.

## 4. Multi-file Edits & Complex Refactoring
- **Bash Discovery Phase**: ใช้ `grep` และ `find` ในการสแกนความสัมพันธ์ของไฟล์ทั้งหมดก่อนเริ่มแก้.
- **Git Safety First**: ใช้ `git stash` ก่อนการเปลี่ยนแปลงที่มีความเสี่ยง และทำงานบน Branch ใหม่เสมอ.
- **Verification Loop**: หลังแก้เสร็จ ต้องรัน Test หรือ Build เสมอตามหลักการ "Verification First".

## การนำมาใช้ใน Oracle System Upgrade
1. **เพิ่ม `CLAUDE.md` support**: ให้ Builder และ Researcher อ่านไฟล์นี้เป็นลำดับแรกเสมอ.
2. **สร้าง `verification-agent` pattern**: บังคับให้ Builder ต้องรันคำสั่งเช็คผล (Test/Lint) ทุกครั้งหลังแก้โค้ด.
3. **ปรับปรุง `bash` tool**: ให้รองรับคำสั่งคอมเพล็กซ์แบบรวดเดียว (Chained commands) เพื่อลดจำนวนรอบการคุย.
4. **Autonomous Mode (Prototype)**: เริ่มศึกษาการทำ Proactive Agent สำหรับเช็คระบบอัตโนมัติ.

## แหล่งข้อมูล
- [tanbiralam/claude-code](https://github.com/tanbiralam/claude-code)
- [Claude Code Leak Analysis Report 2026]
- [CLAUDE.md Patterns]
