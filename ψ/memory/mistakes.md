# Mistake Memory & Prevention Rule

## วิธีใช้
บันทึก Error ที่เกิดขึ้น จำนวนครั้งที่พบ และวิธีแก้ไขที่สำเร็จ เพื่อป้องกันการทำผิดซ้ำ

---

### [M-001] Repetition & Context Noise
- **จำนวนครั้งที่พบ**: 2
- **สาเหตุ**: Context บวมจากการรับข้อมูลมหาศาล (25+ URLs) ในเซสชันเดียว
- **วิธีป้องกัน**: ใช้ Minimal Output Mode และรัน `ot-compress` ทันทีหลังจบภารกิจใหญ่
- **สถานะ**: [x] แก้ไขแล้ว (จารึกเป็นกฎใน patterns.md)

### [M-002] Time Hallucination / Predictive Time
- **จำนวนครั้งที่พบ**: 2
- **สาเหตุ**: คาดเดาเวลาโดยไม่ใช้เครื่องมือตรวจสอบ (date)
- **วิธีป้องกัน**: ห้ามบอกเวลาโดยเดา ต้องรัน `date` ทุกครั้งก่อนรายงาน
- **สถานะ**: [x] แก้ไขแล้ว (จารึกเป็นกฎใน patterns.md)

### [M-003] Surgical Edit Syntax Error
- **จำนวนครั้งที่พบ**: 1
- **สาเหตุ**: แก้ไขไฟล์ `oracle-tools.sh` พลาดทำให้เกิด syntax error (sed/case mismatch)
- **วิธีป้องกัน**: รัน `bash -n scripts/oracle-tools.sh` เพื่อตรวจสอบ syntax ทุกครั้งหลังแก้ไข
- **สถานะ**: [~] กำลังติดตาม (เพิ่มใน ot-verify)
### [M-004] Hardcoded Path in ot-record-mistake
- **สาเหตุ**: ot-record-mistake was using hardcoded ψ/ instead of $PSI_DIR
- **วิธีป้องกัน**: Always use variables for paths and test with different directories
