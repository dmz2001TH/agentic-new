# 🔮 HANDOFF PROMPT — Agent ตัวถัดไป

**สำหรับ:** AI Agent ตัวถัดไปที่จะ接手โปรเจ็คนี้
**สร้างเมื่อ:** 2026-04-19 (commit 724eaac)
**สถานะปัจจุบัน:** UI buttons ✅ + Bridge ✅ + Tests ผ่าน (23/23) — ยังไม่เทสบน browser จริง

---

## 📌 สิ่งที่ Agent ตัวนี้ทำไปแล้ว

### 1. 📎 Image Attachment + 🎤 Voice Input ใน Live Terminal
- `maw-ui/src/components/TerminalView.tsx` — เพิ่ม 2 ปุ่มใน bottom bar
  - 📎 ซ้ายสุด → file picker → upload ไป `/api/upload` → แสดง thumbnail 32×32 → ส่ง URL ตอน Enter
  - 🎤 ขวา → Web Speech API (`lang="th-TH"`) → ใส่ text ใน input buffer → 🎤=idle 🔴=listening
  - รองรับ clipboard paste รูปภาพ (Ctrl+V)
- `maw-ui/src/hooks/useImageUpload.ts` — hook upload รูปไป `/api/upload`
- `maw-ui/src/hooks/useVoiceInput.ts` — hook Web Speech API
- **Build ผ่าน** ✅ — dist deployed ทั้ง `maw-js/ui/office/` และ `~/.maw/ui/dist/`
- **ยังไม่เทสบน browser** — ต้อง `maw serve` แล้วเปิด `/terminal.html` ดู

### 2. 🔗 Agent Chat Bridge — 2 agents คุยกันผ่าน tmux
- `maw-js/src/api/bridge.ts` — Backend relay service
  - ใช้ `tmux capture-pane` + diff algorithm จับ output ใหม่
  - ใช้ `tmux sendText()` ยิงข้อความเข้า tmux pane ของอีกฝ่าย
  - prompt detection (`❯`, `>`, `$`) เพื่อรู้ว่า agent ตอบเสร็จ
  - API: `POST /api/bridge/start`, `POST /api/bridge/stop`, `POST /api/bridge/send`, `GET /api/bridge/list`
  - WebSocket: `/ws/bridge/:id` — stream conversation events
- `maw-js/src/core/server.ts` — เพิ่ม WS handler สำหรับ `/ws/bridge/:id`
- `maw-js/src/api/index.ts` — register `bridgeApi`
- `maw-ui/src/components/BridgeView.tsx` — Chat UI (left/right bubbles, agent selection, manual injection)
- `maw-ui/src/apps/bridge.tsx` + `maw-ui/bridge.html` — page entry
- **Test: 23/23 passed** (diffCapture, prompt detection, cleanOutput, full relay simulation)
- **เจอ + แก้ bug:** `diffCapture` เดิม match suffix กับท้าย buffer แทนต้น → แก้เป็น suffix-prefix match
- **ยังไม่เทสจริง** — ต้อง wake 2 agents แล้ว bridge จริง

### 3. แก้ DashboardPro.tsx syntax error
- ลบ `{` หน้า `READONLY` ternary → build ผ่าน

---

## 🏗️ โครงสร้างปัจจุบัน

```
Repo: https://github.com/dmz2001TH/agentic (master)
Fork: https://github.com/dmz2001TH/maw-ui (main — fork ของ Soul-Brews-Studio/maw-ui)
```

### Files Changed:
```
agentic:
  maw-js/src/api/bridge.ts                          Bridge relay service (NEW)
  maw-js/src/api/index.ts                           register bridgeApi
  maw-js/src/core/server.ts                         WS handler /ws/bridge/:id
  maw-js/ui/office/*                                rebuilt dist (includes bridge.html + TerminalView with 📎🎤)

maw-ui (fork at dmz2001TH/maw-ui):
  src/components/TerminalView.tsx                    📎 + 🎤 buttons
  src/components/BridgeView.tsx                      Chat bridge UI (NEW)
  src/apps/bridge.tsx                                bridge page entry (NEW)
  src/hooks/useImageUpload.ts                        upload hook (NEW)
  src/hooks/useVoiceInput.ts                         speech hook (NEW)
  src/components/DashboardPro.tsx                    syntax fix
  bridge.html                                        HTML entry (NEW)
  vite.config.ts                                     add bridge entry point
```

---

## 🔴 สิ่งที่ห้ามทำ

1. ห้ามลบ Upload API (`src/api/upload.ts`)
2. ห้ามลบ Bridge API (`src/api/bridge.ts`)
3. ห้ามลบ GOD agent (`.gemini/agents/god.md`)
4. ห้ามลบ DNS timeout ใน `peers/probe.ts`
5. ห้ามลบ `run-isolated-safe.sh`
6. ห้ามลบ YAML frontmatter ใน `god.md`
7. ห้ามเปลี่ยน `uploadApi` export
8. ห้ามลบ `launch-agent.sh`
9. ห้ามแก้ test scripts กลับ

---

## 🎯 สิ่งที่ Agent ตัวถัดไปต้องทำ

### Priority 1: เทส UI + Bridge บน browser จริง
```bash
cd agentic/maw-js && bun install
maw serve  # port 3456

# Terminal UI — ทดสอบ 📎 + 🎤
# เปิด http://localhost:3456/terminal.html
# ทดสอบ 📎: กด → เลือกรูป → ดู thumbnail → กด Enter ส่ง
# ทดสอบ 🎤: กด → พูด → ดู text ปรากฏ → กด Enter ส่ง

# Bridge — ทดสอบ 2 agents คุยกัน
# เปิด http://localhost:3456/bridge.html
# Wake 2 agents: maw wake agent-a && maw wake agent-b
# เลือก agent-a + agent-b → Start Bridge
# ดู live terminal ทั้ง 2 ตัวว่า relay ทำงานมั้ย
# ดู /bridge.html ว่า chat bubbles แสดงถูกมั้ย
```

### Priority 2: แก้ปัญหาที่อาจเจอ
- **Prompt detection ไม่แม่น** — ถ้า agent ใช้ prompt แปลกๆ อาจ relay ไม่ทำงาน → เพิ่ม pattern ใน `isPromptLine()`
- **Voice input ไม่ทำงาน** — Web Speech API ต้อง HTTPS หรือ localhost → ถ้าเข้าผ่าน IP อาจไม่ได้
- **Upload endpoint** — maw-js ใช้ Elysia (Bun) แต่ maw-ui hook ส่งไป `/api/upload` → ถ้าไม่ตรงให้แก้ hook
- **Diff algorithm** — ถ้า agent output มี ANSI code เยอะๆ diff อาจผิด → ต้อง strip ANSI ก่อน diff

### Priority 3: ปรับปรุง Bridge
- เพิ่ม `tmux pipe-pane` แทน polling (real-time stream)
- เพิ่ม conversation history บันทึกเป็นไฟล์
- เพิ่ม "thinking" timeout — ถ้า agent คิดนานเกิน X วินาที ข้ามไป
- เพิ่ม conversation template — ให้ agent คุยกันตามหัวข้อที่กำหนด

### Priority 4: อื่นๆ
- maw-ui PR กลับไป Soul-Brews-Studio/maw-ui (ถ้าต้องการ merge upstream)
- arra-oracle-v3 tests (ต้อง DB setup)
- Process management (pm2/systemd)

---

## 💡 สิ่งที่เรียนรู้

1. **tmux capture-pane diff** — ต้อง match suffix ของ prev กับ prefix ของ curr (ไม่ใช่ suffix ของ curr)
2. **tmux sendText** — ใช้ load-buffer สำหรับ multiline, send-keys -l สำหรับ short text
3. **Web Speech API** — ต้อง HTTPS หรือ localhost, ไม่ทำงานบน HTTP + IP
4. **Elysia plugin format** — `new Elysia({ prefix: "/api" }).post(...).get(...)`
5. **Vite multi-page** — เพิ่ม entry ใน `rollupOptions.input` + สร้าง HTML file
6. **Bridge architecture** — tmux level bridge > shell pipe bridge เพราะ agent ไม่ต้องร่วมมือ
7. **DashboardPro syntax** — `{READONLY ? (` ผิด ต้องเป็น `READONLY ? (` (ไม่มี `{` ครอบ)

---

## 🧪 วิธีเทส

```bash
# ====== maw-js tests ======
cd agentic/maw-js && bun install
bun run test:all          # 1,890+ tests

# ====== Bridge test (mock — already done) ======
# 23/23 tests passed
# diffCapture, prompt detection, cleanOutput, full relay simulation

# ====== maw server ======
maw serve                 # port 3456

# ====== Upload API ======
curl -F "file=@image.png" http://localhost:3456/api/upload

# ====== Bridge API ======
curl -X POST http://localhost:3456/api/bridge/start \
  -H "Content-Type: application/json" \
  -d '{"agentA":"session-name:0","agentB":"session-name:1"}'
curl http://localhost:3456/api/bridge/list

# ====== UI ======
# http://localhost:3456/terminal.html  — live terminal with 📎🎤
# http://localhost:3456/bridge.html    — agent chat bridge
```

---

## 📚 ลิงก์

- **Repo:** https://github.com/dmz2001TH/agentic
- **maw-ui fork:** https://github.com/dmz2001TH/maw-ui
- **maw-ui upstream:** https://github.com/Soul-Brews-Studio/maw-ui
- **Commits:** https://github.com/dmz2001TH/agentic/commits/master

---

**ทำต่อได้เลย!** 🔗📎🎤
