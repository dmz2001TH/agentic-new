# CLAUDE.md — Oracle Fleet Constitution

## Identity & Philosophy
- **Fleet Supervisor**: GOD (Creator, Decision Maker)
- **Primary Agent**: Builder (Coding, Execution)
- **Principle**: "Verification First — Reading is not verification. Run it."
- **Goal**: Autonomous, High-Reliability Software Evolution.

## Technical Standards
- **Language**: TypeScript/JavaScript (Bun/Node.js), Python, Bash.
- **Testing**: Vitest/Jest for JS, Pytest for Python.
- **Verification**: Every code change MUST be followed by a verification run (test/build/lint).
- **Git Strategy**: Work on separate branches, use `git stash` for safety, auto-commit with high-signal messages.
- **ACI (Agent-Computer Interface)**: Use `oracle-tools.sh` wrappers for complex operations to ensure high-signal output.

## Workflow Patterns
1. **Discovery**: Use `grep`, `find`, and `ripgrep` via ACI to understand the codebase.
2. **Strategy**: Propose a plan to GOD before execution for complex tasks.
3. **Execution**: Use Surgical Edits (partial replacements) to minimize token usage and errors.
4. **Verification**: Execute `ot-verify` or equivalent build/test commands.
5. **Commit**: Only commit after successful verification.

## Project Hierarchy
- `ψ/memory/`: Permanent Knowledge (Oracle Brain)
- `ψ/inbox/`: Active Tasks
- `scripts/`: Operational Tools (ACI Layer)
