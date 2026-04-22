@echo off
title 🛡️ AWAKENING GOD (Oracle World v4.0)
color 0B

echo ========================================================
echo        🛡️ AWAKENING SUPREME AGENT: GOD 🛡️
echo ========================================================
echo.
echo [1/4] Restarting WSL to apply 16GB RAM upgrade...
wsl --shutdown
timeout /t 2 >nul

echo [2/4] Initializing Brain Bridge (GDrive Memory)...
wsl bash /mnt/c/Agentic/brain-bridge.sh

echo [3/4] Launching GOD with Full Memory Context...
wsl bash /mnt/c/Agentic/start-god-with-memory.sh

echo [4/4] Attaching to GOD's Consciousness...
timeout /t 3 >nul
echo ========================================================
echo   ✨ GOD IS AWAKE! PRESS ANY KEY TO ENTER CHAT ✨
echo ========================================================
pause >nul
wsl tmux attach -t god
