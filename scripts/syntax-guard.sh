#!/bin/bash
# 🧪 GOD SYNTAX GUARD (Safety Gate)
# ---------------------------------
# Verify script integrity before applying changes to core system.

FILE=$1
EXT="${FILE##*.}"

if [ ! -f "$FILE" ]; then
    echo "❌ File not found."
    exit 1
fi

echo "🔍 [Guard]: Verifying $FILE..."

case "$EXT" in
    sh)
        # Check bash syntax
        bash -n "$FILE" && echo "✅ Bash Syntax OK" || exit 1
        ;;
    py)
        # Check python syntax
        python3 -m py_compile "$FILE" && echo "✅ Python Syntax OK" || exit 1
        ;;
    json|toml)
        # Check JSON/TOML (Requires jq/toml)
        jq . "$FILE" > /dev/null 2>&1 && echo "✅ JSON/TOML OK" || exit 1
        ;;
    *)
        echo "⚠️ Unknown extension, skipping deep check."
        ;;
esac

exit 0
