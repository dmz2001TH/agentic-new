#!/usr/bin/env python3
"""
Oracle System - Browser-Use Agent Bridge
----------------------------------------
This script uses the 'browser-use' framework to allow autonomous web navigation.
It bridges the gap between bash workflow scripts and Python async execution.

Prerequisites: 
pip install browser-use langchain-openai playwright
playwright install
"""

import sys
import asyncio
import argparse
import json
import os

try:
    from browser_use import Agent
    from langchain_openai import ChatOpenAI
except ImportError:
    print(json.dumps({"status": "error", "message": "Missing dependencies. Run: pip install browser-use langchain-openai playwright"}))
    sys.exit(1)

async def run_browser_task(task_description: str, headless: bool = False):
    """Executes a web task using the browser-use Agent."""
    try:
        # Initialize the LLM (Requires OPENAI_API_KEY)
        if not os.environ.get("OPENAI_API_KEY"):
            print(json.dumps({"status": "error", "message": "OPENAI_API_KEY is not set."}))
            sys.exit(1)

        llm = ChatOpenAI(model="gpt-4o") # Using GPT-4o for best vision capabilities
        
        # In a full integration, we would configure the Agent to connect to our 
        # existing Chrome instance on port 9222 (as learned previously), 
        # but for this bridge, we use the default setup.
        agent = Agent(
            task=task_description,
            llm=llm,
        )
        
        print(f"Starting Agent Task: {task_description}", file=sys.stderr)
        result = await agent.run()
        
        # Ensure result can be serialized to JSON
        # browser-use returns an AgentHistoryList, we can grab the final result text
        final_text = "Task completed (check logs for details)."
        if hasattr(result, 'final_result') and result.final_result():
            final_text = result.final_result()
        elif hasattr(result, 'history') and len(result.history) > 0:
            final_text = "History captured." # Simplified for the bridge

        print(json.dumps({
            "status": "success", 
            "task": task_description,
            "result": final_text
        }))

    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Oracle Browser-Use Bridge")
    parser.add_argument("task", help="The description of the task for the browser agent to perform")
    parser.add_argument("--headless", action="store_true", help="Run browser in background")
    
    args = parser.parse_args()
    
    # Run the async loop
    asyncio.run(run_browser_task(args.task, args.headless))
