
## 2026-04-21 — Oracle Cowork Engine: Playwright with Persistent Context
- **บริบท**: การสร้าง Browser Engine ที่สามารถแชร์ session และ history กับผู้ใช้ (Peach) ได้จริง
- **สิ่งที่เรียนรู้**: การใช้ `chromium.launchPersistentContext` พร้อมระบุ `channel: 'chrome'` และ `headless: false` ช่วยให้ Agent สามารถเปิดเบราว์เซอร์บน Windows Desktop ของผู้ใช้โดยตรง โดยใช้โปรไฟล์ที่แยกออกมาต่างหากแต่เก็บความจำ (Sessions/Cookies) ไว้ถาวร
- **วิธีใช้**: รันผ่าน `node.exe` จาก WSL โดยใช้ `wslpath -w` เพื่อระบุพาธไฟล์สคริปต์ให้ Windows Node.js ทำงานได้ถูกต้อง
- **แท็ก**: #playwright #cowork #windows-bridge #persistent-context

## 2026-04-21 — Persistent Data Extraction
- **บริบท**: ต้องการดึงข้อมูลจาก Gmail โดยใช้ session เดิมของผู้ใช้
- **สิ่งที่เรียนรู้**: การใช้ launchPersistentContext ใน Playwright ช่วยให้ข้ามการ Login ได้ถ้าเคย Login ไว้แล้ว แต่ต้องระวังเรื่อง Profile Lock ถ้ามีการเปิดซ้อนกัน
- **วิธีใช้**: ใช้สคริปต์แยกที่เรียกผ่าน node.exe บน Windows เพื่อให้เข้าถึง Chrome profile ที่เก็บไว้ใน C:\Users\Public
- **แท็ก**: #playwright #automation #gmail #extraction
