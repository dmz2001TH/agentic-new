#!/usr/bin/env bash
source scripts/oracle-tools.sh
CONTENT=$(cat ψ/memory/patterns.md)
oracle_learn "Patterns" "$CONTENT" "memory"
