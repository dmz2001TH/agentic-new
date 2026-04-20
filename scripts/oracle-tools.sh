#!/bin/bash

# ═══════════════════════════════════════════════════════════
# ORACLE TOOLS (ACI LAYER) v2.0
# "Verification First — Reading is not verification. Run it."
# ═══════════════════════════════════════════════════════════

# --- Surgical Edit (ACI) ---
ot-edit-surgical() {
    local file=$1
    local old_text=$2
    local new_text=$3
    # Use sed or a specialized script to replace exactly one occurrence
    # For now, a simple sed wrapper (caution: escapes needed for real use)
    sed -i "s/$old_text/$new_text/g" "$file"
    echo "Surgical edit completed on $file"
}

# --- Verification (ACI) ---
ot-verify() {
    echo "--- Starting Verification Loop ---"
    
    # 1. Lint/Type Check
    if [ -f "package.json" ]; then
        echo "Checking TypeScript/Lint..."
        npm run lint || echo "Lint failed (proceeding to tests)"
    fi
    
    # 2. Run Tests
    if [ -f "vitest.config.ts" ] || [ -f "package.json" ]; then
        echo "Running Tests..."
        npm test -- --run || echo "Tests failed!"
    fi
    
    echo "--- Verification Finished ---"
}

# --- Context Summary (ACI) ---
ot-summarize-repo() {
    echo "Summarizing Repository Structure..."
    find . -maxdepth 2 -not -path '*/.*'
}

# --- Read Range (ACI) ---
ot-read-range() {
    local file=$1
    local start=$2
    local end=$3
    if [ -z "$file" ] || [ -z "$start" ] || [ -z "$end" ]; then
        echo "Usage: ot-read-range <file> <start_line> <end_line>"
        return 1
    fi
    if [ ! -f "$file" ]; then
        echo "Error: File $file not found."
        return 1
    fi
    echo "--- Reading $file (Lines $start to $end) ---"
    sed -n "${start},${end}p" "$file"
}

# Add more ACI tools as needed...
case "$1" in
    verify) ot-verify ;;
    edit) ot-edit-surgical "$2" "$3" "$4" ;;
    summary) ot-summarize-repo ;;
    read-range) ot-read-range "$2" "$3" "$4" ;;
    *) echo "Usage: ot {verify|edit|summary|read-range}" ;;
esac
