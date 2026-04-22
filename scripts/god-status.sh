#!/bin/bash
START_TIME=$(date +%s)
while true; do
  ELAPSED=$(( $(date +%s) - START_TIME ))
  MIN=$(( ELAPSED / 60 ))
  SEC=$(( ELAPSED % 60 ))
  printf "\r 🧠 god · %s [%02d:%02d]" "$1" "$MIN" "$SEC"
  sleep 1
done
