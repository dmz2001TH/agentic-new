# Reflection System — ระบบคิดทบทวน

## คืออะไร
ทุกครั้งที่ทำงานเสร็จ (หรือติดปัญหา) agent ต้อง "ทบทวน" ก่อนไปต่อ
เหมือนคนทำงานเสร็จแล้วคิดว่า "ทำดีมั้ย ปรับปรุงอะไรได้"

## เมื่อไหร่ต้องทำ Reflection
1. ทำงานเสร็จ 1 task
2. ติดปัญหาและแก้ได้
3. ติดปัญหาและแก้ไม่ได้ (ต้อง escalate)
4. ก่อนจบ session (handoff)

## Template Reflection

```markdown
# Reflection — YYYY-MM-DD HH:MM

## Agent: [ชื่อ]
## Task: [สิ่งที่ทำ]

### ผลลัพธ์
- สำเร็จ / ล้มเหลว / บางส่วน

### สิ่งที่做得ดี
- [สิ่งที่做得ดี 1]
- [สิ่งที่做得ดี 2]

### สิ่งที่ปรับปรุงได้
- [สิ่งที่ควร做得不同 1]
- [สิ่งที่ควร做得不同 2]

### เรียนรู้
- [บทเรียนที่ได้ → บันทึกใน patterns.md ด้วย]

### ขั้นตอนต่อไป
- [下一步做什么]

### Confidence
- สูง / กลาง / ต่ำ
```

## วิธีบันทึก
```bash
# สร้าง reflection file
cat > ψ/memory/reflections/YYYY-MM-DD_HH-MM_task.md << 'EOF'
[content from template above]
EOF

# ถ้าได้บทเรียนสำคัญ → เพิ่มลง patterns.md ด้วย
echo "- [YYYY-MM-DD] [lesson learned]" >> ψ/memory/patterns.md
```
