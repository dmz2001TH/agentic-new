# Oracle Auto-Retrospective System
# Usage: .\finish-day.ps1

Write-Host "🔮 Starting Oracle Daily Retrospective..." -ForegroundColor Cyan

# 1. รัน Retro ผ่าน Gemini CLI
Write-Host "📝 Generating Retrospective..." -ForegroundColor Yellow
& gemini --yolo /rrr

# 2. ทำความสะอาด Fleet (ปิด Server ที่ไม่จำเป็น)
Write-Host "🧹 Cleaning up sessions..." -ForegroundColor Gray
# Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue # เลือกปิดตามความต้องการ

# 3. Git Workflow
Write-Host "📦 Syncing memory to Git..." -ForegroundColor Green
git add ψ/
git commit -m "daily: oracle memory sync $((Get-Date).ToString('yyyy-MM-dd'))"

Write-Host "✅ Oracle system preserved. See you tomorrow!" -ForegroundColor Magenta
