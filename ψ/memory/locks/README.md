# Memory Lock System — ป้องกันการเขียนชนกัน

## ปัญหา
ถ้า 2 agent เขียนไฟล์เดียวกันพร้อมกัน → ข้อมูลสูญหาย

## วิธีแก้: Lock File Protocol

### กฎ
1. **ก่อนเขียนไฟล์ shared** (`ψ/memory/` shared files) → สร้าง lock
2. **หลังเขียนเสร็จ** → ลบ lock
3. **ถ้าเจอ lock อยู่** → รอ 5 วินาที แล้วลองใหม่ (สูงสุด 3 ครั้ง)
4. **ถ้า lock เก่าเกิน 60 วินาที** → ถือว่า stale ลบได้

### ไฟล์ Lock
```
ψ/memory/locks/<filename>.lock
```

### ตัวอย่าง
```bash
# เขียน patterns.md อย่างปลอดภัย
LOCK_FILE="ψ/memory/locks/patterns.md.lock"
TARGET="ψ/memory/patterns.md"

# 1. สร้าง lock
echo "god:$(date +%s)" > "$LOCK_FILE"

# 2. เขียนไฟล์
echo "- [$(date +%Y-%m-%d)] new pattern" >> "$TARGET"

# 3. ปล่อย lock
rm -f "$LOCK_FILE"
```

### ตรวจสอบ lock
```bash
# ดู locks ทั้งหมด
ls -la ψ/memory/locks/ 2>/dev/null

# ดู lock เก่า (> 60s) → ลบได้
find ψ/memory/locks/ -name "*.lock" -mmin +1 -delete
```

### ไฟล์ที่ต้อง lock (shared memory writes)
- `ψ/memory/patterns.md`
- `ψ/memory/decisions.md`
- `ψ/memory/people.md`
- `ψ/memory/goals.md`
- `ψ/memory/values.md`
- `ψ/memory/notes.md`

### ไฟล์ที่ไม่ต้อง lock (personal memory)
- `ψ/agents/<name>/memory/*` — เฉพาะตัวเอง เขียนได้เลย
