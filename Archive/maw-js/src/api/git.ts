import { Elysia, t } from "elysia";
import { resolve } from "path";
import { loadConfig } from "../config";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");

// Helper: run git command
async function git(args: string, timeoutSec = 30): Promise<{ exitCode: number; stdout: string; stderr: string }> {
  try {
    const proc = Bun.spawn(["bash", "-c", `cd '${PROJECT_ROOT}' && git ${args}`], {
      stdout: "pipe",
      stderr: "pipe",
    });
    const timer = setTimeout(() => proc.kill(), timeoutSec * 1000);
    const exitCode = await proc.exited;
    clearTimeout(timer);
    return {
      exitCode,
      stdout: (await new Response(proc.stdout).text()).trim(),
      stderr: (await new Response(proc.stderr).text()).trim(),
    };
  } catch (e: any) {
    return { exitCode: -1, stdout: "", stderr: e.message };
  }
}

export const gitApi = new Elysia({ prefix: "/git" });

// Status: GET /api/git/status
gitApi.get("/status", async () => {
  const r = await git("status --short");
  return { files: r.stdout ? r.stdout.split("\n") : [], exitCode: r.exitCode };
});

// Log: GET /api/git/log?limit=10
gitApi.get("/log", async ({ query }) => {
  const limit = query.limit || "10";
  const r = await git(`log --oneline -${limit}`);
  return { commits: r.stdout ? r.stdout.split("\n") : [] };
}, {
  query: t.Object({ limit: t.Optional(t.String()) }),
});

// Diff: GET /api/git/diff?file=...
gitApi.get("/diff", async ({ query }) => {
  const fileArg = query.file ? ` -- '${query.file}'` : "";
  const r = await git(`diff${fileArg}`);
  return { diff: r.stdout, exitCode: r.exitCode };
}, {
  query: t.Object({ file: t.Optional(t.String()) }),
});

// Stage: POST /api/git/add { files? }
gitApi.post("/add", async ({ body }) => {
  const files = (body as any)?.files || ".";
  const r = await git(`add ${files}`);
  return { ok: r.exitCode === 0, stdout: r.stdout, stderr: r.stderr };
}, {
  body: t.Optional(t.Object({ files: t.Optional(t.String()) })),
});

// Commit: POST /api/git/commit { message }
gitApi.post("/commit", async ({ body, set }) => {
  const { message } = body as { message: string };
  if (!message) { set.status = 400; return { error: "message required" }; }

  // Configure bot identity if not set
  await git('config user.email "oracle-bot@agentic.local" 2>/dev/null || true');
  await git('config user.name "Oracle Bot" 2>/dev/null || true');

  const r = await git(`commit -m '${message.replace(/'/g, "'\\''")}'`);
  return {
    ok: r.exitCode === 0,
    stdout: r.stdout,
    stderr: r.stderr,
  };
}, {
  body: t.Object({ message: t.String() }),
});

// Push: POST /api/git/push
gitApi.post("/push", async () => {
  const r = await git("push", 60);
  return { ok: r.exitCode === 0, stdout: r.stdout, stderr: r.stderr };
});

// Pull: POST /api/git/pull
gitApi.post("/pull", async () => {
  const r = await git("pull --rebase", 60);
  return { ok: r.exitCode === 0, stdout: r.stdout, stderr: r.stderr };
});

// Branch: GET /api/git/branch
gitApi.get("/branch", async () => {
  const r = await git("branch --show-current");
  return { branch: r.stdout || "unknown" };
});

// Stash: POST /api/git/stash
gitApi.post("/stash", async () => {
  const r = await git("stash");
  return { ok: r.exitCode === 0, stdout: r.stdout };
});

// Auto commit + push: POST /api/git/ship { message }
gitApi.post("/ship", async ({ body, set }) => {
  const { message } = body as { message: string };
  if (!message) { set.status = 400; return { error: "message required" }; }

  // Stage all
  const addR = await git("add -A");
  if (addR.exitCode !== 0) return { ok: false, step: "add", error: addR.stderr };

  // Commit
  await git('config user.email "oracle-bot@agentic.local" 2>/dev/null || true');
  await git('config user.name "Oracle Bot" 2>/dev/null || true');
  const commitR = await git(`commit -m '${message.replace(/'/g, "'\\''")}'`);

  // Push (even if commit says "nothing to commit", still try push)
  const pushR = await git("push", 60);

  return {
    ok: pushR.exitCode === 0,
    staged: addR.exitCode === 0,
    committed: commitR.exitCode === 0,
    pushed: pushR.exitCode === 0,
    commitOutput: commitR.stdout,
    pushOutput: pushR.stdout,
    pushError: pushR.stderr,
  };
}, {
  body: t.Object({ message: t.String() }),
});
