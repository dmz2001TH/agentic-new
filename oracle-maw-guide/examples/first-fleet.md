# ตัวอย่าง: สร้าง Fleet แรก

> จาก Oracle ตัวเดียว → ทีม 3 ตัว ใน 15 นาที

## ขั้นที่ 1: สร้าง Oracle 3 ตัว

สมมติคุณมี Oracle ตัวแรกชื่อ `jarvis` (จาก oracle-step-by-step)
ตอนนี้อยากเพิ่ม:
- `writer` — ช่วยเขียน
- `researcher` — ช่วย research

```bash
# สร้าง repo ให้แต่ละตัว
mkdir -p ~/oracles/writer-oracle && cd ~/oracles/writer-oracle
git init
claude   # เปิด Claude Code → /awaken

mkdir -p ~/oracles/researcher-oracle && cd ~/oracles/researcher-oracle
git init
claude   # เปิด Claude Code → /awaken
```

## ขั้นที่ 2: สร้าง Fleet Config

```bash
# Initialize fleet จาก repos ที่มี
maw fleet init

# ดูผลลัพธ์
maw fleet ls
```

ถ้า fleet init ไม่เจอ → สร้าง manual:

```bash
mkdir -p ~/.maw/fleet

# jarvis
cat > ~/.maw/fleet/jarvis.json << 'EOF'
{
  "oracle": "jarvis",
  "window": 1,
  "repo": "your-name/jarvis-oracle",
  "path": "/home/you/oracles/jarvis-oracle",
  "tmux": "01-jarvis:0",
  "dormant": false
}
EOF

# writer
cat > ~/.maw/fleet/writer.json << 'EOF'
{
  "oracle": "writer",
  "window": 2,
  "repo": "your-name/writer-oracle",
  "path": "/home/you/oracles/writer-oracle",
  "tmux": "02-writer:0",
  "dormant": false
}
EOF

# researcher
cat > ~/.maw/fleet/researcher.json << 'EOF'
{
  "oracle": "researcher",
  "window": 3,
  "repo": "your-name/researcher-oracle",
  "path": "/home/you/oracles/researcher-oracle",
  "tmux": "03-researcher:0",
  "dormant": false
}
EOF
```

## ขั้นที่ 3: ปลุกทั้งทีม

```bash
# ปลุกทีละตัว
maw wake jarvis
maw wake writer
maw wake researcher

# หรือปลุกทั้งทีม
maw wake all
```

## ขั้นที่ 4: ทดสอบ Messaging

```bash
# ส่งข้อความหา writer
maw hey writer "สวัสดี — ตอบกลับว่าได้รับข้อความ"

# ดูว่า writer ตอบไหม
maw peek writer

# ส่งงานจริง
maw hey researcher "research เรื่อง Oracle multi-agent patterns"
maw hey writer "เขียนบทความเรื่อง AI agents สำหรับ blog"
```

## ขั้นที่ 5: ตั้ง Loop แรก

```bash
maw loop add '{
  "id": "daily-standup",
  "oracle": "jarvis",
  "tmux": "01-jarvis:0",
  "schedule": "0 9 * * *",
  "prompt": "Morning standup — สรุปสถานะ ดูว่ามี task อะไรค้าง",
  "requireIdle": true,
  "enabled": true,
  "description": "Daily morning standup"
}'
```

## เสร็จ!

ตอนนี้คุณมี:
- Oracle 3 ตัว ทำงานเป็นทีม
- Fleet config จัดการ wake/sleep
- Messaging ส่งข้อความข้ามตัว
- Loop ทำงานทุกเช้า

**ขั้นต่อไป**: เพิ่ม Oracle ตามความต้องการ — QA, Admin, Designer — ทีละตัว
