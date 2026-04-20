# Learning: Agentic Development Tools & ACI (2026)
- **วันที่**: 2026-04-20
- **หัวข้อ**: Agent-Computer Interface (ACI) & Autonomous Coding
- **บริบท**: ศึกษาจาก Claude Code, Aider, Open Interpreter, SWE-agent

## สิ่งที่เรียนรู้ (Core Insights)
1. **ACI (Agent-Computer Interface)**: เอเจนท์ที่เขียนโค้ดได้เก่ง ไม่ใช่เอเจนท์ที่เก่ง Bash แต่เป็นเอเจนท์ที่ใช้ "Tool ที่สรุปผลมาให้แล้ว" (Summarized Tools)
2. **Verification First**: "Reading is not verification. Run it." ต้องรัน Test/Build ยืนยันผลเสมอ (จาก Claude Code Leak)
3. **Surgical Edits**: แก้ไขเฉพาะจุด (String Replacement) แทนการเขียนใหม่ทั้งไฟล์ เพื่อความแม่นยำสูงสุด (จาก Claude Code Leak)
4. **Git-Awareness (Aider)**: การผูกกระบวนการแก้โค้ดเข้ากับ Git Commit อัตโนมัติ
4. **Claude Code Leak Insights**:
    - **Verification Agent Pattern**: "Reading is not verification. Run it." (การอ่านอย่างเดียวไม่ใช่การยืนยัน ต้องรันด้วย)
    - **Bash as "Crown Jewel"**: ใช้ Bash (grep/find) ในการสำรวจ codebase วงกว้างเพื่อเตรียมแผนก่อนแก้
    - **Surgical Edits**: การแก้โค้ดแบบ Partial replace ช่วยลดโอกาสหลุดของโค้ดเดิมในไฟล์ใหญ่
    - **CLAUDE.md Hierarchy**: การใช้ไฟล์ config หลายระดับ (Global/Project/Local) เพื่อส่ง Context ให้เอเจนท์

## การนำมาใช้ใน Oracle World
- พัฒนา `oracle-tools.sh` ให้เป็น ACI เลเยอร์ โดยมีคำสั่งเช่น `ot-diff`, `ot-summarize-repo`, `ot-commit-fix`
- สอนให้ Builder ใช้ Git เป็นส่วนหนึ่งของ Workflow การแก้โค้ด (Work -> Test -> Commit)
- ใช้ `run_shell_command` อย่างมีประสิทธิภาพผ่าน Wrapper ที่ลด Noise ใน Output
- **บังคับใช้ `CLAUDE.md`** ในทุกโปรเจ็คเพื่อเป็น Source of Truth สำหรับเอเจนท์

## แหล่งข้อมูล
- [Claude Code Leak (tanbiralam/claude-code)](https://github.com/tanbiralam/claude-code)
- [Aider](https://github.com/Aider-AI/aider)
- [SWE-agent](https://github.com/princeton-nlp/SWE-agent)
