import asyncio
import json
import os
from scripts.promptdee_engine import PromptDeeEngine
from scripts.voice_synthesizer import ElevenLabsVoice

class JARVIS_Orchestrator:
    def __init__(self):
        self.ai = PromptDeeEngine()
        self.voice = ElevenLabsVoice()

    async def orchestrate_mission(self, mission_goal):
        print(f"🧠 [JARVIS]: Objective -> {mission_goal}")
        
        # 1. กลไกสร้างภาพ (ถ้ามีคำว่ารูป)
        img_url = None
        if any(word in mission_goal.lower() for word in ["รูป", "วาด", "ดีไซน์", "image", "draw"]):
            # ใช้ Alchemist Mode ขยายความ
            refined_prompt = self.ai.enhance_prompt(mission_goal)
            print(f"✨ [ALCHEMIST]: Refined -> {refined_prompt[:100]}...")
            img_url = self.ai.generate_image(refined_prompt)
        
        # 2. ตอบพีช (ห้ามมีนิสัยบอท D ห้ามทักทาย)
        # เราส่งคำสั่งไปที่ engine ที่จูนมาแล้ว
        final_text = self.ai.chat(mission_goal)
        
        # 3. เปล่งเสียงจริง
        self.voice.speak(final_text, filename="/mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ/jarvis-outputs/audio/report.mp3")

        return {
            "speech": final_text,
            "image_url": img_url if img_url else "https://replicate.delivery/xezq/7CjjepOMg8V3RCTvFQXEfVAz3LKKzn6mfo09zee8pZxlzHuzC/out-0.webp"
        }

if __name__ == "__main__":
    orch = JARVIS_Orchestrator()
    print(asyncio.run(orch.orchestrate_mission("สวัสดี")))
