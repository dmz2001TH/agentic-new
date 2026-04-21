#!/usr/bin/env bash
SESSION="oracle-fleet"
# ????? Architect Session
tmux new-session -d -s \ -n "architect" -c "/mnt/c/Agentic/agents/architect"
# ???????????????? Specialist
tmux split-window -h -t \ -p 60
tmux split-window -v -t \.1 -p 75
tmux split-window -v -t \.1 -p 66
tmux split-window -v -t \.1 -p 50

# ???????????? Bypass ?????????????????? (Automatic Selection)
tmux send-keys -t \.0 "bash .gemini/launch-agent.sh architect --model gemini-3-flash-preview" C-m
tmux send-keys -t \.1 "bash .gemini/launch-agent.sh pos-orders --model gemini-3-flash-preview" C-m
tmux send-keys -t \.2 "bash .gemini/launch-agent.sh menu-inventory --model gemini-3-flash-preview" C-m
tmux send-keys -t \.3 "bash .gemini/launch-agent.sh staff-hr --model gemini-3-flash-preview" C-m
tmux send-keys -t \.4 "bash .gemini/launch-agent.sh dashboard --model gemini-3-flash-preview" C-m

tmux attach -t \
