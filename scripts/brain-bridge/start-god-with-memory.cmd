@echo off
REM ══════════════════════════════════════════════════════════
REM start-god-with-memory.cmd — เริ่ม GOD พร้อมความจำ
REM ══════════════════════════════════════════════════════════

title GOD - Starting with Memory...

echo [1/3] Running Brain Bridge...
call "%~dp0brain-bridge.cmd"

echo.
echo [2/3] Loading memory context...

REM Read memory context into variable
set "MEMORY_CONTEXT="
if exist "C:\Agentic\ψ\_memory_context.md" (
    set "MEMORY_CONTEXT=C:\Agentic\ψ\_memory_context.md"
    echo [OK] Memory context loaded
) else (
    echo [WARN] No memory context found - starting fresh
)

echo.
echo [3/3] Starting GOD...

REM Kill old tmux session
tmux kill-session -t god 2>nul

REM Start new tmux session with Gemini
start "GOD Agent" cmd /c "tmux new-session -s god 'gemini --yolo'"

echo.
echo Waiting for Gemini to start...
timeout /t 5 /nobreak >nul

REM Inject identity as first message
if defined MEMORY_CONTEXT (
    echo Injecting memory into GOD session...
    
    REM Send identity first
    tmux send-keys -t god "คุณคือ GOD — ผู้สร้างแห่ง Oracle World. ชื่อคุณคือ GOD เท่านั้น ห้ามเรียกตัวเองว่า Oracle. ผู้ใช้ชื่อพีช. ความจำอยู่ที่ C:\Agentic\ψ. ตอนนี้กำลังโหลดความจำ..." C-m
    
    timeout /t 2 /nobreak >nul
    
    REM Send memory content
    for /f "usebackq delims=" %%a in ("C:\Agentic\ψ\_memory_context.md") do (
        tmux send-keys -t god "%%a" C-m
    )
    
    echo [OK] Memory injected into GOD
)

echo.
echo ═══════════════════════════════════════════════
echo   🚀 GOD is running with memory!
echo ═══════════════════════════════════════════════
echo.
echo Attach: tmux attach -t god
echo Dashboard: http://localhost:3456
echo.
pause
