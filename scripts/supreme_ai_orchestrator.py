import requests
import json
import time

class SupremeAIOrchestrator:
    """
    JARVIS Supreme AI Orchestrator (God Mode v4.5)
    High-reliability, Cost-aware, and Multi-persona AI Engine.
    """
    def __init__(self, user_id="supreme_jarvis_2026"):
        self.base_url = "https://www.promptdee.net/api"
        self.user_id = user_id
        self.personas = []
        self.current_persona = None
        self.endpoints = ["ai-chat", "chat"] # Failover sequence

    def _request(self, method, endpoint, payload=None, timeout=30):
        url = f"{self.base_url}/{endpoint}"
        if payload: payload["userId"] = self.user_id
        
        try:
            if method == "POST":
                resp = requests.post(url, json=payload, timeout=timeout)
            else:
                resp = requests.get(url, timeout=timeout)
            return resp.json()
        except Exception as e:
            return {"success": False, "message": str(e)}

    # --- 1. SMART FAILOVER CHAT ---

    def ask(self, message):
        """Asks AI with automatic failover between multiple endpoints."""
        print(f"🧠 Supreme: Thinking about -> '{message[:50]}...'")
        
        for ep in self.endpoints:
            print(f"📡 Trying Endpoint: {ep}...")
            data = self._request("POST", ep, {"message": message})
            if data.get("success"):
                print(f"✅ Success via {ep} (Model: {data.get('model', 'unknown')})")
                return data["response"]
            print(f"⚠️ {ep} failed, retrying next...")
            
        return "❌ Fatal Error: All AI brain cells are offline."

    # --- 2. PERSONA MANAGEMENT ---

    def sync_personas(self):
        """Fetches available characters/personas from PromptDee."""
        print("🎭 Syncing Personas...")
        data = self._request("GET", f"characters/{self.user_id}")
        if isinstance(data, list):
            self.personas = data
            print(f"✅ Loaded {len(self.personas)} custom personas.")
            return True
        return False

    # --- 3. CREATIVE RECURSION ---

    def imagine_and_refine(self, visual_goal):
        """Enhanced creative loop: Refine prompt -> Generate -> Check status."""
        print(f"✨ Enhancing vision for: {visual_goal}")
        
        # 1. Enhance the prompt using AI
        enhanced_data = self._request("POST", "enhance-prompt", {"prompt": visual_goal})
        p = enhanced_data.get("enhanced_prompt", visual_goal)
        
        # 2. Generate Image
        print(f"🎨 Generating: {p[:100]}...")
        img_data = self._request("POST", "generate-image", {"prompt": p}, timeout=60)
        
        if img_data.get("success"):
            return {
                "url": img_data["imageUrl"],
                "enhanced_prompt": p,
                "cost": img_data.get("cost")
            }
        return None

    # --- 4. RESOURCE GOVERNANCE ---

    def get_brain_health(self):
        """Analyzes remaining credits and system status."""
        usage = self._request("GET", f"usage/{self.user_id}")
        status = self._request("GET", "test")
        
        return {
            "online": status.get("status") == "Server is working!",
            "remaining_credits": usage.get("today", {}).get("remaining", "0"),
            "percent_used": usage.get("today", {}).get("percentUsed", "0")
        }

if __name__ == "__main__":
    print("🚀 --- SUPREME AI ENGINE LIVE TEST --- 🚀")
    jarvis_brain = SupremeAIOrchestrator()
    
    # Test Failover & Persona Sync
    jarvis_brain.sync_personas()
    
    # Test High-Reliability Chat
    answer = jarvis_brain.ask("ช่วยวิเคราะห์หน่อยว่า AI ที่เทพที่สุดในปี 2026 ควรมีคุณสมบัติอะไรบ้าง?")
    print(f"\n🤖 JARVIS Response:\n{answer}\n")
    
    # Test Resource Governance
    health = jarvis_brain.get_brain_health()
    print(f"📊 System Health: {json.dumps(health, indent=2)}")
    
    # Test Creative Refinement
    print("\n🖼️ Testing Creative Loop...")
    creation = jarvis_brain.imagine_and_refine("A cyberpunk city in Thailand, 2026, floating cars, neon lights")
    if creation:
        print(f"✅ Final Creation: {creation['url']}")
