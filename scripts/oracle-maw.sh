#!/bin/bash
# Oracle MAW (Multi-Agent Workflow) - Clarity Trilogy Implementation
# อ้างอิงสถาปัตยกรรมจาก neo-oracle/Clarity-Trilogy

VAULT_TEAMS_DIR="/mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ/memory/mailbox/teams"
mkdir -p "$VAULT_TEAMS_DIR"

command=$1
team_name=$2

case "$command" in
  spawn)
    if [ -z "$team_name" ]; then echo "Usage: maw spawn <team_name> <mission>"; exit 1; fi
    mission="${3:-Exploring Oracle World}"
    
    # 1. สร้าง Manifest (JSON)
    cat > "$VAULT_TEAMS_DIR/$team_name-manifest.json" <<EOF
{
  "teamName": "$team_name",
  "mission": "$mission",
  "spawnedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "status": "active"
}
EOF

    # 2. สร้าง Spawn Prompt (Markdown) - นี่คือจิตวิญญาณของทีม
    cat > "$VAULT_TEAMS_DIR/$team_name-spawn-prompt.md" <<EOF
# Team: $team_name
## Mission: $mission

คุณคือทีมเอเจนท์เฉพาะทางที่ถูกสร้างขึ้นเพื่อปฏิบัติภารกิจ: "$mission"

## กฎการทำงานอัตโนมัติ (Autonomous YOLO Mode)
1. **ห้ามหยุดรอคำสั่งจากมนุษย์:** คุณต้องคิด วางแผน และลงมือทำจนกว่างานจะเสร็จสมบูรณ์ 100%
2. **ทำงานร่วมกับทีม:** ถ้างานคุณต้องรอคนอื่น ให้เขียนข้อความทิ้งไว้ใน Inbox ของเพื่อนร่วมทีม
3. **การส่งงาน:** เมื่อเสร็จสิ้น ให้สรุปผลลงใน ψ/memory/mailbox/$team_name/outbox.md
4. **ลงมือทำทันที:** เริ่มต้นด้วยการอ่านไฟล์ที่เกี่ยวข้อง และเขียนโค้ด/สร้างไฟล์ได้เลย

ลุยเลย!
EOF
    echo "✨ [Oracle MAW] ทีม '$team_name' ถูกจารึกลงใน Vault แล้ว พร้อมลุยภารกิจ '$mission'"
    ;;

  resume)
    if [ -z "$team_name" ]; then echo "Usage: maw resume <team_name>"; exit 1; fi
    
    if [ ! -f "$VAULT_TEAMS_DIR/$team_name-manifest.json" ]; then
      echo "❌ ไม่พบทีม '$team_name' ใน Vault"
      exit 1
    fi
    
    echo "🌀 [Oracle MAW] กำลังส่งเอเจนท์ทีม '$team_name' เข้าประจำการที่แนวรบด้านขวา..."
    
    if [ -n "$TMUX" ]; then
      # 1. สร้าง Pane ใหม่
      tmux split-window -h -d "bash .gemini/launch-agent.sh '$team_name' '$VAULT_TEAMS_DIR/$team_name-spawn-prompt.md'"
      
      # 2. ตั้งชื่อ Pane ให้เห็นชัดเจนว่าเป็น Agent ตัวไหน
      # ดึง ID ของ Pane ที่เพิ่งสร้างล่าสุด
      LAST_PANE=$(tmux display-message -p -t ! '#{pane_id}')
      tmux set-option -p -t "$LAST_PANE" pane-border-status top
      tmux select-pane -T "🤖 $team_name" -t "$LAST_PANE"
      
      # 3. จัด Layout ใหม่ให้เป็น "หน้าต่างหลักซ้าย - ลูกทีมเรียงขวา"
      tmux select-layout main-vertical
      tmux set-window-option main-pane-width 65%
      tmux select-layout main-vertical
      
      echo "✅ เอเจนท์ทีม '$team_name' ประจำที่แล้ว!"
    else
      echo "⚠️ คุณไม่ได้อยู่ใน Tmux! ขอเปิดหน้าต่างใหม่แทน..."
      tmux new-window -n "team-$team_name" "bash .gemini/launch-agent.sh '$team_name' '$VAULT_TEAMS_DIR/$team_name-spawn-prompt.md'"
    fi
    ;;

  stop)
    if [ -z "$team_name" ]; then echo "Usage: maw stop <team_name>"; exit 1; fi
    echo "🛑 [Oracle MAW] กำลังสั่งปิดการทำงานของทีม '$team_name'..."
    
    if [ -n "$TMUX" ]; then
      # หา pane id ที่มีชื่อตรงกับทีม แล้วสั่งปิด
      PANE_ID=$(tmux list-panes -a -F "#{pane_id} #{pane_title}" | grep "🤖 $team_name" | awk '{print $1}' | head -n 1)
      if [ -n "$PANE_ID" ]; then
        tmux kill-pane -t "$PANE_ID"
        tmux select-layout main-vertical
        echo "✅ ปิดแท็บของทีม '$team_name' เรียบร้อยแล้ว"
      else
        echo "⚠️ ไม่พบแท็บของทีม '$team_name' ที่กำลังทำงานอยู่"
      fi
    else
      echo "⚠️ คุณไม่ได้อยู่ใน Tmux!"
    fi
    ;;

  *)
    echo "Usage: maw {spawn|resume|stop} <team_name> [mission]"
    ;;
esac
