import { Elysia, t } from "elysia";
import { startHeartbeat, stopHeartbeat, getHeartbeatStatus, forceHeartbeat } from "../core/heartbeat";
import { runTaskCycle, parseGoals, getNextPendingGoal } from "../core/task-runner";

export const heartbeatApi = new Elysia({ prefix: "/heartbeat" });

// Get heartbeat status: GET /api/heartbeat
heartbeatApi.get("/", () => {
  return getHeartbeatStatus();
});

// Start heartbeat: POST /api/heartbeat/start { intervalMs? }
heartbeatApi.post("/start", ({ body }) => {
  const { intervalMs } = (body as any) || {};
  startHeartbeat(intervalMs);
  return { ok: true, ...getHeartbeatStatus() };
}, {
  body: t.Optional(t.Object({ intervalMs: t.Optional(t.Number()) })),
});

// Stop heartbeat: POST /api/heartbeat/stop
heartbeatApi.post("/stop", () => {
  stopHeartbeat();
  return { ok: true, running: false };
});

// Force run: POST /api/heartbeat/run
heartbeatApi.post("/run", async () => {
  const result = await forceHeartbeat();
  return result;
});

// Task runner endpoints

// Run task cycle: POST /api/heartbeat/task-cycle
heartbeatApi.post("/task-cycle", async () => {
  const results = await runTaskCycle();
  return { results };
});

// Get next goal: GET /api/heartbeat/next-goal
heartbeatApi.get("/next-goal", () => {
  const goal = getNextPendingGoal();
  return { goal };
});

// Get all goals: GET /api/heartbeat/goals
heartbeatApi.get("/goals", () => {
  return { goals: parseGoals() };
});
