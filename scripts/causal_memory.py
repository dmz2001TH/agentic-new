import json
import os

class CausalMemory:
    """
    JARVIS Causal Memory Layer
    Stores 'Cause -> Effect -> Fix' patterns to avoid repeated mistakes.
    """
    def __init__(self, storage_path="ψ/memory/causal_patterns.json"):
        self.storage_path = storage_path
        self.patterns = self._load_patterns()

    def _load_patterns(self):
        if os.path.exists(self.storage_path):
            with open(self.storage_path, 'r') as f:
                return json.load(f)
        return {}

    def log_fix(self, error_type, symptom, fix_action):
        """Records a successful fix for a specific error."""
        if error_type not in self.patterns:
            self.patterns[error_type] = []
        
        entry = {
            "symptom": symptom,
            "fix": fix_action,
            "success_count": 1
        }
        
        # Simple deduplication
        for p in self.patterns[error_type]:
            if p["symptom"] == symptom:
                p["success_count"] += 1
                return

        self.patterns[error_type].append(entry)
        self._save()

    def _save(self):
        with open(self.storage_path, 'w') as f:
            json.dump(self.patterns, f, indent=2)

    def suggest_fix(self, error_message):
        """Suggests a fix based on past successes."""
        for error_type, entries in self.patterns.items():
            if error_type in error_message:
                return sorted(entries, key=lambda x: x['success_count'], reverse=True)[0]
        return None

# Usage Example for JARVIS
# memory = CausalMemory()
# memory.log_fix("JSONDecodeError", "Invalid JSON from LLM", "Use a stricter JSON repair prompt")
