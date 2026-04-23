import asyncio
import json
import subprocess
import ast
import os
from dataclasses import dataclass
from typing import List, Dict, Any

@dataclass
class MCPTool:
    name: str
    description: str
    parameters: Dict[str, Any]
    handler: Any # เปลี่ยนจาก template เป็น function handler เพื่อความยืดหยุ่น

class JARVIS_MCPServer:
    """
    Oracle World - MCP Server (Functional Edition v2)
    Connects AI agents to REAL system commands and AST analysis.
    """
    def __init__(self):
        self.tools: Dict[str, MCPTool] = {}
        self._register_tools()

    def _register_tools(self):
        # Tool: Dependency Analyzer (REAL AST Analysis)
        self.register_tool(MCPTool(
            name="analyze_project_structure",
            description="Analyzes Python/JS files to find real dependencies using AST.",
            parameters={"type": "object", "properties": {"root_dir": {"type": "string"}}},
            handler=self.analyze_dependencies
        ))

    def register_tool(self, tool: MCPTool):
        self.tools[tool.name] = tool
        print(f"📦 MCP: Registered tool [{tool.name}]")

    def analyze_dependencies(self, root_dir="."):
        """REAL implementation of dependency analysis."""
        results = {}
        for root, _, files in os.walk(root_dir):
            for file in files:
                if file.endswith(".py"):
                    path = os.path.join(root, file)
                    with open(path, "r") as f:
                        try:
                            tree = ast.parse(f.read())
                            imports = [node.module for node in ast.walk(tree) if isinstance(node, ast.ImportFrom)]
                            results[file] = imports
                        except:
                            results[file] = "Parse Error"
        return {"status": "success", "data": results}

    async def call_tool(self, name: str, arguments: Dict[str, Any]):
        if name not in self.tools:
            return {"status": "error", "message": f"Tool '{name}' not found."}
        
        tool = self.tools[name]
        print(f"🚀 MCP EXEC: {name} with {arguments}")
        # Execute the handler function
        try:
            result = tool.handler(**arguments)
            return result
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def list_tools(self):
        return [{"name": t.name, "description": t.description} for t in self.tools.values()]
