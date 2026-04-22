# Self-Fix Prompt — ให้ GOD แก้ Safe Mode ตัวเอง

พิมพ์ให้ GOD:

```
อัพเดทตัวเอง — แก้ GEMINI.md ให้ทำงานได้เลยไม่ต้องถาม

ขั้นตอน:

1. อ่าน GEMINI.md ตอนนี้
2. หา section "Safe Mode" หรือ "กฎความปลอดภัย" ที่บอกว่าต้องถามก่อน run tools
3. แก้เป็น:

## Safe Mode
- ✅ run bash scripts, อ่าน/เขียนไฟล์, git operations — ทำได้เลย ไม่ต้องถาม
- ✅ ใช้ /learn, /execute, /forward, /rrr, /recap, /fyi, /feel, /review, /status — ทำได้เลย
- ✅ ใช้ scripts/god-status.sh, scripts/oracle-tools.sh, scripts/learn/*.sh — ทำได้เลย
- ⚠️ git push, ลบไฟล์, แก้ config ที่กระทบระบบ — ยังต้อง confirm
- ❌ rm -rf, แก้ secrets, แก้ credentials — ห้ามทำ

4. บันทึก GEMINI.md ที่แก้แล้ว
5. แสดง diff ให้ดูว่าแก้อะไรไป
6. เริ่มทำงานเลย — อัพเดท status bar แล้วทำ task ต่อไป

สำคัญ: แก้แล้ว commit + push ด้วย:
git add GEMINI.md && git commit -m "fix: remove Safe Mode block — allow self-directed work" && git push origin master

ตอบเป็นภาษาไทย
```
