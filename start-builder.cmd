@echo off
title Awakening Agent: Builder
color 0E

echo ========================================================
echo        AWAKENING AGENT: Builder (Coding Specialist)
echo ========================================================
echo.
echo Checking if Builder is already awake...

tmux has-session -t mawjs-builder >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Builder is already awake!
    echo To talk to Builder, open tmux: tmux attach -t mawjs-builder
    echo.
    pause
    exit /b
)

echo [STARTING] Creating a new Tmux session for Builder...
start "Agent Builder (Do not close)" cmd /c "title Agent Builder && color 0E && tmux new-session -s mawjs-builder 'bash .gemini/launch-agent.sh builder'"

echo.
echo ========================================================
echo   BUILDER IS NOW ONLINE!
echo ========================================================
echo 1. Builder is running in tmux session "mawjs-builder"
echo 2. GOD can delegate tasks via: send_to_agent builder "..."
echo.
echo Note: A new window will pop up. You can minimize it.
echo ========================================================
pause
