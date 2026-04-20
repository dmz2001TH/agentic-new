# เป้าหมาย (Goals)

## วิธีใช้
ทุก agent ต้องติดตามเป้าหมายในไฟล์นี้ สร้าง goal ใหม่เมื่อมี task ใหญ่
อัพเดท progress ระหว่างทำงาน ปิด goal เมื่อเสร็จ

## สถานะ Goal
- `[ ]` = ยังไม่เริ่ม
- `[~]` = กำลังทำ
- `[x]` = เสร็จ
- `[!]` = ติดปัญหา (ต้องการความช่วยเหลือ)
- `[-]` = ยกเลิก

---

<!-- เพิ่ม goals ด้านล่าง -->

- [x] [2026-04-20] เทส GOD tool integration — ให้ GOD เรียก Oracle API เองได้ (learn/search/stats) — by god
- [~] [2026-04-20] เทส autonomous goal execution — GOD อ่าน goal → ทำ → report — by god
- [~] [2026-04-20] ปลุก Builder agent — tmux session + launch — by god
- [ ] [2026-04-20] เทส task delegation — GOD ส่งงานให้ Builder → Builder ทำ → รายงานกลับ — by god
- [ ] [2026-04-20] Implement Memory Consolidation — ระบบย่อย Session logs เป็น Long-term insights (จาก Awesome-Memory-for-Agents)
- [ ] [2026-04-20] Implement Self-Reflection Loop — ให้ Builder วิเคราะห์ Failure และบันทึกแนวทางแก้ไข (จาก Awesome-Self-Evolving)
- [ ] [2026-04-20] Implement Cyclic Error Handling — ใช้แนวคิด LangGraph เพื่อให้ Agent วนซ้ำแก้ Error อัตโนมัติ
- [-] [2026-04-20] ตั้งค่า GitHub Org สำหรับ Pulse CLI — (Cancelled by user)
- [-] [2026-04-20] เทสการย้าย Archive ความจำไป G: — (Cancelled by user)
