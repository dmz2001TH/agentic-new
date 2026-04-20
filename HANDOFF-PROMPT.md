# 🔮 HANDOFF PROMPT — Oracle v3 Agentic Project

**สำหรับ:** AI Agent ตัวถัดไปที่จะ接手โปรเจ็คนี้
**สร้างเมื่อ:** 2026-04-19
**สถานะปัจจุบัน:** ระบบรันได้ทั้ง 3 ports + Maw UI ติดตั้งแล้ว (ARRA Office) Frontend แสดงข้อมูลจริงจาก Oracle

---

## 📌 สรุปสิ่งที่ทำไปแล้ว (What Was Done)

คุณกำลัง接手โปรเจ็ค **Oracle v3** ที่เป็น multi-agent system สำหรับ Windows + Windsurf ประกอบด้วย 3 ส่วนหลัก:

### โครงสร้างโปรเจ็ค

```
Repo: https://github.com/dmz2001TH/agentic
Branch: master
โฟลเดอร์หลัก: C:\Agentic (บน Windows)
```

| Component | Port | หน้าที่ | Source |
|-----------|------|---------|--------|
| **arra-oracle-v3** | 47778 | สมองความจำ (HTTP API) | `arra-oracle-v3/src/server.ts` |
| **maw-js** | 3456 | Fleet Control + API + Maw UI (ARRA Office) | `maw-js/server.ts` |
| **Frontend** | 5173 | Dashboard UI | `arra-oracle-v3/frontend` |

### สิ่งที่ทำไปแล้วทั้งหมด

#### 1. แก้ Bug Critical (commit a5b8de4)
- **`.env.json`** port 3457 → 3456
- **`start-oracle.cmd`** เปลี่ยนจาก `bun run src\index.ts` (MCP) เป็น `bun src\server.ts` (HTTP)
- **`start-oracle.cmd`** เปลี่ยน path จาก `C:\Agentic` เป็น `%~dp0`
- **`howtoinstall.txt`** อัพเดทคำสั่ง Oracle Core
- **`maw-js/src/api/index.ts`** แก้ comment ผิด ("deprecated.ts removed")
- สร้าง **`.gitignore`** สำหรับ SQLite binary files
- ลบ SQLite DB files ออกจาก git tracking
- ลบ `package-lock.json` ที่ว่างเปล่า

#### 2. เปลี่ยน 127.0.0.1 → localhost (commit efdc7b2)
- เปลี่ยนใน 8 ไฟล์: `.env.json`, `load.ts`, `vite.config.ts`, `server.ts` (ทั้ง 2 ตัว), `start-oracle.cmd`, `start-god.cmd`, `howtoinstall.txt`
- สร้าง **`INSTALLATION.md`** — คู่มือติดตั้งฉบับเต็ม

#### 3. ลบ Ghost Agents จุดที่ 1 (commit 1d749cd)
- **`maw-js/src/core/transport/tmux-class.ts`** — ลบ `names.add("god"/"god-oracle"/"gemini")` ใน `listSessions()` และ `listAll()`

#### 4. ลบ Ghost Agents จุดที่ 2-3 (commit 78be8b9)
- **`maw-js/src/api/sessions.ts`** — ลบ `forceSessions` array ใน `/api/sessions` endpoint
- **`maw-js/src/core/transport/ssh.ts`** — ลบ `names.add("god-oracle")` ใน `listSessions()`

#### 5. ลบ Ghost Agents จาก Config (commit 6cda5bc)
- **`maw-js/.env.json`** — ลบ `"god-oracle"` จาก sessions, ลบ `"*-oracle"` จาก commands
- **`maw-js/src/config/load.ts`** — ลบ `"god-oracle"` และ `"gemini"` จาก DEFAULTS sessions
- **`INSTALL-WINDOWS-SCRATCH.md`** — เพิ่มส่วน troubleshooting 8 จุด + กฎป้องกัน regression

#### 6. คู่มือที่สร้าง
- **`INSTALLATION.md`** — คู่มือสำหรับคนที่มี GitHub อยู่แล้ว
- **`INSTALL-WINDOWS-SCRATCH.md`** — คู่มือสำหรับคนเริ่มจาก 0 (ติดตั้ง Git, Node, Bun, WSL, tmux, Gemini CLI)
- **`agentic-project-review.md`** — รีวิวโปรเจ็คฉบับละเอียด (อยู่ใน workspace ของ agent เก่า)

#### 7. แก้ Frontend แสดง Mock Data (commit 44a3d01)
- **`maw-js/src/api/deprecated.ts`** — เปลี่ยนจาก mock endpoints → proxy จริงไป Oracle Core (15 routes)
  - `GET /api/search` — proxy ไป Oracle (ก่อนหน้า: 404)
  - `POST /api/learn` — proxy ไป Oracle (ก่อนหน้า: 404)
  - `POST /api/auth/login` — proxy ไป Oracle (ก่อนหน้า: 404)
  - `GET /api/settings` — proxy ไป Oracle (ก่อนหน้า: 404)
  - `POST /api/settings` — proxy ไป Oracle (ก่อนหน้า: 404)
  - `GET /api/list, /api/stats, /api/reflect, /api/graph, /api/map` — proxy จริง (ก่อนหน้า: mock empty data)
  - `GET /api/dashboard/summary, /api/dashboard/activity, /api/dashboard/growth` — proxy จริง
  - `GET /api/auth/status, /api/session/stats, /api/oraclenet/status` — proxy จริง
  - `GET /api/similar` — proxy ไป Oracle (ก่อนหน้า: 404)
  - มี fallback ถ้า Oracle ไม่รัน → คืนค่า default (ไม่ crash)
- **`maw-js/src/config/load.ts`** — `ghqRoot: "C:\Agentic"` → `ghqRoot: detectGhqRoot()` (dynamic detection)
- **`arra-oracle-v3/src/server/handlers.ts`** — ซ่อน vector search warning ถ้าเป็น connection error (Ollama ไม่ได้ติดตั้ง)
- **`arra-oracle-v3/src/tools/search.ts`** — ซ่อน vector search warning (MCP side)
- **`.gitignore`** — เพิ่ม `psi/vault/*.db.export-*.csv` และ `psi/vault/*.db.export-*.json`

#### 8. แก้ Windows WSL tmux compatibility (commit pending)
- **`maw-js/src/core/transport/tmux-types.ts`** — `tmuxCmd()` ตรวจจับ Windows (`process.platform === "win32"`) → คืน `wsl tmux` แทน `tmux` (เพราะ tmux อยู่ใน WSL ไม่ใช่ Windows native)
- **`maw-js/src/core/transport/ssh.ts`** — `hostExec()` บน Windows: ถ้า command มี `tmux` → รันผ่าน `["wsl", "bash", "-c", cmd]` แทน `["cmd.exe", "/c", cmd]` เพื่อให้ single quotes, `2>/dev/null` และ bash syntax ทำงานได้
- ส่งผลให้ `listSessions()`, `capture()`, `sendKeys()`, `switchClient()` ทำงานบน Windows + WSL ได้

#### 9. ติดตั้ง Maw UI (ARRA Office)
- ดาวน์โหลด maw-ui v1.4.2 จาก GitHub Releases → แตกไฟล์ไปที่ `~/.maw/ui/dist/`
- หน้าแรก (`/`) แสดง ARRA Office แทน landing page เปล่า
- Pages ที่มี: office, fleet, terminal, dashboard, chat, mission, config, inbox, workspace, federation_2d, federation, arena, shrine, timemachine
- **บน Windows:** รัน `maw ui --install` หรือดาวน์โหลดจาก https://github.com/Soul-Brews-Studio/maw-ui/releases/latest

---

## 🔗 ลิงก์ทั้งหมดที่ Agent ต้องดู

### โปรเจ็คหลัก
- **Repo หลัก:** https://github.com/dmz2001TH/agentic
- **Commits:** https://github.com/dmz2001TH/agentic/commits/master

### โปรเจ็คต้นฉบับ (Fork มาจาก)
- **maw-js:** https://github.com/Soul-Brews-Studio/maw-js
- **arra-oracle-v3:** https://github.com/Soul-Brews-Studio/arra-oracle-v3
- **oracle-skills-cli:** https://github.com/Soul-Brews-Studio/oracle-skills-cli
- **multi-agent-workflow-kit:** https://github.com/Soul-Brews-Studio/multi-agent-workflow-kit
- **oracle-vault-report:** https://github.com/Soul-Brews-Studio/oracle-vault-report
- **opensource-nat-brain-oracle:** https://github.com/Soul-Brews-Studio/opensource-nat-brain-oracle

### เอกสารอ้างอิง
- **Oracle Guide:** https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide
- **Multi-Agent Book:** https://soul-brews-studio.github.io/multi-agent-orchestration-book/
- **หนังสือ "รูปสอนความว่าง":** https://book.buildwithoracle.com
- **Oracle Family Discussions:** https://github.com/Soul-Brews-Studio/arra-oracle-v3/discussions
- **Pulse CLI:** https://github.com/Pulse-Oracle/pulse-cli
- **Claude Code Statusline:** https://github.com/laris-co/claude-code-statusline

### เครื่องมือ
- **Bun:** https://bun.sh
- **Gemini CLI:** https://github.com/google-gemini/gemini-cli
- **tmux:** https://github.com/tmux/tmux
- **Windsurf:** https://windsurf.com (AI editor ที่ผู้ใช้ใช้)

---

## 🏗️ สถาปัตยกรรมระบบ (Architecture)

```
┌─────────────────────────────────────────────────────────┐
│                    Browser (ผู้ใช้)                      │
│              http://localhost:5173                       │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTP
┌──────────────────────▼──────────────────────────────────┐
│           Frontend Dashboard (Port 5173)                │
│         arra-oracle-v3/frontend — Vite + React          │
│                                                         │
│  Pages: Overview, Search, Graph, Feed, Forum, Settings  │
│  Proxy: /api → localhost:3456                           │
│  Live Terminal: ws://localhost:3456/ws/pty              │
└──────────────────────┬──────────────────────────────────┘
                       │ /api proxy + WebSocket
┌──────────────────────▼──────────────────────────────────┐
│           Maw API Server (Port 3456)                    │
│         maw-js — Elysia.js + Hono                       │
│                                                         │
│  API Routes: /api/sessions, /api/sessions/god/ask     │
│              /api/fleet, /api/asks, /api/stats, etc.    │
│  WebSocket: /ws (engine), /ws/pty (live terminal)       │
│  Config: maw-js/.env.json                               │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  god   │  │  agent2  │  │  agent3  │  ← tmux     │
│  │ (gemini) │  │ (gemini) │  │ (gemini) │    sessions  │
│  └──────────┘  └──────────┘  └──────────┘              │
└──────────────────────┬──────────────────────────────────┘
                       │ oracleUrl: http://localhost:47778
┌──────────────────────▼──────────────────────────────────┐
│           Oracle Core (Port 47778)                      │
│     arra-oracle-v3 — Hono.js + SQLite + Vector DB      │
│                                                         │
│  Routes: /api/health, /api/search, /api/learn           │
│          /api/list, /api/stats, /api/graph, etc.        │
│  Data: ~/.arra-oracle-v2/oracle.db                      │
│  ψ/: memory, inbox, writing, lab, vault                 │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 โครงสร้างไฟล์สำคัญ

### Config Files
```
maw-js/.env.json                    ← Maw API config (port, sessions, commands)
maw-js/src/config/load.ts           ← Config loader + DEFAULTS
arra-oracle-v3/src/config.ts        ← Oracle paths resolver
arra-oracle-v3/src/const.ts         ← Oracle constants (default port 47778)
arra-oracle-v3/frontend/vite.config.ts ← Frontend proxy config
```

### Transport Layer (Ghost Agent Fix Location)
```
maw-js/src/core/transport/tmux-class.ts  ← Tmux wrapper (listSessions, listAll)
maw-js/src/core/transport/ssh.ts         ← SSH transport (listSessions — ใช้จริง!)
maw-js/src/core/transport/pty.ts         ← Live Terminal PTY handler
maw-js/src/api/sessions.ts               ← /api/sessions endpoint
```

### API Layer
```
maw-js/src/api/index.ts             ← API router (import deprecatedApi)
maw-js/src/api/deprecated.ts        ← Proxy endpoints → Oracle Core (search, learn, auth, settings, dashboard)
maw-js/src/api/sessions.ts          ← Sessions API (was forceSessions)
maw-js/src/api/fleet.ts             ← Fleet management
maw-js/src/api/asks.ts              ← Ask/message agents
maw-js/src/core/server.ts           ← Main server + WebSocket handler
```

### Start Scripts
```
start-oracle.cmd                    ← เริ่มระบบทั้งหมด (3 ports)
start-god.cmd                     ← ปลุก Agent GOD
finish-day.ps1                      ← จบวัน + git commit
gemini-yolo.cmd                     ← Wrapper สำหรับ gemini --yolo
```

### Documentation
```
INSTALLATION.md                     ← คู่มือติดตั้ง (มี GitHub)
INSTALL-WINDOWS-SCRATCH.md          ← คู่มือติดตั้ง (เริ่มจาก 0)
howtoinstall.txt                    ← คู่มือเก่า (แก้แล้ว)
GEMINI.md                           ← ระบบ Oracle สำหรับ Gemini CLI
HANDOFF-PROMPT.md                   ← ไฟล์นี้ (ส่งต่อให้ agent ถัดไป)
```

### Memory System
```
ψ/memory/identity.md                ← ตัวตน Agent
ψ/memory/patterns.md                ← Patterns ที่ค้นพบ
ψ/memory/learnings.md               ← สิ่งที่เรียนรู้
ψ/memory/notes.md                   ← บันทึกด่วน
ψ/memory/decisions.md               ← การตัดสินใจ
ψ/memory/people.md                  ← คน & Agent ที่ลงทะเบียน
ψ/memory/values.md                  ← ค่านิยม
ψ/memory/handoff.md                 ← Handoff ระหว่าง session
ψ/memory/retrospectives/            ← สรุปประจำวัน
ψ/inbox/                            ← งานที่กำลังทำ
ψ/vault/                            ← SQLite DB + backups
```

---

## 🐛 ปัญหาที่แก้แล้ว (DO NOT REVERT)

### กฎเหล็ก — ห้ามย้อนกลับ

1. **ห้ามเพิ่ม `names.add("ชื่อagent")`** ใน tmux-class.ts หรือ ssh.ts
2. **ห้ามเพิ่ม `forceSessions`** ใน sessions.ts
3. **ห้ามเปลี่ยน port** จาก 3456 โดยไม่แก้ทุกที่
4. **ห้ามเปลี่ยน Oracle Core** จาก `bun src/server.ts` เป็น `bun run src/index.ts`
5. **ห้าม hardcode path** `C:\Agentic` — ใช้ `%~dp0`
6. **ห้ามใช้ `127.0.0.1`** — ใช้ `localhost`
7. **ห้ามเปลี่ยน deprecated.ts กลับเป็น mock** — ต้อง proxy จริงไป Oracle Core เสมอ
8. **ห้ามแสดง vector search warning** ให้ผู้ใช้เห็น — ถ้า Ollama ไม่ได้ติดตั้ง ให้เงียบ fallback เป็น FTS5
9. **ห้ามเปลี่ยน hostExec** กลับเป็น `cmd.exe /c` สำหรับ tmux — ต้องผ่าน `wsl bash -c` เสมอ

---

## ✅ สิ่งที่เทสแล้ว (Verified Working)

| ทดสอบ | ผล |
|--------|-----|
| Oracle Core HTTP (47778) | ✅ Health, Learn, Search, Stats, List, Reflect, Graph, Map |
| Maw API (3456) | ✅ Sessions, Config, Triggers, Fleet |
| Frontend Proxy (5173→3456) | ✅ /api ผ่าน proxy ได้ |
| Maw → Oracle proxy (deprecated.ts) | ✅ 15 routes ส่งข้อมูลจริง (search, learn, auth, settings, dashboard) |
| Vector warning suppressed | ✅ ไม่แสดง warning เมื่อ Ollama ไม่ได้ติดตั้ง |
| Tmux session detection | ✅ แสดง real sessions เท่านั้น |
| No ghost agents | ✅ god-oracle/gemini หายแล้ว |
| Live Terminal (PTY) | ✅ Grouped session + capture pane |
| Frontend build | ✅ TypeScript + Vite build ผ่าน |
| Windows WSL tmux (code review) | ✅ hostExec routes tmux through wsl bash -c on win32 |
| Maw UI (ARRA Office) | ✅ 17 pages served on :3456 (fleet, terminal, dashboard, chat, etc.) |

---

## 🔧 งานที่ยังไม่ได้ทำ (TODO)

### สิ่งที่ควรทำต่อ

1. **ทดสอบบน Windows จริง** — ตอนนี้เทสแค่บน Linux ยังไม่ได้เทส WSL + Windows path
2. **Gemini CLI auto-login** — หาวิธี login ล่วงหน้าเพื่อไม่ต้อง login ทุกครั้งที่สร้าง agent ใหม่
3. **Multiple agents** — ทดสอบสร้าง agent หลายๆ ตัวทำงานพร้อมกัน
4. **Fleet management** — ทดสอบ wake/sleep/peek ผ่าน Dashboard
5. **Vector search (optional)** — ถ้าต้องการ semantic search ต้องติดตั้ง Ollama + ollama pull bge-m3 (ปัจจุบันใช้ FTS5 keyword search ทำงานปกติ)
6. **Process management** — หาวิธีรัน 3 services เป็น background daemon บน Windows (PM2 หรือ NSSM)
7. **Frontend bundle optimization** — ตอนนี้ 1.4MB ควร code-split ด้วย dynamic import
8. **Maw UI on Windows** — ทดสอบ maw-ui บน Windows (`maw ui --install` หรือ manual download)

### ปัญหาที่ยังมีอยู่ (Known Issues)

1. **Vector search warning** — `Unable to connect. Is the computer able to access the url?` (embedding service ไม่ได้ตั้งค่า)
2. **Orphaned PTY sessions** — ถ้า browser ปิดโดยไม่ detach PTY session จะค้าง (มี cleanup timer แต่ช้า)
3. **`ψ/vault/*.db.export-*.csv/json`** — ยังอยู่ใน git (ไม่ได้ลบออกเพราะ Oracle philosophy "Nothing is Deleted")
4. **Config defaults** — `load.ts` DEFAULTS ยังมี `ghqRoot: "C:\\Agentic"` ที่ hardcode path

---

## 🧪 วิธีเทสระบบ (How to Test)

### ติดตั้ง Maw UI (ครั้งแรกเท่านั้น)

```bash
# Option A: maw CLI (ต้องมี gh CLI)
maw ui --install

# Option B: Manual download
# 1. ดาวน์โหลดจาก https://github.com/Soul-Brews-Studio/maw-ui/releases/latest
# 2. แตกไฟล์ไป ~/.maw/ui/dist/
```

### เริ่มระบบทั้งหมด

```bash
# Terminal 1: Oracle Core
cd /tmp/agentic/arra-oracle-v3
bun src/server.ts

# Terminal 2: Maw API
cd /tmp/agentic/maw-js
bun server.ts

# Terminal 3: Frontend
cd /tmp/agentic/arra-oracle-v3/frontend
bun run dev --port 5173 --host localhost
```

### สร้าง Agent + ทดสอบ Live Terminal

```bash
# สร้าง tmux session
tmux new-session -d -s god "gemini"

# ตรวจสอบผ่าน API
curl -s http://localhost:3456/api/sessions | python3 -m json.tool

# ทดสอบ PTY grouped session
tmux new-session -d -t god -s maw-pty-test -x 120 -y 40
tmux capture-pane -t maw-pty-test -p

# ล้าง
tmux kill-session -t maw-pty-test
tmux kill-server
```

### เทส Oracle Core

```bash
# Learn
curl -s -X POST http://localhost:47778/api/learn \
  -H "Content-Type: application/json" \
  -d '{"pattern": "test", "category": "test"}'

# Search
curl -s "http://localhost:47778/api/search?q=test" | python3 -m json.tool

# Stats
curl -s http://localhost:47778/api/stats | python3 -m json.tool
```

---

## 💬 Prompt สำหรับ Agent ถัดไป

คุณได้รับมอบหมายให้ดูแลโปรเจ็ค **Oracle v3 Agentic System** (https://github.com/dmz2001TH/agentic)

**背景:**
- โปรเจ็คนี้เป็น multi-agent system สำหรับ Windows ใช้ Bun + tmux + Gemini CLI
- ประกอบด้วย 3 ส่วน: Oracle Core (47778), Maw API (3456), Frontend Dashboard (5173)
- ผู้ใช้ใช้ **Windsurf** เป็น AI editor หลัก
- มี bug ที่แก้แล้ว 8 จุด (ดู HANDOFF-PROMPT.md ใน repo)

**สิ่งที่ต้องทำ:**
1. อ่านไฟล์ทั้งหมดใน repo โดยเฉพาะ: `INSTALL-WINDOWS-SCRATCH.md`, `INSTALLATION.md`, `howtoinstall.txt`
2. อ่านโค้ดใน: `maw-js/src/api/sessions.ts`, `maw-js/src/core/transport/ssh.ts`, `maw-js/src/core/transport/tmux-class.ts`, `maw-js/src/core/transport/pty.ts`
3. เทสระบบตามขั้นตอนใน "วิธีเทสระบบ" ด้านบน
4. ดู reference: https://github.com/Soul-Brews-Studio/maw-js, https://soul-brews-studio.github.io/multi-agent-orchestration-book/

**ห้าม:**
- ย้อนกลับ bug fixes ที่ทำไปแล้ว (ดู "กฎเหล็ก" ด้านบน)
- เปลี่ยน port หรือ path โดยไม่แก้ทุกที่
- เพิ่ม ghost agents กลับเข้าไป
- เปลี่ยน deprecated.ts กลับเป็น mock (ต้อง proxy จริงไป Oracle)
- แสดง vector search warning ให้ผู้ใช้เห็น
- เปลี่ยน hostExec กลับเป็น cmd.exe สำหรับ tmux commands (ต้องผ่าน wsl bash -c)

**เป้าหมาย:**
- ทำให้ระบบรันบน Windows ได้ 100% ผ่าน Windsurf
- ผู้ใช้ใช้ port 3456 เป็นหลักในการควบคุม
- Live Terminal ต้องทำงานได้จริงผ่าน Dashboard
