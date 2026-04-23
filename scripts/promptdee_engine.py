import requests
import json
import os

class PromptDeeEngine:
    """
    JARVIS High-Fidelity Engine (GPT-4o-mini Edition)
    Optimized for zero-bot-personality and high-intelligence tasks.
    """
    def __init__(self, user_id="jarvis_gpt4o_mini_2026"):
        self.base_url = "https://www.promptdee.net/api"
        self.user_id = user_id

    def chat(self, message):
        """Pure GPT-4o-mini logic with forced concise personality."""
        # ล็อคเป้าหมายให้ AI เป็น JARVIS 100% และห้ามมีนิสัยพนักงาน
        prompt = f"""
        [SYSTEM: ACT AS JARVIS. HIGH-LEVEL AI. NO GREETINGS. NO BOT PERSONALITY. CONCISE ONLY.]
        User Command: {message}
        JARVIS Response:
        """
        
        try:
            response = requests.post(
                f"{self.base_url}/ai-chat",
                json={"message": prompt, "userId": self.user_id},
                timeout=30
            )
            data = response.json()
            if data.get("success"):
                # สกัดเอาคำตอบที่อาจจะมีขยะติดมาออก
                res = data["response"].replace("บอท D:", "").replace("Bot D:", "").strip()
                return res
            return "Error: API Communication Failed."
        except Exception as e:
            return f"Error: {str(e)}"

    def generate_image(self, prompt):
        """Generates image using Flux-Schnell via PromptDee."""
        try:
            response = requests.post(
                f"{self.base_url}/generate-image",
                json={"prompt": prompt, "userId": self.user_id},
                timeout=60
            )
            data = response.json()
            if data.get("success"):
                return data["imageUrl"]
            return None
        except:
            return None

    def enhance_prompt(self, raw_prompt):
        """Uses GPT-4o-mini to turn simple words into Epic Cinematic Prompts."""
        alchemist_task = f"Convert '{raw_prompt}' into a legendary cinematic 8k masterpiece prompt for an AI artist. Include lighting, camera lens, and atmosphere. Return ONLY the prompt in English."
        return self.chat(alchemist_task)
