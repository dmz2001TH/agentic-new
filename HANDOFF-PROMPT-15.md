# HANDOFF-PROMPT-15 — 🖥️ Maw Server Setup + Fleet UI Testing

## สิ่งที่ทำเสร็จแล้ว (อย่าแก้ซ้ำ)
- ✅ 1,890+ tests ผ่านหมด (upload test แก้แล้ว — routes ตรง API จริง)
- ✅ `test/upload.test.ts` แก้ routes จาก `/upload`, `/files` → `/api/upload`, `/api/uploads/:filename`
- ✅ ลบ `terminal.html` + `bridge.html` (ไม่ใช้แล้ว)
- ✅ `scripts/ensure-agents.sh` — auto-recreate tmux sessions ตอน server boot
- ✅ `src/core/server.ts` — hook `ensure-agents.sh` เข้า startup sequence
- ✅ `RoomGrid-Dfd-BVop.js` — WebGL fallback (try-catch) สำหรับ headless browser
- ✅ Bun ติดตั้งแล้ว (`~/.bun/bin/bun`)
- ✅ Config files สร้างแล้ว: `~/.config/maw/maw.config.json` + `~/.config/maw/fleet/mawjs.json`

## สิ่งที่ Agent ตัวถัดไปต้องทำ

### Priority 1: ติดตั้ง + รัน Server (ขั้นตอนละเอียด)

#### 1.1 ติดตั้ง Bun
```bash
# ถ้ายังไม่มี bun:
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun --version  # ควรได้ 1.3.12+
```

#### 1.2 Clone + Install
```bash
cd /root/.openclaw/workspace  # หรือ path ที่ต้องการ
git clone https://github.com/dmz2001TH/agentic.git
cd agentic/maw-js
bun install  # 362 packages
```

#### 1.3 รัน Tests
```bash
cd agentic/maw-js
bun run test:all  # 1,890+ tests — ต้อง 0 fail
```

#### 1.4 สร้าง Config Files (สำคัญมาก!)
```bash
# Config directory
mkdir -p ~/.config/maw/fleet

# maw.config.json — register agents
cat > ~/.config/maw/maw.config.json << 'EOF'
{
  "agents": {
    "mawjs": "local"
  }
}
EOF

# Fleet config — 1 entry ต่อ agent
cat > ~/.config/maw/fleet/mawjs.json << 'EOF'
{
  "name": "mawjs",
  "node": "local",
  "status": "active"
}
EOF
```

**⚠️ ถ้าไม่สร้าง config files → UI จะแสดง "0 agents" แม้ tmux session จะมีอยู่**

#### 1.5 รัน Server
```bash
cd agentic/maw-js
export MAW_UI_DIR=/root/.openclaw/workspace/agentic/maw-js/ui/office
bun src/cli.ts serve  # port 3456 (default)
```

**⚠️ ต้องตั้ง `MAW_UI_DIR` env var ไม่งั้น UI ไม่โหลด (แสดง door page)**

#### 1.6 ตรวจสอบ Server ทำงาน
```bash
# ตรวจสอบ port
ss -tlnp | grep 3456

# ถ้า bind ที่ 127.0.0.1:
curl -s http://127.0.0.1:3456/api/sessions

# ถ้า bind ที่ localhost (อาจ resolve เป็น 127.0.1.1):
curl -s http://127.0.1.1:3456/api/sessions

# ตรวจสอบ hostname ที่ server bind:
ss -tlnp | grep 3456
# output: LISTEN 0 512 127.0.0.1:3456 → ใช้ 127.0.0.1
# output: LISTEN 0 512 127.0.1.1:3456 → ใช้ 127.0.1.1
```

### Priority 2: สร้าง Agent (tmux session)

#### 2.1 God Agent
```bash
# สร้าง tmux session
tmux new-session -d -s "mawjs-oracle" -c /root/.openclaw/workspace/agentic
tmux rename-window -t mawjs-oracle:0 "god"

# ตั้ง env vars
tmux send-keys -t mawjs-oracle:0 "export CLAUDE_AGENT_NAME=god" Enter

# ตรวจสอบ
tmux list-sessions
tmux list-windows -t mawjs-oracle
```

#### 2.2 ตรวจสอบใน API
```bash
curl -s http://127.0.0.1:3456/api/sessions
# ควรได้: [{"name":"mawjs-oracle","windows":[{"index":0,"name":"god","active":true}]}]

curl -s http://127.0.0.1:3456/api/fleet
# ควรได้: {"fleet":[{"file":"mawjs.json","name":"mawjs","node":"local","status":"active"}]}
```

#### 2.3 Auto-Recovery (ensure-agents.sh)
```bash
# ทดสอบ: kill tmux แล้ว restart server
tmux kill-server
# → restart server
# → server boot จะรัน scripts/ensure-agents.sh อัตโนมัติ
# → tmux session mawjs-oracle จะถูกสร้างใหม่
```

### Priority 3: เทส UI ใน Browser

#### 3.1 Headless Browser (ไม่มี GPU)
- **ปัญหา**: Three.js ต้องใช้ WebGL → crash ใน headless mode
- **แก้แล้ว**: `RoomGrid-Dfd-BVop.js` มี try-catch fallback
- **ถ้ายัง crash**: ตรวจสอบว่า patch ใช้ได้:
  ```bash
  grep "WebGL not available" maw-js/ui/office/assets/RoomGrid-Dfd-BVop.js
  ```

#### 3.2 วิธีเทส
```bash
# เปิด browser ไปที่:
http://127.0.0.1:3456/#fleet     # Fleet view — แสดง agents
http://127.0.0.1:3456/api/sessions  # JSON API — ตรวจสอบข้อมูล
```

#### 3.3 สิ่งที่ควรมองเห็นใน UI
- Header: `ARRA OFFICE | LIVE | 1 agents | 1 rooms | 1 tabs`
- Navigation: Inbox, Mission, Dashboard, **Fleet**, Office, Overview, Terminal, Chat, Teams, Fed, 2D, Config
- Fleet view: MawJS room (cyan header, "local" badge, "1" count)
- Agent: "god" with idle status (gray circle)

### Priority 4: เพิ่ม Agents

```bash
# เพิ่ม agent ใหม่ — ต้องทำ 3 อย่าง:

# 1. สร้าง tmux session
tmux new-session -d -s "mawjs-zeus" -c /root/.openclaw/workspace/agentic
tmux rename-window -t mawjs-zeus:0 "zeus"
tmux send-keys -t mawjs-zeus:0 "export CLAUDE_AGENT_NAME=zeus" Enter

# 2. เพิ่มใน config
node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync(process.env.HOME+'/.config/maw/maw.config.json','utf8'));
cfg.agents.zeus = 'local';
fs.writeFileSync(process.env.HOME+'/.config/maw/maw.config.json', JSON.stringify(cfg,null,2));
"

# 3. สร้าง fleet config
cat > ~/.config/maw/fleet/zeus.json << 'EOF'
{
  "name": "zeus",
  "node": "local",
  "status": "active"
}
EOF

# 4. เพิ่มใน ensure-agents.sh (เพิ่มบรรทัด ensure_session "mawjs-zeus" "zeus")
```

## โครงสร้างไฟล์ที่เปลี่ยน

```
agentic:
├── scripts/
│   └── ensure-agents.sh          [ใหม่] auto-recreate tmux sessions
├── maw-js/
│   ├── src/core/server.ts         [แก้] hook ensure-agents into boot
│   ├── test/upload.test.ts        [แก้] routes ตรง API จริง
│   └── ui/office/
│       ├── assets/RoomGrid-Dfd-BVop.js [แก้] WebGL fallback
│       ├── bridge.html            [ลบ]
│       └── terminal.html          [ลบ]
```

## Config Files (อยู่นอก repo)

```
~/.config/maw/
├── maw.config.json    agents: { "mawjs": "local" }
└── fleet/
    └── mawjs.json     { name, node, status }
```

## ปัญหาที่อาจเจอ

| ปัญหา | สาเหตุ | วิธีแก้ |
|--------|--------|---------|
| UI แสดง "0 agents" | ไม่มี config files | สร้าง `~/.config/maw/maw.config.json` |
| UI ไม่โหลด (door page) | ไม่ได้ตั้ง `MAW_UI_DIR` | `export MAW_UI_DIR=...` |
| "Something crashed" | WebGL error | ตรวจสอบ RoomGrid patch |
| curl ไม่ต่อ | bind คนละ IP | ตรวจสอบ `ss -tlnp \| grep 3456` |
| agent หายหลัง restart | tmux session หาย | ตรวจสอบ `ensure-agents.sh` |
| port 3456 ถูกใช้ | server เก่ายังรัน | `kill $(pgrep -f "bun.*serve")` |

## สิ่งที่ห้ามทำ
- ห้ามลบ `scripts/ensure-agents.sh`
- ห้ามลบ config files ใน `~/.config/maw/`
- ห้ามแก้ `RoomGrid-Dfd-BVop.js` กลับ (ต้องมี WebGL fallback)
- ห้ามลบ patch ใน `src/core/server.ts` (ensure-agents hook)
- ห้ามแก้ `test/upload.test.ts` กลับ (routes ต้องตรง API จริง)

## เริ่มทำงานได้เลย!
1. `cd agentic/maw-js && bun install`
2. `bun run test:all` — ยืนยัน 0 fail
3. สร้าง config files (ดู 1.4)
4. `export MAW_UI_DIR=... && bun src/cli.ts serve`
5. สร้าง tmux session (ดู 2.1)
6. เปิด browser → `http://127.0.0.1:3456/#fleet`
7. เห็น "1 agents · 1 rooms · 1 tabs" ✅
```
