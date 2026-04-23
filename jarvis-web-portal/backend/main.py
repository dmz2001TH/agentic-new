from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import time
import os
from fastapi.staticfiles import StaticFiles
import json

app = FastAPI(title="JARVIS Brain Bridge")

# เปิดบริการไฟล์เสียงและภาพจาก GDrive Output
OUTPUT_DIR = "/mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ/jarvis-outputs"
app.mount("/audio", StaticFiles(directory=os.path.join(OUTPUT_DIR, "audio")), name="audio")

# ปลดล็อก CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

PIPE_DIR = "/mnt/c/Agentic/agentic-new/jarvis-web-portal/pipe"
REQUEST_FILE = os.path.join(PIPE_DIR, "request.json")
RESPONSE_FILE = os.path.join(PIPE_DIR, "response.json")

# สร้างโฟลเดอร์ pipe ถ้ายังไม่มี
os.makedirs(PIPE_DIR, exist_ok=True)

class ChatRequest(BaseModel):
    message: str

@app.post("/api/chat")
async def chat_with_god(req: ChatRequest):
    # 1. เขียนคำถามลงใน Pipe
    try:
        with open(REQUEST_FILE, "w") as f:
            json.dump({"message": req.message, "timestamp": time.time()}, f)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to write request: {e}")

    # 2. รอคำตอบจาก GOD Bridge (สูงสุด 30 วินาที)
    start_time = time.time()
    while time.time() - start_time < 30:
        if os.path.exists(RESPONSE_FILE):
            try:
                with open(RESPONSE_FILE, "r") as f:
                    data = json.load(f)
                os.remove(RESPONSE_FILE) # ล้างไฟล์หลังอ่านเสร็จ
                return data
            except:
                pass
        time.sleep(0.5)

    return {"status": "timeout", "message": "JARVIS is processing deeply... Please try again."}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
