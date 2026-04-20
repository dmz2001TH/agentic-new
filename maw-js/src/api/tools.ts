import { Elysia, t } from "elysia";
import { readFileSync, writeFileSync, existsSync, appendFileSync, mkdirSync } from "fs";
import { join, resolve } from "path";
import { sendKeys, listSessions } from "../core/transport/ssh";
import { loadConfig } from "../config";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const ORACLE_URL = process.env.ORACLE_URL || loadConfig().oracleUrl || "http://localhost:47778";
const PSI_DIR = join(PROJECT_ROOT, "ψ");

// Auth: optional API token for tools endpoints
// Set MAW_TOOLS_TOKEN env var or toolsToken in maw.config.json to enable
const TOOLS_TOKEN = process.env.MAW_TOOLS_TOKEN || (loadConfig() as any).toolsToken || "";

// Helper: check auth token (if configured)
function checkAuth(headers: Record<string, string | undefined>): boolean {
  if (!TOOLS_TOKEN) return true; // no token = no auth (dev mode)
  const auth = headers["authorization"] || headers["x-api-key"] || "";
  return auth === TOOLS_TOKEN || auth === `Bearer ${TOOLS_TOKEN}`;
}

// ═══════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════

async function oracleProxy(path: string, opts: { method?: string; body?: any } = {}) {
  const { method = "GET", body } = opts;
  try {
    const init: RequestInit = { method, headers: { "Content-Type": "application/json" } };
    if (body) init.body = JSON.stringify(body);
    const res = await fetch(`${ORACLE_URL}${path}`, init);
    return { ok: res.ok, status: res.status, data: await res.json() };
  } catch (e: any) {
    return { ok: false, status: 502, data: { error: `Oracle unreachable: ${e.message}` } };
  }
}

function safePath(userPath: string): string {
  // Resolve relative to PROJECT_ROOT, prevent directory traversal
  const resolved = resolve(PROJECT_ROOT, userPath);
  if (!resolved.startsWith(PROJECT_ROOT)) {
    throw new Error("Path traversal detected");
  }
  return resolved;
}

function getGoalsFile(): string {
  return join(PSI_DIR, "memory", "goals.md");
}

// ═══════════════════════════════════════════
// Tools API — Agent's hands
// ═══════════════════════════════════════════

export const toolsApi = new Elysia({ prefix: "/tools" })
  .onBeforeHandle(({ request, set }) => {
    // Auth check (only if token is configured)
    if (TOOLS_TOKEN) {
      const headers: Record<string, string | undefined> = {};
      request.headers.forEach((v, k) => { headers[k.toLowerCase()] = v; });
      if (!checkAuth(headers)) {
        set.status = 401;
        return { error: "Unauthorized — provide Authorization: Bearer <token> or X-Api-Key: <token>" };
      }
    }
  });

// ─── Oracle Integration ───

// Learn: POST /api/tools/learn { title, content, type? }
toolsApi.post("/learn", async ({ body, set }) => {
  const result = await oracleProxy("/api/learn", { method: "POST", body });
  if (!result.ok) set.status = result.status;
  return result.data;
}, {
  body: t.Object({
    title: t.String(),
    content: t.String(),
    type: t.Optional(t.String()),
  }),
});

// Search: GET /api/tools/search?q=...&mode=...&limit=...
toolsApi.get("/search", async ({ query, set }) => {
  if (!query.q) { set.status = 400; return { error: "q required" }; }
  const params = new URLSearchParams({ q: query.q });
  if (query.mode) params.set("mode", query.mode);
  if (query.limit) params.set("limit", query.limit);
  const result = await oracleProxy(`/api/search?${params}`);
  if (!result.ok) set.status = result.status;
  return result.data;
}, {
  query: t.Object({
    q: t.String(),
    mode: t.Optional(t.String()),
    limit: t.Optional(t.String()),
  }),
});

// Stats: GET /api/tools/stats
toolsApi.get("/stats", async () => {
  const result = await oracleProxy("/api/stats");
  return result.ok ? result.data : { error: "Oracle unreachable" };
});

// Reflect: POST /api/tools/reflect { task, result, good, improve, lesson }
toolsApi.post("/reflect", async ({ body }) => {
  const { task, result: taskResult, good, improve, lesson, agent } = body as any;
  const date = new Date().toISOString().slice(0, 16).replace(":", "-").replace("T", "_");
  const filename = `${date}_${(task || "unknown").replace(/\s+/g, "-")}.md`;
  const filepath = join(PSI_DIR, "memory", "reflections", filename);

  mkdirSync(join(PSI_DIR, "memory", "reflections"), { recursive: true });
  const content = `# Reflection
Agent: ${agent || "unknown"} | Task: ${task || "unknown"}
Date: ${new Date().toISOString()}

## Result: ${taskResult || "unknown"}
## Good: ${good || "none noted"}
## Improve: ${improve || "none noted"}
## Lesson: ${lesson || "none noted"}
`;
  writeFileSync(filepath, content);

  // Also learn the lesson
  if (lesson) {
    await oracleProxy("/api/learn", {
      method: "POST",
      body: { title: `Lesson: ${task}`, content: lesson, type: "learning" },
    });
  }

  return { ok: true, file: filename };
}, {
  body: t.Object({
    task: t.String(),
    result: t.Optional(t.String()),
    good: t.Optional(t.String()),
    improve: t.Optional(t.String()),
    lesson: t.Optional(t.String()),
    agent: t.Optional(t.String()),
  }),
});

// ─── File Operations ───

// Read file: GET /api/tools/file?path=...
toolsApi.get("/file", ({ query, set }) => {
  try {
    const filepath = safePath(query.path || "");
    if (!existsSync(filepath)) { set.status = 404; return { error: "File not found" }; }
    return { content: readFileSync(filepath, "utf-8"), path: query.path };
  } catch (e: any) {
    set.status = 400;
    return { error: e.message };
  }
}, {
  query: t.Object({ path: t.String() }),
});

// Write file: PUT /api/tools/file { path, content }
toolsApi.put("/file", ({ body, set }) => {
  try {
    const { path: filePath, content } = body as { path: string; content: string };
    const filepath = safePath(filePath);
    mkdirSync(join(filepath, ".."), { recursive: true });
    writeFileSync(filepath, content, "utf-8");
    return { ok: true, path: filePath };
  } catch (e: any) {
    set.status = 400;
    return { error: e.message };
  }
}, {
  body: t.Object({
    path: t.String(),
    content: t.String(),
  }),
});

// Append to file: PATCH /api/tools/file { path, content }
toolsApi.patch("/file", ({ body, set }) => {
  try {
    const { path: filePath, content } = body as { path: string; content: string };
    const filepath = safePath(filePath);
    appendFileSync(filepath, content + "\n", "utf-8");
    return { ok: true, path: filePath };
  } catch (e: any) {
    set.status = 400;
    return { error: e.message };
  }
}, {
  body: t.Object({
    path: t.String(),
    content: t.String(),
  }),
});

// ─── Goal Management ───

// List goals: GET /api/tools/goals?status=pending|active|done|blocked|all
toolsApi.get("/goals", ({ query }) => {
  const goalsFile = getGoalsFile();
  if (!existsSync(goalsFile)) return { goals: [], pending: 0, active: 0, done: 0, blocked: 0 };

  const content = readFileSync(goalsFile, "utf-8");
  const lines = content.split("\n");

  const parseGoal = (line: string) => {
    const match = line.match(/^- \[(.)\]\s*(?:\[([^\]]+)\]\s*)?(.+?)(?:\s*—\s*(.+))?$/);
    if (!match) return null;
    return {
      status: match[1],
      date: match[2] || "",
      description: match[3].trim(),
      assignee: (match[4] || "").replace(/^by\s+/, "").trim(),
      raw: line,
    };
  };

  const allGoals = lines.map(parseGoal).filter(Boolean);
  const status = query.status || "all";

  const filtered = status === "all"
    ? allGoals
    : allGoals.filter(g => {
        const map: Record<string, string> = { pending: " ", active: "~", done: "x", blocked: "!" };
        return g!.status === map[status];
      });

  return {
    goals: filtered,
    pending: allGoals.filter(g => g!.status === " ").length,
    active: allGoals.filter(g => g!.status === "~").length,
    done: allGoals.filter(g => g!.status === "x").length,
    blocked: allGoals.filter(g => g!.status === "!").length,
  };
}, {
  query: t.Object({
    status: t.Optional(t.String()),
  }),
});

// Add goal: POST /api/tools/goals { description, assignee? }
toolsApi.post("/goals", ({ body }) => {
  const { description, assignee } = body as { description: string; assignee?: string };
  const date = new Date().toISOString().slice(0, 10);
  const agent = assignee || "god";
  const line = `- [ ] [${date}] ${description} — by ${agent}`;

  const goalsFile = getGoalsFile();
  appendFileSync(goalsFile, line + "\n");
  return { ok: true, goal: line };
}, {
  body: t.Object({
    description: t.String(),
    assignee: t.Optional(t.String()),
  }),
});

// Update goal status: PATCH /api/tools/goals { search, newStatus }
toolsApi.patch("/goals", ({ body, set }) => {
  const { search, newStatus } = body as { search: string; newStatus: string };
  const goalsFile = getGoalsFile();
  if (!existsSync(goalsFile)) { set.status = 404; return { error: "No goals file" }; }

  const content = readFileSync(goalsFile, "utf-8");
  const statusMap: Record<string, string> = { pending: " ", active: "~", done: "x", blocked: "!" };
  const targetChar = statusMap[newStatus];
  if (!targetChar) { set.status = 400; return { error: `Invalid status: ${newStatus}` }; }

  const lines = content.split("\n");
  let found = false;
  const updated = lines.map(line => {
    if (!found && line.includes(search)) {
      found = true;
      return line.replace(/^- \[.\]/, `- [${targetChar}]`);
    }
    return line;
  });

  if (!found) { set.status = 404; return { error: `Goal not found: ${search}` }; }

  writeFileSync(goalsFile, updated.join("\n"));

  // Auto-learn on completion
  if (newStatus === "done") {
    oracleProxy("/api/learn", {
      method: "POST",
      body: { title: `Goal Completed`, content: search, type: "goal-completion" },
    }).catch(() => {});
  }

  return { ok: true, search, newStatus };
}, {
  body: t.Object({
    search: t.String(),
    newStatus: t.String(),
  }),
});

// Run next pending goal: POST /api/tools/goals/next
toolsApi.post("/goals/next", () => {
  const goalsFile = getGoalsFile();
  if (!existsSync(goalsFile)) return { goal: null, message: "No goals file" };

  const content = readFileSync(goalsFile, "utf-8");
  const lines = content.split("\n");

  for (let i = 0; i < lines.length; i++) {
    if (/^- \[ \]/.test(lines[i])) {
      lines[i] = lines[i].replace(/^- \[ \]/, "- [~]");
      writeFileSync(goalsFile, lines.join("\n"));

      const goalText = lines[i].replace(/^- \[~\]\s*(?:\[([^\]]+)\]\s*)?/, "");

      // Log
      const logDir = join(PSI_DIR, "memory", "logs");
      mkdirSync(logDir, { recursive: true });
      appendFileSync(join(logDir, "task-runner.log"),
        `[${new Date().toISOString()}] Started: ${goalText}\n`);

      return { goal: goalText, line: i + 1, status: "active" };
    }
  }

  return { goal: null, message: "No pending goals" };
});

// ─── Agent Messaging ───

// Send message to agent: POST /api/tools/message { agent, message }
toolsApi.post("/message", async ({ body, set }) => {
  const { agent: agentName, message: msg } = body as { agent: string; message: string };
  const config = loadConfig();
  const sessionName = (config.sessions as Record<string, string>)?.[agentName] || `mawjs-${agentName}`;

  try {
    const sessions = await listSessions();
    const session = sessions.find(s => s.name === sessionName);
    if (!session) {
      set.status = 404;
      return { error: `Agent '${agentName}' not found (session: ${sessionName})` };
    }

    await sendKeys(sessionName, msg);
    return { ok: true, agent: agentName, session: sessionName, sent: msg };
  } catch (e: any) {
    set.status = 500;
    return { error: e.message };
  }
}, {
  body: t.Object({
    agent: t.String(),
    message: t.String(),
  }),
});

// ─── Command Execution ───

// Execute command: POST /api/tools/exec { command, timeout? }
toolsApi.post("/exec", async ({ body }) => {
  const { command, timeout: timeoutSec } = body as { command: string; timeout?: number };
  const timeout = (timeoutSec || 30) * 1000;

  try {
    const proc = Bun.spawn(["bash", "-c", command], {
      stdout: "pipe",
      stderr: "pipe",
      cwd: PROJECT_ROOT,
    });

    const timer = setTimeout(() => proc.kill(), timeout);
    const exitCode = await proc.exited;
    clearTimeout(timer);

    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();

    return {
      exitCode,
      stdout: stdout.trim(),
      stderr: stderr.trim(),
      success: exitCode === 0,
    };
  } catch (e: any) {
    return { exitCode: -1, stdout: "", stderr: e.message, success: false };
  }
}, {
  body: t.Object({
    command: t.String(),
    timeout: t.Optional(t.Number()),
  }),
});

// ─── System Status ───

// Fleet status: GET /api/tools/fleet
toolsApi.get("/fleet", async () => {
  const sessions = await listSessions();
  const config = loadConfig();

  // Oracle health
  let oracleHealth = "unreachable";
  try {
    const res = await fetch(`${ORACLE_URL}/api/health`);
    if (res.ok) {
      const data = await res.json();
      oracleHealth = data.status || "ok";
    }
  } catch {}

  // Goals summary
  const goalsFile = getGoalsFile();
  let pending = 0, active = 0, done = 0, blocked = 0;
  if (existsSync(goalsFile)) {
    const content = readFileSync(goalsFile, "utf-8");
    for (const line of content.split("\n")) {
      if (/^- \[ \]/.test(line)) pending++;
      else if (/^- \[~\]/.test(line)) active++;
      else if (/^- \[x\]/.test(line)) done++;
      else if (/^- \[!\]/.test(line)) blocked++;
    }
  }

  return {
    sessions: sessions.map(s => ({
      name: s.name,
      windows: s.windows?.length || 0,
    })),
    oracle: oracleHealth,
    goals: { pending, active, done, blocked },
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  };
});

// ─── Memory Operations ───

// Read memory: GET /api/tools/memory/:file
toolsApi.get("/memory/:file", ({ params, set }) => {
  try {
    const filepath = safePath(join("ψ", "memory", params.file));
    if (!existsSync(filepath)) { set.status = 404; return { error: "Memory file not found" }; }
    return { content: readFileSync(filepath, "utf-8"), file: params.file };
  } catch (e: any) {
    set.status = 400;
    return { error: e.message };
  }
});

// Write memory: PUT /api/tools/memory/:file { content }
toolsApi.put("/memory/:file", ({ params, body, set }) => {
  try {
    const filepath = safePath(join("ψ", "memory", params.file));
    const { content } = body as { content: string };

    // Lock protocol
    const lockDir = join(PSI_DIR, "memory", "locks");
    mkdirSync(lockDir, { recursive: true });
    const lockFile = join(lockDir, `${params.file}.lock`);
    writeFileSync(lockFile, `tools-api:${Date.now()}`);

    mkdirSync(join(filepath, ".."), { recursive: true });
    writeFileSync(filepath, content, "utf-8");

    // Unlock
    try { require("fs").unlinkSync(lockFile); } catch {}

    return { ok: true, file: params.file };
  } catch (e: any) {
    set.status = 400;
    return { error: e.message };
  }
}, {
  body: t.Object({ content: t.String() }),
});

// Append memory: PATCH /api/tools/memory/:file { content }
toolsApi.patch("/memory/:file", ({ params, body, set }) => {
  try {
    const filepath = safePath(join("ψ", "memory", params.file));
    const { content } = body as { content: string };
    appendFileSync(filepath, content + "\n", "utf-8");
    return { ok: true, file: params.file };
  } catch (e: any) {
    set.status = 400;
    return { error: e.message };
  }
}, {
  body: t.Object({ content: t.String() }),
});

// ─── Inbox Processing ───

// List inbox: GET /api/tools/inbox
toolsApi.get("/inbox", () => {
  const inboxDir = join(PSI_DIR, "inbox");
  if (!existsSync(inboxDir)) return { items: [] };

  try {
    const { readdirSync, statSync } = require("fs");
    const files = readdirSync(inboxDir).map((f: string) => {
      const stat = statSync(join(inboxDir, f));
      return { name: f, size: stat.size, modified: stat.mtime.toISOString() };
    });
    return { items: files };
  } catch {
    return { items: [] };
  }
});

// Read inbox item: GET /api/tools/inbox/:file
toolsApi.get("/inbox/:file", ({ params, set }) => {
  try {
    const filepath = safePath(join("ψ", "inbox", params.file));
    if (!existsSync(filepath)) { set.status = 404; return { error: "Inbox item not found" }; }
    return { content: readFileSync(filepath, "utf-8"), file: params.file };
  } catch (e: any) {
    set.status = 400;
    return { error: e.message };
  }
});

// Add inbox item: POST /api/tools/inbox { filename, content }
toolsApi.post("/inbox", ({ body }) => {
  const { filename, content } = body as { filename: string; content: string };
  const inboxDir = join(PSI_DIR, "inbox");
  mkdirSync(inboxDir, { recursive: true });
  writeFileSync(join(inboxDir, filename), content, "utf-8");
  return { ok: true, file: filename };
}, {
  body: t.Object({
    filename: t.String(),
    content: t.String(),
  }),
});

// Delete inbox item: DELETE /api/tools/inbox/:file
toolsApi.delete("/inbox/:file", ({ params, set }) => {
  try {
    const filepath = safePath(join("ψ", "inbox", params.file));
    if (!existsSync(filepath)) { set.status = 404; return { error: "Not found" }; }
    // Archive instead of delete
    const archiveDir = join(PSI_DIR, "inbox", "archive");
    mkdirSync(archiveDir, { recursive: true });
    const { renameSync } = require("fs");
    renameSync(filepath, join(archiveDir, `${Date.now()}-${params.file}`));
    return { ok: true, archived: params.file };
  } catch (e: any) {
    set.status = 400;
    return { error: e.message };
  }
});
