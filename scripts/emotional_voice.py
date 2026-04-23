import json
import os

class EmotionalVoice:
    """
    JARVIS Emotional Voice Engine (ElevenLabs v3 Standard)
    Uses [tags] to inject emotion into speech.
    """
    def __init__(self, synthesizer):
        self.synth = synthesizer

    def generate_emotional_report(self, text, emotion="calm"):
        """
        Emotions: [excited], [nervous], [whispers], [laughs], [serious]
        """
        styled_text = f"[{emotion}] {text}"
        print(f"🎙️ [EMOTIONAL VOICE]: Delivery style -> {emotion}")
        # เรียกใช้ voice_synthesizer เดิมแต่ส่ง text ที่มี tag ไป
        return self.synth.speak(styled_text, filename="jarvis_emotional_report.mp3")

# Note: Integration with the main VoiceSynthesizer
