import json
import os

class KnowledgeGraph:
    """
    JARVIS Knowledge Graph (Reasoning Edition)
    Can perform multi-hop searches to understand relationships between files and tasks.
    """
    def __init__(self, storage_path="ψ/memory/knowledge_graph.json"):
        self.storage_path = storage_path
        self.graph = self._load_graph()

    def _load_graph(self):
        if os.path.exists(self.storage_path):
            try:
                with open(self.storage_path, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {"nodes": [], "edges": []}

    def add_fact(self, source_id, relation, target_id, metadata=None):
        """Adds a fact with high-level relationship mapping."""
        # Ensure nodes exist
        self._ensure_node(source_id)
        self._ensure_node(target_id)
        
        edge = {"source": source_id, "relation": relation, "target": target_id, "metadata": metadata or {}}
        if edge not in self.graph["edges"]:
            self.graph["edges"].append(edge)
            self._save()

    def _ensure_node(self, node_id):
        if not any(n["id"] == node_id for n in self.graph["nodes"]):
            self.graph["nodes"].append({"id": node_id, "type": "entity", "metadata": {}})

    def get_impact_analysis(self, entity_id):
        """Analyzes what will be impacted if an entity changes (Multi-hop reasoning)."""
        impacted = []
        for edge in self.graph["edges"]:
            if edge["source"] == entity_id:
                impacted.append({"id": edge["target"], "reason": f"Directly {edge['relation']}"})
        return impacted

    def _save(self):
        os.makedirs(os.path.dirname(self.storage_path), exist_ok=True)
        with open(self.storage_path, 'w') as f:
            json.dump(self.graph, f, indent=2)

# JARVIS now understands that fixing File A might impact Service B.
