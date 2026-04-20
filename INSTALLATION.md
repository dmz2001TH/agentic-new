# 📦 คู่มือการติดตั้ง Oracle v3 Fleet & Dashboard (Windows)

**อัพเดทล่าสุด:** 2026-04-19
**สถานะ:** ใช้งานได้ 100% หลังแก้ไข

---

## 📖 สารบัญ

1. [ภาพรวมระบบ](#ภาพรวมระบบ)
2. [สิ่งที่ต้องมีก่อนติดตั้ง](#สิ่งที่ต้องมีก่อนติดตั้ง)
3. [ขั้นตอนที่ 1: ติดตั้ง Bun](#ขั้นตอนที่-1-ติดตั้ง-bun)
4. [ขั้นตอนที่ 2: ติดตั้ง tmux](#ขั้นตอนที่-2-ติดตั้ง-tmux)
5. [ขั้นตอนที่ 3: ติดตั้ง Gemini CLI](#ขั้นตอนที่-3-ติดตั้ง-gemini-cli)
6. [ขั้นตอนที่ 4: Clone โปรเจ็ค](#ขั้นตอนที่-4-clone-โปรเจ็ค)
7. [ขั้นตอนที่ 5: ติดตั้ง Dependencies](#ขั้นตอนที่-5-ติดตั้ง-dependencies)
8. [ขั้นตอนที่ 6: รันระบบทั้งหมด](#ขั้นตอนที่-6-รันระบบทั้งหมด)
9. [ขั้นตอนที่ 7: ปลุก Agent ตัวแรก](#ขั้นตอนที่-7-ปลุก-agent-ตัวแรก)
10. [ขั้นตอนที่ 8: จบวัน (Daily Retrospective)](#ขั้นตอนที่-8-จบวัน)
11. [Port Mapping](#port-mapping)
12. [การแก้ปัญหา (Troubleshooting)](#การแก้ปัญหา)
13. [คำสั่งที่ใช้บ่อย](#คำสั่งที่ใช้บ่อย)

---

## ภาพรวมระบบ

Oracle v3 ประกอบด้วย 3 ส่วนหลักที่ต้องรันประสานกัน:

```
┌─────────────────────────────────────────────────────────┐
│                    Browser (คุณ)                         │
│              http://localhost:5173                       │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│           Frontend Dashboard (Port 5173)                │
│         arra-oracle-v3/frontend — Vite + React          │
└──────────────────────┬──────────────────────────────────┘
                       │ /api → proxy
┌──────────────────────▼──────────────────────────────────┐
│           Maw API Server (Port 3456)                    │
│         maw-js — Elysia.js Fleet Controller             │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  GOD   │  │ god-     │  │  Gemini  │  ← Agents    │
│  │ (tmux)   │  │ oracle   │  │  (tmux)  │    (tmux)    │
│  └──────────┘  └──────────┘  └──────────┘              │
└──────────────────────┬──────────────────────────────────┘
                       │ oracleUrl
┌──────────────────────▼──────────────────────────────────┐
│           Oracle Core (Port 47778)                      │
│     arra-oracle-v3 — Hono.js + SQLite + Vector DB      │
│            สมองความจำ / Knowledge Base                   │
└─────────────────────────────────────────────────────────┘
```

**หลักการทำงาน:**
- คุณสั่งงานผ่าน **Dashboard** (port 5173) หรือ **maw CLI** (port 3456)
- Maw API จัดการ tmux sessions ของ agents แต่ละตัว
- Oracle Core เก็บความจำ ค้นหาข้อมูล จัดการ knowledge base
- Agent ทำงานใน tmux session ของตัวเอง (gemini --yolo)

---

## สิ่งที่ต้องมีก่อนติดตั้ง

| ซอฟต์แวร์ | 用途 | จำเป็น |
|-----------|------|---------|
| **Windows 10/11** | ระบบปฏิบัติการ | ✅ |
| **Git** | Clone repo | ✅ |
| **Bun** | JavaScript Runtime | ✅ |
| **tmux** | Terminal Multiplexer (จัดการ agent) | ✅ |
| **Gemini CLI** | AI ที่ run ใน tmux | ✅ |
| **WSL** (แนะนำ) | รัน tmux + Bun ง่ายขึ้น | ⚡ แนะนำ |

---

## ขั้นตอนที่ 1: ติดตั้ง Bun

### ตัวเลือก A: ติดตั้งบน Windows โดยตรง

```powershell
# เปิด PowerShell (Run as Administrator)
powershell -c "irm bun.sh/install.ps1 | iex"
```

### ตัวเลือก B: ติดตั้งผ่าน WSL (แนะนำ)

```bash
# ใน WSL (Ubuntu)
curl -fsSL https://bun.sh/install | bash
```

### ตรวจสอบว่าติดตั้งสำเร็จ

```powershell
bun --version
# ควรแสดงเวอร์ชัน เช่น 1.2.x
```

---

## ขั้นตอนที่ 2: ติดตั้ง tmux

### ตัวเลือก A: ผ่าน WSL (แนะนำ ง่ายสุด)

```bash
# ใน WSL
sudo apt update && sudo apt install tmux -y
tmux -V
# ควรแสดงเวอร์ชัน เช่น tmux 3.4
```

### ตัวเลือก B: ผ่าน MSYS2

```bash
# ใน MSYS2
pacman -S tmux
```

### ตัวเลือก C: ผ่าน Git Bash

ต้องติดตั้ง tmux เพิ่มเติมจาก https://github.com/nicholasgasior/gow-tmux หรือใช้ chocolatey:

```powershell
choco install tmux
```

---

## ขั้นตอนที่ 3: ติดตั้ง Gemini CLI

```powershell
# ติดตั้งผ่าน npm (ต้องมี Node.js)
npm install -g @google/gemini-cli

# Login ด้วยบัญชี Google
gemini
# จะเปิด browser ให้ login → เลือกบัญชี Google ได้เลย
# ไม่ต้องใช้ API key!
```

### ตรวจสอบว่า login สำเร็จ

```powershell
gemini --version
# ควรแสดงเวอร์ชัน
```

---

## ขั้นตอนที่ 4: Clone โปรเจ็ค

```powershell
# สร้างโฟลเดอร์หลัก
mkdir C:\Agentic
cd C:\Agentic

# Clone repo
git clone https://github.com/dmz2001TH/agentic.git .

# ตรวจสอบโครงสร้าง
dir
# ควรเห็น: maw-js, arra-oracle-v3, start-oracle.cmd, etc.
```

> ⚠️ **สำคัญ:** ถ้า clone ไปที่อื่นนอกจาก `C:\Agentic` ก็ใช้ได้ แต่ต้องรัน `start-oracle.cmd` จากโฟลเดอร์นั้น (มันใช้ `%~dp0` หา path อัตโนมัติ)

---

## ขั้นตอนที่ 5: ติดตั้ง Dependencies

ต้องรัน `bun install` ใน 3 ที่:

```powershell
# 1. maw-js (ระบบควบคุม Fleet)
cd C:\Agentic\maw-js
bun install
echo "maw-js dependencies installed ✓"

# 2. Oracle Core (สมองความจำ)
cd C:\Agentic\arra-oracle-v3
bun install
echo "Oracle Core dependencies installed ✓"

# 3. Frontend Dashboard (หน้าเว็บ)
cd C:\Agentic\arra-oracle-v3\frontend
bun install
echo "Frontend dependencies installed ✓"

# กลับไปโฟลเดอร์หลัก
cd C:\Agentic
```

### ตรวจสอบว่าติดตั้งสำเร็จ

```powershell
# แต่ละโฟลเดอร์ควรมี node_modules/
dir maw-js\node_modules 2>nul && echo "maw-js ✓" || echo "maw-js ✗ MISSING"
dir arra-oracle-v3\node_modules 2>nul && echo "oracle ✓" || echo "oracle ✗ MISSING"
dir arra-oracle-v3\frontend\node_modules 2>nul && echo "frontend ✓" || echo "frontend ✗ MISSING"
```

---

## ขั้นตอนที่ 6: รันระบบทั้งหมด

### ทางลัด: รันทีเดียวจบ (แนะนำ)

```powershell
cd C:\Agentic
.\start-oracle.cmd
```

จะเปิด 3 หน้าต่าง CMD โดยอัตโนมัติ:
- 🟢 หน้าต่าง 1: Oracle Core (Port 47778)
- 🟣 หน้าต่าง 2: Maw API (Port 3456)
- 🟡 หน้าต่าง 3: Frontend Dashboard (Port 5173)

**รอ 5-10 วินาที** ให้ทุก server โหลดเสร็จ แล้วเปิด browser ไปที่:

```
http://localhost:5173
```

### รันทีละตัว (ถ้าอยากเห็น log / debug)

เปิด **3 Terminal** แยกกัน:

#### Terminal 1: Oracle Core (สมองความจำ)

```powershell
cd C:\Agentic\arra-oracle-v3
bun src\server.ts
```

รอจนเห็น:
```
🔮 Oracle HTTP server listening on port 47778
```

#### Terminal 2: Maw API Server (ระบบควบคุม)

```powershell
cd C:\Agentic\maw-js
bun server.ts
```

รอจนเห็น:
```
🚀 maw serve → http://localhost:3456
```

#### Terminal 3: Frontend Dashboard (หน้าเว็บ)

```powershell
cd C:\Agentic\arra-oracle-v3\frontend
bun run dev --port 5173 --host localhost
```

รอจนเห็น:
```
Vite v7.x.x ready in xxx ms
➜  Local:   http://localhost:5173
```

### ลำดับการรันสำคัญมาก!

```
ต้องรันตามลำดับนี้:

  1. Oracle Core (47778)  ← รันก่อน เพราะ maw-js จะเชื่อมมาที่นี่
  2. Maw API (3456)       ← รันที่ 2 เพราะ frontend จะ proxy มาที่นี่
  3. Frontend (5173)      ← รันสุดท้าย
```

---

## ขั้นตอนที่ 7: ปลุก Agent ตัวแรก

### สร้างโฟลเดอร์และไฟล์ identity ให้ GOD

```powershell
# สร้างโฟลเดอร์ memory
mkdir -p C:\Agentic\ψ\agents\god\memory
```

สร้างไฟล์ `C:\Agentic\ψ\agents\god\identity.md`:

```markdown
# Agent Identity
- Name: GOD
- Role: Memory Coordinator — จัดการความจำและเชื่อมต่อ Oracle Core
- Project: Agentic
- Platform: Gemini CLI (Windows)
- Created: 2026-04-19
- Last Active: 2026-04-19
- Sessions: 0
- Principles: Nothing is Deleted | Patterns Over Intentions | External Brain Not Commander
```

### ลงทะเบียน GOD ในระบบ

เปิดไฟล์ `C:\Agentic\ψ\memory\people.md` แล้วเพิ่ม:

```markdown
## GOD
- **บทบาท**: Memory Coordinator Agent
- **ความชอบ**: ทำงานเงียบๆ จัดการความจำ
- **สิ่งที่ต้องจำ**: Agent ตัวแรกของทีม
- **ติดต่อล่าสุด**: 2026-04-19
```

### ปลุก GOD ผ่าน tmux

```powershell
# สร้าง tmux session ชื่อ "god" แล้วรัน gemini --yolo ข้างใน
tmux new-session -s god "gemini --yolo"
```

### ปลุกผ่าน start-god.cmd (ทางลัด)

```powershell
cd C:\Agentic
.\start-god.cmd
```

### ตรวจสอบว่า GOD ออนไลน์

```powershell
# ดู tmux sessions ที่รันอยู่
tmux list-sessions
# ควรมี "god" อยู่ในรายการ

# หรือดูผ่าน Dashboard
# เปิด http://localhost:5173 → Fleet → ควรมี god แสดงอยู่
```

---

## ขั้นตอนที่ 8: จบวัน

เมื่อทำงานเสร็จ รันคำสั่งนี้เพื่อสรุปและบันทึก:

```powershell
cd C:\Agentic
.\finish-day.ps1
```

สิ่งที่มันทำ:
1. สรุป Retrospective ประจำวัน (ผ่าน gemini --yolo /rrr)
2. Sync memory ลง git (`git add ψ/ && git commit`)
3. ระบบพร้อมสำหรับวันพรุ่งนี้

---

## Port Mapping

| Port | Service | ไฟล์ | หน้าที่ |
|------|---------|------|---------|
| **3456** | Maw API | `maw-js/server.ts` | 🔧 ระบบควบคุมหลัก — คุณสั่งงานผ่าน port นี้ |
| **5173** | Frontend | `arra-oracle-v3/frontend` | 👁️ Dashboard UI — หน้าเว็บที่คุณดูสถานะ |
| **47778** | Oracle Core | `arra-oracle-v3/src/server.ts` | 🧠 สมองความจำ — maw-js เรียกใช้เบื้องหลัง |

**สิ่งที่คุณใช้โดยตรง:**
- `http://localhost:5173` — เปิดดู Dashboard
- `maw hey god "ทำโน่นทำนี่"` — สั่งงานผ่าน CLI (วิ่งผ่าน port 3456)

**ทำงานเบื้องหลัง (ไม่ต้องสนใจ):**
- `localhost:3456` — API ที่ Frontend + CLI เรียกใช้
- `localhost:47778` — Oracle Core ที่ Maw API เรียกใช้

---

## การแก้ปัญหา

### หน้าจอ Dashboard ขาว / หมุนค้าง

**สาเหตุ:** Frontend (5173) ติดต่อ Backend (3456) ไม่ได้

**แก้ไข:**
```powershell
# 1. เช็คว่า Maw API รันอยู่มั้ย
curl http://localhost:3456/api/stats
# ถ้า connection refused = Maw API ไม่ได้รัน

# 2. เช็คว่า port ถูกใช้มั้ย
netstat -ano | findstr :3456
# ถ้าไม่มี output = ไม่มีใครใช้ port นี้ → ต้องรัน maw-js

# 3. รัน Maw API ใหม่
cd C:\Agentic\maw-js
bun server.ts
```

### Error: EADDRINUSE (Port ถูกจอง)

**สาเหตุ:** มี process เก่าค้างอยู่บน port นั้น

**แก้ไข:**
```powershell
# หา process ที่ใช้ port 3456
netstat -ano | findstr :3456
# จะได้ PID เช่น 12345

# ฆ่า process นั้น
taskkill /PID 12345 /F

# หรือฆ่า bun ทั้งหมด
taskkill /F /IM bun.exe /T
```

### 0 Agents แสดงใน Dashboard

**สาเหตุ:** tmux ไม่มี session หรือ CRLF issue

**แก้ไข:**
```powershell
# 1. ตรวจสอบ tmux sessions
tmux list-sessions
# ควรมี "god" หรือ agent อื่นๆ

# 2. ถ้าไม่มี → ปลุกใหม่
tmux new-session -d -s god "gemini --yolo"

# 3. รีเฟรช Dashboard (F5)
```

### Oracle Core รันไม่ได้ / Port 47778 error

**แก้ไข:**
```powershell
# 1. ตรวจสอบ port
netstat -ano | findstr :47778

# 2. ฆ่า process เก่า
taskkill /PID <PID จากขั้นตอน 1> /F

# 3. รันใหม่
cd C:\Agentic\arra-oracle-v3
bun src\server.ts
```

### bun: command not found

**แก้ไข:**
```powershell
# ติดตั้ง bun ใหม่
powershell -c "irm bun.sh/install.ps1 | iex"

# ปิดแล้วเปิด Terminal ใหม่
# หรือเพิ่ม PATH ด้วยตนเอง
$env:PATH += ";$env:USERPROFILE\.bun\bin"
```

### tmux: command not found

**แก้ไข:**
```powershell
# ถ้าใช้ WSL
wsl -- sudo apt install tmux -y

# ถ้าใช้ Git Bash / MSYS2
pacman -S tmux

# หรือผ่าน Chocolatey
choco install tmux
```

---

## คำสั่งที่ใช้บ่อย

### เริ่มต้นวัน

```powershell
# 1. รันระบบทั้งหมด
cd C:\Agentic
.\start-oracle.cmd

# 2. ปลุก agents (ถ้ายังไม่ตื่น)
tmux new-session -d -s god "gemini --yolo"

# 3. เปิด Dashboard
start http://localhost:5173
```

### ระหว่างวัน

```powershell
# ดูสถานะ tmux sessions
tmux list-sessions

# เข้าไปคุยกับ GOD โดยตรง
tmux attach -t god

# ออกจาก tmux (ไม่ฆ่า session)
# กด Ctrl+B แล้วกด D

# ดู Dashboard
start http://localhost:5173
```

### จบวัน

```powershell
cd C:\Agentic
.\finish-day.ps1
```

### หยุดระบบทั้งหมด

```powershell
# ฆ่า bun processes
taskkill /F /IM bun.exe /T

# ฆ่า tmux sessions
tmux kill-server

# หรือฆ่าแค่ session เดียว
tmux kill-session -t god
```

### ล้างทุกอย่างแล้วเริ่มใหม่

```powershell
taskkill /F /IM bun.exe /T 2>nul
tmux kill-server 2>nul
timeout /t 2
cd C:\Agentic
.\start-oracle.cmd
```

---

## สรุปแบบสั้น

```powershell
# ครั้งแรก: ติดตั้ง
git clone https://github.com/dmz2001TH/agentic.git C:\Agentic
cd C:\Agentic
cd maw-js && bun install && cd ..
cd arra-oracle-v3 && bun install && cd ..
cd arra-oracle-v3\frontend && bun install && cd ..\..

# ทุกวัน: รัน
cd C:\Agentic
.\start-oracle.cmd
# รอ 10 วินาที → เปิด http://localhost:5173
```

**3 คำสั่งจำให้ขึ้นใจ:**
1. `.\start-oracle.cmd` — เริ่มระบบทั้งหมด
2. `.\start-god.cmd` — ปลุก GOD
3. `.\finish-day.ps1` — จบวัน + บันทึก
