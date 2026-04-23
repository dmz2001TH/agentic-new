import requests
import json

class PromptDeeBridge:
    """
    Bridge to PromptDee API services.
    Provides free AI Chat and Image Generation for JARVIS.
    """
    def __init__(self, user_id="jarvis_evolution_2026"):
        self.base_url = "https://www.promptdee.net/api"
        self.user_id = user_id

    def chat(self, message):
        """Sends a chat message to PromptDee AI."""
        print(f"💬 PromptDee: Sending message -> {message}")
        try:
            response = requests.post(
                f"{self.base_url}/ai-chat",
                json={"message": message, "userId": self.user_id},
                timeout=30
            )
            data = response.json()
            if data.get("success"):
                return {"status": "success", "response": data["response"], "model": data["model"]}
            return {"status": "error", "message": "API returned failure"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def generate_image(self, prompt):
        """Generates an image via PromptDee (Flux-Schnell)."""
        print(f"🎨 PromptDee: Generating image for -> {prompt}")
        try:
            response = requests.post(
                f"{self.base_url}/generate-image",
                json={"prompt": prompt, "userId": self.user_id},
                timeout=60
            )
            data = response.json()
            if data.get("success"):
                return {"status": "success", "url": data["imageUrl"], "model": data["model"]}
            return {"status": "error", "message": "API returned failure"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    # LIVE TEST
    bridge = PromptDeeBridge()
    print("--- [TEST 1: AI CHAT] ---")
    chat_result = bridge.chat("สวัสดี บอกผมหน่อยว่าคุณคือใคร?")
    print(json.dumps(chat_result, indent=2, ensure_ascii=False))
    
    print("\n--- [TEST 2: IMAGE GEN] ---")
    image_result = bridge.generate_image("Modern high-tech JARVIS interface dashboard, neon blue, 8k")
    print(json.dumps(image_result, indent=2))
