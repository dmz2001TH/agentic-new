#!/bin/bash
# setup.sh — First-run setup for maw-js
# Usage: cd agentic && bash scripts/setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MAW_JS_DIR="$PROJECT_DIR/maw-js"

echo "🚀 Maw-JS First-Run Setup"
echo "========================="

# 1. Check bun
if ! command -v bun &>/dev/null; then
  echo "📦 Installing Bun..."
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi
echo "✅ Bun: $(bun --version)"

# 2. Install dependencies
echo "📦 Installing dependencies..."
cd "$MAW_JS_DIR"
bun install

# 3. Run tests
echo "🧪 Running tests..."
bun run test:all || echo "⚠️ Some tests failed — check output above"

# 4. Create config files
echo "⚙️ Creating config files..."
mkdir -p ~/.config/maw/fleet

cat > ~/.config/maw/maw.config.json << 'EOF'
{
  "agents": {
    "mawjs": "local"
  }
}
EOF

cat > ~/.config/maw/fleet/mawjs.json << 'EOF'
{
  "name": "mawjs",
  "node": "local",
  "status": "active"
}
EOF
echo "✅ Config: ~/.config/maw/"

# 5. Create tmux session
echo "🖥️ Creating tmux session..."
tmux kill-session -t mawjs-oracle 2>/dev/null || true
tmux new-session -d -s "mawjs-oracle" -c "$PROJECT_DIR"
tmux rename-window -t mawjs-oracle:0 "god"
tmux send-keys -t mawjs-oracle:0 "export CLAUDE_AGENT_NAME=god" Enter
echo "✅ tmux: mawjs-oracle → god"

# 6. Start server
export MAW_UI_DIR="$MAW_JS_DIR/ui/office"
echo ""
echo "========================="
echo "✅ Setup complete!"
echo ""
echo "To start the server:"
echo "  cd maw-js"
echo "  export MAW_UI_DIR=\$PWD/ui/office"
echo "  bun src/cli.ts serve"
echo ""
echo "Then open: http://127.0.0.1:3456/#fleet"
echo "Expected: 1 agents · 1 rooms · 1 tabs ✅"
