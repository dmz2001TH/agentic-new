import asyncio
import json

# Import the 4 pillars of JARVIS
try:
    from scripts.mcp_server import JARVIS_MCPServer
    from scripts.graph_memory import KnowledgeGraph
    from scripts.vision_analyzer import VisionAnalyzer
    from scripts.security_guard import AgenticGuard
except ImportError:
    from mcp_server import JARVIS_MCPServer
    from graph_memory import KnowledgeGraph
    from vision_analyzer import VisionAnalyzer
    from security_guard import AgenticGuard

class JARVIS_Core:
    """
    JARVIS Supreme Core (2026 Edition)
    The central brain integrating MCP, GraphRAG, Vision, and Security.
    """
    def __init__(self):
        print("🧠 Booting JARVIS Core...")
        self.mcp = JARVIS_MCPServer()
        self.memory = KnowledgeGraph()
        self.vision = VisionAnalyzer()
        self.guard = AgenticGuard()
        self.status = "Awake"

    async def execute_task(self, user_intent: str, visual_context=None):
        print(f"\n--- 🚀 JARVIS Task Started: {user_intent} ---")
        
        # 1. SECURITY: Check intent
        security_check = self.guard.scan_intent(user_intent, "Planning phase")
        if security_check["status"] == "blocked":
            print(f"❌ SECURITY BLOCK: {security_check['reason']}")
            return {"status": "failed", "reason": "security_blocked"}
        print("✅ Security Check: Passed")

        # 2. VISION: Analyze visual context if provided
        vision_result = None
        if visual_context:
            vision_result = await self.vision.analyze_ui(visual_context, user_intent)
            print(f"👁️ Vision Analysis: {vision_result['observation']}")
            # Link visual context to memory
            self.memory.add_node("current_vision_task", "vision_context", vision_result)

        # 3. MEMORY: GraphRAG lookup
        self.memory.add_node("task_" + str(hash(user_intent)), "task", {"intent": user_intent})
        print("🕸️ Memory: Task registered in GraphRAG.")

        # 4. MCP: Discover and Execute Tools
        available_tools = await self.mcp.list_tools()
        print(f"📦 MCP: Found {len(available_tools)} tools available.")
        
        # Simulated Execution
        if "health" in user_intent.lower():
            result = await self.mcp.call_tool("system_health_check", {"verbose": True})
            print(f"⚡ MCP Execution Result: {result['result']}")
        else:
            print("⚡ JARVIS is orchestrating the solution...")

        print("--- 🏁 Task Complete ---")
        return {"status": "success", "intent": user_intent}

async def main():
    jarvis = JARVIS_Core()
    # Test full integration
    await jarvis.execute_task("Run a system health check", visual_context="dashboard.png")

if __name__ == "__main__":
    asyncio.run(main())
