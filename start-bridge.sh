#!/bin/bash
export PATH="/home/phasa/.bun/bin:$PATH"
while true; do
  echo "Starting Oracle Bridge Server..."
  bun run scripts/bridge-server.ts
  echo "Server crashed. Restarting in 2 seconds..."
  sleep 2
done
