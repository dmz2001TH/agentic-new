# HANDOFF-PROMPT-15 — 🖥️ Maw Server Setup + Fleet UI Testing

> **Last updated**: 2026-04-20 03:30 GMT+8
> **Sessions**: 2 (Session 1: test + server setup, Session 2: WebGL fix + WebSocket fix + Windows debugging)
> **Tests**: 1,894 pass / 12 skip / 0 fail

---

## สิ่งที่ทำเสร็จแล้ว (อย่าแก้ซ้ำ)

### Session 1 — Test + Server Setup + Auto-Recovery
- ✅ 1,894 tests ผ่านหมด (upload test แก้แล้ว — routes ตรง API จริง)
- ✅ `test/upload.test.ts` แก้ routes จาก `/upload`, `/files` → `/api/upload`, `/api/uploads/:filename`
- ✅ ลบ `terminal.html` + `bridge.html` (ไม่ใช้แล้ว)
- ✅ `scripts/ensure-agents.sh` — auto-recreate tmux sessions ตอน server boot
- ✅ `src/core/server.ts` — hook `ensure-agents.sh` เข้า startup sequence
- ✅ `RoomGrid-Dfd-BVop.js` — WebGL fallback (try-catch) สำหรับ headless browser
- ✅ Bun ติดตั้งแล้ว (`~/.bun/bin/bun`)
- ✅ Config files สร้างแล้ว: `~/.config/maw/maw.config.json` + `~/.config/maw/fleet/mawjs.json`

### Session 2 — WebGL Crash Fix + WebSocket Fix + Windows Support
- ✅ `federation-CR5WtdJB.js` — WebGL fallback (try-catch รอบ WebGLRenderer)
- ✅ `src/core/server.ts` — hostname `localhost` → `0.0.0.0` (แก้ WebSocket ไม่ต่อ)
- ✅ `scripts/setup.sh` — first-run auto setup script
- ✅ `WINDOWS-SETUP-GUIDE.md` — คู่มือละเอียดสำหรับ Windows/WSL
- ✅ `.gitattributes` — บังคับ LF line endings ป้องกัน `\r\n` error บน Windows
- ✅ `HANDOFF-PROMPT-15.md` — อัพเดท session 2 findings

### UI ที่ทำงานแล้ว
- Header: `ARRA OFFICE | LIVE | 1 agents | 1 rooms | 1 tabs`
- Fleet view: MawJS room (cyan header, "local" badge, "1" count)
- Agent: "god" with idle status (gray circle)
- WebSocket: connected, live data feed ทำงาน
- Navigation: Inbox, Mission, Dashboard, Fleet, Office, Overview, Terminal, Chat, Teams, Fed, 2D, Config

---

## ปัญหาที่เจอและแก้ไขแล้ว (ทั้งหมด)

### Bug 1: RoomGrid — WebGL crash (Session 1)
- **อาการ**: UI แสดง "Something crashed" ตอนเปิดหน้าแรก
- **สาเหตุ**: Three.js WebGLRenderer ไม่สามารถสร้าง WebGL context ได้ใน headless/no-GPU environment
- **ที่อยู่**: `maw-js/ui/office/assets/RoomGrid-Dfd-BVop.js`
- **วิธีแก้**: เพิ่ม try-catch รอบ `new WebGLRenderer({antialias:false, alpha:false})`
  ```js
  let t;try{t=new U({antialias:!1,alpha:!1})}catch(e){console.warn("WebGL not available, skipping 3D background");return}
  ```
- **สถานะ**: ✅ แก้แล้ว

### Bug 2: Federation view — WebGL crash (Session 2)
- **อาการ**: UI แสดง "Something crashed" — แต่ error ไม่ได้มาจาก RoomGrid (RoomGrid มี fallback แล้ว)
- **สาเหตุ**: `federation-CR5WtdJB.js` สร้าง `new WebGLRenderer({antialias:true})` แบบ **ไม่มี try-catch**
- **ที่อยู่**: `maw-js/ui/office/assets/federation-CR5WtdJB.js`
- **วิธีแก้**: เพิ่ม try-catch เหมือน RoomGrid
  ```js
  // BEFORE (crash):
  const f=new yt({antialias:!0});f.setSize(r,o)...

  // AFTER (fallback):
  let f;try{f=new yt({antialias:!0})}catch(e){console.warn("WebGL not available, skipping federation 3D view");return}f.setSize(r,o)...
  ```
- **สถานะ**: ✅ แก้แล้ว

### Bug 3: WebSocket ไม่ต่อ — hostname mismatch (Session 2)
- **อาการ**: UI แสดง "0 agents" ทั้งที่ API (`/api/sessions`) คืนข้อมูลถูกต้อง
- **สาเหตุ**: Server bind ที่ `localhost` → resolve เป็น `127.0.1.1` แต่ browser เชื่อมต่อ `127.0.0.1`
  - curl ทดสอบ WebSocket ได้ (101 Switching Protocols)
  - Browser ไม่ได้ → `ERR_CONNECTION_REFUSED`
- **ที่อยู่**: `maw-js/src/core/server.ts` บรรทัด 209
- **วิธีแก้**: เปลี่ยน hostname จาก conditional เป็น `0.0.0.0`
  ```ts
  // BEFORE:
  const hostname = hasPeers ? "0.0.0.0" : "localhost";

  // AFTER:
  const hostname = "0.0.0.0";
  ```
- **สถานะ**: ✅ แก้แล้ว

### Bug 4: Shell script `\r\n` error บน Windows/WSL
- **อาการ**: `ensure-agents.sh` พังด้วย error `$'\r': command not found` และ `set: pipefail\r: invalid option name`
- **สาเหตุ**: Git บน Windows แปลง LF → CRLF ตอน checkout (`core.autocrlf=true`)
- **ที่อยู่**: ทุกไฟล์ `.sh` ใน repo
- **วิธีแก้**: เพิ่ม `.gitattributes` บังคับ LF
  ```
  *.sh text eol=lf
  *.ts text eol=lf
  *.js text eol=lf
  ```
- **วิธีแก้ชั่วคราว** (ถ้า clone มาก่อนที่จะแก้ `.gitattributes`):
  ```bash
  find . -name "*.sh" -exec sed -i 's/\r$//' {} +
  ```
- **สถานะ**: ✅ แก้แล้ว (เพิ่ม `.gitattributes`)

### Bug 5: Server รันไม่ได้บน Windows (EADDRINUSE + tmux context)
- **อาการ**: Server รันใน PowerShell/Git Bash ไม่ได้, มองไม่เห็น tmux sessions
- **สาเหตุ**:
  - PowerShell ไม่มี tmux
  - Git Bash มี tmux แต่อยู่คนละ environment กับ PowerShell server
  - `wsl bash -c "command &"` — WSL instance ปิดตัวทันที → background process ตาย
- **วิธีแก้**: ต้องรันทุกอย่างใน **WSL terminal เดียวกัน**
- **สถานะ**: ⚠️ ต้องทำตาม `WINDOWS-SETUP-GUIDE.md`

### Bug 6: Browser cache — แสดง error เก่า
- **อาการ**: Console error จาก page load ก่อนหน้า (ตอน server ยังไม่รัน) ยังค้างอยู่
- **สาเหตุ**: Browser ไม่ clear console ระหว่าง page reload
- **วิธีแก้**: Hard refresh (`Ctrl+Shift+R`) หรือเปิด tab ใหม่
- **สถานะ**: ℹ️ ไม่ใช่ bug ของ code

---

## สิ่งที่ Agent ตัวถัดไปต้องทำ

### Priority 1: รัน Server บน Linux (ไม่ใช่ Windows)

```bash
cd agentic/maw-js
bun install
bun run test:all  # ยืนยัน 0 fail

# สร้าง config
mkdir -p ~/.config/maw/fleet
echo '{"agents":{"mawjs":"local"}}' > ~/.config/maw/maw.config.json
echo '{"name":"mawjs","node":"local","status":"active"}' > ~/.config/maw/fleet/mawjs.json

# สร้าง tmux session
tmux new-session -d -s "mawjs-oracle" -c $(pwd)/..
tmux rename-window -t mawjs-oracle:0 "god"

# รัน server
export MAW_UI_DIR=$PWD/ui/office
bun src/cli.ts serve

# ตรวจสอบ
curl -s http://127.0.0.1:3456/api/sessions
# ควรได้: [{"name":"mawjs-oracle","windows":[{"index":0,"name":"god","active":true}]}]
```

### Priority 2: ถ้าต้องรันบน Windows → ใช้ WSL

อ่าน `WINDOWS-SETUP-GUIDE.md` แล้วทำตาม Step 0-7

**กฎสำคัญ**:
- ทุกอย่างต้องอยู่ใน **WSL terminal เดียวกัน** (tmux + bun + server)
- ห้ามรัน server ใน PowerShell หรือ Git Bash
- ห้ามสร้าง tmux ใน Git Bash แล้วรัน server ใน PowerShell (มองไม่เห็นกัน)
- Server เป็น long-running process — ต้องรันค้างใน terminal จริง, `wsl bash -c "command &"` ทำไม่ได้

### Priority 3: เพิ่ม Agents ใหม่

```bash
# 1. สร้าง tmux session
tmux new-session -d -s "mawjs-zeus" -c /path/to/agentic
tmux rename-window -t mawjs-zeus:0 "zeus"

# 2. เพิ่มใน config
cat > ~/.config/maw/maw.config.json << 'EOF'
{"agents":{"mawjs":"local","zeus":"local"}}
EOF

# 3. สร้าง fleet config
cat > ~/.config/maw/fleet/zeus.json << 'EOF'
{"name":"zeus","node":"local","status":"active"}
EOF

# 4. เพิ่มใน ensure-agents.sh (บรรทัด ensure_session)
```

---

## โครงสร้างไฟล์ที่เปลี่ยน

```
agentic:
├── .gitattributes                          [ใหม่] บังคับ LF line endings
├── scripts/
│   ├── ensure-agents.sh                    [จาก session 1] auto-recreate tmux
│   └── setup.sh                            [ใหม่] first-run auto setup
├── WINDOWS-SETUP-GUIDE.md                  [ใหม่] คู่มือ Windows/WSL
├── HANDOFF-PROMPT-15.md                    [อัพเดท] ไฟล์นี้
└── maw-js/
    ├── src/core/server.ts                  [แก้] ensure-agents hook + hostname="0.0.0.0"
    ├── test/upload.test.ts                 [แก้] routes ตรง API จริง
    └── ui/office/
        ├── assets/
        │   ├── RoomGrid-Dfd-BVop.js        [แก้] WebGL fallback
        │   └── federation-CR5WtdJB.js      [แก้] WebGL fallback
        ├── bridge.html                     [ลบ]
        └── terminal.html                   [ลบ]
```

## Config Files (อยู่นอก repo)

```
~/.config/maw/
├── maw.config.json    agents: { "mawjs": "local" }
└── fleet/
    └── mawjs.json     { name, node, status }
```

---

## ตารางปัญหาทั้งหมด + วิธีแก้

| # | ปัญหา | สาเหตุ | วิธีแก้ | แก้แล้ว? |
|---|--------|--------|---------|----------|
| 1 | "Something crashed" (RoomGrid) | WebGLRenderer ไม่มี fallback | Patch `RoomGrid-Dfd-BVop.js` | ✅ |
| 2 | "Something crashed" (Federation) | WebGLRenderer ไม่มี fallback | Patch `federation-CR5WtdJB.js` | ✅ |
| 3 | UI แสดง "0 agents" | WebSocket ไม่ต่อ (hostname mismatch) | `server.ts`: hostname → `0.0.0.0` | ✅ |
| 4 | `ensure-agents.sh` พังบน WSL | `\r\n` line endings | `.gitattributes` + `sed -i` | ✅ |
| 5 | PowerShell รัน server ไม่ได้ | ไม่มี tmux + env แยก | ใช้ WSL (WINDOWS-SETUP-GUIDE.md) | ⚠️ |
| 6 | `wsl bash -c "serve &"` ไม่ทำงาน | WSL instance ปิด → process ตาย | รันใน WSL terminal จริง | ℹ️ |
| 7 | `EADDRINUSE` | server เก่ายังรันอยู่ | `kill $(lsof -t -i:3456)` | ℹ️ |
| 8 | Console error เก่าค้าง | Browser cache | Hard refresh / tab ใหม่ | ℹ️ |
| 9 | curl ใน PowerShell = Invoke-WebRequest | PowerShell alias | ใช้ `curl.exe` หรือ `wsl curl` | ℹ️ |
| 10 | Browser แสดง "0 agents" | WebSocket hook retry maxed out | Clear localStorage + refresh | ℹ️ |

---

## สิ่งที่ห้ามทำ
- ห้ามลบ `scripts/ensure-agents.sh`
- ห้ามลบ `scripts/setup.sh`
- ห้ามลบ config files ใน `~/.config/maw/`
- ห้ามแก้ `RoomGrid-Dfd-BVop.js` กลับ (ต้องมี WebGL fallback)
- ห้ามแก้ `federation-CR5WtdJB.js` กลับ (ต้องมี WebGL fallback)
- ห้ามลบ patch ใน `src/core/server.ts` (ensure-agents hook + hostname fix)
- ห้ามแก้ `test/upload.test.ts` กลับ (routes ต้องตรง API จริง)
- ห้ามลบ `.gitattributes` (ป้องกัน `\r\n` error บน Windows)

## เริ่มทำงานได้เลย!

### บน Linux:
```bash
cd agentic && bash scripts/setup.sh
cd maw-js && export MAW_UI_DIR=$PWD/ui/office && bun src/cli.ts serve
```

### บน Windows:
อ่าน `WINDOWS-SETUP-GUIDE.md` → ทำ Step 0-7 ทั้งหมดใน **WSL terminal เดียวกัน**

### ตรวจสอบผลลัพธ์:
```bash
curl -s http://127.0.0.1:3456/api/sessions
# ควรได้: [{"name":"mawjs-oracle","windows":[{"index":0,"name":"god","active":true}]}]
```

เปิด browser → `http://127.0.0.1:3456/#fleet`
→ เห็น **1 agents · 1 rooms · 1 tabs** ✅
