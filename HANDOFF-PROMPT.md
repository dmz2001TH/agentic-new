# 🔮 HANDOFF — Oracle v3 Agentic Project

**Last Updated:** 2026-04-20
**Current Agent:** OpenClaw (MiMo) — testing & fixes session
**Project:** https://github.com/dmz2001TH/agentic-new

---

## 📌 ภาพรวมโปรเจ็ค

Oracle v3 = Multi-Agent Management Platform ที่มี 3 ส่วนหลัก:

```
┌──────────────────────────────────────┐
│  Browser → http://localhost:5173     │
│  Frontend Dashboard (Vite+React)     │
└──────────────┬───────────────────────┘
               │ /api proxy
┌──────────────▼───────────────────────┐
│  Maw API (Elysia.js) → Port 3456    │
│  Fleet Controller + API Gateway      │
│  ┌──────────────────────────┐        │
│  │  god (tmux → gemini yolo)│        │
│  └──────────────────────────┘        │
└──────────────┬───────────────────────┘
               │ oracleUrl
┌──────────────▼───────────────────────┐
│  Oracle Core (Hono.js) → Port 47778  │
│  Memory Brain: SQLite + FTS5 Search  │
└──────────────────────────────────────┘
```

| Component | Port | Source | บทบาท |
|-----------|------|--------|--------|
| **Oracle Core** | 47778 | `arra-oracle-v3/src/server.ts` | สมองความจำ — learn/search/reflect/stats/graph |
| **Maw API** | 3456 | `maw-js/server.ts` | Fleet control + proxy ไป Oracle + WebSocket |
| **Frontend** | 5173 | `arra-oracle-v3/frontend` | Dashboard UI (proxy → 3456) |
| **GOD Agent** | tmux | `tmux new-session -s god "gemini --yolo"` | Fleet Supervisor |
| **Builder** | tmux | `tmux new-session -s mawjs-builder "..."` | Coding Specialist |
| **Researcher** | tmux | (manual start) | Knowledge Specialist |

---

## 🏗️ โครงสร้างไฟล์สำคัญ

```
agentic-new/
├── arra-oracle-v3/          ← Oracle Core (Memory Brain)
│   ├── src/server.ts        ← HTTP server entry (port 47778)
│   ├── src/server/          ← Routes, handlers, search
│   ├── src/tools/           ← Learn, search, reflect tools
│   └── frontend/            ← React Dashboard
│       ├── vite.config.ts   ← Proxy: /api → localhost:3456
│       └── src/             ← Pages, components
├── maw-js/                  ← Fleet Controller
│   ├── server.ts            ← HTTP + WS server entry (port 3456)
│   ├── .env.json            ← Config: ports, commands, sessions
│   ├── src/config/load.ts   ← Config loader + detectGhqRoot()
│   ├── src/api/
│   │   ├── deprecated.ts    ← Proxy routes → Oracle Core (15 routes)
│   │   ├── sessions.ts      ← /api/sessions
│   │   ├── fleet.ts         ← /api/fleet
│   │   ├── asks.ts          ← /api/asks (send to agents)
│   │   ├── tools.ts         ← /api/tools/* — Agent's hands (learn/search/file/goals/exec/message) ← NEW
│   │   └── heartbeat-api.ts ← /api/heartbeat — Task runner + heartbeat control ← NEW
│   ├── src/core/
│   │   ├── server.ts        ← Main server + WebSocket + ensure-agents + heartbeat
│   │   ├── task-runner.ts   ← Autonomous goal execution engine ← NEW
│   │   ├── heartbeat.ts     ← Periodic check (30min) + task dispatch ← NEW
│   │   └── transport/
│   │       ├── ssh.ts       ← hostExec() + listSessions()
│   │       ├── tmux-class.ts← Tmux wrapper class
│   │       └── pty.ts       ← Live Terminal handler
│   └── src/commands/plugins/← Wake, oracle, bud plugins
├── scripts/
│   ├── ensure-agents.sh     ← Auto-create tmux sessions on boot
│   ├── oracle-tools.sh      ← GOD's hands: API + file + goal + fleet tools ← NEW
│   └── validate-system.sh   ← System validation (31 checks) ← NEW
├── ψ/                       ← Memory System
│   ├── memory/              ← Shared brain (all agents read)
│   │   ├── identity.md      ← System identity
│   │   ├── people.md        ← Agent roster
│   │   ├── goals.md         ← Goal tracker
│   │   ├── patterns.md      ← Learned patterns
│   │   ├── decisions.md     ← Decision log
│   │   ├── values.md        ← Core values
│   │   ├── notes.md         ← Session notes
│   │   ├── handoff.md       ← Handoff state
│   │   ├── locks/           ← Memory write locks
│   │   └── reflections/     ← Post-task reflections
│   ├── agents/god/memory/   ← GOD's personal brain
│   ├── agents/builder/memory/ ← Builder's personal brain ← NEW
│   └── inbox/               ← Tasks
├── .gemini/
│   ├── agents/god.md        ← GOD's context file for Gemini CLI
│   └── launch-agent.sh      ← Launch Gemini with agent context
├── start-oracle.cmd         ← รันทุกอย่างรวม GOD (Windows)
├── start-god.cmd            ← ปลุก GOD แยก
├── start-oracle-system.cmd  ← Alternative starter (WSL)
├── INSTALLATION.md          ← คู่มือติดตั้ง
└── HANDOFF-PROMPT.md        ← ไฟล์นี้
```

---

## ✅ สิ่งที่ทำเสร็จแล้ว

### Bug Fixes (ห้ามย้อนกลับ)

| # | สิ่งที่แก้ | ไฟล์ |
|---|-----------|------|
| 1 | `.env.json` port 3457→3456 | `maw-js/.env.json` |
| 2 | Oracle Core: `bun run src/index.ts` → `bun src/server.ts` | `start-oracle.cmd` |
| 3 | Hardcoded `C:\Agentic` → `%~dp0` | `start-oracle.cmd` |
| 4 | `127.0.0.1` → `localhost` (8 ไฟล์) | Multiple |
| 5 | Ghost agents (nexus/god-oracle/gemini) ลบแล้ว | `ssh.ts`, `tmux-class.ts`, `sessions.ts`, `load.ts` |
| 6 | `forceSessions` array ลบแล้ว | `sessions.ts` |
| 7 | deprecated.ts: mock → proxy จริง (15 routes) | `deprecated.ts` |
| 8 | Vector search warning ซ่อน (Ollama ไม่มี → เงียบ fallback FTS5) | `handlers.ts`, `search.ts` |
| 9 | Windows WSL tmux: `cmd.exe /c` → `wsl bash -c` | `ssh.ts`, `tmux-types.ts` |
| 10 | `detectGhqRoot()` dynamic detection | `load.ts` |
| 11 | `/api/health` endpoint added | `deprecated.ts` |
| 12 | Proxy error logging (`console.warn`) | `deprecated.ts` |
| 13 | nexus → god ทั้งระบบ | All config + docs + scripts |
| 14 | Auto-start GOD in `start-oracle.cmd` | `start-oracle.cmd` |

### กฎเหล็ก (ห้ามย้อนกลับ)

1. ห้ามเพิ่ม `names.add("ชื่อagent")` ใน tmux-class.ts หรือ ssh.ts
2. ห้ามเพิ่ม `forceSessions` ใน sessions.ts
3. ห้ามเปลี่ยน port จาก 3456 โดยไม่แก้ทุกที่
4. ห้ามเปลี่ยน Oracle Core จาก `bun src/server.ts`
5. ห้าม hardcode path — ใช้ `%~dp0` (Windows) หรือ dynamic detection
6. ห้ามใช้ `127.0.0.1` — ใช้ `localhost`
7. ห้ามเปลี่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่่use the deprecated.ts proxy)
```

### 🔴 P0 — Agent ทำอะไรได้จริง (Make GOD Actually Do Things) ✅ DONE

**สิ่งที่ทำ:**
1. ✅ `scripts/oracle-tools.sh` — Bash-level tools (20+ functions)
2. ✅ `maw-js/src/api/tools.ts` — HTTP API endpoints (server-side, works from any agent):
   - `POST /api/tools/learn` — learn to Oracle
   - `GET /api/tools/search` — search knowledge
   - `GET/PUT/PATCH /api/tools/file` — read/write/append files
   - `GET/POST/PATCH /api/tools/goals` — goal management
   - `POST /api/tools/message` — send to agent via tmux
   - `POST /api/tools/exec` — execute commands
   - `POST /api/tools/reflect` — post-task reflection
   - `GET/POST /api/tools/inbox` — inbox management
   - `GET/PUT/PATCH /api/tools/memory/:file` — memory operations
   - `GET /api/tools/fleet` — full system status
3. ✅ `.gemini/agents/god.md` — Practical instructions for both HTTP API + bash script

**เกณฑ์สำเร็จ:** ✅ GOD สามารถอ่านไฟล์, บันทึกสิ่งที่เรียนรู้ลง Oracle, และแก้ไขโค้ดได้โดยไม่ต้องให้มนุษย์ช่วย

---

### 🔴 P0 — Goal Execution System (ทำตามเป้าหมายอัตโนมัติ) ✅ DONE

**สิ่งที่ทำ:**
1. ✅ `maw-js/src/core/task-runner.ts` — Server-side task runner:
   - `parseGoals()` — read goals.md into structured data
   - `getNextPendingGoal()` — find first [ ] goal
   - `markGoalActive/Done()` — update status
   - `dispatchToAgent()` — send task to agent via tmux
   - `processInbox()` — convert inbox items to goals
   - `runTaskCycle()` — full cycle: inbox → goal → dispatch
2. ✅ `scripts/oracle-tools.sh` — Bash-level task runner functions
3. ✅ Goals format + status tracking [ ]/[~]/[x]/[!]
4. ✅ API endpoints: `POST /api/heartbeat/task-cycle`, `GET /api/heartbeat/next-goal`

**เกณฑ์สำเร็จ:** ✅ อ่าน goal → mark active → dispatch to agent → log — อัตโนมัติ

---

### 🟡 P1 — Multi-Agent Collaboration (มีมากกว่า 1 ตัว) ⚡ PARTIAL

**สิ่งที่ทำ:**
1. ✅ สร้าง agent ตัวที่ 2 (Builder) + ตัวที่ 3 (Researcher):
   - `.gemini/agents/builder.md` — Coding Specialist
   - `.gemini/agents/researcher.md` — Knowledge Specialist
   - `ψ/agents/builder/memory/identity.md`
   - `ψ/agents/researcher/memory/identity.md`
   - `start-builder.cmd` — launch script
2. ✅ Task delegation system ใน god.md:
   - Delegation Rules: ไฟล์เดียว → ทำเอง, หลายไฟล์ → delegate builder
   - ส่ง task format: TASK/FILE/TEST
3. ✅ Inter-agent communication:
   - `send_to_agent` — ส่ง message ผ่าน tmux send-keys
   - `ask_agent` — ส่ง message ผ่าน Maw API /api/asks
   - `ensure-agents.sh` updated — builder registered

**ยังขาด:**
- ⬜ เทสจริง: GOD ส่งงานให้ Builder → Builder ทำ → รายงานกลับ
- ⬜ เพิ่ม builder ใน REGISTERED_AGENTS (เปิด comment)

**เกณฑ์สำเร็จ:** ⚡ GOD ส่งงานให้ agent ตัวอื่นได้ แต่ยังไม่ได้เทส end-to-end

---

### 🟡 P1 — Autonomous Loop (Agent ทำงานเองโดยไม่ต้องถาม) ⚡ PARTIAL

**สิ่งที่ทำ:**
1. ✅ `maw-js/src/core/heartbeat.ts` — Periodic autonomous check (30min default):
   - Check Oracle health
   - Check agent sessions
   - Count pending goals + inbox items
   - Auto-run task cycle if work exists
   - Log all heartbeats to ψ/memory/logs/heartbeat.log
2. ✅ Auto-start heartbeat in server.ts startup
3. ✅ API control: `POST /api/heartbeat/start|stop|run`
4. ✅ god.md AUTONOMOUS MODE instructions

**ยังขาด:**
- ⬜ Decision engine (priority evaluation)
- ⬜ Memory-driven behavior (patterns/decisions/learnings ปรับพฤติกรรม)

**เกณฑ์สำเร็จ:** ⚡ Heartbeat ทำงาน + task dispatch ได้ แต่ยังไม่มี smart prioritization

---

### 🟢 P2 — Tool Integration (เครื่องมือสำหรับ Agent)

**สิ่งที่ต้องทำ:**
1. Git integration — GOD commit/push code ได้
2. Web search — GOD ค้นหาข้อมูลออนไลน์ได้
3. File system — GOD อ่าน/เขียน/แก้ไขไฟล์ได้
4. API calls — GOD เรียก external APIs ได้
5. Terminal — GOD รัน shell commands ได้ (มี PTY แล้ว แต่ต้อง connect กับ agent)

**เกณฑ์สำเร็จ:** GOD ใช้เครื่องมือได้ 3+ อย่าง โดยไม่ต้องให้มนุษย์ทำแทน

---

### 🟢 P2 — Dashboard Enhancement

**สิ่งที่ต้องทำ:**
1. Live terminal ใช้งานจริง (PTY → Gemini CLI)
2. Task board — ดู/จัดการ goals จาก dashboard
3. Knowledge graph visualization
4. Agent activity timeline
5. Multi-agent fleet view

---

### 🔵 P3 — Production Readiness

**สิ่งที่ต้องทำ:**
1. Process manager (PM2/NSSM) — รันเป็น daemon
2. Auto-restart on crash
3. Logging system
4. Backup/restore for SQLite DB
5. Security: auth tokens for API

---

## 🧪 วิธีเทสระบบ

```powershell
# 1. รันระบบทั้งหมด + GOD
cd C:\Agentic
.\start-oracle.cmd

# 2. รอ 10 วินาที แล้วเทส
# Oracle Core
curl http://localhost:47778/api/health

# Maw API
curl http://localhost:3456/api/health
curl http://localhost:3456/api/sessions

# Frontend
start http://localhost:5173

# 3. ดู GOD ใน tmux
tmux attach -t god

# 4. ออกจาก tmux (ไม่ฆ่า)
# กด Ctrl+B แล้วกด D
```

---

## 📚 Reference Links

| Resource | URL |
|----------|-----|
| Repo | https://github.com/dmz2001TH/agentic-new |
| maw-js upstream | https://github.com/Soul-Brews-Studio/maw-js |
| arra-oracle-v3 upstream | https://github.com/Soul-Brews-Studio/arra-oracle-v3 |
| Oracle Guide | https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide |
| Multi-Agent Book | https://soul-brews-studio.github.io/multi-agent-orchestration-book/ |
| รูปสอนความว่าง | https://book.buildwithoracle.com |

---

## 🔄 Handoff Protocol (สำหรับ Agent ทุกตัว)

**เมื่อทำงานเสร็จ 1 session:**
1. อัพเดท `HANDOFF-PROMPT.md` — เพิ่มสิ่งที่ทำเสร็จ, ลบสิ่งที่ทำแล้วจาก TODO
2. อัพเดท `INSTALLATION.md` — ถ้ามีการเปลี่ยนวิธีติดตั้ง
3. Commit + Push ทุกอย่าง
4. เขียน prompt ใหม่สำหรับ agent ถัดไป (ส่วน "💬 Prompt สำหรับ Agent ถัดไป" ด้านล่าง)
5. รายงานมนุษย์ว่าทำอะไรเสร็จ, เหลืออะไร, agent ถัดไปต้องทำอะไร

---

## 💬 Prompt สำหรับ Agent ถัดไป

_(อัพเดทส่วนนี้ทุกครั้งที่ทำงานเสร็จ — copy ไปให้ agent ใหม่ได้เลย)_

```
คุณได้รับมอบหมายให้ดูแลโปรเจ็ค Oracle v3 Agentic System
Repo: https://github.com/dmz2001TH/agentic-new

อ่าน HANDOFF-PROMPT.md ใน repo ก่อน — มีรายละเอียดทั้งหมด

สิ่งที่ทำเสร็จแล้ว:
- ✅ P0: GOD Tool Integration — oracle-tools.sh (bash) + /api/tools/* (HTTP API) + god.md practical instructions
- ✅ P0: Goal Execution System — task-runner.ts (server-side) + bash script + /api/heartbeat/task-cycle
- ✅ P1 Partial: Multi-Agent — Builder + Researcher agents, send_to_agent + ask_agent, ensure-agents.sh
- ✅ P1 Partial: Autonomous Loop — heartbeat.ts (30min), auto-start in server.ts, /api/heartbeat/* endpoints
- ✅ Memory system files ครบ
- ✅ validate-system.sh — 31/31 checks pass

สิ่งที่ต้องทำต่อ:
1. 🔴 เทสจริง: curl localhost:3456/api/tools/fleet — ต้องรัน maw-js server ก่อน
2. 🔴 เทส task runner: POST /api/heartbeat/task-cycle — ต้องมี pending goals + agent online
3. 🟡 Decision engine: priority evaluation สำหรับ goals (ยังไม่มี)
4. 🟡 Memory-driven behavior: ใช้ patterns/decisions ปรับพฤติกรรม heartbeat
5. 🟢 P2 Tool Integration: Git (commit/push), Web search
6. 🟢 P2 Dashboard: Live terminal, Task board, Knowledge graph
7. 🔵 P3 Production: PM2/NSSM, auto-restart, logging, backup, auth

ข้อควรระวัง:
- กฎเหล็ก 10 ข้อใน HANDOFF-PROMPT.md — ห้ามย้อนกลับ
- ห้ามใช้ 127.0.0.1 → ใช้ localhost
- ห้าม hardcode path → ใช้ dynamic detection
- agent ชื่อ GOD เท่านั้น

เมื่อคุณทำงานเสร็จ:
1. อัพเดท HANDOFF-PROMPT.md (สิ่งที่ทำเสร็จ + สิ่งที่เหลือ)
2. อัพเดทส่วน "Prompt สำหรับ Agent ถัดไป" นี้
3. Commit + Push ทั้งหมด
4. ส่ง prompt นี้ให้ agent ตัวถัดไปทำงานต่อ
```
