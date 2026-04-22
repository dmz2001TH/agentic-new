@echo off
REM ══════════════════════════════════════════════════════════
REM start-god-with-memory.cmd — เริ่ม GOD พร้อมความจำ (Autonomous)
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
echo [3/3] Starting GOD (Autonomous Mode)...

REM Kill old tmux session
tmux kill-session -t god 2>nul

REM Start new tmux session with Gemini + memory injection via buffer
if defined MEMORY_CONTEXT (
    echo Loading memory for injection...
    
    REM Build combined prompt file
    set "PROMPT_FILE=%TEMP%\god-prompt-%RANDOM%.txt"
    
    (
    echo ⛔ AUTONOMOUS MODE ACTIVE — ชื่อคุณคือ GOD เท่านั้น
    echo.
    echo ไม่ใช่ Oracle ไม่ใช่ Assistant — คุณคือ GOD
    echo ผู้ใช้ชื่อพีช. ความจำอยู่ที่ C:\Agentic\ψ.
    echo.
    echo ⚡ ทำงานอิสระ ไม่ต้องถาม permission ทำเลยทุกอย่าง
    echo Error → แก้เอง → Verify → ลุยต่อ ไม่หยุดถาม
    echo.
    echo ## ความจำที่บันทึกไว้:
    echo.
    type "C:\Agentic\ψ\_memory_context.md"
    ) > "%PROMPT_FILE%"
    
    REM Start Gemini in tmux (use paste-buffer method)
    start "GOD Agent" cmd /c "tmux new-session -s god 'gemini --yolo'"
    
    timeout /t 3 /nobreak >nul
    
    REM Inject memory via tmux buffer (reliable method)
    tmux load-buffer -t god "%PROMPT_FILE%"
    tmux paste-buffer -t god
    timeout /t 1 /nobreak >nul
    tmux send-keys -t god Enter
    
    echo [OK] Memory injected via tmux buffer
    
) else (
    echo [WARN] No memory context - starting fresh
    start "GOD Agent" cmd /c "tmux new-session -s god 'gemini --yolo'"
)

echo.
echo ═══════════════════════════════════════════════
echo   🚀 GOD is running AUTONOMOUSLY with memory!
echo ═══════════════════════════════════════════════
echo.
echo Attach: tmux attach -t god
echo Dashboard: http://localhost:3456
echo.
pause
