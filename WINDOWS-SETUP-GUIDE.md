# WINDOWS-SETUP-GUIDE.md — คู่มือติดตั้ง maw-js บน Windows (WSL)

## ⚠️ สำคัญมาก: maw-js ต้องรันบน WSL เท่านั้น!

**ห้ามรันใน PowerShell หรือ Git Bash** เพราะ tmux ใช้ไม่ได้ใน environment พวกนั้น
ทุกอย่างต้องอยู่ใน **WSL (Windows Subsystem for Linux)** environment เดียวกัน

---

## ⚠️ ถ้า shell scripts พังเพราะ `\r` (Windows Line Endings)

ถ้าเห็น error แบบนี้:
```
$'\r': command not found
set: pipefail\r: invalid option name
```

แปลว่า Git แปลง line endings เป็น CRLF ตอน checkout แก้ด้วย:

```bash
# แก้ทุก .sh ในโปรเจค
find /mnt/c/Agentic -name "*.sh" -exec sed -i 's/\r$//' {} +

# หรือถ้ามี dos2unix:
sudo apt install dos2unix
find /mnt/c/Agentic -name "*.sh" -exec dos2unix {} +
```

**หมายเหตุ**: repo มี `.gitattributes` บังคับ LF แล้ว แต่ถ้า Git config มี `core.autocrlf=true` อยู่ก่อน อาจต้อง clone ใหม่หรือตั้งค่า:
```bash
git config --global core.autocrlf input
```

---

## เงื่อนไขก่อนเริ่ม

- Windows 10/11 ที่มี WSL ติดตั้งแล้ว (`wsl --version` ต้องได้)
- ถ้ายังไม่มี WSL: เปิด PowerShell แล้วรัน `wsl --install` แล้ว restart เครื่อง

---

## ขั้นตอนทั้งหมด (ทำทีเดียวจบ)

### Step 0: เปิด WSL

```bash
wsl
```

**ทุกคำสั่งต่อจากนี้รันใน WSL เท่านั้น ห้ามรันใน PowerShell**

### Step 1: ติดตั้ง Dependencies

```bash
# อัพเดท package
sudo apt update && sudo apt install -y tmux curl unzip

# ติดตั้ง Bun
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ยืนยันว่าติดตั้งสำเร็จ
bun --version    # ควรได้ 1.3.12+
tmux -V          # ควรได้ 3.x
```

### Step 2: Clone + Install

```bash
cd ~
git clone https://github.com/dmz2001TH/agentic.git
cd agentic/maw-js
bun install      # รอสักครู่ ประมาณ 362 packages
```

### Step 3: สร้าง Config Files

```bash
mkdir -p ~/.config/maw/fleet

# maw.config.json — register agents
cat > ~/.config/maw/maw.config.json << 'EOF'
{
  "agents": {
    "mawjs": "local"
  }
}
EOF

# mawjs.json — fleet config
cat > ~/.config/maw/fleet/mawjs.json << 'EOF'
{
  "name": "mawjs",
  "node": "local",
  "status": "active"
}
EOF

# ยืนยัน
cat ~/.config/maw/maw.config.json
cat ~/.config/maw/fleet/mawjs.json
```

**⚠️ ถ้าข้ามขั้นตอนนี้ → UI จะแสดง "0 agents" แม้ tmux session จะมีอยู่**

### Step 4: สร้าง Tmux Session (Agent)

```bash
cd ~/agentic

# สร้าง tmux session
tmux new-session -d -s "mawjs-oracle" -c ~/agentic
tmux rename-window -t mawjs-oracle:0 "god"
tmux send-keys -t mawjs-oracle:0 "export CLAUDE_AGENT_NAME=god" Enter

# ยืนยัน
tmux list-sessions
# ควรเห็น: mawjs-oracle: 1 windows
```

### Step 5: รัน Server

```bash
cd ~/agentic/maw-js
export MAW_UI_DIR=$PWD/ui/office
bun src/cli.ts serve
```

จะเห็น:
```
maw  serve → http://localhost:3456 (ws://localhost:3456/ws) [0.0.0.0]
```

**อย่าปิด terminal นี้ — server กำลังรันอยู่**

### Step 6: ตรวจสอบ (เปิด WSL terminal ใหม่)

```bash
# ตรวจสอบ API
curl -s http://127.0.0.1:3456/api/sessions
# ควรได้: [{"name":"mawjs-oracle","windows":[{"index":0,"name":"god","active":true}]}]

# ตรวจสอบ Fleet
curl -s http://127.0.0.1:3456/api/fleet
# ควรได้: {"fleet":[{"file":"mawjs.json","name":"mawjs","node":"local","status":"active"}]}
```

### Step 7: เปิด Browser (บน Windows)

เปิด browser บน Windows แล้วเข้า:
```
http://127.0.0.1:3456/#fleet
```

ควรเห็น: **1 agents · 1 rooms · 1 tabs** ✅

---

## Script ลัด (ทำทีเดียวจบ)

ถ้าขี้เกียจทำทีละขั้น รัน script นี้ทีเดียวใน WSL:

```bash
#!/bin/bash
set -e

echo "🚀 Maw-JS WSL Setup"
echo "===================="

# 1. Dependencies
sudo apt update && sudo apt install -y tmux curl unzip
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# 2. Clone + Install
cd ~
[ -d agentic ] || git clone https://github.com/dmz2001TH/agentic.git
cd agentic/maw-js
bun install

# 3. Config
mkdir -p ~/.config/maw/fleet
echo '{"agents":{"mawjs":"local"}}' > ~/.config/maw/maw.config.json
echo '{"name":"mawjs","node":"local","status":"active"}' > ~/.config/maw/fleet/mawjs.json

# 4. Tmux
tmux kill-session -t mawjs-oracle 2>/dev/null || true
tmux new-session -d -s "mawjs-oracle" -c ~/agentic
tmux rename-window -t mawjs-oracle:0 "god"

# 5. Start server
export MAW_UI_DIR=$PWD/ui/office
echo ""
echo "✅ Setup complete! Starting server..."
echo "Open browser: http://127.0.0.1:3456/#fleet"
echo ""
bun src/cli.ts serve
```

---

## ปัญหาที่อาจเจอ + วิธีแก้

| ปัญหา | สาเหตุ | วิธีแก้ |
|--------|--------|---------|
| `bun: command not found` | ไม่ได้ติดตั้ง Bun ใน WSL | รัน `curl -fsSL https://bun.sh/install \| bash` ใน WSL |
| `tmux: command not found` | ไม่ได้ติดตั้ง tmux | รัน `sudo apt install tmux` ใน WSL |
| UI แสดง "0 agents" | ไม่มี config files | สร้าง `~/.config/maw/maw.config.json` |
| UI ไม่โหลด (door page) | ไม่ได้ตั้ง `MAW_UI_DIR` | `export MAW_UI_DIR=$PWD/ui/office` |
| "Something crashed" | WebGL error | ตรวจสอบว่า patch ใช้ได้แล้ว (อยู่ใน repo) |
| `curl ได้ []` | ไม่มี tmux session | รัน Step 4 สร้าง session |
| `EADDRINUSE` | port 3456 ถูกใช้ | `kill $(pgrep -f "bun.*serve")` แล้วรันใหม่ |
| `ensure-agents.sh not found` | path ผิดบน Windows | ต้องรันใน WSL ไม่ใช่ PowerShell |

---

## ⛔ สิ่งที่ห้ามทำ

1. **ห้ามรัน server ใน PowerShell** — tmux ใช้ไม่ได้, agent ไม่แสดง
2. **ห้ามรัน server ใน Git Bash** — tmux คนละ environment กับ server
3. **ห้ามข้าม Step 3 (Config Files)** — UI จะแสดง 0 agents
4. **ห้ามข้าม Step 4 (Tmux Session)** — API จะได้ []
5. **ห้ามรัน tmux ใน Git Bash แล้วรัน server ใน PowerShell** — มองไม่เห็นกัน

## ✅ กฎทอง

> **ทุกอย่างต้องอยู่ใน WSL เดียวกัน: tmux + bun + server**
> อย่าแยก environment — แยกเมื่อไหร่ พังเมื่อนั้น
