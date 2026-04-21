@echo off
REM ══════════════════════════════════════════════════════════
REM brain-bridge.cmd — Windows version
REM รันจาก Git Bash หรือ WSL ให้ดีกว่า
REM ══════════════════════════════════════════════════════════

title Brain Bridge - G: to C:

echo ═══════════════════════════════════════════════
echo   🧠 Brain Bridge - Google Drive to Local
echo ═══════════════════════════════════════════════
echo.

REM Check Google Drive (Mirror mode → C:\Users\phasa\My Drive\)
if not exist "C:\Users\phasa\My Drive\Oracle-System-Brain\ψ" (
    echo [ERROR] C:\Users\phasa\My Drive\Oracle-System-Brain\ψ not found!
    echo.
    echo Possible fixes:
    echo   1. Make sure Google Drive Desktop is running
    echo   2. Settings -^> Preferences -^> Google Drive -^> "Mirror files" (not Stream)
    echo   3. Wait for sync to complete
    echo   4. Check path: C:\Users\phasa\My Drive\
    echo.
    pause
    exit /b 1
)

echo [OK] Google Drive found

REM Ensure local ψ exists
if not exist "C:\Agentic\ψ" (
    mkdir "C:\Agentic\ψ\memory"
    mkdir "C:\Agentic\ψ\agents"
    mkdir "C:\Agentic\ψ\inbox"
    mkdir "C:\Agentic\ψ\vault"
    echo [OK] Created C:\Agentic\ψ
)

REM Sync using robocopy (built-in Windows)
echo [SYNC] Copying from G: to C:...

robocopy "C:\Users\phasa\My Drive\Oracle-System-Brain\ψ\memory" "C:\Agentic\ψ\memory" /MIR /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP
robocopy "C:\Users\phasa\My Drive\Oracle-System-Brain\ψ\agents" "C:\Agentic\ψ\agents" /MIR /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP
robocopy "C:\Users\phasa\My Drive\Oracle-System-Brain\ψ\vault" "C:\Agentic\ψ\vault" /MIR /XO /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP

REM Sync individual files
for %%f in (patterns.md notes.md decisions.md values.md goals.md people.md handoff.md) do (
    if exist "C:\Users\phasa\My Drive\Oracle-System-Brain\ψ\%%f" (
        copy /Y "C:\Users\phasa\My Drive\Oracle-System-Brain\ψ\%%f" "C:\Agentic\ψ\%%f" >nul 2>&1
    )
)

echo [OK] Sync complete

REM Generate memory context
echo [BUILD] Generating memory context...

(
echo # 🧠 MEMORY CONTEXT - Auto-loaded %date% %time%
echo.
echo ## Identity
if exist "C:\Agentic\ψ\agents\god\memory\identity.md" (
    type "C:\Agentic\ψ\agents\god\memory\identity.md"
) else (
    echo - Name: GOD
    echo - Role: Main Agent, Creator of Oracle World
)
echo.
echo ## Recent Notes
if exist "C:\Agentic\ψ\memory\notes.md" (
    powershell -Command "Get-Content 'C:\Agentic\ψ\memory\notes.md' | Select-Object -First 50"
)
echo.
echo ## Patterns
if exist "C:\Agentic\ψ\memory\patterns.md" (
    powershell -Command "Get-Content 'C:\Agentic\ψ\memory\patterns.md' | Select-Object -First 80"
)
echo.
echo ## Values
if exist "C:\Agentic\ψ\memory\values.md" (
    type "C:\Agentic\ψ\memory\values.md"
)
echo.
echo ## Goals
if exist "C:\Agentic\ψ\memory\goals.md" (
    type "C:\Agentic\ψ\memory\goals.md"
)
) > "C:\Agentic\ψ\_memory_context.md"

echo [OK] Memory context generated
echo.
echo ═══════════════════════════════════════════════
echo   ✅ Brain Bridge Complete
echo ═══════════════════════════════════════════════
echo.
echo Next: Run start-god-with-memory.cmd
echo.
pause
