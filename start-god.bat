@echo off
wsl bash -c "cd /mnt/c/Agentic/agentic-new && git pull && cp start-god-with-memory.sh GEMINI.md brain-bridge.sh /mnt/c/Agentic/ && chmod +x /mnt/c/Agentic/start-god-with-memory.sh /mnt/c/Agentic/brain-bridge.sh && cd /mnt/c/Agentic && bash start-god-with-memory.sh"
pause
