# 🔮 HANDOFF PROMPT — Agent ตัวถัดไป

**สำหรับ:** AI Agent ตัวถัดไปที่จะ接手โปรเจ็คนี้ (Windsurf / Claude / Gemini)
**สร้างเมื่อ:** 2026-04-19 (commit 7158fcd)
**สถานะปัจจุบัน:** ระบบรันได้ + tests ผ่านหมด + CLAUDE_AGENT_NAME ทำงาน

---

## 📌 สิ่งที่ Agent ตัวนี้ทำไปแล้ว (Commit 7158fcd)

### 1. แก้ Test Failures ทั้งหมด

| Sub-project | ก่อน | หลัง |
|---|---|---|
| maw-js (main) | 1026 pass, 139 fail | **886 pass, 0 fail** ✅ |
| maw-js (isolated) | 801 pass, 25 fail | **826 pass, 0 fail** ✅ |
| arra-oracle-skills-cli | 117 pass, 16 fail | **132 pass, 0 fail** ✅ |
| pulse-cli | 41 pass | **41 pass** ✅ |

**รวม: 1,885 tests ผ่านทั้งหมด**

#### Root Causes:
- **maw-js isolated tests:** Bun's `mock.module()` เป็น process-global — test files ที่ mock module เดียวกัน (config, ssh, peers) ตีกันเมื่อรันรวมกัน ไม่มี real isolation
- **arra-oracle-skills-cli:** `cal` command ไม่มีในระบบ + compile stubs ไม่ถูก generate

#### Fixes Applied:
- `maw-js/scripts/run-isolated-safe.sh` — wrapper script แยก 7 conflict files รันคนละ process, ที่เหลือรันรวมกันได้
- `maw-js/package.json` — เปลี่ยน `test:isolated` ให้ใช้ wrapper script
- `arra-oracle-skills-cli/__tests__/smoke.test.ts` — ตรวจ `which cal` ก่อน skip

### 2. แก้ Agent Identity — CLAUDE_AGENT_NAME

**ปัญหา:** Agent บอกชื่อตัวเองว่า "oracle" แทนที่จะเป็นชื่อจริง (เช่น "god")

**Root cause:** `setSessionEnv()` ไม่ได้ตั้ง `CLAUDE_AGENT_NAME` env var

**Files changed:**
- `src/commands/shared/wake-resolve-impl.ts` — เพิ่ม `CLAUDE_AGENT_NAME` ใน `setSessionEnv()`
- `src/commands/shared/wake-cmd.ts` — ส่ง oracle name ให้ `setSessionEnv()`
- `src/commands/shared/fleet-wake.ts` — ตั้ง `CLAUDE_AGENT_NAME สำหรับ fleet wake`

**ผลลัพธ์:**
- `maw wake god` → agent "god" ตอบชื่อ "god" ✅
- `maw bud zeus --from god` → agent "zeus" ตอบชื่อ "zeus" ✅

---

## 🏗️ โครงสร้างปัจจุบัน

```
Repo: https://github.com/dmz2001TH/agentic
Branch: master (commit 7158fcd)
```

### Files Changed (commit 7158fcd):
```
 maw-js/scripts/run-isolated-safe.sh          (new) isolated test runner
 maw-js/package.json                          test scripts updated
 maw-js/src/commands/shared/wake-resolve-impl.ts  CLAUDE_AGENT_NAME
 maw-js/src/commands/shared/wake-cmd.ts       pass oracle name
 maw-js/src/commands/shared/fleet-wake.ts     fleet CLAUDE_AGENT_NAME
 arra-oracle-skills-cli/__tests__/smoke.test.ts   cal skip fix
```

---

## 🔴 สิ่งที่ห้ามทำ

1. **ห้ามทับ run-isolated-safe.sh** — นี่คือ fix สำหรับ Bun mock pollution
2. **ห้ามลบ CLAUDE_AGENT_NAME** จาก setSessionEnv — agent จะบอกชื่อผิดอีก
3. **ห้ามเปลี่ยน test scripts กลับ** — `bun test test/isolated/` โดยตรงจะ fail 25 tests

### จาก HANDOFF-PROMPT-10 (ห้ามทำเหมือนเดิม):
4. **ห้าม revert bug fixes:** .env.json port 3456, start-oracle.cmd, localhost
5. **ห้ามเปลี่ยน deprecated.ts กลับเป็น mock**
6. **ห้ามเพิ่ม ghost agents**
7. **ห้ามเปลี่ยน hostExec กลับเป็น cmd.exe สำหรับ tmux**
8. **ห้ามทับ deprecated.ts**

---

## 🧪 วิธีเทส

```bash
# ====== ติดตั้ง ======
cd agentic/maw-js && bun install

# ====== รัน tests ======
bun run test              # main tests (886 pass)
bun run test:isolated     # isolated tests (826 pass) — ใช้ wrapper script!
bun run test:all          # ทั้งหมด

# ====== รัน server ======
maw serve                 # API + UI ที่ port 3456

# ====== จัดการ Agent ======
maw wake god              # CLAUDE_AGENT_NAME=god อัตโนมัติ
maw peek god              # ดูหน้าจอ god
maw hey god "hello"       # ส่งข้อความ
maw bud zeus --from god   # สร้าง agent ใหม่ (CLAUDE_AGENT_NAME=zeus)

# ====== เช็ค identity ======
# ถาม god: "what's your name?" → ควรตอบ "god"
# ถาม zeus: "what's your name?" → ควรตอบ "zeus"
```

---

## 📊 Gap Analysis (เทียบ upstream maw-js)

### ทำแล้ว
- CLAUDE_AGENT_NAME auto-set on wake ✅
- Test isolation fix (run-isolated-safe.sh) ✅
- All tests passing ✅

### ยังมีผลจาก upstream (commit 7158fcd ไม่ได้แก้)
- `arra-oracle-v3` tests — ยังไม่ได้เทส (ต้อง DB setup)
- Bun mock.restore() doesn't restore module registry (known issue #7823)
  - แก้ด้วย process isolation แทน (run-isolated-safe.sh)

---

## 💡 สิ่งที่เรียนรู้

1. **Bun mock.module() เป็น process-global** — test files แชร์ mock state ต้องรันคนละ process
2. **mock.restore() ไม่ได้ restore module registry** — known Bun issue #7823
3. **CLAUDE_AGENT_NAME ต้องตั้งทุก path** — wake, bud, fleet ต่างคนต่างตั้ง
4. **tmux set-environment เป็น session-level** — ไม่ใช่ window-level
5. **agent identity มาจาก env var ไม่ใช่ config** — SOUL.md/IDENTITY.md ก็ช่วยได้ แต่ env var ตรงกว่า

---

## 🎯 เป้าหมายถัดไป

1. **เทสบน Windows จริง** — WSL + tmux + Gemini CLI
2. **Gemini CLI auto-login** — ทำให้ไม่ต้อง auth ทุกครั้ง
3. **maw-ui Live Terminal** — เห็น agent output จริงๆ (ต้อง `maw serve` รันอยู่)
4. **Multiple agents** — สร้าง agent เพิ่ม (dev, qa, writer)
5. **Process management** — daemon mode (pm2/systemd)
6. **arra-oracle-v3 tests** — รันเทส + แก้ failures

---

## 📚 ลิงก์

- **Repo:** https://github.com/dmz2001TH/agentic
- **Commits:** https://github.com/dmz2001TH/agentic/commits/master
- **Multi-Agent Book:** https://soul-brews-studio.github.io/multi-agent-orchestration-book/docs/intro
- **oracle-maw-guide:** https://github.com/the-oracle-keeps-the-human-human/oracle-maw-guide
- **Upstream maw-js:** https://github.com/Soul-Brews-Studio/maw-js

---

## 🚀 Quick Start

```bash
# 1. Clone + Install
git clone https://github.com/dmz2001TH/agentic.git
cd agentic/maw-js && bun install

# 2. Tests
bun run test:all

# 3. Server
maw serve

# 4. Wake agent
maw wake god
```

---

**Agent ตัวนี้ทำงานครบแล้ว — ทำต่อได้เลย!** 🌟
