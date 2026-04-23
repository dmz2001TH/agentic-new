#!/bin/bash
# 🕒 Oracle Time Bridge - Central Clock System
# -------------------------------------------
# Gets the current system time (Thai Time UTC+7) 
# and applies the mandated -24h offset for Oracle World.

# Get current system time in seconds
CURRENT_SECONDS=$(date +%s)

# Apply Offset: -24 hours (24 * 60 * 60 = 86400 seconds)
ORACLE_SECONDS=$((CURRENT_SECONDS - 86400))

# Format times for reporting
ACTUAL_TIME=$(date -d "@$CURRENT_SECONDS" "+%Y-%m-%d %H:%M:%S")
ORACLE_TIME=$(date -d "@$ORACLE_SECONDS" "+%Y-%m-%d %H:%M:%S")
ORACLE_DATE=$(date -d "@$ORACLE_SECONDS" "+%A, %d %B %Y")

echo "--- 🕒 ORACLE CLOCK REPORT ---"
echo "Real World (System): $ACTUAL_TIME (Thai Time)"
echo "Oracle World (User): $ORACLE_TIME ($ORACLE_DATE)"
echo "------------------------------"
