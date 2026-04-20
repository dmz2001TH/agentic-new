/**
 * heartbeat.ts — Periodic autonomous check for the agentic system
 *
 * Runs every N minutes (configurable). Checks:
 *   1. System health (Oracle Core, Maw API)
 *   2. Pending goals
 *   3. Inbox items
 *   4. Agent status
 *
 * Triggers task runner if there's work to do.
 */

import { readFileSync, existsSync, mkdirSync, appendFileSync } from "fs";
import { join, resolve } from "path";
import { loadConfig } from "../config";
import { runTaskCycle, parseGoals, isAgentOnline } from "./task-runner";
import { listSessions } from "../core/transport/ssh";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const PSI_DIR = join(PROJECT_ROOT, "ψ");
const ORACLE_URL = process.env.ORACLE_URL || loadConfig().oracleUrl || "http://localhost:47778";

const DEFAULT_INTERVAL_MS = 60 * 1000; // 1 minute
let heartbeatTimer: ReturnType<typeof setInterval> | null = null;
let lastRun: string | null = null;
let isRunning = false;

interface HeartbeatResult {
  timestamp: string;
  oracle: string;
  sessions: number;
  pendingGoals: number;
  activeGoals: number;
  inboxItems: number;
  tasksRun: number;
  errors: string[];
}

/**
 * Check Oracle Core health
 */
async function checkOracleHealth(): Promise<string> {
  try {
    const res = await fetch(`${ORACLE_URL}/api/health`, { signal: AbortSignal.timeout(5000) });
    if (res.ok) {
      const data = await res.json();
      return data.status || "ok";
    }
    return `error-${res.status}`;
  } catch {
    return "unreachable";
  }
}

/**
 * Count inbox items
 */
function countInboxItems(): number {
  const inboxDir = join(PSI_DIR, "inbox");
  if (!existsSync(inboxDir)) return 0;
  try {
    const { readdirSync } = require("fs");
    return readdirSync(inboxDir).filter((f: string) =>
      f.endsWith(".md") || f.endsWith(".txt") || f.endsWith(".json")
    ).length;
  } catch {
    return 0;
  }
}

/**
 * Run a single heartbeat cycle
 */
async function runHeartbeat(): Promise<HeartbeatResult> {
  if (isRunning) {
    return {
      timestamp: new Date().toISOString(),
      oracle: "skipped",
      sessions: 0,
      pendingGoals: 0,
      activeGoals: 0,
      inboxItems: 0,
      tasksRun: 0,
      errors: ["Heartbeat already running"],
    };
  }

  isRunning = true;
  const errors: string[] = [];

  try {
    const timestamp = new Date().toISOString();

    // 1. Check Oracle
    const oracle = await checkOracleHealth();

    // 2. Check sessions
    let sessions: any[] = [];
    try {
      sessions = await listSessions();
    } catch (e: any) {
      errors.push(`listSessions: ${e.message}`);
    }

    // 3. Check goals
    const goals = parseGoals();
    const pendingGoals = goals.filter(g => g.status === " ").length;
    const activeGoals = goals.filter(g => g.status === "~").length;

    // 4. Check inbox
    const inboxItems = countInboxItems();

    // 5. Run task cycle if there's work
    let tasksRun = 0;
    if (pendingGoals > 0 || inboxItems > 0) {
      try {
        const results = await runTaskCycle();
        tasksRun = results.filter(r => r.success).length;
      } catch (e: any) {
        errors.push(`taskCycle: ${e.message}`);
      }
    }

    // 6. Log result
    const result: HeartbeatResult = {
      timestamp,
      oracle,
      sessions: sessions.length,
      pendingGoals,
      activeGoals,
      inboxItems,
      tasksRun,
      errors,
    };

    lastRun = timestamp;
    logHeartbeat(result);

    return result;
  } finally {
    isRunning = false;
  }
}

/**
 * Log heartbeat result to file
 */
function logHeartbeat(result: HeartbeatResult): void {
  const logDir = join(PSI_DIR, "memory", "logs");
  mkdirSync(logDir, { recursive: true });

  const line = `[${result.timestamp}] oracle=${result.oracle} sessions=${result.sessions} ` +
    `pending=${result.pendingGoals} active=${result.activeGoals} inbox=${result.inboxItems} ` +
    `tasks=${result.tasksRun}${result.errors.length ? ` errors=${result.errors.join(";")}` : ""}`;

  appendFileSync(join(logDir, "heartbeat.log"), line + "\n");
}

/**
 * Start the heartbeat loop
 */
export function startHeartbeat(intervalMs?: number): void {
  if (heartbeatTimer) {
    console.log("[heartbeat] Already running");
    return;
  }

  const ms = intervalMs || loadConfig().intervals?.heartbeat || DEFAULT_INTERVAL_MS;
  console.log(`[heartbeat] Starting — interval ${ms / 1000}s (${ms / 60000}min)`);

  // Run immediately on start
  runHeartbeat().then(result => {
    console.log(`[heartbeat] Initial run: oracle=${result.oracle} tasks=${result.tasksRun}`);
  }).catch(e => {
    console.error(`[heartbeat] Initial run failed: ${e.message}`);
  });

  // Then run on interval
  heartbeatTimer = setInterval(async () => {
    try {
      const result = await runHeartbeat();
      if (result.tasksRun > 0 || result.errors.length > 0) {
        console.log(`[heartbeat] tasks=${result.tasksRun} errors=${result.errors.length}`);
      }
    } catch (e: any) {
      console.error(`[heartbeat] Error: ${e.message}`);
    }
  }, ms);
}

/**
 * Stop the heartbeat loop
 */
export function stopHeartbeat(): void {
  if (heartbeatTimer) {
    clearInterval(heartbeatTimer);
    heartbeatTimer = null;
    console.log("[heartbeat] Stopped");
  }
}

/**
 * Get heartbeat status
 */
export function getHeartbeatStatus() {
  return {
    running: heartbeatTimer !== null,
    lastRun,
    intervalMs: DEFAULT_INTERVAL_MS,
  };
}

/**
 * Force run heartbeat once
 */
export async function forceHeartbeat(): Promise<HeartbeatResult> {
  return runHeartbeat();
}
