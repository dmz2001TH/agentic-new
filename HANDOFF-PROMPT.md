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
| **GOD Agent** | tmux | `tmux new-session -s god "gemini --yolo"` | Agent หลัก |

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
│   │   └── asks.ts          ← /api/asks (send to agents)
│   ├── src/core/
│   │   ├── server.ts        ← Main server + WebSocket + ensure-agents
│   │   └── transport/
│   │       ├── ssh.ts       ← hostExec() + listSessions()
│   │       ├── tmux-class.ts← Tmux wrapper class
│   │       └── pty.ts       ← Live Terminal handler
│   └── src/commands/plugins/← Wake, oracle, bud plugins
├── scripts/
│   └── ensure-agents.sh     ← Auto-create tmux sessions on boot
├── ψ/                       ← Memory System
│   ├── memory/              ← Shared brain (all agents read)
│   ├── agents/god/memory/   ← GOD's personal brain
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

### 🔴 P0 — Agent ทำอะไรได้จริง (Make GOD Actually Do Things)

**ปัญหา:** GOD ตอนนี้แค่คุยตอบ มันไม่ได้อ่านไฟล์, รัน code, แก้ไขอะไรจริงๆ

**สิ่งที่ต้องทำ:**
1. สร้าง `.gemini/agents/god.md` context ที่สอนให้ GOD เรียก Oracle API เองได้:
   - `curl localhost:47778/api/learn` → บันทึกสิ่งที่เรียนรู้
   - `curl localhost:47778/api/search?q=...` → ค้นหาความรู้
   - `curl localhost:47778/api/stats` → เช็คสถานะ
2. ให้ GOD อ่าน/เขียนไฟล์ในโปรเจ็คได้ (ผ่าน Gemini CLI's file access)
3. ให้ GOD เรียกใช้ tools ผ่าน Gemini CLI function calling

**เกณฑ์สำเร็จ:** GOD สามารถอ่านไฟล์, บันทึกสิ่งที่เรียนรู้ลง Oracle, และแก้ไขโค้ดได้โดยไม่ต้องให้มนุษย์ช่วย

---

### 🔴 P0 — Goal Execution System (ทำตามเป้าหมายอัตโนมัติ)

**ปัญหา:** ψ/memory/goals.md เก็บ goals แต่ไม่มีระบบ execute

**สิ่งที่ต้องทำ:**
1. สร้าง task runner ที่ GOD จะ:
   - อ่าน goals จาก `ψ/memory/goals.md`
   - วางแผนขั้นตอน (plan)
   - ลงมือทำทีละขั้น (execute)
   - บันทึก progress (update goal status)
   - รายงานผล (reflect)
2. สร้าง workflow definition format:
   ```yaml
   # ψ/inbox/example-task.md
   goal: "ทำ X ให้เสร็จ"
   steps:
     - action: read_file
       target: "path/to/file"
     - action: run_command
       cmd: "bun test"
     - action: learn
       pattern: "สิ่งที่เรียนรู้"
   ```

**เกณฑ์สำเร็จ:** GOD อ่าน goal → วางแผน → ลงมือ → รายงานผล โดยอัตโนมัติ

---

### 🟡 P1 — Multi-Agent Collaboration (มีมากกว่า 1 ตัว)

**ปัญหา:** มีแค่ GOD ตัวเดียว ไม่มีการแบ่งงาน

**สิ่งที่ต้องทำ:**
1. สร้าง agent ตัวที่ 2 เช่น:
   - **Builder** — รับผิดชอบ coding/build/test
   - **Researcher** — รับผิดชอบ search/learn/summarize
2. สร้าง task delegation system:
   - GOD รับคำสั่งจากมนุษย์
   - GOD แบ่งงาน → ส่งให้ agent ที่เหมาะสม
   - Agent ทำงาน → ส่งผลกลับ GOD
   - GOD รายงานมนุษย์
3. ใช้ Maw API สำหรับ inter-agent communication:
   - `POST /api/asks` → ส่งข้อความระหว่าง agent
   - tmux `send-keys` → ส่งคำสั่งไป agent โดยตรง

**เกณฑ์สำเร็จ:** GOD ส่งงานให้ agent ตัวอื่น → agent ทำงาน → รายงานผลกลับ

---

### 🟡 P1 — Autonomous Loop (Agent ทำงานเองโดยไม่ต้องถาม)

**ปัญหา:** Agent แค่ตอบเมื่อถูกถาม ไม่ได้ตื่นมาเช็คงานเอง

**สิ่งที่ต้องทำ:**
1. สร้าง heartbeat/cron สำหรับ GOD:
   - ทุก 30 นาที: เช็ค inbox, เช็ค goals ค้าง
   - ทุกเช้า: daily planning, เช็ค calendar/email
   - ทุกเย็น: daily retrospective
2. สร้าง decision engine:
   - GOD ประเมิน priority ของงานเอง
   - เลือกทำงานที่สำคัญที่สุดก่อน
   - รู้ว่า什么时候ควรถามมนุษย์什么时候ทำเอง
3. Memory-driven behavior:
   - อ่าน patterns.md → ปรับพฤติกรรม
   - อ่าน decisions.md → ไม่ตัดสินใจซ้ำ
   - อ่าน learnings.md → ใช้ความรู้เดิม

**เกณฑ์สำเร็จ:** GOD ทำงาน autonomously ได้ 1+ task โดยไม่ต้องให้มนุษย์สั่ง

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

สิ่งที่ทำเสร็จแล้ว: [อัพเดทตรงนี้]
สิ่งที่ต้องทำต่อ: [อัพเดทตรงนี้ — เอาจาก TODO list ข้างบน]

เมื่อคุณทำงานเสร็จ:
1. อัพเดท HANDOFF-PROMPT.md (สิ่งที่ทำเสร็จ + สิ่งที่เหลือ)
2. อัพเดทส่วน "Prompt สำหรับ Agent ถัดไป" นี้
3. Commit + Push ทั้งหมด
4. ส่ง prompt นี้ให้ agent ตัวถัดไปทำงานต่อ
```
