#!/bin/bash
# Oracle Fleet Manager (อ้างอิงจาก Tmux/Zellij Workspace Pattern)
# จัดการเอเจนท์ที่ทำงานอยู่เบื้องหลัง

COMMAND="${1:-status}"
AGENT_NAME="${2:-unknown}"

case "$COMMAND" in
  spawn)
    if [ -z "$2" ]; then echo "Usage: fleet-manager.sh spawn <agent_name>"; exit 1; fi
    # ตรวจสอบว่ามี session อยู่แล้วหรือไม่
    if tmux has-session -t "oracle-$AGENT_NAME" 2>/dev/null; then
      echo "Agent '$AGENT_NAME' is already running."
    else
      # สร้าง session ใหม่แบบ background (-d)
      tmux new-session -d -s "oracle-$AGENT_NAME" "echo 'Agent $AGENT_NAME active'; sleep infinity"
      echo "✅ Spawned Agent: $AGENT_NAME"
    fi
    ;;
  kill)
    if [ -z "$2" ]; then echo "Usage: fleet-manager.sh kill <agent_name>"; exit 1; fi
    if tmux has-session -t "oracle-$AGENT_NAME" 2>/dev/null; then
      tmux kill-session -t "oracle-$AGENT_NAME"
      echo "🛑 Killed Agent: $AGENT_NAME"
    else
      echo "Agent '$AGENT_NAME' is not running."
    fi
    ;;
  status)
    echo "📡 Oracle Fleet Status:"
    # แสดงเฉพาะ session ที่ขึ้นต้นด้วย oracle-
    tmux ls 2>/dev/null | grep "^oracle-" || echo "  (No agents running in background)"
    ;;
  *)
    echo "Usage: fleet-manager.sh {spawn|kill|status} [agent_name]"
    ;;
esac
