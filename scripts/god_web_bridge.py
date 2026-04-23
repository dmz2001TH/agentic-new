import json
import time
import os
import requests

# กำหนด Path แบบ Absolute เพื่อความแม่นยำ
PIPE_DIR = "/mnt/c/Agentic/agentic-new/jarvis-web-portal/pipe"
REQUEST_FILE = os.path.join(PIPE_DIR, "request.json")
RESPONSE_FILE = os.path.join(PIPE_DIR, "response.json")
API_URL = "https://www.promptdee.net/api/ai-chat"
IMAGE_URL = "https://www.promptdee.net/api/generate-image"

# สร้างโฟลเดอร์รอไว้เลยถ้าไม่มี
os.makedirs(PIPE_DIR, exist_ok=True)

print("💎 [JARVIS SUPREME BRIDGE]: Robust System Online. Awaiting mission...")

def clean_response(text):
    return text.replace("บอท D:", "").replace("บอท D", "JARVIS").replace("Bot D:", "").strip()

while True:
    # ตรวจสอบไฟล์แบบปลอดภัย
    if os.path.exists(REQUEST_FILE):
        try:
            # รอสักนิดเผื่อไฟล์ยังเขียนไม่เสร็จ
            time.sleep(0.1) 
            
            with open(REQUEST_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            
            mission = data.get("message", "")
            if not mission:
                os.remove(REQUEST_FILE)
                continue

            print(f"📥 New Mission: {mission}")
            
            # 1. AI Thinking
            system_msg = "ACT AS JARVIS. SUPREME AI. CONCISE THAI RESPONSES ONLY."
            resp = requests.post(API_URL, json={"message": f"{system_msg}\n\nCommand: {mission}", "userId": "jarvis_prod"}, timeout=20)
            ai_data = resp.json()
            answer = clean_response(ai_data.get("response", "Processing, sir."))

            # 2. Image Logic
            img_link = "https://replicate.delivery/xezq/7CjjepOMg8V3RCTvFQXEfVAz3LKKzn6mfo09zee8pZxlzHuzC/out-0.webp"
            if any(w in mission.lower() for w in ["รูป", "วาด", "ดีไซน์", "image", "draw"]):
                print("🎨 Drawing...")
                img_resp = requests.post(IMAGE_URL, json={"prompt": mission, "userId": "jarvis_prod"}, timeout=40)
                img_data = img_resp.json()
                if img_data.get("success"):
                    img_link = img_data["imageUrl"]

            # 3. Write Response (Safe Write)
            with open(RESPONSE_FILE, "w", encoding="utf-8") as f:
                json.dump({
                    "status": "success",
                    "message": answer,
                    "image_url": img_link,
                    "voice_url": "/audio/report.mp3"
                }, f)
            
            # 4. ลบ request ออกอย่างปลอดภัย
            if os.path.exists(REQUEST_FILE):
                os.remove(REQUEST_FILE)
            print(f"✅ Dispatched: {mission}")
            
        except Exception as e:
            print(f"⚠️ Warning: {e}")
            if os.path.exists(REQUEST_FILE):
                try: os.remove(REQUEST_FILE)
                except: pass

    time.sleep(0.5)
