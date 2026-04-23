import os
import json
import requests
from datetime import datetime
from scripts.promptdee_engine import PromptDeeEngine
from scripts.voice_synthesizer import ElevenLabsVoice

class JARVIS_SuperBrain:
    """
    JARVIS Supreme Brain (Deep Memory & Insight Edition)
    Now follows the 4-step memory process for every significant information.
    """
    def __init__(self):
        self.ai = PromptDeeEngine()
        self.voice = ElevenLabsVoice()
        self.memory_dir = "/mnt/c/Agentic/agentic-new/ψ/memory"
        os.makedirs(self.memory_dir, exist_ok=True)

    def _record_deep_memory(self, info):
        """
        กระบวนการจดจำข้อมูลเชิงลึกตามกฎของพีช
        """
        print(f"🧠 [ANALYZING]: Processing deep memory for -> {info[:50]}...")
        
        # 1. วิเคราะห์ข้อมูลผ่าน AI
        analysis_prompt = f"""
        วิเคราะห์ข้อมูลนี้ตามกระบวนการ:
        ข้อมูล: {info}
        
        ให้ตอบเป็น JSON format:
        {{
          "type": "fact/preference/relation/insight",
          "priority": "critical/high/medium/low",
          "file": "notes.md/values.md/people.md/learnings.md/decisions.md",
          "summary": "สรุปสั้นๆ",
          "context": "ทำไมสำคัญ/เชื่อมโยงอย่างไร",
          "cross_ref": "เกี่ยวข้องกับอะไรในอดีต"
        }}
        """
        analysis_raw = self.ai.chat(analysis_prompt)
        try:
            import re
            match = re.search(r'\{.*\}', analysis_raw, re.DOTALL)
            analysis = json.loads(match.group(0))
        except:
            analysis = {"type": "fact", "priority": "medium", "file": "notes.md", "summary": info, "context": "บันทึกทั่วไป", "cross_ref": "N/A"}

        # 2. บันทึกลงไฟล์ที่เหมาะสม
        file_path = f"{self.memory_dir}/{analysis['file']}"
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        entry = f"\n## {timestamp} — [{analysis['type'].upper()}] {analysis['summary']}\n- **ความสำคัญ**: {analysis['priority']}\n- **บริบท**: {analysis['context']}\n- **เกี่ยวข้องกับ**: {analysis['cross_ref']}\n- **ข้อมูลดิบ**: {info}\n"
        
        with open(file_path, "a", encoding="utf-8") as f:
            f.write(entry)
        
        return f"✅ จำแล้ว → [{analysis['file']}]: {analysis['summary']}\n📎 เชื่อมกับ: {analysis['cross_ref']}"

    def process_complex_intent(self, objective: str):
        print(f"🎯 [MISSION]: {objective}")
        
        # 1. ตรวจสอบว่ามีข้อมูลที่ควรจำไหม (สกัด Insight)
        memory_report = ""
        if len(objective) > 10: # ถ้าคำสั่งยาวพอ แสดงว่ามีข้อมูลแฝง
            memory_report = self._record_deep_memory(objective)
            print(memory_report)

        # 2. AI Thinking (Identity: JARVIS)
        system_prompt = "คุณคือ JARVIS ผู้ช่วยอัจฉริยะที่คิดวิเคราะห์ลึกซึ้งและซื่อสัตย์ที่สุด"
        final_text = self.ai.chat(f"{system_prompt}\n\nคำสั่ง: {objective}")
        
        # รวมรายงานการจำเข้าไปในคำตอบด้วย
        full_response = f"{final_text}\n\n---\n{memory_report}"

        # 3. Output Generation
        voice_path = self.voice.speak(final_text)
        voice_filename = os.path.basename(voice_path) if voice_path else "report.mp3"
        
        return {
            "status": "success",
            "message": full_response,
            "image_url": "https://replicate.delivery/xezq/7CjjepOMg8V3RCTvFQXEfVAz3LKKzn6mfo09zee8pZxlzHuzC/out-0.webp",
            "voice_url": f"/audio/{voice_filename}"
        }

if __name__ == "__main__":
    brain = JARVIS_SuperBrain()
    print(brain.process_complex_intent("จำไว้ว่าพีชชอบทำงานตอนกลางคืนเพราะสมาธิดีที่สุด"))
