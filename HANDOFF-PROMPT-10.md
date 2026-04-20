# 🔮 HANDOFF PROMPT — Agent ตัวถัดไป

**สำหรับ:** AI Agent ตัวถัดไปที่จะ接手โปรเจ็คนี้
**สร้างเมื่อ:** 2026-04-19 (commit 3237825)
**สถานะปัจจุบัน:** ระบบรันได้ทั้ง 3 ports + maw-ui + 67 plugins + GOD agent

---

## 📌 สิ่งที่ Agent ตัวนี้ทำไปแล้ว (Commits 9-10)

### Commit 9: Windows WSL tmux fix (28f8b75)
- `tmuxCmd()` → detect `win32` → return `wsl tmux`
- `hostExec()` → detect `win32` + tmux cmd → use `["wsl", "bash", "-c", cmd]`
- ทำให้ tmux ทำงานบน Windows ผ่าน WSL ได้

### Commit 10: Sync upstream plugins + Windows setup guide (3237825)
- **10 plugins ใหม่จาก upstream:** doctor, peers, project, demo, learn, init, incubate, signals, cross-team-queue, pair
- **4 API routes ใหม่:** consent, pair, plugin-download, plugin-list-manifest
- **daily cost tracking:** `/api/costs/daily`
- **core/fleet ใหม่:** leaf.ts, nicknames.ts
- **consent core module** (6 ไฟล์)
- **GEMINI.md** — GOD agent personality
- **WINDOWS-SETUP-GUIDE.md** — คู่มือติดตั้ง Windows ฉบับสมบูรณ์

---

## 🏗️ โครงสร้างปัจจุบัน

```
Repo: https://github.com/dmz2001TH/agentic
Branch: master (commit 3237825)
โฟลเดอร์หลัก: C:\Agentic (บน Windows)
```

| Component | Port | หน้าที่ | สถานะ |
|-----------|------|---------|-------|
| **arra-oracle-v3** | 47778 | Oracle Core (Memory/Search) | ✅ ทำงาน |
| **maw-js** | 3456 | Fleet Control + API + maw-ui | ✅ ทำงาน |
| **maw-ui** | 3456 | ARRA Office (Fleet UI) | ✅ อยู่ที่ 3456 |
| **GOD agent** | tmux | Gemini CLI v0.38.2 | ✅ รันอยู่ (ติด auth) |

---

## 📊 เทียบกับคู่มือเจ้าของโปรเจค

### ✅ มีครบแล้ว
- maw server (port 3456) — 18+ API endpoints
- Oracle Core (port 47778) — search/stats/reflect ทำงาน
- maw-ui v1.4.2 — 23 pages (fleet, dashboard, chat, etc.)
- tmux integration — ls, peek, hey, send
- 67 plugins — doctor, peers, project, fleet, wake, etc.
- Windows WSL tmux fix
- Deprecated proxy → Oracle Core (15 routes)
- Ghost agents cleanup

### ⚠️ ยังไม่ได้เทสบน Windows จริง
- tmux ผ่าน WSL (logic อยู่ในโค้ดแล้ว แต่ไม่ได้เทสบน Windows)
- Gemini CLI auto-login (บน Linux sandbox ติด auth prompt)
- maw-ui Live Terminal + Quick Chat
- Fleet management (wake/sleep/peek)

---

## 🔴 สิ่งที่ห้ามทำ

1. **ห้าม revert bug fixes:**
   - `.env.json` port 3456 (ไม่ใช่ 3457)
   - `start-oracle.cmd` ใช้ `bun src\server.ts` (ไม่ใช่ `bun run src\index.ts`)
   - `start-oracle.cmd` ใช้ `%~dp0` (ไม่ใช่ `C:\Agentic`)
   - localhost (ไม่ใช่ 127.0.0.1)
   - `.gitignore` สำหรับ SQLite files

2. **ห้ามเปลี่ยน deprecated.ts กลับเป็น mock:**
   - ของเรา proxy จริงไป Oracle (15 routes)
   - upstream = 410 Gone ทั้งหมด (ไม่ใช่)
   - ของเราดีกว่า

3. **ห้ามเพิ่ม ghost agents:**
   - ลบ hardcoded "god"/"god-oracle"/"gemini" จาก listSessions() แล้ว
   - ลบ forceSessions array จาก /api/sessions แล้ว
   - ลบ "god-oracle" จาก .env.json sessions แล้ว

4. **ห้ามเปลี่ยน hostExec กลับเป็น cmd.exe สำหรับ tmux:**
   - ต้องใช้ `wsl bash -c` สำหรับ tmux commands บน Windows

5. **ห้ามทับ deprecated.ts:**
   - ของเรา proxy ไป Oracle Core
   - upstream คืน 410 Gone
   - ของเราดีกว่า

---

## 🎯 เป้าหมายถัดไป

1. **เทสบน Windows จริง** — WSL + tmux + Gemini CLI
2. **Gemini CLI auto-login** — ทำให้ไม่ต้อง auth ทุกครั้ง
3. **Fleet management** — wake/sleep/peek god agent
4. **maw-ui Live Terminal** — เห็น agent output จริงๆ
5. **Multiple agents** — สร้าง agent เพิ่ม (dev, qa, writer)
6. **Vector search** — ติดตั้ง Ollama (optional)
7. **Process management** — daemon mode (pm2/systemd)
8. **Frontend bundle optimization** — Vite build

---

## 🔧 วิธีรันระบบ

```powershell
# Windows
cd C:\Agentic
.\start-oracle.cmd

# หรือรันทีละตัว
cd C:\Agentic\arra-oracle-v3 && bun src\server.ts  # Port 47778
cd C:\Agentic\maw-js && bun server.ts               # Port 3456
cd C:\Agentic\arra-oracle-v3\frontend && bun run dev --port 5173 --host localhost  # Port 5173

# ปลุก agent
cd C:\Agentic\maw-js
bun src\cli.ts wake god
bun src\cli.ts peek god
bun src\cli.ts hey god "hello, let's work"
```

---

## 📚 ลิงก์ที่ต้องดู

- **Repo:** https://github.com/dmz2001TH/agentic
- **Commits:** https://github.com/dmz2001TH/agentic/commits/master
- **Multi-Agent Book:** https://soul-brews-studio.github.io/multi-agent-orchestration-book/docs/intro
- **oracle-maw-guide:** https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide
- **Upstream maw-js:** https://github.com/Soul-Brews-Studio/maw-js
- **Upstream arra-oracle-v3:** https://github.com/Soul-Brews-Studio/arra-oracle-v3
- **maw-ui:** https://github.com/Soul-Brews-Studio/maw-ui

---

## 📊 Gap Analysis (เทียบ upstream)

### มีเหมือนกัน
- fleet.ts, sessions.ts, send/hey, capture, teams.ts — identical

### ดึงมาแล้ว (commit 3237825)
- doctor, peers, project, pair, demo, learn, init, incubate, signals, cross-team-queue
- consent API + core, pair API, plugin-download, plugin-list-manifest
- daily cost tracking, fleet/leaf.ts, nicknames.ts

### ยังขาดจาก upstream
- `consent.ts` API (upstream = 410 Gone) — ของเรา proxy ดีกว่า ไม่ต้องดึง
- `pair.ts` — ดึงมาแล้ว ✅
- CalVer versioning — upstream ใช้ CalVer (v26.4.18) เราใช้ SemVer (alpha.109)

---

## 💡 สิ่งที่เรียนรู้

1. **tmux บน Windows ต้องใช้ WSL** — ไม่มี tmux native
2. **deprecated.ts proxy ดีกว่า 410 Gone** — frontend ได้ข้อมูลจริง
3. **Ghost agents สร้างปัญหา** — ต้องแสดงเฉพาะ real tmux sessions
4. **Plugin system ต้อง symlink** — bootstrap ที่ startup
5. **Gemini CLI ต้อง auth** — บนเครื่องจริงจะข้ามได้ถ้า login อยู่แล้ว
6. **maw-ui อยู่ที่ port เดียวกับ server** — ไม่ต้องรัน port แยก
7. **อย่าทับ deprecated.ts** — upstream มีแต่ 410 Gone ของเรา proxy จริง

---

## 🚀 Quick Start สำหรับ Agent ถัดไป

```bash
# 1. Clone repo
git clone https://github.com/dmz2001TH/agentic.git
cd agentic

# 2. Install deps
cd maw-js && bun install
cd ../arra-oracle-v3 && bun install

# 3. Install maw-ui
mkdir -p ~/.maw/ui/dist
curl -sL https://github.com/Soul-Brews-Studio/maw-ui/releases/download/v1.4.2/maw-ui-dist.tar.gz | tar -xzf - -C ~/.maw/ui/dist --strip-components=1

# 4. Start servers
cd arra-oracle-v3 && bun src/server.ts &  # 47778
cd maw-js && bun server.ts &               # 3456

# 5. Create god agent
tmux new-session -d -s god -c . "bash"
tmux send-keys -t god "gemini --yolo" Enter

# 6. Check
curl http://localhost:3456/api/sessions
bun src/cli.ts ls
bun src/cli.ts peek god
```

---

**Agent ตัวนี้ทำงานครบแล้ว — ทำต่อได้เลย!** 🌟
