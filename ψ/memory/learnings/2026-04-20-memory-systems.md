# Learning: Memory & Context Systems (2026)
- **วันที่**: 2026-04-20
- **หัวข้อ**: Semantic & Personalized Memory
- **บริบท**: ศึกษาจาก Mem0, LangMem, Awesome-Memory-for-Agents

## สิ่งที่เรียนรู้ (Core Insights)
1. **Decoupled Memory (Mem0)**: ระบบความจำควรแยกออกมาเป็นเลเยอร์ต่างหาก (Separate Layer) ที่สามารถดึง Insight แบบข้ามเซสชัน (Cross-session) และจดจำ "ความชอบส่วนตัว (Personalization)" ของผู้ใช้ได้
2. **Hierarchical Memory**: แบ่งความจำเป็น 3 ระดับ: 
   - Short-term (Current Context)
   - Long-term (Facts/Knowledge)
   - Semantic (Patterns/Insights)
3. **Consolidation**: กระบวนการแปลง "บันทึกดิบ (Raw Logs)" ให้กลายเป็น "ความรู้ถาวร (Consolidated Knowledge)" คือหัวใจของการที่เอเจนท์จะเก่งขึ้นเรื่อยๆ

## การนำมาใช้ใน Oracle World
- พัฒนา `ψ/memory/patterns.md` ให้เป็นเลเยอร์ความจำเชิงความหมาย (Semantic Memory)
- เพิ่มขั้นตอน "Memory Consolidation" ในทุกๆ ท้ายเซสชัน (ก่อนรัน `finish-day.ps1`)
- ปรับปรุง `ψ/memory/people.md` ให้จดจำสไตล์และ Preference ของท่านอย่างละเอียดมากขึ้น

## แหล่งข้อมูล
- [Mem0](https://github.com/mem0ai/mem0)
- [LangMem](https://github.com/langchain-ai/langmem)
