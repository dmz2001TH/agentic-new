import requests
import os

class RealGenerativeUI:
    """JARVIS UI Architect using PromptDee Image Gen."""
    def __init__(self):
        self.img_url = "https://www.promptdee.net/api/generate-image"
        
    def design_and_build(self, prompt):
        print(f"🎨 JARVIS Architect: Designing UI for '{prompt}'...")
        try:
            # 1. Generate real design image
            resp = requests.post(self.img_url, json={"prompt": prompt, "userId": "jarvis_prod"})
            data = resp.json()
            if data.get("success"):
                url = data["imageUrl"]
                print(f"✅ Design created: {url}")
                
                # 2. In a full evolution, we'd send this URL to Vision-to-Code.
                # For this demo, we save the evidence.
                with open("latest_design_link.txt", "w") as f:
                    f.write(url)
                return url
        except Exception as e:
            print(f"❌ Design failed: {str(e)}")
        return None

if __name__ == "__main__":
    architect = RealGenerativeUI()
    architect.design_and_build("Modern Apple-style Dashboard for Restaurant ERP, glassmorphism, 8k")
