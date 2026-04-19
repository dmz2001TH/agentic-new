@echo off
title Oracle System Starter
echo --------------------------------------------------
echo [1/2] Starting Maw Server (Dashboard) in WSL...
start "Oracle Server" wsl bash -c "cd /mnt/c/Agentic/maw-js && /home/phasa/.bun/bin/bun src/cli.ts serve"

echo Waiting for server to initialize...
timeout /t 3 /nobreak

echo [2/2] Starting Agents (GOD) in WSL...
start "Oracle Agents" wsl bash -c "cd /mnt/c/Agentic && bash scripts/ensure-agents.sh && echo. && echo --- Active Agents --- && tmux ls && echo. && echo You can close this window now, or type 'tmux a' to see the agent. && sleep 10"

echo --------------------------------------------------
echo [SUCCESS] Everything is starting up!
echo Dashboard: http://localhost:3456
echo --------------------------------------------------
timeout /t 5
