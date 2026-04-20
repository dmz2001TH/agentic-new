/**
 * Scheduler API — Time-based task scheduling endpoints
 *
 * POST /api/scheduler/add        — Add a new schedule
 * POST /api/scheduler/update     — Update a schedule
 * POST /api/scheduler/delete     — Delete a schedule
 * GET  /api/scheduler/list       — List all schedules
 * POST /api/scheduler/run        — Force check and run due schedules
 * POST /api/scheduler/start      — Start the scheduler loop
 * POST /api/scheduler/stop       — Stop the scheduler loop
 * GET  /api/scheduler/status     — Scheduler status
 */

import { Elysia, t } from "elysia";
import {
  loadSchedules,
  addSchedule,
  updateSchedule,
  deleteSchedule,
  checkSchedules,
  startScheduler,
  stopScheduler,
  getSchedulerStatus,
} from "../core/scheduler";

export const schedulerApi = new Elysia({ prefix: "/scheduler" });

// List all schedules
schedulerApi.get("/list", () => {
  const schedules = loadSchedules();
  return { schedules, count: schedules.length };
});

// Add a new schedule
schedulerApi.post("/add", ({ body }) => {
  const b = body as any;

  if (!b.cron || !b.name) {
    return { error: "Missing required fields: name, cron" };
  }

  // Validate: must have either task+agent or chat fields
  if (b.type === "chat") {
    if (!b.from || !b.to || !b.message) {
      return { error: "Chat schedule requires: from, to, message" };
    }
  } else {
    if (!b.agent || !b.task) {
      return { error: "Task schedule requires: agent, task" };
    }
  }

  const schedule = addSchedule({
    name: b.name,
    cron: b.cron,
    agent: b.agent,
    task: b.task,
    type: b.type || "task",
    from: b.from,
    to: b.to,
    message: b.message,
    enabled: b.enabled !== false,
  });

  return { ok: true, schedule };
}, {
  body: t.Object({
    name: t.String(),
    cron: t.String(),
    type: t.Optional(t.Union([t.Literal("task"), t.Literal("chat")])),
    agent: t.Optional(t.String()),
    task: t.Optional(t.String()),
    from: t.Optional(t.String()),
    to: t.Optional(t.String()),
    message: t.Optional(t.String()),
    enabled: t.Optional(t.Boolean()),
  }),
});

// Update a schedule
schedulerApi.post("/update", ({ body }) => {
  const { id, ...patch } = body as any;
  if (!id) return { error: "Missing schedule id" };

  const schedule = updateSchedule(id, patch);
  if (!schedule) return { error: "Schedule not found" };

  return { ok: true, schedule };
}, {
  body: t.Object({
    id: t.String(),
    name: t.Optional(t.String()),
    cron: t.Optional(t.String()),
    enabled: t.Optional(t.Boolean()),
    task: t.Optional(t.String()),
    message: t.Optional(t.String()),
  }),
});

// Delete a schedule
schedulerApi.post("/delete", ({ body }) => {
  const { id } = body as { id: string };
  if (!id) return { error: "Missing schedule id" };

  const ok = deleteSchedule(id);
  return { ok };
}, {
  body: t.Object({ id: t.String() }),
});

// Force run check
schedulerApi.post("/run", async () => {
  const result = await checkSchedules();
  return result;
});

// Start scheduler
schedulerApi.post("/start", () => {
  startScheduler();
  return { ok: true, ...getSchedulerStatus() };
});

// Stop scheduler
schedulerApi.post("/stop", () => {
  stopScheduler();
  return { ok: true, running: false };
});

// Scheduler status
schedulerApi.get("/status", () => {
  return getSchedulerStatus();
});
