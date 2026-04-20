@echo off
echo [GOD] Initializing Awakening Sequence...
call "%~dp0start-oracle-system.cmd"
call "%~dp0.gemini\launch-agent.sh" GOD
echo [GOD] System Awake. Fleet Status Check Required.
pause
