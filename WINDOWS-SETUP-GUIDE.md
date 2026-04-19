# 🪟 Oracle v3 + Maw — Windows Setup Guide

> คู่มือติดตั้งฉบับสมบูรณ์สำหรับ Windows 10/11
> อ้างอิงจาก: [Multi-Agent Orchestration Book](https://soul-brews-studio.github.io/multi-agent-orchestration-book/docs/intro) + [oracle-maw-guide](https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide)
> อัพเดท: 2026-04-19

---

## 📋 Checklist Overview

| # | Component | ทำไมต้องมี | สถานะ |
|---|-----------|------------|-------|
| 1 | Git | clone repo | ❓ เช็คก่อน |
| 2 | Node.js | runtime | ❓ เช็คก่อน |
| 3 | Bun | รัน maw-js + Oracle | ❓ เช็คก่อน |
| 4 | WSL2 + Ubuntu | tmux ทำงานบน Windows ผ่าน WSL | ❓ เช็คก่อน |
| 5 | tmux (ใน WSL) | terminal multiplexer — หัวใจของ maw | ❓ เช็คก่อน |
| 6 | Gemini CLI | ตัว agent ที่ maw ปลุก | ❓ เช็คก่อน |
| 7 | Claude Code (optional) | ตัว agent ทางเลือก | ❓ เช็คก่อน |
| 8 | Clone agentic repo | โค้ดทั้งหมด | ❌ ยัง |
| 9 | maw-ui (ARRA Office) | Dashboard UI | ❌ ยัง |
| 10 | Oracle Core (port 47778) | Memory/Search engine | ❌ ยัง |
| 11 | เทสทุกอย่าง | ยืนยันว่าใช้ได้ | ❌ ยัง |

---

## ขั้นตอนที่ 1: เช็คของที่มีอยู่แล้ว

เปิด **PowerShell** แล้วรันทีละบรรทัด:

```powershell
# Git
git --version

# Node.js
node --version

# Bun
bun --version

# WSL
wsl --list --verbose

# tmux (ผ่าน WSL)
wsl tmux -V
```

ถ้าขาดอันไหน → ข้ามไปขั้นตอนนั้น
ถ้ามีครบ → ไปขั้นตอนที่ 8 เลย

---

## ขั้นตอนที่ 2: ติดตั้ง Git (ถ้ายังไม่มี)

```powershell
# วิธีง่าย: winget
winget install Git.Git

# หรือดาวน์โหลดจาก https://git-scm.com/download/win

# รีสตาร์ท PowerShell แล้วเช็ค
git --version
```

---

## ขั้นตอนที่ 3: ติดตั้ง Node.js (ถ้ายังไม่มี)

```powershell
# winget
winget install OpenJS.NodeJS.LTS

# หรือดาวน์โหลดจาก https://nodejs.org (v20+ แนะนำ)

# รีสตาร์ท PowerShell แล้วเช็ค
node --version
npm --version
```

---

## ขั้นตอนที่ 4: ติดตั้ง Bun (ถ้ายังไม่มี)

```powershell
# PowerShell (run as admin)
powershell -c "irm bun.sh/install.ps1 | iex"

# หรือผ่าน npm (ถ้ามี npm)
npm install -g bun

# รีสตาร์ท PowerShell แล้วเช็ค
bun --version
```

ถ้า `bun` ไม่เจอ ให้เพิ่ม PATH:
```powershell
$env:PATH = "$env:USERPROFILE\.bun\bin;$env:PATH"
# หรือเพิ่มใน System Environment Variables ถาวร
```

---

## ขั้นตอนที่ 5: ติดตั้ง WSL2 + Ubuntu (ถ้ายังไม่มี)

**สำคัญมาก:** tmux ไม่มีบน Windows ต้องใช้ผ่าน WSL

```powershell
# เปิด PowerShell เป็น Admin
wsl --install

# ถ้าต้องการ Ubuntu เฉยๆ (default)
wsl --install -d Ubuntu

# รีสตาร์ทเครื่อง
# หลังรีสตาร์ท WSL จะถาม username/password — จำให้ดี

# เช็ค
wsl --list --verbose
```

ผลลัพธ์ควรมี:
```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

---

## ขั้นตอนที่ 6: ติดตั้ง tmux ใน WSL (ถ้ายังไม่มี)

```powershell
# เปิด WSL terminal
wsl

# ใน WSL:
sudo apt update
sudo apt install -y tmux

# เช็ค
tmux -V
```

ควรมี tmux 3.4+

---

## ขั้นตอนที่ 7: ติดตั้ง Gemini CLI

### วิธี A: npm (ง่ายสุด)

```powershell
# ใน PowerShell (ไม่ต้อง WSL)
npm install -g @anthropic-ai/claude-code
npm install -g @google/genkit-cli

# หรือเฉพาะ Gemini:
npm install -g @anthropic-ai/claude-code
```

**จริงๆ แล้ว** config ใช้ `gemini --yolo` — ต้องติดตั้ง Gemini CLI:

```powershell
# Gemini CLI
npm install -g @anthropic-ai/claude-code
# หรือผ่าน:
bun add -g @anthropic-ai/claude-code
```

### วิธี B: ถ้าใช้ Claude Code แทน

ถ้าจะใช้ Claude Code แทน Gemini — เปลี่ยน config:

```json
// maw-js/.env.json
{
  "commands": {
    "default": "claude --dangerously-skip-permissions --continue"
  }
}
```

### วิธี C: ถ้ายังไม่มี CLI agent

ติดตั้งอย่างใดอย่างหนึ่ง:

```powershell
# Claude Code (แนะนำ — คู่มือเจ้าของโปรเจคใช้)
npm install -g @anthropic-ai/claude-code

# หรือ Gemini
npm install -g @anthropic-ai/claude-code
# (เช็ค docs ล่าสุดจาก Google)
```

---

## ขั้นตอนที่ 8: Clone Repo + ติดตั้ง Dependencies

```powershell
# สร้างโฟลเดอร์
mkdir C:\Agentic
cd C:\Agentic

# Clone
git clone https://github.com/dmz2001TH/agentic.git .
# หรือถ้า clone สำเร็จแล้ว:
# cd C:\Agentic

# ติดตั้ง dependencies — maw-js
cd C:\Agentic\maw-js
bun install

# ติดตั้ง dependencies — Oracle Core
cd C:\Agentic\arra-oracle-v3
bun install

# ติดตั้ง dependencies — Oracle Core frontend (ถ้ามี)
cd C:\Agentic\arra-oracle-v3\frontend
bun install
```

---

## ขั้นตอนที่ 9: ติดตั้ง maw-ui (ARRA Office)

### วิธี A: ผ่าน maw CLI (ถ้ามี)

```powershell
cd C:\Agentic\maw-js
bun src\cli.ts ui install
```

### วิธี B: ดาวน์โหลดด้วยตนเอง

```powershell
# สร้างโฟลเดอร์
mkdir -Force $env:USERPROFILE\.maw\ui\dist

# ดาวน์โหลดจาก GitHub Releases
# https://github.com/Soul-Brews-Studio/maw-ui/releases/latest
# ดาวน์โหลด dist.tar.gz หรือ dist.zip

# แตกไฟล์ไปที่ ~/.maw/ui/dist/
# เช่น ใช้ 7-Zip หรือ Windows Explorer

# ตรวจสอบ
ls $env:USERPROFILE\.maw\ui\dist\
```

ควรเห็นไฟล์ `.html`, `.js`, `.css` มากมาย (ARRA Office UI)

---

## ขั้นตอนที่ 10: ตั้งค่า Config

### maw-js/.env.json

```json
{
  "node": "Agentic-Master",
  "host": "localhost",
  "port": 3456,
  "ghqRoot": "C:\\Agentic",
  "oracleUrl": "http://localhost:47778",
  "commands": {
    "default": "claude --dangerously-skip-permissions --continue"
  },
  "sessions": {
    "nexus": "02-nexus"
  }
}
```

**สำคัญ:**
- `ghqRoot` → ใช้ `C:\\Agentic` (double backslash) หรือ path ที่คุณ clone ไว้
- `oracleUrl` → `http://localhost:47778` (Oracle Core ต้องรันบน 47778)
- `commands.default` → เปลี่ยนเป็น CLI agent ที่คุณติดตั้ง

### เช็คว่า Oracle Core ต้องการ config เพิ่มมั้ย

```powershell
cd C:\Agentic\arra-oracle-v3
ls .env* config*
# ถ้ามี .env.example → copy เป็น .env แล้วแก้ค่า
```

---

## ขั้นตอนที่ 11: รันทั้งระบบ!

### วิธี A: ใช้ start-oracle.cmd (ง่ายสุด)

```powershell
cd C:\Agentic
.\start-oracle.cmd
```

จะเปิด 3 windows:
1. **Oracle Core** (port 47778) — สีเขียว
2. **Maw API** (port 3456) — สีม่วง
3. **Frontend** (port 5173) — สีเหลือง

รอ 5-10 วินาที แล้วเปิด browser:
- **Dashboard:** http://localhost:5173
- **Maw UI:** http://localhost:3456
- **Oracle API:** http://localhost:47778

### วิธี B: รันทีละตัว (debug ง่ายกว่า)

```powershell
# Terminal 1: Oracle Core (Port 47778)
cd C:\Agentic\arra-oracle-v3
bun src\server.ts

# Terminal 2: Maw API (Port 3456)
cd C:\Agentic\maw-js
bun server.ts

# Terminal 3: Frontend (Port 5173) — optional
cd C:\Agentic\arra-oracle-v3\frontend
bun run dev --port 5173 --host localhost
```

---

## ขั้นตอนที่ 12: ปลุก Agent ตัวแรก!

```powershell
# ดูสถานะ
cd C:\Agentic\maw-js
bun src\cli.ts ls

# ปลุก nexus
bun src\cli.ts wake nexus

# ดูว่า nexus กำลังทำอะไร
bun src\cli.ts peek nexus

# ส่งข้อความให้ nexus
bun src\cli.ts hey nexus "hello, welcome to the team!"
```

**สิ่งที่ควรเห็น:**
```
nexus
  ● 0: claude --dangerously-skip-permissions --continue
```

---

## ขั้นตอนที่ 13: เทสทุกอย่าง

### เทส tmux (ผ่าน WSL)

```powershell
# ดู sessions
wsl tmux list-sessions

# ควรมี nexus session อยู่
```

### เทส Maw API

```powershell
# Sessions
curl http://localhost:3456/api/sessions

# Fleet
curl http://localhost:3456/api/fleet

# Identity
curl http://localhost:3456/api/reflect

# Dashboard
curl http://localhost:3456/api/dashboard/summary
```

### เทส Oracle Core

```powershell
# Search
curl "http://localhost:47778/api/search?q=test"

# Stats
curl http://localhost:47778/api/stats

# Dashboard
curl http://localhost:47778/api/dashboard/summary
```

### เทส maw CLI

```powershell
cd C:\Agentic\maw-js

# Version
bun src\cli.ts --version

# List sessions
bun src\cli.ts ls

# Peek
bun src\cli.ts peek nexus

# Overview
bun src\cli.ts overview

# Fleet
bun src\cli.ts fleet ls
```

---

## 🔧 Troubleshooting

### Problem: `error connecting to /tmp/tmux-0/default`

**สาเหตุ:** tmux socket ไม่ทำงาน

**แก้ไข:**
```powershell
# รัน tmux ผ่าน WSL
wsl tmux new-session -d -s test "bash"
wsl tmux list-sessions
```

maw-js แก้แล้ว — `hostExec()` จะ detect `win32` แล้วรัน `wsl bash -c` สำหรับ tmux commands

---

### Problem: `ghq: not found`

**สาเหตุ:** ไม่ได้ติดตั้ง ghq

**ผลกระทบ:** ต่ำ — `detectGhqRoot()` มี fallback เป็น `~/Code/github.com`

**แก้ไข (optional):**
```powershell
# ใน WSL
wsl bash -c "sudo apt install -y ghq"
```

---

### Problem: `Oracle unreachable`

**สาเหตุ:** Oracle Core (port 47778) ไม่ได้รัน

**แก้ไข:**
```powershell
# รัน Oracle Core
cd C:\Agentic\arra-oracle-v3
bun src\server.ts

# เช็คว่ารันอยู่
curl http://localhost:47778/api/stats
```

---

### Problem: `no active Claude session in <name>`

**สาเหตุ:** tmux session มีอยู่ แต่ไม่มี CLI agent รันอยู่

**แก้ไข:**
```powershell
# ต้อง wake agent ก่อน
cd C:\Agentic\maw-js
bun src\cli.ts wake nexus

# หรือใช้ --force เพื่อส่งข้อความเข้า tmux pane โดยตรง
bun src\cli.ts hey nexus "hello" --force
```

---

### Problem: maw-ui แสดง landing page ธรรมดา (ไม่ใช่ ARRA Office)

**สาเหตุ:** ยังไม่ได้ติดตั้ง maw-ui

**แก้ไข:**
```powershell
# ตรวจสอบ
ls $env:USERPROFILE\.maw\ui\dist\

# ถ้าว่าง → ติดตั้งตามขั้นตอนที่ 9
```

---

### Problem: tmux commands ช้ามาก

**สาเหตุ:** WSL startup time

**แก้ไข:**
```powershell
# รักษา WSL ให้รันตลอด
wsl --list --verbose  # เช็ค STATE = Running

# ถ้า Stopped → เปิด WSL terminal ค้างไว้
```

---

### Problem: port ถูกใช้แล้ว

```powershell
# เช็ค port
netstat -ano | findstr :3456
netstat -ano | findstr :47778
netstat -ano | findstr :5173

# kill process
taskkill /PID <PID> /F
```

---

### Problem: `bun` ไม่เจอหลัง restart

```powershell
# เพิ่ม PATH ถาวร
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\.bun\bin", "User")

# หรือรันก่อนใช้ทุกครั้ง
$env:PATH = "$env:USERPROFILE\.bun\bin;$env:PATH"
```

---

## 📦 Repo Status: เทียบกับ Upstream

| Component | Our Version | Upstream | สถานะ |
|-----------|------------|----------|-------|
| maw-js | v2.0.0-alpha.109 | CalVer (v26.4.19) | ⚠️ ตามหลัง |
| arra-oracle-v3 | 0.5.0 | v26.4.19-alpha.7 | ⚠️ ตามหลัง |
| arra-oracle-skills-cli | 3.9.1-alpha.1 | ล่าสุด | ⚠️ ตามหลัง |
| maw-ui | ยังไม่ติดตั้ง | v1.4.2+ | ❌ ขาด |
| multi-agent-workflow-kit | มีโค้ด | upstream | ✅ มี |

### สิ่งที่ Upstream มีแต่เราไม่มี/ยังไม่ได้เทส

| Feature | Source | สถานะ |
|---------|--------|-------|
| `maw doctor` | maw-js | ⚠️ มีโค้ด ไม่ได้เทส |
| `maw bud <name>` | maw-js | ⚠️ มีโค้ด ไม่ได้เทส |
| `maw inbox read/write` | maw-js | ⚠️ มีโค้ด ไม่ได้เทส |
| `maw ping` | maw-js | ⚠️ มีโค้ด ไม่ได้เทส |
| `maw ui install` | maw-js | ⚠️ มีโค้ด ไม่ได้เทส |
| Vector search (ChromaDB) | arra-oracle-v3 | ❌ ต้องติดตั้ง Ollama |
| oracle-vault CLI | arra-oracle-v3 | ⚠️ มีโค้ด ไม่ได้เทส |
| WASM plugins | maw-js | ⚠️ มีโค้ด ไม่ได้เทส |
| Federation (multi-node) | maw-js | ⚠️ ต้อง 2+ เครื่อง |

---

## 🎯 Quick Start (TL;DR)

```powershell
# 1. ติดตั้ง
wsl --install
wsl sudo apt install -y tmux
winget install Git.Git OpenJS.NodeJS.LTS
npm install -g bun @anthropic-ai/claude-code

# 2. Clone
mkdir C:\Agentic && cd C:\Agentic
git clone https://github.com/dmz2001TH/agentic.git .

# 3. Install deps
cd maw-js && bun install
cd ..\arra-oracle-v3 && bun install

# 4. Install maw-ui
mkdir -Force $env:USERPROFILE\.maw\ui\dist
# ดาวน์โหลด maw-ui dist → extract ไป ~/.maw/ui/dist/

# 5. Run
cd C:\Agentic
.\start-oracle.cmd

# 6. Open
# Browser → http://localhost:5173
# Browser → http://localhost:3456

# 7. Wake first agent
cd C:\Agentic\maw-js
bun src\cli.ts wake nexus
bun src\cli.ts peek nexus
```

---

## 📚 อ้างอิง

- [Multi-Agent Orchestration Book](https://soul-brews-studio.github.io/multi-agent-orchestration-book/docs/intro)
- [oracle-maw-guide](https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide)
- [Soul-Brews-Studio/maw-js (upstream)](https://github.com/Soul-Brews-Studio/maw-js)
- [Soul-Brews-Studio/arra-oracle-v3 (upstream)](https://github.com/Soul-Brews-Studio/arra-oracle-v3)
- [HANDOFF-PROMPT.md](./HANDOFF-PROMPT.md) — รายละเอียดสิ่งที่ทำไปแล้ว

---

*คู่มือนี้สร้างจากการเทสจริงบน Linux + เปรียบเทียบกับคู่มือเจ้าของโปรเจค*
*ปัญหา Windows-specific ได้รับการแก้ไขในโค้ดแล้ว (commit 28f8b75)*
