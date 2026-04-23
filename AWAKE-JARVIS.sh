#!/bin/bash
# 🚀 JARVIS SUPREME WAKE-UP PROTOCOL (3-in-1)
# ------------------------------------------
# This script launches Backend, Brain Bridge, and Frontend all at once.

PORTAL_DIR="/mnt/c/Agentic/agentic-new/jarvis-web-portal"
SCRIPTS_DIR="/mnt/c/Agentic/agentic-new"

echo "🧠 [JARVIS]: Initiating boot sequence..."

# 1. Start Backend (FastAPI)
echo "📡 Starting Backend Bridge (Port 8000)..."
cd "$PORTAL_DIR/backend" && python3 main.py > backend.log 2>&1 &
BACKEND_PID=$!

# 2. Start Brain Bridge (GOD)
echo "💎 Connecting to Super Brain..."
cd "$SCRIPTS_DIR" && PYTHONPATH=. python3 scripts/god_web_bridge.py > bridge.log 2>&1 &
BRIDGE_PID=$!

# 3. Start Frontend (React)
echo "🖥️ Launching User Interface (Port 5173)..."
cd "$PORTAL_DIR/frontend" && npm run dev > frontend.log 2>&1 &
FRONTEND_PID=$!

echo "------------------------------------------------"
echo "✅ JARVIS IS NOW AWAKE!"
echo "🔗 Access your Portal at: http://localhost:5173"
echo "📝 Logs are available in their respective .log files."
echo "------------------------------------------------"
echo "Press [Ctrl+C] to put JARVIS back to sleep."

# Handle graceful shutdown
trap "echo '💤 Putting JARVIS to sleep...'; kill $BACKEND_PID $BRIDGE_PID $FRONTEND_PID; exit" INT
wait
