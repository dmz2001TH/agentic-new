@echo off
title Oracle v3 - System Startup
color 0B

echo ========================================================
echo        ORACLE v3 - TOTAL IGNITION SEQUENCE
echo ========================================================
echo.

echo [1/5] Cleaning up old processes and zombie ports...
taskkill /F /IM bun.exe /T >nul 2>&1
timeout /t 2 >nul

echo [2/5] Starting Oracle Core Memory (Port 47778)...
start "Oracle Core Memory (47778)" cmd /c "cd /d %~dp0\arra-oracle-v3 && title Oracle Core Memory (47778) && color 0A && echo Starting Oracle Core... && bun src\server.ts"

echo [3/5] Starting Maw API Server (Port 3456)...
start "Maw API Server (3456)" cmd /c "cd /d %~dp0\maw-js && title Maw API Server (3456) && color 0D && echo Starting Maw API Server... && bun server.ts"

echo [4/5] Starting Frontend Dashboard (Port 5173)...
start "Frontend Dashboard (5173)" cmd /c "cd /d %~dp0\arra-oracle-v3\frontend && title Frontend Dashboard (5173) && color 0E && echo Starting Frontend UI... && bun run dev --port 5173 --host localhost"

echo [5/5] Awakening GOD agent...
echo Waiting for servers to initialize...
timeout /t 5 /nobreak >nul

REM Kill old GOD session if exists
tmux kill-session -t god >nul 2>&1

REM Create GOD tmux session with gemini --yolo (auto-start)
start "Agent GOD (Do not close)" cmd /c "title Agent GOD && color 09 && tmux new-session -s god 'gemini --yolo'"

echo.
echo ========================================================
echo   ALL SYSTEMS GO! (GOD is Awakened)
echo ========================================================
echo.
echo 1. Wait 5-10 seconds for all servers to load.
echo 2. Open your browser:
echo.
echo    Dashboard: http://localhost:5173
echo    Maw UI:    http://localhost:3456
echo.
echo 3. GOD is running in tmux session "god"
echo    Dashboard > Fleet > god to chat
echo.
echo To stop everything:
echo    taskkill /F /IM bun.exe /T
echo    tmux kill-server
echo ========================================================
pause
