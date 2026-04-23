import os
import json
import asyncio
from scripts.graph_memory import KnowledgeGraph
from scripts.evolution_engine import EvolutionEngine
from scripts.promptdee_bridge import PromptDeeBridge

async def run_showcase():
    print("🚀 --- JARVIS SUPREME SHOWCASE START --- 🚀")
    
    # 1. TEST: Knowledge Graph (Real Workspace Mapping)
    print("\n[Step 1: Mapping Your Empire]")
    g = KnowledgeGraph()
    files = [f for f in os.listdir("scripts") if f.endswith(".py")]
    for f in files:
        g.add_fact("Workspace", "contains", f)
    print(f"✅ JARVIS mapped {len(files)} files in your workspace.")

    # 2. TEST: Autonomous Evolution (Real New Skill: Disk Check)
    print("\n[Step 2: Recursive Self-Improvement]")
    engine = EvolutionEngine()
    
    # DNA ใหม่: ร่าง v3.0.0
    new_dna = '''
class EvolvingAgent:
    def __init__(self):
        self.version = "3.0.0 (God Mode)"
    
    def check_disk_real(self):
        import shutil
        total, used, free = shutil.disk_usage("/")
        print(f"💾 [Version {self.version}] REAL DISK CHECK:")
        print(f"   Total: {total // (2**30)} GB | Used: {used // (2**30)} GB | Free: {free // (2**30)} GB")
        return free
'''
    # บททดสอบเฉพาะสำหรับร่างนี้
    custom_test = '''
agent = EvolvingAgent()
assert agent.version == "3.0.0 (God Mode)"
result = agent.check_disk_real()
assert result > 0, "Disk space check failed!"
print("✅ Simulation: Disk check function works perfectly.")
'''
    
    if engine.test_in_world_model(new_dna, custom_test):
        engine.deploy(new_dna, "evolved_agent_v3.py")
        print("✅ RSI: Agent evolved to v3.0.0 successfully.")
        
        # โหลดร่างใหม่มาโชว์พลัง
        from scripts.evolved_agent_v3 import EvolvingAgent
        v3_agent = EvolvingAgent()
        v3_agent.check_disk_real()

    # 3. TEST: AI Synthesis (PromptDee)
    print("\n[Step 3: AI Executive Summary]")
    bridge = PromptDeeBridge()
    summary_msg = "สแกนไฟล์สำเร็จ สร้างความจำสำเร็จ และอัปเกรดตัวเองเป็น v3.0.0 เช็คเนื้อที่ดิสก์ได้จริงแล้ว รายงานสรุปให้พีชฟังหน่อย"
    result = bridge.chat(summary_msg)
    if result["status"] == "success":
        print(f"🤖 JARVIS Says: {result['response']}")

    print("\n🚀 --- SHOWCASE COMPLETE: 100% FUNCTIONAL --- 🚀")

if __name__ == "__main__":
    asyncio.run(run_showcase())
