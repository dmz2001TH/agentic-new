# Gemini CLI wrapper with YOLO mode enabled
# Usage: .\gemini-yolo.ps1 [arguments]

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

& gemini --yolo $args
