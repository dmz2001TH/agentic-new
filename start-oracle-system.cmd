@echo off
title Oracle System Starter
echo --------------------------------------------------
echo [1/2] Starting Maw Server (Dashboard) in WSL...
start "Oracle Server" wsl bash -c "cd /mnt/c/Agentic/maw-js && /home/phasa/.bun/bin/bun server.ts"

echo Waiting for server to initialize...
timeout /t 3 /nobreak

echo [2/2] Awakening GOD agent in WSL...
start "Agent GOD" wsl bash -c "tmux kill-session -t god 2>/dev/null; tmux new-session -d -s god 'gemini --yolo' && echo GOD is online. Dashboard: http://localhost:3456 && sleep 10"

echo --------------------------------------------------
echo [SUCCESS] Everything is starting up!
echo Dashboard: http://localhost:3456
echo GOD: tmux attach -t god
echo --------------------------------------------------
timeout /t 5
