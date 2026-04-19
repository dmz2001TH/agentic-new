# 🚀 วิธีรัน Oracle Agent System (WSL)

บันทึกเมื่อ: 2026-04-20

## 1. รัน Maw Server (Dashboard)
เปิด WSL Terminal:
```bash
cd /mnt/c/Agentic/maw-js
bun src/cli.ts serve
```
*ใช้สำหรับเข้าใช้งานผ่าน http://localhost:3456*

## 2. ปลุกเอเจนต์ (GOD/Oracle v3)
เปิด WSL Terminal อีกหน้าต่าง:
```bash
cd /mnt/c/Agentic
bash scripts/ensure-agents.sh
```

## 3. คำสั่งจัดการ Tmux (กรณีเอเจนต์ค้างหรือหาย)
- ดูเอเจนต์ที่รันอยู่: `tmux ls`
- เข้าไปดูหน้าจอเอเจนต์: `tmux attach -t mawjs-oracle`
- ออกจากหน้าจอเอเจนต์ (แต่ไม่ปิด): กด `Ctrl+b` แล้วตามด้วย `d`
- ปิดเอเจนต์ทั้งหมด: `tmux kill-server`

---
*บันทึกโดย Oracle — พร้อมรับใช้เสมอครับ*
