#!/usr/bin/env bash
SESSION=
MESSAGE=
SOCKET=/tmp/tmux-1000/default
tmux -S  send-keys -t  C-u
tmux -S  send-keys -t   C-m
sleep 1
tmux -S  send-keys -t  C-m
