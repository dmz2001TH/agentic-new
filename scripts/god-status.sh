#!/bin/bash
echo -ne "\r 🧠 GOD ACTIVE: $1 | Task: $2 | Time: $(date +%M:%S) | System: $(ps -o %cpu,%mem -p $$ | tail -1)"
