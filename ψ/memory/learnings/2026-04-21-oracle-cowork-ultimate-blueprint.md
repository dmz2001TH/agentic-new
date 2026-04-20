# Learning: Oracle Cowork Ultimate Blueprint
- **วันที่**: 2026-04-21
- **หัวข้อ**: Desktop Agent Architecture & Robust GUI Control
- **บริบท**: สรุปจากการวิจัย Claude Cowork 3 เซสชัน (Engineering Grade)

## 🏗️ 1. Vision & UI Control (The Double-Loop)
- **Pre-click Verification**: แคปจอก่อนคลิก (T=0) -> Claude ยืนยันพิกัด -> เช็คซ้ำ (T+50ms) ว่าปุ่มยังอยู่ที่เดิมไหม -> คลิก
- **Post-click Confirmation**: แคปจอหลังคลิก -> วิเคราะห์ผลลัพธ์ว่าสำเร็จหรือมี Pop-up แทรกขึ้นมา

## 📂 2. Data Consistency (Surgical Sync)
- **Hash-before-Write**: เช็ค SHA-256 ของไฟล์ก่อนเขียนทับเสมอ
- **Atomic Operation**: เขียนลง Temp file ก่อนแล้วค่อย Rename เพื่อป้องกันไฟล์เสียหาย (Corrupted)
- **Conflict Strategy**: หากไฟล์ถูกแก้จากภายนอก ให้สร้างไฟล์ Backup (.conflict) แทนการเขียนทับเด็ดขาด

## 🛡️ 3. Self-Healing (Recovery Stack)
1. **Visual Re-scan**: แคปภาพใหม่ด้วยความละเอียดสูงขึ้น
2. **System Check (Bash Fallback)**: ใช้คำสั่ง `ps`, `ls`, `curl` เช็คสถานะจริงของแอป/เน็ต เมื่อ UI ไม่ตอบสนอง
3. **Process Recovery**: สั่ง Kill และ Relaunch แอปที่ค้างโดยอัตโนมัติ
4. **Human Escalation**: หากลองครบ 5 ขั้นตอนแล้วไม่ผ่าน ให้ส่ง Notification แจ้งเตือนท่านพีชทันที

## 🔐 4. Security (The Vault)
- ห้ามเก็บ API Keys ใน Plaintext
- ใช้ Library `keyring` เชื่อมต่อกับ Windows Credential Manager / MacOS Keychain

## การนำมาใช้ใน Oracle World
- พัฒนา `ot-safe-write` และ `ot-ui-verify` ลงใน ACI Layer
- สร้าง `oracle-daemon` (SQLite based) เพื่อคุมงานอัตโนมัติ
