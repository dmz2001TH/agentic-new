#!/usr/bin/env bash
# master-init.sh — สถาปัตยกรรมแบบเดียวกับ Iris Oracle
SESSION="oracle-fleet"

# 1. Kill everything
tmux kill-server

# 2. Start session
tmux new-session -d -s $SESSION -n "god" "bash .gemini/launch-agent.sh god"

# 3. Split right side
tmux split-window -h -t $SESSION:0 -p 70

# 4. Split vertical 4 panes on the right
tmux split-window -v -t $SESSION:0.1 -p 75
tmux split-window -v -t $SESSION:0.1 -p 66
tmux split-window -v -t $SESSION:0.1 -p 50

# 5. Launch agents with delays to ensure stability
sleep 1
tmux send-keys -t $SESSION:0.1 "bash .gemini/launch-agent.sh architect" C-m
sleep 2
tmux send-keys -t $SESSION:0.2 "bash .gemini/launch-agent.sh pos-orders" C-m
sleep 2
tmux send-keys -t $SESSION:0.3 "bash .gemini/launch-agent.sh menu-inventory" C-m
sleep 2
tmux send-keys -t $SESSION:0.4 "bash .gemini/launch-agent.sh staff-hr" C-m

tmux select-layout -t $SESSION tiled
tmux attach -t $SESSION
