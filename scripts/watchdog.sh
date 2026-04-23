#!/bin/bash
# 🛡️ GOD RESOURCE WATCHDOG v1.0
# -----------------------------
# Monitor system resources and protect the session from OOM kills.

THRESHOLD_RAM=90
THRESHOLD_CPU=95

echo "🐕 [Watchdog]: Active. Protecting GOD session..."

while true; do
    # 1. Check RAM usage
    RAM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)
    
    # 2. Check CPU usage (Load Average)
    CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | cut -d. -f1 | tr -d ' ')

    if [ "$RAM_USAGE" -gt "$THRESHOLD_RAM" ]; then
        echo "⚠️ [Watchdog]: CRITICAL RAM USAGE ($RAM_USAGE%). Taking action!"
        # Kill the most resource-heavy process EXCEPT tmux/gemini
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | grep -vE "tmux|gemini|watchdog" | head -n 2 | awk '{print $1}' | xargs kill -9
    fi

    if [ "$CPU_LOAD" -gt 10 ]; then
        echo "⚠️ [Watchdog]: HIGH CPU LOAD ($CPU_LOAD). Throttling..."
        # Optional: Add sleep or lower process priority
    fi

    sleep 10
done
