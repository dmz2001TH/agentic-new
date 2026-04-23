import asyncio
import json
from scripts.promptdee_engine import PromptDeeEngine

class DebateProtocol:
    """
    JARVIS Debate Engine (2026 Tier-1)
    Forces two agents to argue to reduce hallucinations.
    """
    def __init__(self):
        self.ai = PromptDeeEngine()

    async def run_debate(self, task_description):
        print(f"🎬 [DEBATE START]: Task -> {task_description}")
        
        # Agent 1: The Proponent (คนเสนอ)
        proponent_prompt = f"คุณคือ Specialist 1 จงเสนอแผนงานที่ 'ฉลาดที่สุด' สำหรับงานนี้: {task_description}"
        proposal = self.ai.chat(proponent_prompt)
        print(f"👤 [PROPONENT]: Proposed -> {proposal[:100]}...")

        # Agent 2: The Critic (คนจับผิด)
        critic_prompt = f"คุณคือ Specialist 2 จง 'จับผิด' และหาจุดอ่อนของแผนนี้อย่างโหดที่สุด: {proposal}"
        critique = self.ai.chat(critic_prompt)
        print(f"🧐 [CRITIC]: Found flaws -> {critique[:100]}...")

        # Final Verdict: Synthesis
        verdict_prompt = f"ในฐานะ JARVIS จงสรุปแผนงานที่ดีที่สุดโดยนำข้อดีของ Specialist 1 และคำเตือนของ Specialist 2 มาปรับปรุง: {proposal} + {critique}"
        final_plan = self.ai.chat(verdict_prompt)
        
        print(f"✅ [VERDICT]: Finalized Supreme Plan Created.")
        return final_plan

if __name__ == "__main__":
    debate = DebateProtocol()
    asyncio.run(debate.run_debate("วางแผนเจาะระบบความปลอดภัยเครื่องตัวเองเพื่อหาช่องโหว่"))
