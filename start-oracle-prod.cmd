@echo off
title Oracle v3 - Production Startup (Auto-Restart)
color 0B

echo ========================================================
echo        ORACLE v3 - PRODUCTION MODE (Auto-Restart)
echo ========================================================
echo.

echo [1/4] Cleaning up old processes...
taskkill /F /IM bun.exe /T >nul 2>&1
timeout /t 2 >nul

echo [2/4] Starting Oracle Core Memory (Port 47778)...
start "Oracle Core [auto-restart]" cmd /c "cd /d %~dp0 && bash scripts/run-with-restart.sh oracle-core ""cd arra-oracle-v3 && bun src/server.ts"" 10 5"

echo [3/4] Starting Maw API Server (Port 3456)...
timeout /t 3 /nobreak >nul
start "Maw API [auto-restart]" cmd /c "cd /d %~dp0 && bash scripts/run-with-restart.sh maw-api ""cd maw-js && bun server.ts"" 10 5"

echo [4/4] Starting Frontend Dashboard (Port 5173)...
timeout /t 3 /nobreak >nul
start "Frontend [auto-restart]" cmd /c "cd /d %~dp0 && bash scripts/run-with-restart.sh frontend ""cd arra-oracle-v3/frontend && bun run dev --port 5173 --host localhost"" 10 5"

echo.
echo Waiting for servers to initialize...
timeout /t 8 /nobreak >nul

echo [5/5] Awakening GOD agent...
tmux kill-session -t god >nul 2>&1
start "Agent GOD (Do not close)" cmd /c "tmux new-session -s god 'gemini --yolo'"

echo.
echo ========================================================
echo   PRODUCTION MODE ACTIVE (All services auto-restart)
echo ========================================================
echo.
echo Dashboard: http://localhost:5173
echo API:       http://localhost:3456
echo Oracle:    http://localhost:47778
echo.
echo Logs:  ψ/memory/logs/
echo Backup: bash scripts/backup-db.sh
echo.
echo To stop: taskkill /F /IM bun.exe /T
echo          tmux kill-server
echo ========================================================
pause
