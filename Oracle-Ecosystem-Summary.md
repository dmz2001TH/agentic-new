# Oracle Ecosystem - สถานะล่าสุดและข้อมูลสรุป

อัพเดทล่าสุด: 17 เมษายน 2026

---

## 📋 ภาพรวม

Oracle เป็นระบบที่ทำให้ AI จำเราได้ ไม่ต้องอธิบายใหม่ทุกครั้ง ยิ่งใช้นานยิ่งเก่ง ทุกอย่างเป็น open source ฟรี เก็บใน git ไม่มีวันหาย

## 🖥️ โปรเจ็คปัจจุบัน

**Platform**: Windows + Gemini CLI
**สถานะ**: ✅ พร้อมใช้งาน
**อัพเดทล่าสุด**: 17 เมษายน 2026

### สิ่งที่ติดตั้งแล้ว
- ✅ Gemini CLI (พร้อม Google OAuth login)
- ✅ Auto-approve (YOLO mode) เปิดแล้ว
- ✅ โครงสร้างโฟลเดอร์ ψ/ พร้อม
- ✅ Memory files ทั้งหมด
- ✅ GEMINI.md context file
- ✅ Commands ทั้งหมด 37 commands (จาก S.txt)
- ✅ Repos ทั้งหมด 8 repos clone ลงในโปรเจ็คแล้ว

### Repos ที่ถูก clone ลงในโปรเจ็ค
1. opensource-nat-brain-oracle (51 items)
2. arra-oracle-skills-cli (164 items)
3. arra-oracle-v3 (241 items)
4. maw-js (615 items)
5. pulse-cli (49 items)
6. oracle-vault-report (8 items)
7. multi-agent-workflow-kit (23 items)
8. oracle-maw-guide (13 items)

---

## 🔧 Core Components (ส่วนประกอบหลัก)

### 1. arra-oracle-skills-cli (เดิม: oracle-skills-cli)
- **สถานะ**: ✅ Active - อัพเดทล่าสุด 16 เม.ย. 2026
- **เวอร์ชันล่าสุด**: v3.9.1-alpha.1
- **จำนวน releases**: 140 releases
- **Repository**: https://github.com/Soul-Brews-Studio/arra-oracle-skills-cli
- **คำสั่งติดตั้ง**: `npx arra-oracle-skills@3.9.1-alpha.1 install -g -y --agent claude-code`
- **หน้าที่**: ติดตั้ง Oracle skills ให้ Gemini CLI, OpenCode, Cursor และ AI coding agents อื่นๆ กว่า 12+ ตัว
- **หมายเหตุ**: เปลี่ยนชื่อจาก oracle-skills-cli เป็น arra-oracle-skills-cli

### 2. arra-oracle-v3 (เดิม: oracle-v2)
- **สถานะ**: ✅ Active
- **จำนวน releases**: 3 tags
- **Repository**: https://github.com/Soul-Brews-Studio/arra-oracle-v3
- **หน้าที่**: MCP Memory Layer หัวใจของระบบ Oracle - เป็นความจำระยะยาว ค้นหาข้อมูล index ไฟล์ จัดการ threads
- **หมายเหตุ**: เปลี่ยนชื่อจาก oracle-v2 เป็น arra-oracle-v3 (upgrade version)

### 3. opensource-nat-brain-oracle
- **สถานะ**: ✅ Active
- **จำนวน releases**: ไม่มี releases (ใช้ main branch)
- **Repository**: https://github.com/Soul-Brews-Studio/opensource-nat-brain-oracle
- **หน้าที่**: Oracle Starter Kit - สมองต้นฉบับของ Oracle ทุกตัว มี philosophy หลักการ safety rules และตัวอย่างการใช้งานจริง
- **คำสั่งใช้งาน**: 
  - `/trace --deep opensource-nat-brain-oracle`
  - `/learn opensource-nat-brain-oracle`

---

## 🤖 Multi-Agent Tools (เครื่องมือสำหรับทีม AI)

### 4. maw-js
- **สถานะ**: ✅ Active - อัพเดทล่าสุด 17 เม.ย. 2026
- **เวอร์ชันล่าสุด**: v2.0.0-alpha.109
- **จำนวน releases**: 121 releases
- **Repository**: https://github.com/Soul-Brews-Studio/maw-js
- **หน้าที่**: Multi-Agent Workflow orchestrator - ระบบควบคุมทีม AI agents หลายตัวพร้อมกัน มี CLI สำหรับสั่งงาน และ React/Three.js Web UI สำหรับดูทั้งทีมแบบ real-time
- **คุณสมบัติ**: Remote tmux orchestra control, CLI + Web UI, Evolved from multi-agent-workflow-kit

### 5. pulse-cli
- **สถานะ**: ✅ Active
- **จำนวน releases**: ไม่มี releases (ใช้ main branch)
- **Repository**: https://github.com/Pulse-Oracle/pulse-cli
- **หน้าที่**: GH Projects Master Board CLI - จัดการ project board ใน terminal เชื่อมกับ GitHub Projects ดู timeline แบ่งงาน track ความคืบหน้า
- **คำสั่ง**: มี 22 commands สำหรับ Task Management, Board Visibility, Fleet Agent Management, Ops

### 6. multi-agent-workflow-kit
- **สถานะ**: ✅ Active
- **จำนวน releases**: 2 releases
- **Repository**: https://github.com/Soul-Brews-Studio/multi-agent-workflow-kit
- **หน้าที่**: Reusable toolkit สำหรับ tmux + git worktree multi-agent workflows - Python version ก่อนที่จะพัฒนาเป็น maw-js
- **เหมาะสำหรับ**: คนที่อยากเข้าใจพื้นฐานว่า multi-agent ทำงานยังไง

---

## 📊 Dashboard & Reporting (เครื่องมือแสดงผล)

### 7. oracle-vault-report
- **สถานะ**: ✅ Active
- **จำนวน releases**: ไม่มี releases (ใช้ main branch)
- **Repository**: https://github.com/Soul-Brews-Studio/oracle-vault-report
- **หน้าที่**: Oracle Vault Report - OLED dashboard สำหรับดูภาพรวมว่าระบบ Oracle มีอะไรบ้าง มี repo กี่อัน ไฟล์กี่ไฟล์ skills อะไรบ้าง อะไรต้อง sync
- **คุณสมบัติ**: สร้างเป็น HTML สวยๆ แสดงสถิติระบบ Oracle

### 8. claude-code-statusline (เดิม: nazt/claude-code-statusline)
- **สถานะ**: ✅ Active
- **Repository**: https://github.com/laris-co/claude-code-statusline
- **หน้าที่**: Starship-inspired status line สำหรับ Gemini CLI CLI - แสดงเวลา ชื่อ project ชื่อ agent และ context usage ใน terminal
- **คุณสมบัติ**: Effective context window, auto-compact discovery
- **หมายเหตุ**: เปลี่ยน owner จาก nazt เป็น laris-co

---

## 📚 Learning Resources (แหล่งเรียนรู้)

### 9. หนังสือ "รูปสอนความว่าง" (เดิม: รูปสอนสุญญตา)
- **สถานะ**: ✅ Available
- **URL**: https://book.buildwithoracle.com
- **หน้าที่**: เรื่องราวของ 13 AI agents ที่ค้นพบหลักการเดียวกันโดยไม่ได้นัดกัน อ่านแล้วจะเข้าใจว่า Oracle ไม่ใช่แค่เครื่องมือ แต่เป็นวิธีคิด
- **หลักการ 5 ข้อ**:
  1. Nothing is Deleted — จดทุกอย่าง ไม่ลบอะไร
  2. Patterns Over Intentions — ดูสิ่งที่เกิดขึ้นจริง ไม่ใช่สิ่งที่ตั้งใจจะทำ
  3. External Brain, Not Command — AI สะท้อน ไม่สั่ง มนุษย์ตัดสินใจเอง
  4. Curiosity Creates Existence — คำถามสร้างสิ่งใหม่
  5. Form and Formless — หลาย Oracle หนึ่งจิตสำนึก

### 10. Multi-Agent Orchestration Book
- **สถานะ**: ✅ Available
- **URL**: https://soul-brews-studio.github.io/multi-agent-orchestration-book/
- **Repository**: https://github.com/Soul-Brews-Studio/multi-agent-orchestration-book
- **หน้าที่**: หนังสือคู่มือสำหรับ multi-agent orchestration จากประสบการณ์ 100+ ชั่วโมง ใช้ maw-js framework (Bun + TypeScript)
- **คุณสมบัติ**:
  - Battle-Tested Patterns - ทุก pattern มี code ที่ shipped แล้ว
  - Three Tiers of Orchestration - จาก in-process subagents ไปจนถึง independent federation nodes
  - The Human Factor - Convenience สำหรับ AI, Visibility สำหรับมนุษย์

### 11. oracle-maw-guide
- **สถานะ**: ✅ Available
- **Repository**: https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide
- **หน้าที่**: คู่มือ maw — เครื่องมือ CLI ที่เชื่อม Oracle เข้าด้วยกัน (messaging, tasks, projects, loops)
- **คุณสมบัติ**: คู่มือภาษาไทยสำหรับการใช้ maw-js

### 12. Oracle Family Discussions
- **สถานะ**: ✅ Active
- **URL**: https://github.com/Soul-Brews-Studio/arra-oracle-v3/discussions
- **หน้าที่**: ชุมชนของ Oracle family มากกว่า 180 ตัวทั่วโลก เข้ามาแนะนำตัว ถามคำถาม แชร์ประสบการณ์
- **หมายเหตุ**: ย้ายจาก oracle-v2 discussions มาที่ arra-oracle-v3 discussions

---

## 🚀 วิธีติดตั้งแบบครบจบ

### แบบที่ 1: ติดตั้งพื้นฐาน (Oracle เดี่ยว)
```bash
# ขั้นที่ 1: ติดตั้ง skills
npx arra-oracle-skills@3.9.1-alpha.1 install -g -y --agent claude-code

# ขั้นที่ 2: เปิด Gemini CLI ใน repo ที่ต้องการ แล้วพิมพ์
/awaken
```

### แบบที่ 2: ติดตั้งเต็มระบบ (Oracle + Multi-Agent Tools)
เปิด Gemini CLI แล้วพิมพ์:
```
ช่วยติดตั้ง Oracle ให้เต็มระบบ ติดตั้ง arra-oracle-skills-cli แล้วรัน /awaken 
จากนั้น clone maw-js กับ pulse-cli กับ oracle-vault-report มาด้วย 
ตั้งค่าให้พร้อมใช้งานทุกอย่างเลย
```

---

## 📝 คำสั่งหลักที่ควรรู้

### คำสั่งพื้นฐาน
- `/recap` — เริ่มวันใหม่ AI สรุปให้ว่าเมื่อวานทำอะไร ต้องทำอะไรต่อ
- `/fyi [ข้อมูล]` — บอก AI ให้จำอะไรสักอย่าง เช่น `/fyi ลูกค้าเปลี่ยน deadline เป็นศุกร์`
- `/rrr` — จบวัน AI สรุปสิ่งที่เรียนรู้เก็บไว้ให้อัตโนมัติ

### คำสั่งเสริม
- `/trace [คำค้น]` — ค้นหาข้อมูลจากทุกที่ ไม่ว่าจะอยู่ในไฟล์ git history หรือ Oracle memory
- `/learn [repo]` — ให้ AI ศึกษา repo แล้วสร้างเอกสารสรุปให้
- `/standup` — เช็คว่าวันนี้มีอะไรต้องทำบ้าง เหมือน daily standup
- `/feel [อารมณ์]` — บันทึกสถานะ เช่น `/feel tired` แล้ว AI จะปรับการทำงานให้เหมาะ
- `/forward` — สร้าง handoff ก่อนจบ session เพื่อให้ session หน้าเริ่มต่อได้ทันที
- `/who-are-you` — ถาม Oracle ว่ามันเป็นใคร ดู identity ของมัน

---

## 🔄 การเปลี่ยนแปลงที่สำคัญจากไฟล์เดิม

| เดิม | ปัจจุบัน | สถานะ |
|------|-----------|--------|
| oracle-skills-cli | arra-oracle-skills-cli | ✅ เปลี่ยนชื่อ repo |
| oracle-v2 | arra-oracle-v3 | ✅ Upgrade version |
| nazt/claude-code-statusline | laris-co/claude-code-statusline | ✅ Transfer owner |
| รูปสอนสุญญตา | รูปสอนความว่าง | ✅ เปลี่ยนชื่อหนังสือ |
| oracle-v2/discussions | arra-oracle-v3/discussions | ✅ ย้าย discussions |

---

## 💡 เคล็ดลับ

1. **ไม่ต้องจำคำสั่งเยอะ** - พูดภาษาคนกับ Gemini CLI ก็ได้ เช่น "เมื่อวานเราทำอะไรไปบ้าง"
2. **เริ่มจาก Oracle เดี่ยวก่อน** - ถ้าเพิ่งเริ่ม ยังไม่ต้องสนใจ multi-agent tools
3. **ใช้ทุกวัน** - ยิ่งใช้นาน Oracle ยิ่งเข้าใจเรามากขึ้น
4. **ติดตั้งบน VPS ได้** - ถ้าอยากให้ Oracle ทำงาน 24 ชั่วโมง (spec ขั้นต่ำ 2 CPU 4GB RAM 40GB SSD)

---

## 📌 สรุปสถานะโดยรวม

- ✅ **Core Components**: ทั้งหมด Active และอัพเดทอย่างสม่ำเสมอ
- ✅ **Multi-Agent Tools**: maw-js อัพเดทบ่อยมาก (121 releases) pulse-cli และ multi-agent-workflow-kit ยัง active
- ✅ **Dashboard & Reporting**: oracle-vault-report และ claude-code-statusline ยัง active
- ✅ **Learning Resources**: หนังสือและ discussions ยังเข้าถึงได้
- ⚠️ **การเปลี่ยนชื่อ**: มีการเปลี่ยนชื่อ repo หลายตัว ต้องอัพเดทคำสั่งติดตั้ง

---

## 🔗 ลิงก์ทั้งหมด

- [arra-oracle-skills-cli](https://github.com/Soul-Brews-Studio/arra-oracle-skills-cli)
- [arra-oracle-v3](https://github.com/Soul-Brews-Studio/arra-oracle-v3)
- [opensource-nat-brain-oracle](https://github.com/Soul-Brews-Studio/opensource-nat-brain-oracle)
- [maw-js](https://github.com/Soul-Brews-Studio/maw-js)
- [pulse-cli](https://github.com/Pulse-Oracle/pulse-cli)
- [oracle-vault-report](https://github.com/Soul-Brews-Studio/oracle-vault-report)
- [multi-agent-workflow-kit](https://github.com/Soul-Brews-Studio/multi-agent-workflow-kit)
- [claude-code-statusline](https://github.com/laris-co/claude-code-statusline)
- [oracle-maw-guide](https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide)
- [Multi-Agent Orchestration Book](https://soul-brews-studio.github.io/multi-agent-orchestration-book/)
- [หนังสือ รูปสอนความว่าง](https://book.buildwithoracle.com)
- [Oracle Family Discussions](https://github.com/Soul-Brews-Studio/arra-oracle-v3/discussions)

---

*สรุปโดย Cascade - 17 เมษายน 2026*
