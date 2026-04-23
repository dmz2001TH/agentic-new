import requests
import json
import os
import base64

class ElevenLabsVoice:
    """
    JARVIS Premium Voice Engine (Base64 Decoder Edition)
    Saves high-quality voice directly as an MP3 file.
    """
    def __init__(self, user_id="supreme_jarvis_2026"):
        self.api_url = "https://www.promptdee-ai.com/api/generate-voice-elevenlabs"
        self.user_id = user_id
        self.default_voice_id = "21m00Tcm4TlvDq8ikWAM" # Rachel

    def speak(self, text, filename="jarvis_voice_report.mp3"):
        print(f"🎙️ ElevenLabs: Synthesizing voice for -> '{text[:30]}...'")
        
        payload = {
            "text": text,
            "voiceId": self.default_voice_id,
            "userId": self.user_id
        }
        
        try:
            response = requests.post(self.api_url, json=payload, timeout=60)
            data = response.json()
            
            if data.get("success") and "audioUrl" in data:
                # 1. Extract Base64 string (remove the prefix 'data:audio/mpeg;base64,')
                audio_data = data["audioUrl"].split(",")[1]
                
                # 2. Decode and save as MP3
                with open(filename, "wb") as f:
                    f.write(base64.b64decode(audio_data))
                
                full_path = os.path.abspath(filename)
                print(f"✅ Voice file saved successfully: {full_path}")
                return full_path
            else:
                print(f"❌ Voice API Error: {json.dumps(data)}")
                return None
        except Exception as e:
            print(f"❌ Connectivity Error: {str(e)}")
            return None

if __name__ == "__main__":
    engine = ElevenLabsVoice()
    text_to_say = "สวัสดีครับคุณพีช ผมคือจาร์วิสที่อัปเกรดระบบเสียงพรีเมียมเรียบร้อยแล้ว ไฟล์เสียงของคุณพร้อมให้รับฟังแล้วครับ"
    file_path = engine.speak(text_to_say)
    if file_path:
        print(f"\n🎵 ภารกิจสำเร็จ! คุณสามารถเปิดฟังได้ที่:\n{file_path}")
