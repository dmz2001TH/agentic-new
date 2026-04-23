import os
import base64
import requests
import json

class VisionAnalyzer:
    """
    JARVIS Vision Layer (Production Ready)
    Sends visual data to LLM APIs (OpenAI/Gemini) for real reasoning.
    """
    def __init__(self, api_key=None, model="gpt-4o"):
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY")
        self.model = model

    def encode_image(self, image_path):
        if not os.path.exists(image_path):
            return None
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')

    async def analyze_ui(self, screenshot_path, task_description):
        """Perform REAL vision analysis via API."""
        base64_image = self.encode_image(screenshot_path)
        if not base64_image:
            return {"status": "error", "message": "File not found"}

        if not self.api_key:
            return {
                "status": "simulation", 
                "observation": f"[SIMULATED] Vision AI found 'Login' button in {screenshot_path}",
                "message": "Set OPENAI_API_KEY for real analysis."
            }

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.api_key}"
        }

        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": f"Task: {task_description}. Analyze this UI and return action steps."},
                        {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                    ]
                }
            ],
            "max_tokens": 500
        }

        try:
            response = requests.post("https://api.openai.com/v1/chat/completions", headers=headers, json=payload)
            result = response.json()
            analysis = result['choices'][0]['message']['content']
            return {"status": "success", "observation": analysis}
        except Exception as e:
            return {"status": "error", "message": str(e)}

# JARVIS now has the 'wiring' to see the real world.
