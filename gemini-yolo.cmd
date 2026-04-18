@echo off
REM Gemini CLI wrapper with YOLO mode enabled
REM Usage: gemini-yolo [arguments]

cd /d "%~dp0"
gemini --yolo %*
