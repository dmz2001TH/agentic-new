# 🧠 Brain Bridge — เชื่อม Google Drive (G:\) กับ Agent

## ปัญหา
- Agent (GOD/Gemini) จำอะไรไม่ได้ตอนเริ่มแชทใหม่
- ความจำถาวรอยู่ใน G:\ (Google Drive 5TB) แต่ agent เข้าถึงไม่ได้
- Google Drive Desktop ใช้ virtual filesystem — ไฟล์บางอันยังไม่ได้ download

## Solution Architecture

```
G:\My Drive\Oracle-System-Brain\ψ\   ← ความจำถาวร (Google Drive)
         ↕ sync (brain-bridge.sh)
C:\Agentic\ψ\                        ← ความจำใช้งาน (Local SSD)
         ↕ โหลดตอน start
Gemini CLI (--prompt injection)      ← Agent ที่จำได้
```

## ขั้นตอน

### 1. ตั้งค่า Google Drive Desktop
- เปิด Google Drive Desktop
- คลิกขวาที่โฟลเดอร์ `Oracle-System-Brain` → **"Make available offline"**
- สำคัญมาก! ถ้าไม่ทำ WSL จะอ่านไฟล์ไม่ได้

### 2. ตรวจสอบ G:\ ใน WSL
```bash
# รันใน WSL
ls /mnt/g/My\ Drive/Oracle-System-Brain/ψ/
```
ถ้าไดร์ฟไม่ขึ้น ลอง:
```bash
# หาว่า G:\ mount อยู่ที่ไหน
mount | grep -i "g:"
# หรือ
df -h | grep -i google
```

### 3. รัน Brain Bridge
```bash
# รันใน WSL หรือ Git Bash
bash brain-bridge.sh
```

### 4. เริ่ม Agent ด้วย Memory
```bash
bash start-god-with-memory.sh
```

## ไฟล์ที่มี
- `brain-bridge.sh` — sync ความจำระหว่าง G:\ ↔ C:\Agentic
- `start-god-with-memory.sh` — เริ่ม Gemini พร้อม inject memory context
- `verify-brain.sh` — ตรวจสอบว่าความจำพร้อมใช้มั้ย
