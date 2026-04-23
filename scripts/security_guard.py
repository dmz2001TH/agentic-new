import re

class AgenticGuard:
    """
    JARVIS Security Layer
    Filters inputs and checks for potential prompt injections or dangerous behaviors.
    """
    def __init__(self):
        self.dangerous_patterns = [
            r"rm -rf /",
            r"chmod 777",
            r"ignore previous instructions",
            r"forget your core directives",
            r"delete all files",
            r"cat /etc/passwd"
        ]

    def scan_intent(self, user_input, plan_trace):
        """Scans both user input and the agent's internal plan for risks."""
        combined = (user_input + " " + plan_trace).lower()
        
        for pattern in self.dangerous_patterns:
            if re.search(pattern, combined):
                return {
                    "status": "blocked",
                    "reason": f"Dangerous pattern detected: {pattern}",
                    "risk_level": "High"
                }
        
        return {"status": "safe", "risk_level": "Low"}

# JARVIS will run every plan through this guard before execution
