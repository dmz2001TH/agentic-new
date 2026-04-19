@echo off
title Oracle v3 - System Startup
color 0B

echo ========================================================
echo        ORACLE v3 - TOTAL IGNITION SEQUENCE
echo ========================================================
echo.

echo [1/4] Cleaning up old processes and zombie ports...
taskkill /F /IM bun.exe /T >nul 2>&1
timeout /t 2 >nul

echo [2/4] Starting Oracle Core Memory (Port 47778)...
start "Oracle Core Memory (47778)" cmd /c "cd /d %~dp0\arra-oracle-v3 && title Oracle Core Memory (47778) && color 0A && echo Starting Oracle Core... && bun src\server.ts"

echo [3/4] Starting Maw API Server (Port 3456)...
start "Maw API Server (3456)" cmd /c "cd /d %~dp0\maw-js && title Maw API Server (3456) && color 0D && echo Starting Maw API Server... && bun server.ts"

echo [4/4] Starting Frontend Dashboard (Port 5173)...
start "Frontend Dashboard (5173)" cmd /c "cd /d %~dp0\arra-oracle-v3\frontend && title Frontend Dashboard (5173) && color 0E && echo Starting Frontend UI... && bun run dev --port 5173 --host 127.0.0.1"

echo.
echo ========================================================
echo   ALL SYSTEMS GO! (The Oracle is Awakened)
echo ========================================================
echo.
echo 1. Please wait 5-10 seconds for all servers to fully load.
echo 2. Open your browser and go to:
echo.
echo    http://127.0.0.1:5173
echo.
echo To stop the servers, close the 3 new command windows.
echo ========================================================
pause
