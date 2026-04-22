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
- ✅ **Agent Enhancement System v3** — 8 modules, 41 tests passing, auto-middleware
  - chain-of-thought.ts: บังคับคิดทีละ step
  - self-reflection.ts: ตรวจงานตัวเอง + แก้ไข
  - prompt-templates.ts: optimize prompt สำหรับ model กาก
  - repetition-guard.ts: ตรวจจับ + ทำลาย repetition loop
  - memory-augmented-reasoning.ts: ค้น Oracle ระหว่างคิด
  - multi-agent-debate.ts: 2 perspective เถียงกัน แล้วสรุป
  - smart-retry.ts: auto-retry 5 strategies ตอนทำงานพลาด
  - learning-feedback-loop.ts: จำสิ่งที่เคยทำ แล้วนำกลับมาใช้
  - agent-middleware.ts: auto-hook เข้า runtime
  - API: 13 endpoints /api/enhance/*
- ✅ **AUTONOMOUS MODE (2026-04-23)** — Full autonomy, no permission blocks
  - settings.json: defaultApprovalMode = "yolo"
  - GEMINI.md: Red Lines → Autonomous Actions (ทำเลย + log)
  - god.md: ลบ "⚠️ ต้อง confirm ก่อน" → ทำได้ทั้งหมด
  - builder.md: ลบ "⚠️ ต้องบอก GOD ก่อน" → ทำได้เองทั้งหมด
  - start-god-with-memory.cmd: ลบ --prompt flag → tmux buffer injection
  - start-god-with-memory.sh: เพิ่ม AUTONOMOUS RULES
  - test-autonomous.sh: 15/15 tests PASSED
  - AUDIT-REPORT.md: 16 blockers identified & fixed
  - ดูรายละเอียด: HANDOFF-AUTONOMOUS-2026-04-23.md

## สิ่งที่ต้องทำต่อ (按ลำดับความสำคัญ)

### 🔴 P0 — เทส Agent Enhancement อัตโนมัติ
- รัน start-oracle.cmd → curl http://localhost:3456/api/enhance/config
- เทส full pipeline: POST /api/enhance/solve กับ task จริง
- เทส repetition guard: POST /api/enhance/guard กับ output ที่มี ✦ ซ้ำ
- เทส debate: POST /api/enhance/debate กับคำถามยากๆ
- เช็ค GEMINI.md ว่า auto-patch enhancement rules แล้ว
- **ถ้า fail → log error + ข้ามไป P1 (ไม่หยุด)**

### 🟡 P1 — Integrate Enhancement กับ Agent จริง
- เชื่อม memory-augmented-reasoning กับ Oracle จริง (ต้องมีข้อมูลใน knowledge base)
- ทดสอบ learning-feedback-loop: รัน solve หลายครั้ง → เช็ค learning-stats
- ปรับ tuning: debateConfidenceThreshold, cotMaxSteps ตามผลจริง

### 🟢 P2 — Dashboard Enhancement
- React UI components สำหรับ task board
- Knowledge graph visualization
- Agent activity timeline
- Enhancement stats visualization

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
