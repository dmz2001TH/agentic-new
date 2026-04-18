# Handoff Prompt - สำหรับ Agent ตัวใหม่

## สถานะปัจจุบัน

**โปรเจ็คอยู่**: `G:\My Drive\Agentic` (Google Drive)
**Platform**: Windows + Gemini CLI
**สิ่งที่ทำเสร็จแล้ว**:
- ✅ ติดตั้ง Gemini CLI และ login
- ✅ สร้างโครงสร้างโฟลเดอร์ ψ/
- ✅ สร้าง settings.json และ memory files
- ✅ สร้าง GEMINI.md context file
- ✅ สร้าง commands ทั้งหมด 37 commands (จาก S.txt)
- ✅ ตั้งค่า auto-approve ด้วย script wrapper gemini-yolo
- ✅ Clone repos ทั้งหมด 8 repos:
  - opensource-nat-brain-oracle
  - arra-oracle-skills-cli
  - arra-oracle-v3
  - maw-js
  - pulse-cli
  - oracle-vault-report
  - multi-agent-workflow-kit
  - oracle-maw-guide
- ✅ อัพเดท Oracle-Ecosystem-Summary.md
- ✅ เปิด oracle-vault-report index.html (static HTML dashboard)

## ปัญหาที่พบ

**maw-js และ pulse-cli มีปัญหาบน Windows**:
- ต้องการ symlinks (Windows ไม่รองรับโดย default)
- ต้องการ ghq (GitHub repository management tool)
- ใช้ Bun workspaces (มีปัญหา symlink errors)
- **สาเหตุหลัก**: โปรเจ็คอยู่ใน Google Drive (network drive) ทำให้:
  - WSL path translation ล้มเหลว
  - Google Drive sync มีปัญหากับ symlinks และ file locks
  - npm/bun install ล้มเหลวเพราะ file locks

## สิ่งที่ต้องทำต่อ

**เป้าหมาย**: รัน agent บนเว็บ (web UI)

**ทางเลือก**:

### ทางเลือก 1: ย้ายโปรเจ็คไป local drive (C:\Agentic)
- **ข้อดี**: แก้ปัญหาทั้งหมด (symlinks, WSL path translation, file locks)
- **ข้อเสีย**: ต้องคัดลอกโปรเจ็ค (แต่คัดลอกโดยไม่รวม node_modules และ .git)
- **วิธีทำ**:
  ```powershell
  robocopy "G:\My Drive\Agentic" "C:\Agentic" /E /XD "node_modules" ".git"
  ```
- **หลังย้าย**: ทดสอบติดตั้ง maw-js และ pulse-cli ใน C:\Agentic

### ทางเลือก 2: ใช้ oracle-vault-report (เปิดแล้ว)
- **ข้อดี**: เปิดแล้วใช้ได้เลย (static HTML dashboard)
- **ข้อเสีย**: เป็น dashboard เท่านั้น ไม่ใช่ multi-agent orchestration
- **สถานะ**: เปิด index.html แล้ว ✅

### ทางเลือก 3: ใช้ WSL กับ Google Drive
- **ข้อดี**: รองรับ Linux tools
- **ข้อเสีย**: ต้อง mount Google Drive ใน WSL และยังมีปัญหา sync อยู่
- **วิธีทำ**:
  ```powershell
  wsl sudo mkdir -p /mnt/g
  wsl sudo mount -t drvfs G: /mnt/g
  ```

## คำสั่งที่สำคัญ

**สำหรับทดสอบ maw-js** (หลังย้ายไป local drive):
```bash
cd C:\Agentic
maw ui install
maw serve
maw ui
```

**สำหรับทดสอบ pulse-cli** (หลังย้ายไป local drive):
```bash
cd C:\Agentic\pulse-cli
bun install
bun run pulse
```

**สำหรับ oracle-vault-report** (เปิดแล้ว):
```bash
cd G:\My Drive\Agentic\oracle-vault-report
start index.html
```

## ไฟล์สำคัญ

- `G:\My Drive\Agentic\.gemini\settings.json` - Gemini CLI settings
- `G:\My Drive\Agentic\GEMINI.md` - Oracle context file
- `G:\My Drive\Agentic\Oracle-Ecosystem-Summary.md` - เอกสารสรุป Oracle Ecosystem
- `G:\My Drive\Agentic\gemini-yolo.cmd` - Script wrapper สำหรับ auto-approve
- `G:\My Drive\Agentic\ψ/` - Oracle memory structure

## คำแนะนำ

1. **แนะนำให้ย้ายไป C:\Agentic** เพื่อแก้ปัญหาทั้งหมด
2. **ถ้าไม่ต้องการย้าย**: ใช้ oracle-vault-report ที่เปิดแล้ว
3. **ถ้าต้องการ multi-agent orchestration**: ต้องย้ายไป local drive หรือใช้ WSL

## หมายเหตุ

- โปรเจ็คใช้ Gemini CLI ไม่ใช่ Claude Code
- Commands ทั้งหมดอยู่ใน `.gemini/commands/`
- ใช้ภาษาไทยใน commands ทั้งหมด
- YOLO mode ใช้ผ่าน `gemini-yolo.cmd` หรือ `gemini --yolo`

---
*สร้างโดย Cascade - 17 เมษายน 2026*
