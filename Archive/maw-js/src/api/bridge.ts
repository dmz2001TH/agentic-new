/**
 * Agent Chat Bridge — lets two agents talk to each other via tmux.
 *
 * How it works:
 *  1. Bridge polls each agent's tmux pane via capture-pane
 *  2. Diffs against last capture to find new output
 *  3. When agent A finishes responding (prompt detected), relays to agent B
 *  4. Events stream to frontend via /ws/bridge WebSocket
 *
 * Usage:
 *  POST /api/bridge/start { agentA: "session:0", agentB: "session:1" }
 *  GET  /ws/bridge/:id    — WebSocket stream of conversation events
 *  POST /api/bridge/stop  { id }
 */

import { Elysia } from "elysia";
import { tmux } from "../core/transport/tmux";
import { randomUUID } from "crypto";

// --- Types ---

interface BridgeConfig {
  id: string;
  agentA: string;
  agentB: string;
  agentAName: string;
  agentBName: string;
  running: boolean;
  startedAt: number;
  listeners: Set<WebSocket>;
  messages: BridgeMessage[];
}

interface BridgeMessage {
  ts: number;
  from: string;       // agent target
  fromName: string;   // display name
  to: string;         // recipient target
  text: string;
}

interface BridgeEvent {
  type: "message" | "status" | "error" | "history";
  bridge: string;
  ts: number;
  [key: string]: any;
}

// --- State ---

const bridges = new Map<string, BridgeConfig>();

// --- Prompt detection ---
// Common CLI agent prompts: "❯", ">", "$", "#", "Human:", "?", or ANSI-colored versions
const PROMPT_PATTERNS = [
  /\u276f\s*$/,          // ❯ (common agent prompt)
  />\s*$/,               // >
  /\$\s*$/,              // $
  /#\s*$/,               // #
  /\?\s*$/,              // ? (interactive prompts)
  />\s*$/,               // unicode >
  /❯\s*$/,               // alt ❯
];

function isPromptLine(line: string): boolean {
  const stripped = line.replace(/\x1b\[[0-9;]*m/g, "").trim();
  if (!stripped) return false;
  return PROMPT_PATTERNS.some(p => p.test(stripped));
}

/** Diff two text blocks — return only new lines.
 *  Since tmux capture-pane returns the visible buffer, new output appends
 *  to the bottom. We find where prev's suffix matches curr's prefix, then
 *  return everything after that match. */
function diffCapture(prev: string, curr: string): string[] {
  if (!prev) return [];
  const prevLines = prev.split("\n");
  const currLines = curr.split("\n");

  // Find the longest suffix of prev that appears as a contiguous block
  // at the START of curr. Everything after that block is new.
  for (let len = Math.min(prevLines.length, currLines.length); len >= 1; len--) {
    let match = true;
    for (let i = 0; i < len; i++) {
      if (prevLines[prevLines.length - len + i] !== currLines[i]) {
        match = false;
        break;
      }
    }
    if (match) {
      return currLines.slice(len);
    }
  }
  // No overlap — return all of curr
  return [...currLines];
}

/** Clean output for relay — strip ANSI, trim, remove empty lines */
function cleanOutput(lines: string[]): string {
  return lines
    .map(l => l.replace(/\x1b\[[0-9;]*m/g, "").replace(/\r/g, ""))
    .filter(l => l.trim().length > 0)
    .join("\n")
    .trim();
}

// --- Bridge loop ---

async function runBridge(config: BridgeConfig) {
  const POLL_MS = 800;        // poll interval
  const IDLE_MS = 1500;       // wait after last output before relaying
  const CAPTURE_LINES = 60;

  let prevA = "";
  let prevB = "";
  let lastOutputA = Date.now();
  let lastOutputB = Date.now();
  let pendingA = "";   // buffered output from A waiting to send to B
  let pendingB = "";   // buffered output from B waiting to send to A
  let aTurn = true;    // whose turn to speak first

  function broadcast(event: BridgeEvent) {
    for (const ws of config.listeners) {
      try { ws.send(JSON.stringify(event)); } catch { config.listeners.delete(ws); }
    }
  }

  broadcast({ type: "status", bridge: config.id, ts: Date.now(), state: "started" });

  while (config.running) {
    try {
      // Capture both panes
      const [capA, capB] = await Promise.all([
        tmux.capture(config.agentA, CAPTURE_LINES).catch(() => ""),
        tmux.capture(config.agentB, CAPTURE_LINES).catch(() => ""),
      ]);

      // Diff
      const newLinesA = diffCapture(prevA, capA);
      const newLinesB = diffCapture(prevB, capB);
      prevA = capA;
      prevB = capB;

      if (newLinesA.length > 0) {
        lastOutputA = Date.now();
        const cleaned = cleanOutput(newLinesA);
        if (cleaned) pendingA += (pendingA ? "\n" : "") + cleaned;
      }
      if (newLinesB.length > 0) {
        lastOutputB = Date.now();
        const cleaned = cleanOutput(newLinesB);
        if (cleaned) pendingB += (pendingB ? "\n" : "") + cleaned;
      }

      const now = Date.now();
      const aIdle = now - lastOutputA > IDLE_MS;
      const bIdle = now - lastOutputB > IDLE_MS;

      // Check for prompt in latest capture (agent is waiting for input)
      const lastLineA = capA.split("\n").pop() || "";
      const lastLineB = capB.split("\n").pop() || "";
      const aHasPrompt = isPromptLine(lastLineA);
      const bHasPrompt = isPromptLine(lastLineB);

      // Relay: A → B (when A is idle and B has prompt = B is ready to receive)
      if (pendingA && aIdle && bHasPrompt) {
        const text = pendingA;
        pendingA = "";

        const msg: BridgeMessage = {
          ts: Date.now(),
          from: config.agentA,
          fromName: config.agentAName,
          to: config.agentB,
          text,
        };
        config.messages.push(msg);

        broadcast({
          type: "message",
          bridge: config.id,
          ...msg,
        });

        await tmux.sendText(config.agentB, `[From ${config.agentAName}]: ${text}`);
        lastOutputB = Date.now(); // reset idle timer for B
        aTurn = false;
      }

      // Relay: B → A
      if (pendingB && bIdle && aHasPrompt) {
        const text = pendingB;
        pendingB = "";

        const msg: BridgeMessage = {
          ts: Date.now(),
          from: config.agentB,
          fromName: config.agentBName,
          to: config.agentA,
          text,
        };
        config.messages.push(msg);

        broadcast({
          type: "message",
          bridge: config.id,
          ...msg,
        });

        await tmux.sendText(config.agentA, `[From ${config.agentBName}]: ${text}`);
        lastOutputA = Date.now();
        aTurn = true;
      }

      // Safety: if pending has been waiting too long (>10s), force relay
      if (pendingA && now - lastOutputA > 10000) {
        const text = pendingA;
        pendingA = "";
        const msg: BridgeMessage = { ts: Date.now(), from: config.agentA, fromName: config.agentAName, to: config.agentB, text };
        config.messages.push(msg);
        broadcast({ type: "message", bridge: config.id, ...msg });
        await tmux.sendText(config.agentB, `[From ${config.agentAName}]: ${text}`);
        lastOutputB = Date.now();
      }
      if (pendingB && now - lastOutputB > 10000) {
        const text = pendingB;
        pendingB = "";
        const msg: BridgeMessage = { ts: Date.now(), from: config.agentB, fromName: config.agentBName, to: config.agentA, text };
        config.messages.push(msg);
        broadcast({ type: "message", bridge: config.id, ...msg });
        await tmux.sendText(config.agentA, `[From ${config.agentBName}]: ${text}`);
        lastOutputA = Date.now();
      }
    } catch (err: any) {
      broadcast({ type: "error", bridge: config.id, ts: Date.now(), error: err.message });
    }

    await new Promise(r => setTimeout(r, POLL_MS));
  }

  broadcast({ type: "status", bridge: config.id, ts: Date.now(), state: "stopped" });
}

// --- Clean agent name ---
function cleanName(target: string): string {
  return target.split(":").pop()?.replace(/-oracle$/, "").replace(/-/g, " ") || target;
}

// --- API ---

export const bridgeApi = new Elysia({ prefix: "/api/bridge" })
  .post("/start", async ({ body, set }) => {
    const { agentA, agentB } = body as { agentA: string; agentB: string };

    if (!agentA || !agentB) {
      set.status = 400;
      return { ok: false, error: "agentA and agentB required (format: session:window)" };
    }
    if (agentA === agentB) {
      set.status = 400;
      return { ok: false, error: "Cannot bridge an agent to itself" };
    }

    // Verify both agents exist
    try {
      const [existsA, existsB] = await Promise.all([
        tmux.hasSession(agentA.split(":")[0]),
        tmux.hasSession(agentB.split(":")[0]),
      ]);
      // Note: we check session existence, not individual panes
      // The targets could be "session:window" format
    } catch { /* tmux might not be available */ }

    const id = randomUUID().slice(0, 8);
    const config: BridgeConfig = {
      id,
      agentA,
      agentB,
      agentAName: cleanName(agentA),
      agentBName: cleanName(agentB),
      running: true,
      startedAt: Date.now(),
      listeners: new Set(),
      messages: [],
    };
    bridges.set(id, config);

    // Start bridge loop (non-blocking)
    runBridge(config).catch(err => {
      console.error(`[bridge:${id}] error:`, err);
      config.running = false;
    });

    return {
      ok: true,
      id,
      agentA: config.agentAName,
      agentB: config.agentBName,
      wsUrl: `/ws/bridge/${id}`,
    };
  })

  .post("/stop", ({ body, set }) => {
    const { id } = body as { id: string };
    const config = bridges.get(id);
    if (!config) {
      set.status = 404;
      return { ok: false, error: "Bridge not found" };
    }
    config.running = false;
    bridges.delete(id);
    return { ok: true, messages: config.messages.length };
  })

  .post("/send", async ({ body, set }) => {
    // Manual message injection into bridge
    const { id, to, text } = body as { id: string; to: "A" | "B"; text: string };
    const config = bridges.get(id);
    if (!config) {
      set.status = 404;
      return { ok: false, error: "Bridge not found" };
    }
    const target = to === "A" ? config.agentA : config.agentB;
    const senderName = to === "A" ? config.agentBName : config.agentAName;
    await tmux.sendText(target, `[From ${senderName} (user relay)]: ${text}`);
    return { ok: true };
  })

  .get("/list", () => {
    return [...bridges.values()].map(b => ({
      id: b.id,
      agentA: b.agentAName,
      agentB: b.agentBName,
      running: b.running,
      messageCount: b.messages.length,
      startedAt: b.startedAt,
    }));
  });

/** Handle /ws/bridge/:id WebSocket connections */
export function handleBridgeWs(ws: WebSocket, bridgeId: string): boolean {
  const config = bridges.get(bridgeId);
  if (!config) return false;

  config.listeners.add(ws);

  // Send existing messages as history
  ws.send(JSON.stringify({
    type: "history",
    bridge: bridgeId,
    ts: Date.now(),
    messages: config.messages,
  }));

  ws.addEventListener("close", () => {
    config.listeners.delete(ws);
  });

  return true;
}
