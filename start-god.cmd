@echo off
title Awakening Agent: GOD
color 0B

echo ========================================================
echo        AWAKENING AGENT: GOD (The Creator)
echo ========================================================
echo.
echo Checking if GOD is already awake...

tmux has-session -t god >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] GOD is already awake and waiting for commands!
    echo To talk to GOD, open the Dashboard: http://localhost:5173
    echo Or open a new terminal and type: tmux attach -t god
    echo.
    pause
    exit /b
)

echo [STARTING] Creating a new Tmux session for GOD...
start "Agent GOD (Do not close)" cmd /c "title Agent GOD (Running in Tmux) && color 09 && tmux new-session -s god 'gemini --yolo'"

echo.
echo ========================================================
echo   GOD IS NOW ONLINE!
echo ========================================================
echo 1. You can now chat with GOD on the Dashboard!
echo 2. Go to: http://localhost:5173
echo 3. Click on "god" in the Fleet menu and type your command.
echo.
echo Note: A new window will pop up for GOD. You can minimize it.
echo ========================================================
pause
