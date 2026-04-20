/**
 * scheduler.ts — Time-based Task Scheduler
 *
 * Supports scheduling agent tasks at specific times (like cron).
 * Schedules are stored in ψ/memory/schedules.json and checked every minute.
 *
 * Schedule format:
 * {
 *   id: "unique-id",
 *   name: "morning-research",
 *   cron: "0 7 * * *",        // Every day at 7:00 AM
 *   agent: "researcher",       // Which agent to dispatch to
 *   task: "Read and summarize today's news about AI agents",
 *   enabled: true,
 *   lastRun: null,
 *   nextRun: "2026-04-21T07:00:00Z"
 * }
 *
 * Also supports chat-based schedules:
 * {
 *   id: "chat-summary",
 *   cron: "0 8 * * *",
 *   type: "chat",
 *   from: "god",
 *   to: "builder",
 *   message: "What did you work on yesterday? Summarize.",
 *   enabled: true
 * }
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "fs";
import { join, resolve } from "path";
import { loadConfig } from "../config";
import { sendKeys, listSessions } from "./transport/ssh";
import { sendChatMessage } from "./chat";
import { parseCronField } from "./runtime/triggers-cron";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const PSI_DIR = join(PROJECT_ROOT, "ψ");
const SCHEDULES_FILE = join(PSI_DIR, "memory", "schedules.json");

export interface Schedule {
  id: string;
  name: string;
  cron: string;              // 5-field cron: minute hour day month dow
  agent?: string;            // Target agent for task dispatch
  task?: string;             // Task description to send
  type?: "task" | "chat";    // Default: "task"
  from?: string;             // For chat type: sender
  to?: string;               // For chat type: recipient
  message?: string;          // For chat type: message content
  enabled: boolean;
  lastRun: string | null;
  nextRun: string | null;
  createdAt: string;
}

let schedulerTimer: ReturnType<typeof setInterval> | null = null;

/**
 * Load all schedules from disk.
 */
export function loadSchedules(): Schedule[] {
  if (!existsSync(SCHEDULES_FILE)) return [];
  try {
    return JSON.parse(readFileSync(SCHEDULES_FILE, "utf-8"));
  } catch {
    return [];
  }
}

/**
 * Save schedules to disk.
 */
function saveSchedules(schedules: Schedule[]): void {
  mkdirSync(join(PSI_DIR, "memory"), { recursive: true });
  writeFileSync(SCHEDULES_FILE, JSON.stringify(schedules, null, 2), "utf-8");
}

/**
 * Add a new schedule.
 */
export function addSchedule(schedule: Omit<Schedule, "id" | "lastRun" | "nextRun" | "createdAt">): Schedule {
  const schedules = loadSchedules();
  const id = `sched-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

  const newSchedule: Schedule = {
    ...schedule,
    id,
    lastRun: null,
    nextRun: computeNextRun(schedule.cron),
    createdAt: new Date().toISOString(),
  };

  schedules.push(newSchedule);
  saveSchedules(schedules);
  log(`Schedule added: ${newSchedule.name} (${newSchedule.cron})`);
  return newSchedule;
}

/**
 * Update an existing schedule.
 */
export function updateSchedule(id: string, patch: Partial<Schedule>): Schedule | null {
  const schedules = loadSchedules();
  const idx = schedules.findIndex(s => s.id === id);
  if (idx === -1) return null;

  schedules[idx] = { ...schedules[idx], ...patch };
  if (patch.cron) {
    schedules[idx].nextRun = computeNextRun(patch.cron);
  }
  saveSchedules(schedules);
  return schedules[idx];
}

/**
 * Delete a schedule.
 */
export function deleteSchedule(id: string): boolean {
  const schedules = loadSchedules();
  const filtered = schedules.filter(s => s.id !== id);
  if (filtered.length === schedules.length) return false;
  saveSchedules(filtered);
  log(`Schedule deleted: ${id}`);
  return true;
}

/**
 * Compute next run time from a cron expression.
 */
function computeNextRun(cronExpr: string): string | null {
  try {
    const parts = cronExpr.trim().split(/\s+/);
    if (parts.length !== 5) return null;

    const [mF, hF, domF, monF, dowF] = parts;
    const minutes = parseCronField(mF, 0, 59);
    const hours = parseCronField(hF, 0, 23);
    const doms = parseCronField(domF, 1, 31);
    const months = parseCronField(monF, 1, 12);
    const dows = parseCronField(dowF, 0, 6);

    const d = new Date();
    d.setSeconds(0, 0);
    d.setMinutes(d.getMinutes() + 1);

    const maxIter = 366 * 24 * 60;
    for (let i = 0; i < maxIter; i++) {
      const mon = d.getMonth() + 1;
      if (!months.has(mon)) { d.setMonth(d.getMonth() + 1, 1); d.setHours(0, 0, 0, 0); continue; }
      const dom = d.getDate();
      const dow = d.getDay();
      if (!doms.has(dom) || !dows.has(dow)) { d.setDate(d.getDate() + 1); d.setHours(0, 0, 0, 0); continue; }
      if (!hours.has(d.getHours())) { d.setHours(d.getHours() + 1, 0, 0, 0); continue; }
      if (minutes.has(d.getMinutes())) return d.toISOString();
      d.setMinutes(d.getMinutes() + 1);
    }
    return null;
  } catch {
    return null;
  }
}

/**
 * Check and fire due schedules.
 */
export async function checkSchedules(): Promise<{ fired: number; errors: string[] }> {
  const schedules = loadSchedules();
  const now = new Date();
  let fired = 0;
  const errors: string[] = [];

  for (const sched of schedules) {
    if (!sched.enabled) continue;
    if (!sched.nextRun) continue;
    if (new Date(sched.nextRun) > now) continue;

    try {
      if (sched.type === "chat" && sched.from && sched.to && sched.message) {
        // Chat schedule: send message between agents
        const msg = sendChatMessage(sched.from, sched.to, sched.message);
        // Try to dispatch immediately
        const config = loadConfig();
        const sessionName = (config.sessions as Record<string, string>)?.[sched.to] || `mawjs-${sched.to}`;
        try {
          const sessions = await listSessions();
          const session = sessions.find(s => s.name === sessionName);
          if (session) {
            await sendKeys(sessionName, `[CHAT from:${sched.from}] ${sched.message}`);
            log(`Chat schedule dispatched: ${sched.from} → ${sched.to}`);
          }
        } catch { /* agent offline, message stays in inbox */ }

        fired++;
      } else if (sched.agent && sched.task) {
        // Task schedule: dispatch task to agent
        const config = loadConfig();
        const sessionName = (config.sessions as Record<string, string>)?.[sched.agent] || `mawjs-${sched.agent}`;
        const sessions = await listSessions();
        const session = sessions.find(s => s.name === sessionName);
        if (session) {
          await sendKeys(sessionName, `TASK: ${sched.task}`);
          log(`Task schedule dispatched: ${sched.name} → ${sched.agent}`);
        } else {
          log(`Task schedule: ${sched.name} → ${sched.agent} (offline, will retry next cycle)`);
        }
        fired++;
      } else {
        errors.push(`Schedule ${sched.name}: missing task/chat config`);
        continue;
      }

      // Update schedule
      sched.lastRun = now.toISOString();
      sched.nextRun = computeNextRun(sched.cron);
      saveSchedules(schedules);

    } catch (e: any) {
      errors.push(`Schedule ${sched.name}: ${e.message}`);
    }
  }

  return { fired, errors };
}

/**
 * Start the scheduler loop (checks every 60 seconds).
 */
export function startScheduler(): void {
  if (schedulerTimer) {
    console.log("[scheduler] Already running");
    return;
  }

  console.log("[scheduler] Starting — checks every 60s");

  // Check immediately
  checkSchedules().then(({ fired, errors }) => {
    if (fired > 0 || errors.length > 0) {
      console.log(`[scheduler] Initial: fired=${fired} errors=${errors.length}`);
    }
  });

  // Check every minute
  schedulerTimer = setInterval(async () => {
    try {
      const { fired, errors } = await checkSchedules();
      if (fired > 0 || errors.length > 0) {
        console.log(`[scheduler] fired=${fired} errors=${errors.length}`);
      }
    } catch (e: any) {
      console.error(`[scheduler] Error: ${e.message}`);
    }
  }, 60 * 1000);
}

/**
 * Stop the scheduler loop.
 */
export function stopScheduler(): void {
  if (schedulerTimer) {
    clearInterval(schedulerTimer);
    schedulerTimer = null;
    console.log("[scheduler] Stopped");
  }
}

/**
 * Get scheduler status.
 */
export function getSchedulerStatus() {
  const schedules = loadSchedules();
  return {
    running: schedulerTimer !== null,
    total: schedules.length,
    enabled: schedules.filter(s => s.enabled).length,
    nextSchedule: schedules
      .filter(s => s.enabled && s.nextRun)
      .sort((a, b) => (a.nextRun || "").localeCompare(b.nextRun || ""))[0] || null,
  };
}

function log(msg: string): void {
  const logDir = join(PSI_DIR, "memory", "logs");
  mkdirSync(logDir, { recursive: true });
  appendFileSync(join(logDir, "scheduler.log"), `[${new Date().toISOString()}] ${msg}\n`);
}
