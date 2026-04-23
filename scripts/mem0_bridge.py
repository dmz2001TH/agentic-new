#!/usr/bin/env python3
"""
Oracle System - Mem0 Semantic Memory Bridge
-------------------------------------------
This script acts as a bridge between bash scripts and the mem0ai Python SDK.
It allows agents to store and search for semantic memories.

Prerequisites: pip install mem0ai openai
"""

import sys
import argparse
import json
import os

try:
    from mem0 import Memory
except ImportError:
    print("Error: mem0ai library not found. Please run: pip install mem0ai openai", file=sys.stderr)
    sys.exit(1)

# Initialize memory (will use default local vector store like chromadb or qdrant embedded)
memory = Memory()

def add_memory(content: str, user_id: str, agent_id: str):
    """Add a new memory to the store."""
    try:
        # We pass the content as a user message, but it represents the agent's observation
        messages = [{"role": "user", "content": content}]
        metadata = {"agent_id": agent_id} if agent_id else {}
        
        result = memory.add(messages, user_id=user_id, metadata=metadata)
        print(json.dumps({"status": "success", "action": "add", "result": result}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)

def search_memory(query: str, user_id: str, limit: int):
    """Search for relevant memories."""
    try:
        results = memory.search(query=query, user_id=user_id, limit=limit)
        
        # Format the output for easy consumption by bash scripts
        formatted_results = []
        if "results" in results:
            for item in results["results"]:
                formatted_results.append({
                    "memory": item.get("memory", ""),
                    "score": item.get("score", 0.0)
                })
        
        print(json.dumps({"status": "success", "action": "search", "data": formatted_results}))
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Oracle Mem0 Bridge")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Add command
    add_parser = subparsers.add_parser("add", help="Add a new memory")
    add_parser.add_argument("content", help="The memory content to store")
    add_parser.add_argument("--user", default="peach", help="User ID (default: peach)")
    add_parser.add_argument("--agent", default="god", help="Agent ID generating the memory")

    # Search command
    search_parser = subparsers.add_parser("search", help="Search for memories")
    search_parser.add_argument("query", help="The search query")
    search_parser.add_argument("--user", default="peach", help="User ID (default: peach)")
    search_parser.add_argument("--limit", type=int, default=3, help="Max results to return")

    args = parser.parse_args()

    # Ensure OPENAI_API_KEY is present for embeddings
    if not os.environ.get("OPENAI_API_KEY") and not os.environ.get("MEM0_API_KEY"):
        print(json.dumps({"status": "warning", "message": "No OPENAI_API_KEY found. Mem0 might fail if it relies on default OpenAI embeddings."}), file=sys.stderr)

    if args.command == "add":
        add_memory(args.content, args.user, args.agent)
    elif args.command == "search":
        search_memory(args.query, args.user, args.limit)
    else:
        parser.print_help()
        sys.exit(1)
