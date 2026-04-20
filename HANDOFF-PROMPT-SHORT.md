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
- ✅ P0: GOD Tool Integration — /api/tools/* (15 endpoints), oracle-tools.sh, god.md practical instructions
- ✅ P0: Goal Execution System — task-runner.ts, heartbeat.ts (30min auto), /api/heartbeat/* endpoints
- ✅ P1: Multi-Agent — Builder + Researcher agents (.md context + memory), /api/tools/message, ensure-agents.sh
- ✅ P1: Autonomous Loop — heartbeat auto-start in server.ts, /api/heartbeat/start|stop|run
- ✅ P2: Git Integration — maw-js/src/api/git.ts (status/add/commit/push/ship/pull/stash)
- ✅ P2: Web Search — maw-js/src/api/search.ts (DuckDuckGo + Wikipedia + HN)
- ✅ P3: Auto-restart — scripts/run-with-restart.sh, start-oracle-prod.cmd
- ✅ P3: Backup — scripts/backup-db.sh (SQLite backup, 7-day retention)
- ✅ P3: Auth — MAW_TOOLS_TOKEN for /api/tools/* (optional, dev=no auth)
- ✅ All TypeScript compiles: 570 modules bundled successfully

## สิ่งที่ต้องทำต่อ (按ลำดับความสำคัญ)

### 🔴 P0 — เทสจริง (Runtime Testing)
- รัน start-oracle.cmd แล้วเทส: curl http://localhost:3456/api/tools/fleet
- เทส task runner: เพิ่ม goal → POST /api/heartbeat/task-cycle → ดู dispatch
- เทส GOD เรียก API: tmux attach -t god → สั่งให้ GOD เรียก curl /api/tools/*

### 🟡 P1 — Decision Engine
- สร้าง priority evaluation สำหรับ goals
- Memory-driven behavior: ใช้ patterns/decisions ปรับพฤติกรรม heartbeat

### 🟢 P2 — Dashboard Enhancement
- React UI components สำหรับ task board
- Knowledge graph visualization
- Agent activity timeline

### 🔵 P3 — Production
- PM2/NSSM daemon setup
- TLS/HTTPS certificates

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
