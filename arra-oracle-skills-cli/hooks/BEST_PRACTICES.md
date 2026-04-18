# Hook Best Practices (#231)

> Pitfalls learned from building safety-check.sh and session-start.sh.

## JSON Input Handling

Hooks receive JSON via stdin. Common pitfalls:

### 1. Always use fallback defaults

```bash
# ✅ Good — fallback to empty string
CMD=$(jq -r '.tool_input.command // ""' 2>/dev/null)

# ❌ Bad — no fallback, returns "null" string on missing field
CMD=$(jq -r '.tool_input.command' 2>/dev/null)
```

### 2. Use explicit jq path

```bash
# ✅ Good — explicit path, works on all systems
CWD=$(echo "$INPUT" | /usr/bin/jq -r '.cwd // ""' 2>/dev/null)

# ❌ Bad — relies on PATH, breaks in restricted environments
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
```

### 3. Don't mask errors during development

```bash
# ✅ Development — see errors
CMD=$(jq -r '.tool_input.command // ""')

# ✅ Production — suppress errors, fail silently
CMD=$(jq -r '.tool_input.command // ""' 2>/dev/null)

# ❌ Always suppressing — you'll never find bugs
```

### 4. Read stdin once

```bash
# ✅ Good — read once, use many times
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# ❌ Bad — stdin is consumed on first read
CMD=$(jq -r '.tool_input.command // ""')       # works
FILE=$(jq -r '.tool_input.file_path // ""')     # EMPTY — stdin already consumed
```

### 5. Handle pipe failures

```bash
# ✅ Good — check exit code
if ! CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null); then
  exit 0  # Don't block on parse failure
fi

# ❌ Bad — pipe failure silently produces empty string
CMD=$(gh issue list | jq 'length' 2>/dev/null || echo "?")
# If gh fails mid-output, jq gets malformed JSON
```

## Hook Output

### JSON output format

Hooks can return JSON to control behavior:

```json
{
  "continue": true,
  "systemMessage": "Warning shown to user"
}
```

Common pitfall: outputting non-JSON text before the JSON object:

```bash
# ❌ Bad — echo before JSON breaks parsing
echo "checking..."
echo '{"continue": true}'

# ✅ Good — only JSON on stdout
echo '{"continue": true}' 
# Use stderr for debug: echo "checking..." >&2
```

## Testing Hooks

Always test with realistic input:

```bash
# PreToolUse on Bash
echo '{"tool_name":"Bash","tool_input":{"command":"git status"}}' | ./safety-check.sh
echo "Exit: $?"

# PreToolUse on Write
echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.md","content":"hello"}}' | ./my-hook.sh

# PostToolUse (includes tool_response)
echo '{"tool_name":"Edit","tool_input":{"file_path":"src/main.ts"},"tool_response":{"success":true}}' | ./post-hook.sh
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `set -euo pipefail` in hook | Causes exit before JSON output on pipe failure — remove or handle |
| Blocking on `gh` commands | Add timeout: `timeout 5 gh issue list` |
| Matching too broadly | `grep 'rm'` matches "format" — use `grep -E '(^|\s)rm\s'` |
| Not testing exit codes | Hook exit 0 = allow, exit 2 = block. Test both paths. |
| Writing to files in hook | Hooks run in restricted context — use stdout/stderr only |

## Reference

| Exit Code | Meaning |
|-----------|---------|
| 0 | Allow (hook passed) |
| 1 | Error (hook failed — tool still runs) |
| 2 | Block (explicitly deny the action) |

See also: `safety-check.sh` and `session-start.sh` in this directory for working examples.
