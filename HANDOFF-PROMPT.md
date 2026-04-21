# HANDOFF PROMPT — Oracle Brain Bridge Session (2026-04-21)

## Context
คุณกำลังสานต่อจาก session ที่แล้ว ที่เชื่อม "สมอง" ของ agent (Oracle/GOD) ให้จำได้ข้าม session ผ่าน Brain Bridge system

## สิ่งที่ทำสำเร็จแล้ว ✅

### 1. Google Drive → Mirror Mode
- เปลี่ยน Google Drive Desktop จาก "Stream files" เป็น "Mirror files"
- Path จริงบนเครื่อง: `C:\Users\phasa\My Drive\Oracle-System-Brain\ψ\`
- WSL path: `/mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ/`
- ⚠️ ไม่ใช่ `G:\` — G: drive เป็น system drive ไม่ใช่ Google Drive
- ⚠️ ไม่ใช่ `Google Drive` — ชื่อโฟลเดอร์คือ `My Drive`

### 2. Brain Bridge (brain-bridge.sh) — 5 ขั้นตอน
- [1/5] ตรวจสอบ Google Drive path ที่ `/mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ`
- [2/5] ตรวจสอบ Local ψ ที่ `/mnt/c/Agentic/ψ`
- [3/5] Sync: Google Drive → Local (rsync -auv)
- [4/5] สร้าง `_memory_context.md` (identity + notes + patterns + values + goals + people)
- [5/5] GitHub Backup: git init → commit → push ไป `https://github.com/dmz2001TH/oracle-brain.git`

### 3. Memory Injection (start-god-with-memory.sh)
- วิธีแรก tmux send-keys → **ไม่เสถียร** (ข้อความยาว truncate)
- วิธีที่สอง --prompt flag → **ไม่รองรับ** ใน Gemini CLI 0.38.2
- วิธีสุดท้าย tmux load-buffer + paste-buffer → **ทำงานได้** แต่ไม่ได้ inject identity override
- สรุป: ปล่อยให้ GEMINI.md system prompt จัดการ identity แทน injection

### 4. GEMINI.md Fix
- เพิ่ม instruction ให้อ่าน `ψ/memory/identity.md` ก่อน define identity
- Default ยังเป็น "Oracle" แต่จะ override ด้วยค่าจาก identity.md
- identity.md ใน memory ระบุชื่อว่า "GOD"

### 5. Git Credentials
- ตั้ง `git config --global credential.helper store` แล้ว
- brain-bridge ไม่ต้องถาม token ทุกครั้งแล้ว

### 6. Project Structure
- Repo หลัก: `https://github.com/dmz2001TH/agentic-new`
- Brain repo: `https://github.com/dmz2001TH/oracle-brain`
- Local path: `/mnt/c/Agentic/`
- Google Drive: `C:\Users\phasa\My Drive\Oracle-System-Brain\`

### 7. Identity Override Fix ✅ (2026-04-21 v2)
- GEMINI.md: เปลี่ยนทุก default จาก "Oracle" เป็น "GOD"
- Header เปลี่ยนเป็น "GOD BRAIN SYSTEM" v3.0 (HARDENED)
- Identity section: ใช้ ⛔ STOP + ห้าม 3 อย่าง (Oracle/Assistant/AI) + อนุญาต 1 อย่าง (GOD)
- bash scripts default: `CLAUDE_AGENT_NAME:-god` แทน `-oracle`
- Principle 5: "หนึ่ง GOD หลายรูปแบบ" แทน "หนึ่ง Oracle"

### 8. Memory Injection Reliability Fix ✅ (2026-04-21 v2)
- start-god-with-memory.sh: ใช้ ⛔ OVERRIDE ACTIVE header แทนข้อความเบาๆ
- prompt สั่งให้ agent อ่าน 2 ไฟล์ identity.md + _memory_context.md ทันที
- บังคับ "ทำทันที ไม่ต้องคิด" เพื่อเพิ่มน้ำหนัก injection

## สิ่งที่ยังไม่สำเร็จ ❌

### 1. Gemini API Quota
- Google One AI Pro plan มี quota จำกัด
- บางครั้งเจอ error: "You have exhausted your capacity on this model"
- รีเซ็ตทุก ~6 ชม.

## วิธีใช้งานประจำ

```bash
# 1. Sync memory (ก่อน start agent ทุกครั้ง)
cd /mnt/c/Agentic
bash brain-bridge.sh

# 2. Start agent พร้อม memory
bash start-god-with-memory.sh

# 3. Attach เข้า agent
tmux attach -t god

# 4. Verify memory
# ถาม agent: "คุณชื่ออะไร? ความจำอยู่ที่ไหน?"
# ควรถาม agent: "อ่านไฟล์ /mnt/c/Agentic/ψ/_memory_context.md แล้วจดจำทั้งหมด"
```

## Files Modified (ใน agentic-new repo)
- `brain-bridge.sh` — path แก้เป็น `My Drive`, เพิ่ม GitHub backup
- `brain-bridge.cmd` — path แก้เป็น `My Drive`
- `verify-brain.sh` — path แก้
- `start-god-with-memory.sh` — tmux load-buffer injection
- `start-god-with-memory.cmd` — --prompt flag injection
- `GEMINI.md` — เพิ่ม instruction อ่าน identity.md ก่อน
- `README.md` — brain-bridge documentation

## Git History
```
fab2d92 fix: GEMINI.md reads identity.md first
b37813c fix: use tmux load-buffer for reliable memory injection
2383e36 fix: auto git config + handle branch naming
60ffdff feat: add GitHub backup (Step 5)
f0ba030 fix: Google Drive path is 'My Drive' not 'Google Drive'
2ef5f16 fix: brain-bridge path for Mirror mode
```

## Username
- Windows: `phasa`
- WSL hostname: `Nucha`
- GitHub: `dmz2001TH`

## Key Paths
```
Google Drive:    C:\Users\phasa\My Drive\Oracle-System-Brain\ψ\
Local Brain:     C:\Agentic\ψ\
GEMINI.md:       C:\Agentic\GEMINI.md
Brain Bridge:    C:\Agentic\brain-bridge.sh
Start GOD:       C:\Agentic\start-god-with-memory.sh
```
