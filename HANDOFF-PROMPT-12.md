# 🔮 HANDOFF PROMPT — Agent ตัวถัดไป

**สำหรับ:** AI Agent ตัวถัดไปที่จะ接手โปรเจ็คนี้
**สร้างเมื่อ:** 2026-04-19 (commit fde05cc)
**สถานะปัจจุบัน:** ระบบรันได้ + tests ผ่านหมด (1,890+ tests) + DNS timeout fix

---

## 📌 สิ่งที่ Agent ตัวนี้ทำไปแล้ว (Commit fde05cc)

### 1. แก้ Peers Tests Timeout (9 failures → 0)

**ปัญหา:** `peers.test.ts` ใช้ `.local` URLs (เช่น `http://white.local:3456`) — DNS lookup สำหรับ `.local` domains ค้างตลอดไปบนเครื่องที่ไม่มี mDNS/Avahi ทำให้ test timeout 5s

**Root cause:** `prefetchDnsCheck()` ใน `probe.ts` เรียก `dns/promises lookup()` โดยไม่มี timeout — `.local` lookup บน Linux ไม่มี Avahi จะค้าง 30+ วินาที

**Fix:** เพิ่ม 2s timeout รอบ DNS lookup ด้วย `Promise.race()`:
```typescript
const lookupPromise = lookup(hostname);
const timeoutPromise = new Promise<never>((_, reject) =>
  setTimeout(() => reject(Object.assign(new Error(...), { code: "ETIMEDOUT" })), 2000)
);
await Promise.race([lookupPromise, timeoutPromise]);
```

**Files changed:**
- `maw-js/src/commands/plugins/peers/probe.ts` — DNS lookup timeout

**ผลลัพธ์:** peers.test.ts 23/23 pass (เดิม 9 fail)

### 2. แก้ Oracle Tests (5 failures → 0)

**ปัญหา:** `oracle.test.ts` ใช้ `mock.module("./impl", ...)` — Bun's `mock.module()` เป็น process-global และไม่ทำงานเมื่อ test รันรวมกับ plugin tests ตัวอื่น (module already cached)

**Fix:** ย้าย oracle test ไปรันใน isolated test runner (separate process):
- `scripts/run-isolated-safe.sh` — เพิ่ม `oracle.test.ts` ใน `CONFLICT_FILES`
- `package.json` — เพิ่ม `--path-ignore-patterns '**/oracle/oracle.test.ts'` ใน `test:plugin`

**Files changed:**
- `maw-js/scripts/run-isolated-safe.sh` — เพิ่ม oracle test
- `maw-js/package.json` — exclude oracle จาก test:plugin

**ผลลัพธ์:** oracle 5/5 pass ใน isolation

### 3. ผลลัพธ์รวม

| Sub-project | ก่อน (handoff-11) | หลัง (commit fde05cc) |
|---|---|---|
| maw-js (main) | 880 pass, 0 fail | **880 pass, 0 fail** ✅ |
| maw-js (isolated) | 826 pass, 0 fail | **831 pass, 0 fail** ✅ (+5 oracle) |
| maw-js (plugin) | 170 pass, 14 fail | **179 pass, 0 fail** ✅ |
| arra-oracle-skills-cli | 132 pass, 0 fail | **132 pass, 0 fail** ✅ (ต้อง run compile ก่อน) |
| pulse-cli | 41 pass, 0 fail | **41 pass, 0 fail** ✅ |

**รวม: ~1,890 tests ผ่านทั้งหมด**

---

## 🏗️ โครงสร้างปัจจุบัน

```
Repo: https://github.com/dmz2001TH/agentic
Branch: master (commit fde05cc)
```

### Files Changed (commit fde05cc):
```
 maw-js/src/commands/plugins/peers/probe.ts   DNS lookup timeout
 maw-js/scripts/run-isolated-safe.sh          oracle test isolation
 maw-js/package.json                          exclude oracle from test:plugin
```

---

## 🔴 สิ่งที่ห้ามทำ

1. **ห้ามลบ DNS timeout ใน prefetchDnsCheck()** — .local lookup จะค้างอีก
2. **ห้ามย้าย oracle test กลับไป test:plugin** — mock.module ไม่ทำงานรวม process
3. **ห้ามทับ run-isolated-safe.sh** — ลบ CONFLICT_FILES ตัวใดตัวหนึ่งจะทำให้ test fail

### จาก HANDOFF-PROMPT-11 (ห้ามทำเหมือนเดิม):
4. **ห้ามทับ run-isolated-safe.sh** — Bun mock pollution fix
5. **ห้ามลบ CLAUDE_AGENT_NAME** จาก setSessionEnv
6. **ห้ามเปลี่ยน test scripts กลับ**
7. **ห้าม revert bug fixes:** .env.json port 3456, start-oracle.cmd, localhost
8. **ห้ามเปลี่ยน deprecated.ts กลับเป็น mock**
9. **ห้ามเพิ่ม ghost agents**
10. **ห้ามเปลี่ยน hostExec กลับเป็น cmd.exe สำหรับ tmux**
11. **ห้ามทับ deprecated.ts**

---

## 🧪 วิธีเทส

```bash
# ====== ติดตั้ง ======
cd agentic/maw-js && bun install

# ====== รัน tests ======
bun run test              # main tests (880 pass)
bun run test:isolated     # isolated tests (831 pass)
bun run test:plugin       # plugin tests (179 pass)
bun run test:all          # ทั้งหมด

# ====== arra-oracle-skills-cli ======
cd agentic/arra-oracle-skills-cli && bun install
bun run compile           # ต้อง compile ก่อนเทส!
bun test                  # 132 pass

# ====== pulse-cli ======
cd agentic/pulse-cli && bun install
bun test                  # 41 pass

# ====== รัน server ======
maw serve                 # API + UI ที่ port 3456

# ====== จัดการ Agent ======
maw wake god              # CLAUDE_AGENT_NAME=god อัตโนมัติ
maw peek god              # ดูหน้าจอ god
maw hey god "hello"       # ส่งข้อความ
```

---

## 💡 สิ่งที่เรียนรู้

1. **Bun mock.module() ยังไม่ reliable** — แม้จะ fix process isolation แล้ว บาง test ยังต้องรันแยก process
2. **DNS lookup สำหรับ .local ไม่มี timeout** — บน Linux ไม่มี Avahi จะค้างตลอด ต้องเพิ่ม timeout เอง
3. **arra-oracle-skills-cli ต้อง compile ก่อนเทส** — tests คาดหวัง compiled stubs ที่ `src/commands/*.md`
4. **peers-probe tests ไม่ timeout** — เพราะใช้ IP address (`127.0.0.1`) ไม่ใช่ `.local`
5. **`--path-ignore-patterns` ใน bun test** — ใช้ exclude files จากรวม run ได้

---

## 🎯 เป้าหมายถัดไป (จาก HANDOFF-PROMPT-11 ที่ยังไม่ได้ทำ)

1. **เทสบน Windows จริง** — WSL + tmux + Gemini CLI
2. **Gemini CLI auto-login** — ทำให้ไม่ต้อง auth ทุกครั้ง
3. **maw-ui Live Terminal** — เห็น agent output จริงๆ (ต้อง `maw serve` รันอยู่)
4. **Multiple agents** — สร้าง agent เพิ่ม (dev, qa, writer)
5. **Process management** — daemon mode (pm2/systemd)
6. **arra-oracle-v3 tests** — รันเทส + แก้ failures (ต้อง DB setup)

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
