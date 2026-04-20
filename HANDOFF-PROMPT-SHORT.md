# 💬 HANDOFF PROMPT — ส่งต่อให้ Agent ตัวถัดไป

Copy ข้อความด้านล่างทั้งหมด → paste ให้ agent ใหม่ได้เลย

---

```
คุณได้รับมอบหมายให้ดูแลและพัฒนาโปรเจ็ค Oracle v3 Agentic System

Repo: https://github.com/dmz2001TH/agentic-new

## สิ่งที่ทำเสร็จแล้ว (DO NOT REVERT)
- ✅ Bug fixes 14 จุด (ดูกฎเหล็กใน HANDOFF-PROMPT.md)
- ✅ Oracle Core (47778) — learn/search/reflect/stats/graph ทำงานได้
- ✅ Maw API (3456) — proxy 15 routes ไป Oracle, sessions, fleet
- ✅ Frontend (5173) — proxy chain ทำงานครบ
- ✅ Agent GOD — ตั้งเป็น agent หลักแทน nexus, auto-start ใน start-oracle.cmd
- ✅ Config: dynamic ghqRoot detection, /health endpoint, error logging
- ✅ Unit tests: arra-oracle-v3 208/0 pass, maw-js 1174/161 pass

## สิ่งที่ต้องทำต่อ (按ลำดับความสำคัญ)

### 🔴 P0 — ให้ GOD ทำอะไรได้จริง
- ให้ GOD เรียก Oracle API เองได้ (curl learn/search/stats)
- ให้ GOD อ่าน/เขียนไฟล์ได้
- ให้ GOD รัน commands ได้
- เกณฑ์: GOD ทำงาน autonomously ได้ 1 task โดยไม่ต้องให้มนุษย์ช่วย

### 🔴 P0 — Goal Execution System
- สร้าง task runner: อ่าน goal → วางแผน → ลงมือ → รายงาน
- GOD อ่าน ψ/memory/goals.md → execute → update status
- เกณฑ์: GOD ทำ goal ให้เสร็จโดยอัตโนมัติ

### 🟡 P1 — Multi-Agent Collaboration
- สร้าง agent ตัวที่ 2 (Builder/Researcher)
- Task delegation: GOD แบ่งงาน → agent ทำ → รายงานกลับ
- ใช้ Maw API /api/asks สำหรับ inter-agent communication

### 🟡 P1 — Autonomous Loop
- Heartbeat: GOD เช็ค inbox/goals ทุก 30 นาที
- Decision engine: GOD ประเมิน priority เอง
- Memory-driven: ใช้ patterns/decisions/learnings ปรับพฤติกรรม

### 🟢 P2 — Tool Integration
- Git (commit/push), Web search, File system, API calls, Terminal

### 🟢 P2 — Dashboard Enhancement
- Live terminal (PTY), Task board, Knowledge graph, Agent timeline

### 🔵 P3 — Production
- PM2/NSSM daemon, Auto-restart, Logging, Backup, Auth

## ขั้นตอนเมื่อคุณทำงานเสร็จ
1. อัพเดท HANDOFF-PROMPT.md — เพิ่มสิ่งที่ทำเสร็จ ลบจาก TODO
2. อัพเดทส่วนนี้ ("สิ่งที่ทำเสร็จแล้ว" + "สิ่งที่ต้องทำต่อ")
3. git add -A && git commit && git push
4. ส่ง prompt นี้ให้ agent ตัวถัดไปทำงานต่อ

## กฎเหล็ก (ห้ามย้อนกลับ)
1. ห้ามเพิ่ม names.add("ชื่อagent") ใน tmux-class.ts หรือ ssh.ts
2. ห้ามเพิ่ม forceSessions ใน sessions.ts
3. ห้ามเปลี่ยน port จาก 3456 โดยไม่แก้ทุกที่
4. ห้ามเปลี่ยน Oracle Core จาก bun src/server.ts
5. ห้าม hardcode path — ใช้ %~dp0 หรือ dynamic detection
6. ห้ามใช้ 127.0.0.1 — ใช้ localhost
7. ห้ามเปลี่ยน deprecated.ts กลับเป็น mock
8. ห้ามแสดง vector search warning ให้ผู้ใช้เห็น
9. ห้ามเปลี่ยน hostExec กลับเป็น cmd.exe สำหรับ tmux
10. agent ชื่อ GOD เท่านั้น — ห้ามใช้ nexus

อ่าน HANDOFF-PROMPT.md และ INSTALLATION.md ก่อนเริ่มทำงาน
```
