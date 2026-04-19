# 🔮 คู่มือติดตั้ง Oracle v3 ตั้งแต่ศูนย์ (Windows + Windsurf)

**สำหรับ:** คนที่ไม่เคยติดตั้งอะไรเลย เริ่มจาก 0
**เครื่องมือที่ใช้:** Windsurf เป็น AI editor หลัก
**วันที่:** 2026-04-19

---

## 📦 สิ่งที่ต้องติดตั้งทั้งหมด (5 อย่าง)

| # | โปรแกรม | ไว้ทำอะไร | เสียเงินมั้ย |
|---|---------|-----------|-------------|
| 1 | **Git** | ดาวน์โหลดโปรเจ็ค | ฟรี |
| 2 | **Node.js** | รัน JavaScript บางตัว | ฟรี |
| 3 | **Bun** | รันโปรเจ็คหลัก (เร็วกว่า Node) | ฟรี |
| 4 | **tmux** (ผ่าน WSL) | ให้ AI agent ทำงานใน background | ฟรี |
| 5 | **Gemini CLI** | AI ที่ทำงานใน tmux เป็น agent | ฟรี (login Google) |

**รวมเวลาติดตั้ง:** ประมาณ 15-20 นาที

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 1: ติดตั้ง Git
## ═══════════════════════════════════════

### ถ้ายังไม่มี Git

1. ไปที่ https://git-scm.com/download/win
2. กดปุ่มดาวน์โหลด (มันจะดาวน์โหลดอัตโนมัติ)
3. เปิดไฟล์ `.exe` ที่ดาวน์โหลดมา
4. กด **Next** รัวๆ จนจบ (ไม่ต้องเปลี่ยนอะไร)
5. เปิด **Command Prompt** หรือ **PowerShell** ใหม่

### ตรวจสอบ

```
git --version
```

ควรแสดงอะไรประมาณ `git version 2.4x.x`

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 2: ติดตั้ง Node.js
## ═══════════════════════════════════════

### ถ้ายังไม่มี Node.js

1. ไปที่ https://nodejs.org
2. กดปุ่ม **LTS** (ปุ่มใหญ่สีเขียว) เพื่อดาวน์โหลด
3. เปิดไฟล์ `.msi` ที่ดาวน์โหลดมา
4. กด **Next** รัวๆ จนจบ
5. เปิด **Command Prompt** หรือ **PowerShell** ใหม่

### ตรวจสอบ

```
node --version
npm --version
```

ควรแสดงเวอร์ชันทั้งสองอัน

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 3: ติดตั้ง Bun
## ═══════════════════════════════════════

Bun เป็น runtime ที่เร็วกว่า Node.js โปรเจ็คนี้ต้องใช้ Bun รัน

### วิธีติดตั้ง

1. เปิด **PowerShell** (คลิกขวา → Run as Administrator)
2. พิมพ์คำสั่งนี้แล้วกด Enter:

```powershell
powershell -c "irm bun.sh/install.ps1 | iex"
```

3. รอจนมันบอกว่า `bun was installed successfully`
4. **ปิด PowerShell แล้วเปิดใหม่** (สำคัญ! เพื่อให้ PATH อัพเดท)

### ตรวจสอบ

```powershell
bun --version
```

ควรแสดงเวอร์ชัน เช่น `1.3.x`

### ถ้า bun --version บอกว่าไม่รู้จัก

เพิ่ม PATH ด้วยตนเอง:

```powershell
$env:PATH += ";$env:USERPROFILE\.bun\bin"
bun --version
```

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 4: ติดตั้ง WSL + tmux
## ═══════════════════════════════════════

tmux เป็นตัวจัดการ terminal ที่ให้ AI agent ทำงานใน background ได้ โปรเจ็คนี้ต้องใช้

### 4.1 ติดตั้ง WSL

1. เปิด **PowerShell** (Run as Administrator)
2. พิมพ์:

```powershell
wsl --install
```

3. มันจะติดตั้ง Ubuntu อัตโนมัติ
4. **รีสตาร์ทเครื่อง** เมื่อเสร็จ
5. หลังรีสตาร์ท มันจะเปิดหน้าต่าง Ubuntu ขึ้นมา ให้ตั้ง username และ password (จำไว้ด้วย!)

### 4.2 ติดตั้ง tmux ใน WSL

1. เปิด **Ubuntu** (ค้นหา "Ubuntu" ใน Start Menu)
2. พิมพ์:

```bash
sudo apt update && sudo apt install tmux -y
```

3. ใส่ password ที่ตั้งไว้
4. รอจนติดตั้งเสร็จ

### ตรวจสอบ

```bash
tmux -V
```

ควรแสดงเวอร์ชัน เช่น `tmux 3.4`

### ⚠️ สำคัญ

tmux ต้องรัน **ใน Ubuntu (WSL)** เท่านั้น ไม่ใช่ใน PowerShell

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 5: ติดตั้ง Gemini CLI
## ═══════════════════════════════════════

Gemini CLI เป็น AI ที่จะถูก spawn ใน tmux session แต่ละตัว เป็น "ตัวทำงาน" ของ agent

### ติดตั้ง

1. เปิด **PowerShell** หรือ **Command Prompt**
2. พิมพ์:

```powershell
npm install -g @google/gemini-cli
```

3. รอจนติดตั้งเสร็จ

### Login ด้วยบัญชี Google

1. พิมพ์:

```powershell
gemini
```

2. มันจะเปิด browser ขึ้นมา
3. เลือกบัญชี Google ของคุณ
4. กด **Allow** เพื่ออนุญาต
5. กลับมาที่ terminal จะเห็นว่า login สำเร็จ

### ตรวจสอบ

```powershell
gemini --version
```

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 6: ดาวน์โหลดโปรเจ็ค
## ═══════════════════════════════════════

### สร้างโฟลเดอร์ + Clone

1. เปิด **PowerShell**
2. พิมพ์:

```powershell
mkdir C:\Agentic
cd C:\Agentic
git clone https://github.com/dmz2001TH/agentic.git .
```

> ⚠️ มี **จุด (.)** ท้ายคำสั่ง สำคัญมาก! มันจะ clone ไฟล์เข้ามาในโฟลเดอร์ปัจจุบัน

### ตรวจสอบ

```powershell
dir
```

ควรเห็น:
```
arra-oracle-v3/        ← สมองความจำ
maw-js/                ← ระบบควบคุม
start-oracle.cmd       ← รันระบบทั้งหมด
start-nexus.cmd        ← ปลุก Agent
INSTALLATION.md        ← คู่มือฉบับเต็ม
```

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 7: ติดตั้ง Dependencies
## ═══════════════════════════════════════

Dependencies = libraries ที่โปรเจ็คต้องใช้ ต้องติดตั้ง 3 ที่

```powershell
cd C:\Agentic

# ที่ 1: maw-js (ระบบควบคุม)
cd maw-js
bun install
cd ..

# ที่ 2: Oracle Core (สมองความจำ)
cd arra-oracle-v3
bun install
cd ..

# ที่ 3: Frontend (หน้า Dashboard)
cd arra-oracle-v3\frontend
bun install
cd ..\..
```

แต่ละอันรอจนเห็น `packages installed` (ประมาณ 1-5 วินาที)

### ตรวจสอบ

```powershell
dir maw-js\node_modules 2>nul && echo "maw-js OK"
dir arra-oracle-v3\node_modules 2>nul && echo "oracle OK"
dir arra-oracle-v3\frontend\node_modules 2>nul && echo "frontend OK"
```

ทั้ง 3 ควรแสดง `OK`

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 8: รันระบบทั้งหมด
## ═══════════════════════════════════════

ระบบมี 3 ส่วนที่ต้องรันพร้อมกัน:

```
Port 47778 = Oracle Core    (สมองความจำ — ทำงานเบื้องหลัง)
Port 3456  = Maw API        (ระบบควบคุม — คุณสั่งงานผ่านนี้)
Port 5173  = Dashboard      (หน้าเว็บ — คุณดูสถานะผ่านนี้)
```

### ทางลัด: รันทีเดียวจบ

```powershell
cd C:\Agentic
.\start-oracle.cmd
```

มันจะเปิด **3 หน้าต่าง CMD** อัตโนมัติ:

- 🟢 หน้าต่าง 1: Oracle Core (Port 47778)
- 🟣 หน้าต่าง 2: Maw API (Port 3456)
- 🟡 หน้าต่าง 3: Dashboard (Port 5173)

**รอ 10-15 วินาที** ให้ทุก server โหลดเสร็จ

### เปิด Dashboard

เปิด browser แล้วไปที่:

```
http://localhost:5173
```

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 9: ปลุก Agent ตัวแรก (Nexus)
## ═══════════════════════════════════════

### 9.1 สร้างโฟลเดอร์ให้ Agent

```powershell
mkdir C:\Agentic\ψ\agents\nexus\memory
```

### 9.2 สร้างไฟล์ตัวตน

เปิด **Notepad** หรือ **Windsurf** แล้วสร้างไฟล์ `C:\Agentic\ψ\agents\nexus\identity.md`:

```markdown
# Agent Identity
- Name: Nexus
- Role: Memory Coordinator
- Project: Agentic
- Platform: Gemini CLI (Windows)
- Created: 2026-04-19
- Sessions: 0
```

### 9.3 ลงทะเบียนในระบบ

เปิดไฟล์ `C:\Agentic\ψ\memory\people.md` แล้วเพิ่ม:

```markdown
## Nexus
- **บทบาท**: Memory Coordinator Agent
- **ติดต่อล่าสุด**: 2026-04-19
```

### 9.4 ปลุก Nexus

**วิธีที่ 1: ผ่าน Ubuntu/WSL**

1. เปิด **Ubuntu** (ค้นหา "Ubuntu" ใน Start Menu)
2. พิมพ์:

```bash
cd /mnt/c/Agentic
tmux new-session -d -s nexus "gemini --yolo"
```

**วิธีที่ 2: ผ่านไฟล์ (ง่ายกว่า)**

```powershell
# ใน PowerShell
cd C:\Agentic
.\start-nexus.cmd
```

### 9.5 ตรวจสอบว่า Nexus ออนไลน์

ใน Ubuntu/WSL:
```bash
tmux list-sessions
```

ควรเห็น `nexus: 1 windows`

หรือดูใน Dashboard: http://localhost:5173 → มองหา nexus ใน Fleet

---

## ═══════════════════════════════════════
## ขั้นตอนที่ 10: ใช้งานร่วมกับ Windsurf
## ═══════════════════════════════════════

### เปิดโปรเจ็คใน Windsurf

1. เปิด **Windsurf**
2. กด **File → Open Folder**
3. เลือก `C:\Agentic`
4. Windsurf จะเห็นไฟล์ทั้งหมด

### สิ่งที่ทำใน Windsurf ได้

- แก้ไขโค้ด (config, template, scripts)
- ดูไฟล์ memory (`ψ/memory/` ต่างๆ)
- แก้ identity (`ψ/agents/nexus/identity.md`)
- ใช้ AI ของ Windsurf ช่วยเขียนโค้ด

### สิ่งที่ต้องรันใน Terminal แยก

ไม่ต้องรันใน Windsurf terminal ให้รันใน **PowerShell** แยกต่างหาก:

- `.\start-oracle.cmd` — เริ่มระบบทั้งหมด
- `.\start-nexus.cmd` — ปลุก Agent
- `.\finish-day.ps1` — จบวัน

---

## ═══════════════════════════════════════
## ทุกวัน: ขั้นตอนการใช้งาน
## ═══════════════════════════════════════

### เริ่มต้นวัน

```
1. PowerShell:  cd C:\Agentic && .\start-oracle.cmd
2. Ubuntu/WSL:  tmux new-session -d -s nexus "gemini --yolo"
3. Browser:     http://localhost:5173
4. Windsurf:    เปิดโฟลเดอร์ C:\Agentic
```

### ระหว่างวัน

```
- ดูสถานะ:    http://localhost:5173
- คุยกับ Agent: tmux attach -t nexus (ใน Ubuntu)
- ออกจาก tmux:  Ctrl+B แล้วกด D (ไม่ฆ่า session)
```

### จบวัน

```
PowerShell:  cd C:\Agentic && .\finish-day.ps1
```

### หยุดระบบทั้งหมด

```powershell
taskkill /F /IM bun.exe /T
taskkill /F /IM node.exe /T
```

ใน Ubuntu/WSL:
```bash
tmux kill-server
```

---

## ═══════════════════════════════════════
## แก้ปัญหาที่พบบ่อย
## ═══════════════════════════════════════

### ❌ bun: command not found

ปิด PowerShell เปิดใหม่ ถ้ายังไม่ได้ → ติดตั้ง bun ใหม่ตามขั้นตอนที่ 3

### ❌ tmux: command not found

tmux ต้องรันใน **Ubuntu** ไม่ใช่ PowerShell เปิด Ubuntu แล้วรัน

### ❌ หน้าจอ Dashboard ขาวเปล่า

Maw API ไม่ได้รัน → รัน `.\start-oracle.cmd` ใหม่

### ❌ Error: EADDRINUSE

มี server เก่าค้างอยู่ → รัน `taskkill /F /IM bun.exe /T` แล้วรันใหม่

### ❌ 0 Agents ใน Dashboard

ไม่มี tmux session → เปิด Ubuntu แล้วรัน `tmux new-session -d -s nexus "gemini --yolo"`

### ❌ git clone ไม่ได้

```powershell
git clone https://github.com/dmz2001TH/agentic.git C:\Agentic --depth 1
```

---

## ═══════════════════════════════════════
## สรุปแบบสั้นที่สุด
## ═══════════════════════════════════════

### ติดตั้งครั้งแรก (ทำครั้งเดียว)

```
1. ติดตั้ง Git        → https://git-scm.com/download/win
2. ติดตั้ง Node.js    → https://nodejs.org (กด LTS)
3. ติดตั้ง Bun        → powershell -c "irm bun.sh/install.ps1 | iex"
4. ติดตั้ง WSL        → wsl --install (แล้วรีสตาร์ท)
5. ติดตั้ง tmux       → Ubuntu: sudo apt install tmux -y
6. ติดตั้ง Gemini CLI → npm install -g @google/gemini-cli
7. Login Google       → gemini (login ผ่าน browser)
8. ดาวน์โหลดโปรเจ็ค   → git clone https://github.com/dmz2001TH/agentic.git C:\Agentic .
9. ติดตั้ง Dependencies → รัน bun install ใน 3 โฟลเดอร์
```

### ใช้งานทุกวัน

```
1. PowerShell:  cd C:\Agentic && .\start-oracle.cmd
2. Ubuntu/WSL:  tmux new-session -d -s nexus "gemini --yolo"
3. Browser:     http://localhost:5173
4. Windsurf:    เปิดโฟลเดอร์ C:\Agentic
```

### จบวัน

```
PowerShell:  cd C:\Agentic && .\finish-day.ps1
```

---

**มีปัญหาอะไร ถามได้เลย**
