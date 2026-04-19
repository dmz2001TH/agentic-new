@echo off
title Awakening Agent: Nexus
color 0B

echo ========================================================
echo        AWAKENING AGENT: NEXUS (The Memory Coordinator)
echo ========================================================
echo.
echo Checking if Nexus is already awake...

tmux has-session -t nexus >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Nexus is already awake and waiting for commands!
    echo To talk to Nexus, open the Dashboard: http://localhost:5173
    echo Or open a new terminal and type: tmux attach -t nexus
    echo.
    pause
    exit /b
)

echo [STARTING] Creating a new Tmux session for Nexus...
start "Agent Nexus (Do not close)" cmd /c "title Agent Nexus (Running in Tmux) && color 09 && echo Agent Nexus is now running... && tmux new-session -s nexus ""gemini --yolo"""

echo.
echo ========================================================
echo   NEXUS IS NOW ONLINE!
echo ========================================================
echo 1. You can now chat with Nexus on the Dashboard!
echo 2. Go to: http://localhost:5173
echo 3. Click on "nexus" in the Fleet menu and type your command.
echo.
echo Note: A new window will pop up for Nexus. You can minimize it.
echo ========================================================
pause
