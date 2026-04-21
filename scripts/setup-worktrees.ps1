# เตรียมโฟลเดอร์เอเจนท์
$agents = @("architect", "pos-orders", "menu-inventory", "staff-hr", "dashboard")
foreach ($agent in $agents) {
    New-Item -Path "agents/$agent/.claude/hooks" -ItemType Directory -Force
    Copy-Item -Path ".claude/hooks/policy-engine.sh" -Destination "agents/$agent/.claude/hooks/"
    git worktree add "agents/$agent" main
}
