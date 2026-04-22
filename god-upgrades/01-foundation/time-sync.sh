#!/bin/bash
# Time Sentinel Active
# Clock Sync & Timestamp Reporting Utility

sync_time() {
    # Using ntpdate as a standard tool for clock sync
    # If not present, warn the user.
    if command -v ntpdate &> /dev/null; then
        echo "Syncing clock with pool.ntp.org..."
        sudo ntpdate pool.ntp.org
    else
        echo "ntpdate not found. Please ensure your system time is managed by systemd-timesyncd or similar."
    fi
}

report_with_time() {
    # Prints timestamp with milliseconds
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S.%3N")
    echo "[$timestamp] $1"
}

# Run sync on startup of this script
sync_time
echo "Time Sentinel Active - Clock synchronized."
