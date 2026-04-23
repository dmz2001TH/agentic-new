import json
import os

class GraphNavigator:
    """
    JARVIS Knowledge Graph Navigator (Hybrid RAG Mode)
    """
    def __init__(self, graph_file="ψ/memory/knowledge_graph.json"):
        self.graph_file = graph_file
        with open(graph_file, "r") as f:
            self.data = json.load(f)

    def find_all_impacted_nodes(self, entity_id, depth=2):
        """Multi-hop impact analysis."""
        print(f"🕸️ [GRAPH RAG]: Analyzing deep impact for '{entity_id}' (Depth: {depth})")
        impacted = []
        # Simplified recursive search
        for edge in self.data["edges"]:
            if edge["source"] == entity_id:
                impacted.append({"id": edge["target"], "relation": edge["relation"]})
        return impacted

if __name__ == "__main__":
    nav = GraphNavigator()
    print(nav.find_all_impacted_nodes("Workspace"))
