#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════
# oracle-tools.test.sh — Verification for Oracle Tools
# ═══════════════════════════════════════════════════════════
set -euo pipefail

# Determine script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ORACLE_TOOLS="$PROJECT_ROOT/scripts/oracle-tools.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🧪 Running Oracle Tools Tests..."

# Check if script exists
if [ ! -f "$ORACLE_TOOLS" ]; then
    echo "❌ oracle-tools.sh not found at $ORACLE_TOOLS"
    exit 1
fi

# Source the tools to test functions directly
source "$ORACLE_TOOLS"

# --- Test: ot-pre-flight ---
test_pre_flight() {
    echo "Testing: ot-pre-flight"
    
    # Create temp directory for testing memory files
    local TEST_PSI_DIR=$(mktemp -d)
    mkdir -p "$TEST_PSI_DIR/memory"
    
    # Override PSI_DIR for testing
    local ORIGINAL_PSI_DIR="$PSI_DIR"
    PSI_DIR="$TEST_PSI_DIR"
    
    # 1. Create dummy files
    cat <<EOF > "$PSI_DIR/memory/mistakes.md"
# Mistake Memory
### [M-001] Test Mistake
- **วิธีป้องกัน**: Rule 1 for testing
- **วิธีป้องกัน**: Rule 2 for testing
EOF

    cat <<EOF > "$PSI_DIR/memory/patterns.md"
# Patterns
- **การกระทำ**: Action 1 for testing
- **การกระทำ**: Action 2 for testing
EOF

    # 2. Run pre-flight and capture output
    local OUTPUT=$(ot-pre-flight)
    
    # 3. Verify output
    if echo "$OUTPUT" | grep -q "Rule 2 for testing" && \
       echo "$OUTPUT" | grep -q "Action 2 for testing"; then
        echo -e "${GREEN}✓ ot-pre-flight passed${NC}"
    else
        echo -e "${RED}❌ ot-pre-flight failed output verification${NC}"
        echo "Output was:"
        echo "$OUTPUT"
        
        # Log mistake if it fails
        PSI_DIR="$ORIGINAL_PSI_DIR" # Restore to log mistake in real memory
        ot-record-mistake "T-001" "ot-pre-flight output mismatch" "Test logic failed to find expected strings" "Ensure grep and sed in ot-pre-flight handle formatting correctly"
        
        exit 1
    fi
    
    # Restore original PSI_DIR and cleanup
    PSI_DIR="$ORIGINAL_PSI_DIR"
    rm -rf "$TEST_PSI_DIR"
}

# --- Test: ot-record-mistake ---
test_record_mistake() {
    echo "Testing: ot-record-mistake"
    
    local TEST_PSI_DIR=$(mktemp -d)
    mkdir -p "$TEST_PSI_DIR/memory"
    
    local ORIGINAL_PSI_DIR="$PSI_DIR"
    PSI_DIR="$TEST_PSI_DIR"
    
    # 1. Record a mistake
    ot-record-mistake "M-TEST" "Test Title" "Test Cause" "Test Prevention"
    
    # 2. Verify it's in the file
    if [ -f "$PSI_DIR/memory/mistakes.md" ] && \
       grep -q "\[M-TEST\] Test Title" "$PSI_DIR/memory/mistakes.md" && \
       grep -q "Test Cause" "$PSI_DIR/memory/mistakes.md" && \
       grep -q "Test Prevention" "$PSI_DIR/memory/mistakes.md"; then
        echo -e "${GREEN}✓ ot-record-mistake passed${NC}"
    else
        echo -e "${RED}❌ ot-record-mistake failed verification${NC}"
        PSI_DIR="$ORIGINAL_PSI_DIR"
        exit 1
    fi
    
    PSI_DIR="$ORIGINAL_PSI_DIR"
    rm -rf "$TEST_PSI_DIR"
}

# Run tests
test_pre_flight
test_record_mistake

echo -e "${GREEN}✨ All tests passed!${NC}"
