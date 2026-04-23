import requests
import json
import time

class RealVoiceAgent:
    """JARVIS Voice Brain using PromptDee API."""
    def __init__(self):
        self.base_url = "https://www.promptdee.net/api/ai-chat"
        
    def think_and_speak(self, message):
        print(f"🎙️ [USER VOICE]: {message}")
        try:
            resp = requests.post(self.base_url, json={"message": message, "userId": "jarvis_prod"})
            data = resp.json()
            if data.get("success"):
                print(f"🤖 [JARVIS VOICE]: {data['response']}")
                return data['response']
        except:
            print("🎙️ JARVIS: Connectivity issue, sir.")
        return None

if __name__ == "__main__":
    agent = RealVoiceAgent()
    agent.think_and_speak("สวัสดี JARVIS รายงานสถานะความพร้อมของระบบหน่อย")
