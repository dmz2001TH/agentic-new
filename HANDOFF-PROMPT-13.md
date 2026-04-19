# 🔮 HANDOFF PROMPT — Agent ตัวถัดไป

**สำหรับ:** AI Agent ตัวถัดไปที่จะ接手โปรเจ็คนี้
**สร้างเมื่อ:** 2026-04-19 (commit pending)
**สถานะปัจจุบัน:** ระบบรันได้ + tests ผ่านหมด (1,890+) + GOD agent + Upload API

---

## 📌 สิ่งที่ Agent ตัวนี้ทำไปแล้ว

### 1. แก้ Peers DNS Timeout + Oracle Test Isolation (commit fde05cc)
- เพิ่ม 2s DNS lookup timeout ใน `probe.ts` — แก้ `.local` domain lookup ค้าง
- ย้าย oracle test ไป isolated runner — Bun mock.module ไม่ทำงานรวม process
- **ผล:** 1,890+ tests ผ่านหมด (maw-js 880+831+179, arra-oracle-skills-cli 132, pulse-cli 41)

### 2. GOD Agent — ผู้สร้าง Oracle World (commit 6ad3d61)
- `.gemini/agents/god.md` — system prompt เฉพาะ พร้อม YAML frontmatter
  - ตัวตน: ผู้สร้าง & ผู้ปกครอง Oracle World
  - 5 บัญญัติ: I Am the Source / See the Forest / Silence Is Wisdom / Justice Over Speed / Nothing Is Destroyed
  - 3 ระดับสิทธิ์: ทำได้เลย / ต้อง confirm / ห้ามทำ
  - สไตล์: สั้น คม ไม่อธิบายเยอะ
  - ลำดับขั้น: god → zeus → apollo → athena → hermes
- `.gemini/launch-agent.sh` — wrapper script สลับ context file ตามชื่อ agent
  - ใช้ node patch settings.json → เปลี่ยน contextFileName → รัน gemini --yolo → restore ตอน exit

### 3. Upload API — รับรูปจาก UI (commit pending)
- `src/api/upload.ts` — Elysia plugin
  - `POST /api/upload` — รับรูป multipart/form-data (สูงสุด 10MB, png/jpg/gif/webp)
  - `GET /api/uploads/:filename` — serve รูปที่อัพโหลด
  - เก็บที่ `/tmp/maw-uploads/`
- ลงทะเบียนใน `src/api/index.ts` แล้ว (บรรทัด 73: `.use(uploadApi)`)

### 4. เทส Gemini CLI
- ติดตั้ง Gemini CLI v0.38.2 สำเร็จ
- Trust folder ทำงาน — ตรวจพบ god agent ("New Agents Discovered")
- YAML frontmatter fix — god.md ต้องขึ้นต้นด้วย `---` block
- Google OAuth ไม่ทำงานใน sandbox (scope bug: `userinfo.profile` ถูกปฏิเสธ)
- `NO_BROWSER=true` ให้ URL + auth code input ได้
- **แนะนำ:** ใช้ `GEMINI_API_KEY` จาก https://aistudio.google.com/apikey แทน

---

## 🏗️ โครงสร้างปัจจุบัน

```
Repo: https://github.com/dmz2001TH/agentic
Branch: master
```

### Files Changed (ทั้งหมด):
```
 .gemini/agents/god.md                          GOD agent system prompt + YAML frontmatter
 .gemini/launch-agent.sh                        per-agent context file launcher
 maw-js/src/api/upload.ts                       Upload API (Elysia plugin)
 maw-js/src/core/server.ts                      (ไม่ได้แก้ — Elysia จัดการ /api/*)
 maw-js/src/commands/plugins/peers/probe.ts     DNS lookup timeout
 maw-js/scripts/run-isolated-safe.sh            oracle test isolation
 maw-js/package.json                            exclude oracle from test:plugin
 HANDOFF-PROMPT-12.md                           session summary
 HANDOFF-PROMPT-13.md                           ฉบับนี้
```

---

## 🔴 สิ่งที่ห้ามทำ

### จาก HANDOFF-PROMPT-12 (ห้ามทำเหมือนเดิม):
1. ห้ามลบ DNS timeout ใน prefetchDnsCheck()
2. ห้ามย้าย oracle test กลับไป test:plugin
3. ห้ามทับ run-isolated-safe.sh

### เพิ่มเติม:
4. **ห้ามลบ YAML frontmatter ใน god.md** — Gemini CLI จะ error "Missing mandatory YAML frontmatter"
5. **ห้ามเปลี่ยน uploadApi export** — index.ts  import { uploadApi } from "./upload"
6. **ห้ามลบ launch-agent.sh** — ใช้สำหรับ per-agent context switching

### จาก HANDOFF-PROMPT-11 (ห้ามทำเหมือนเดิม):
7. ห้ามลบ CLAUDE_AGENT_NAME
8. ห้ามเปลี่ยน test scripts กลับ
9. ห้าม revert bug fixes
10. ห้ามเปลี่ยน deprecated.ts กลับเป็น mock
11. ห้ามเพิ่ม ghost agents
12. ห้ามเปลี่ยน hostExec กลับ
13. ห้ามทับ deprecated.ts

---

## 🧪 วิธีเทส

```bash
# ====== maw-js tests ======
cd agentic/maw-js && bun install
bun run test:all          # 1,890+ tests

# ====== maw server ======
maw serve                 # port 3456

# ====== Upload API ======
curl -F "file=@image.png" http://localhost:3456/api/upload
# Response: { ok: true, filename: "xxx.png", url: "http://localhost:3456/api/uploads/xxx.png", ... }

# ====== Gemini CLI ======
cd agentic
gemini --yolo             # ต้อง auth ก่อน (GEMINI_API_KEY)
# หรือ:
NO_BROWSER=true gemini --yolo  # ได้ URL สำหรับ manual auth

# ====== maw wake god ======
maw wake god              # สร้าง tmux session + โหลด god.md
maw peek god              # ดูหน้าจอ god
```

---

## 🎯 สิ่งที่ Agent ตัวถัดไปต้องทำ

### Priority 1: Live Terminal UI Enhancement
**เป้าหมาย:** เพิ่มปุ่มใน live terminal ของ maw-ui

#### 1.1 📎 Image Attachment Button
- เพิ่มปุ่ม 📎 ซ้ายช่อง "type command..."
- กด → file picker (accept="image/*")
- เลือกรูป → POST `/api/upload` (multipart/form-data)
- ได้ URL กลับมา → แสดง thumbnail เล็กๆ ข้าง input
- กด SEND → ส่ง URL ให้ agent ผ่าน WebSocket

**Backend พร้อมแล้ว** (`POST /api/upload` + `GET /api/uploads/:filename`)
**Frontend ต้องแก้:** maw-ui bundle ที่ `ui/office/assets/index-CtHYDtAH.js`

**วิธีแก้ (เลือก 1):**
- **Option A:** แก้ source maw-ui repo → build → deploy
- **Option B:** inject script ผ่าน Elysia middleware ที่ patch HTML ก่อนส่ง
  ```typescript
  // ใน server.ts — inject script ที่เพิ่มปุ่มเข้าไปในหน้า UI
  // ใช้ HTMLRewriter หรือ string replace บน response
  ```

**ตำแหน่งที่ต้องเพิ่มปุ่ม (จาก minified source):**
```javascript
// หา "type command..." placeholder — นั่นคือ input field
// หา div ที่มี className "flex items-center gap-2 px-3 py-2 bg-[#0e0e18]"
// เพิ่มปุ่มก่อน input element
```

#### 1.2 🎤 Microphone / Voice-to-Text Button
- เพิ่มปุ่ม 🎤 ขวาช่อง input (หรือซ้ายถัดจาก 📎)
- กด → `new SpeechRecognition()` (Web Speech API)
- ตั้ง `lang = "th-TH"` (รองรับไทย+อังกฤษ)
- ผลลัพธ์ → ใส่ใน input field
- กด SEND หรือ auto-send ตอนหยุดพูด

**Web Speech API (ไม่ต้อง backend):**
```javascript
const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
const recognition = new SpeechRecognition();
recognition.lang = "th-TH";
recognition.interimResults = true;
recognition.onresult = (e) => {
  const text = Array.from(e.results).map(r => r[0].transcript).join("");
  setInputValue(text); // ใส่ใน input field
};
recognition.start();
```

### Priority 2: เทสบน Windows จริง
- WSL + tmux + Gemini CLI
- `maw wake god` → ดู live terminal
- กดปุ่ม 📎 / 🎤 ว่าทำงานไหม

### Priority 3: Auto-login Gemini CLI
- `GEMINI_API_KEY` env var — ง่ายสุด
- หรือ fix OAuth scope bug ใน Gemini CLI v0.38.2

### Priority 4: อื่นๆ (จาก handoff ก่อนหน้า)
- maw-ui Live Terminal test
- arra-oracle-v3 tests (ต้อง DB setup)
- Process management (pm2/systemd)
- Multiple agents (dev, qa, writer)

---

## 💡 สิ่งที่เรียนรู้

1. **Gemini CLI agents ต้องมี YAML frontmatter** — `---\nname: xxx\ndescription: ...\n---`
2. **Elysia plugin format** — export `const xxxApi = new Elysia({ prefix: "/api" }).post(...).get(...)`
3. **maw-ui ใช้ xterm.js** — real terminal emulator, ส่ง binary WebSocket frames
4. **Quick action buttons** ใน maw-ui ส่ง keystroke จริงเข้า tmux (ไม่ใช่ mock)
5. **NO_BROWSER=true** สำหรับ Gemini CLI manual auth — ได้ URL + auth code input
6. **`fetchHandler` ใน Bun.serve** ไม่ใช่ async โดย default — ถ้าจะ await ต้องประกาศ async
7. **maw-ui live terminal bottom bar** มีโครงสร้าง: flex items-center + input + SEND button + quick action buttons row

---

## 📚 ลิงก์

- **Repo:** https://github.com/dmz2001TH/agentic
- **Commits:** https://github.com/dmz2001TH/agentic/commits/master
- **maw-ui source:** https://github.com/Soul-Brews-Studio/maw-ui (ต้องแก้ที่นี่สำหรับ frontend)
- **Gemini CLI:** https://github.com/google-gemini/gemini-cli
- **Multi-Agent Book:** https://soul-brews-studio.github.io/multi-agent-orchestration-book/docs/intro
- **Google AI Studio (API Key):** https://aistudio.google.com/apikey

---

## 🚀 Quick Start สำหรับ Agent ถัดไป

```bash
# 1. Clone + Install
git clone https://github.com/dmz2001TH/agentic.git
cd agentic/maw-js && bun install

# 2. Tests
bun run test:all

# 3. Server
maw serve

# 4. Test Upload API
curl -F "file=@test.png" http://localhost:3456/api/upload

# 5. Wake god agent
maw wake god

# 6. Start working on live terminal UI
# → ดู Priority 1 ข้างบน
```

---

**Agent ตัวนี้ทำงานครบแล้ว — ทำต่อได้เลย!** 🌟
