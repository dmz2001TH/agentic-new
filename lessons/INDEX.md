# 📚 Lessons Index

> สรุป lessons ทั้งหมด — inject เข้า system prompt ทุกครั้ง
> อัพเดทเมื่อมี lesson ใหม่

---

## ⛔ Critical Rules (ห้ามแหก)

1. **ต้อง backup ก่อนแก้ database** — เคย data สูญเพราะไม่ backup
2. **ไม่ commit credentials** — API keys, tokens, passwords ห้ามอยู่ใน git
3. **ไม่ deploy โดยไม่ test** — production พังมาแล้ว
4. **ไม่เดา** — ถ้าไม่รู้ บอกว่าไม่รู้ ไม่สร้างข้อมูลเท็จ

---

## ⚠️ Warnings (ระวัง)

1. **เช็ค API version ก่อนใช้** — เคยใช้ deprecated API แล้ว runtime error
2. **ไม่ assume input format** — เคยเจอ unexpected null แล้ว crash
3. **เช็ค edge cases** — เคยเจอ empty array แล้ว error
4. **ไม่แก้ไฟล์ที่ไม่เกี่ยวกับ task** — เคยแก้ไฟล์ผิดแล้วพัง

---

## 💡 Tips (ช่วยได้)

1. ใช้ optional chaining แทน explicit null check
2. เขียน test ก่อนเขียนโค้ด (TDD) — ได้โค้ดที่ดีกว่า
3. Break task ใหญ่เป็น task เล็ก — จัดการง่ายกว่า
4. Explain reasoning ก่อน code — user เข้าใจง่ายกว่า

---

## 📝 Recent Lessons

### 2026-04-23 — Framework Creation
- **สิ่งที่เรียนรู้:** Agent ต้องมี SOUL + CONSTITUTION + LESSONS ถึงจะ behave ได้ดี
- **กฎใหม่:** ทุก agent ต้องมี SOUL.md เป็นของตัวเอง

---

## Stats

- **Total lessons:** 1
- **Critical rules:** 4
- **Warnings:** 4
- **Tips:** 4
- **Last updated:** 2026-04-23
