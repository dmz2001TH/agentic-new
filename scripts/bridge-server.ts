import { serve } from "bun";
import { appendFileSync, writeFileSync, existsSync, readFileSync, unlinkSync } from "fs";

const sockets = new Set<any>();
const LOG_FILE = "/mnt/c/Users/phasa/My Drive/Oracle-System-Brain/ψ/memory/logs/chrome-history.log";
const AGENT_VIEW = "/mnt/c/Agentic/agent_view.json";
const INBOX_CMD = "/mnt/c/Agentic/sidepanel_inbox.json";

// Clear log for fresh start if requested or just append
// appendFileSync(LOG_FILE, `\n\n=== NEW SUPREME SESSION ${new Date().toISOString()} ===\n`);

const server = serve({
  port: 47779,
  fetch(req, server) {
    if (server.upgrade(req)) return;
    return new Response("Oracle Agentic Bridge Online");
  },
  websocket: {
    open(ws) {
      sockets.add(ws);
      console.log("🟢 Extension Linked");
      ws.send(JSON.stringify({ type: "GOD_REPLY", message: "ระบบประสาทเชื่อมต่อแล้วครับพีช ผมเห็นโลกผ่านตาคุณแล้ว" }));
    },
    message(ws, message) {
      const data = JSON.parse(message.toString());

      if (data.type === "AUTO_SYNC" || data.type === "DEEP_SYNC") {
        const view = {
          title: data.title,
          url: data.url,
          lastSeen: new Date().toISOString(),
          axTree: data.axTree || []
        };
        writeFileSync(AGENT_VIEW, JSON.stringify(view, null, 2));
      }

      if (data.type === "USER_CHAT") {
        const entry = {
          t: new Date().toISOString(),
          user: "Peach",
          msg: data.message,
          page: data.title
        };
        appendFileSync(LOG_FILE, JSON.stringify(entry) + "\n");
        console.log(`[SIDEBAR] Peach: ${data.message}`);
      }
    },
    close(ws) {
      sockets.delete(ws);
      console.log("🔴 Extension Unlinked");
    }
  }
});

// Command Listener Loop
setInterval(() => {
  if (existsSync(INBOX_CMD)) {
    try {
      const cmd = JSON.parse(readFileSync(INBOX_CMD, "utf-8"));
      for (const ws of sockets) {
        ws.send(JSON.stringify(cmd));
      }
      unlinkSync(INBOX_CMD);
    } catch (e) {}
  }
}, 500);

console.log(`🚀 Agentic Server on ws://localhost:47779`);
