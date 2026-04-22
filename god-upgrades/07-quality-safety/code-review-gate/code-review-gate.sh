#!/bin/bash
# Code Review Gate — ไม่ให้ push จนกว่า critic approve
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

gate_check() {
    local dir="${1:-.}"
    echo -e "${CYAN}🔍 Pre-push Gate Check${NC}\n"
    local critical=0
    
    # Check for hardcoded secrets
    if grep -rP '(password|secret|token|api_key)\s*=\s*['\''"][^'\''"]+['\''"]' "$dir" --include="*.sh" --include="*.py" --include="*.js" --include="*.json" 2>/dev/null | grep -v node_modules | head -5; then
        echo -e "${RED}🔴 Hardcoded secrets found!${NC}"
        critical=$((critical+1))
    fi
    
    # Check syntax
    for f in $(find "$dir" -name "*.sh" -not -path "*/.git/*" 2>/dev/null | head -20); do
        if ! bash -n "$f" 2>/dev/null; then
            echo -e "${RED}🔴 Syntax error: ${f}${NC}"
            critical=$((critical+1))
        fi
    done
    
    if [ "$critical" -eq 0 ]; then
        echo -e "${GREEN}✅ Gate check passed — safe to push${NC}"
        return 0
    else
        echo -e "${RED}❌ Gate check failed — ${critical} critical issues${NC}"
        return 1
    fi
}
case "${1:-}" in --check) gate_check "$2";; *) echo "Usage: code-review-gate.sh [--check 'dir']";; esac
