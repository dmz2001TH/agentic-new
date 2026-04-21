#!/usr/bin/env bash
SESSION="oracle-fleet"
tmux new-session -d -s $SESSION -n "architect" -c "$PWD/agents/architect"
tmux split-window -h -t $SESSION
tmux split-window -h -t $SESSION
tmux split-window -h -t $SESSION
tmux send-keys -t $SESSION:0.0 "export CLAUDE_AGENT_NAME=architect && bash .gemini/launch-agent.sh architect" C-m
tmux select-layout -t $SESSION tiled
tmux attach -t $SESSION
