/**
 * task-runner.ts — Autonomous goal execution engine (v2 — integrated)
 *
 * Runs as part of the Maw server. Processes inbox items and pending goals
 * by dispatching tasks to the appropriate agent via tmux send-keys.
 *
 * Integrated modules:
 *   - Circuit Breaker: auto-disable failing agents
 *   - Git Auto-Snapshot: auto-commit before runs, rollback on failure
 *   - Replanner: dynamic re-planning when scope changes
 *   - Smart Retry: retry with different strategies on failure
 *   - Alert: real-time notifications to dashboard
 *
 * Flow:
 *   1. Check inbox/ for new task files
 *   2. Check goals.md for pending [ ] goals
 *   3. Circuit breaker check → is agent allowed to run?
 *   4. Git snapshot → save workspace state
 *   5. Create plan → break goal into steps
 *   6. Mark goal as active [~]
 *   7. Send task to assigned agent
 *   8. On success: record success, keep snapshot
 *   9. On failure: smart retry → replan → or rollback + circuit break
 */

import { readFileSync, writeFileSync, existsSync, readdirSync, mkdirSync, appendFileSync, renameSync } from "fs";
import { join, resolve } from "path";
import { sendKeys, listSessions } from "../core/transport/ssh";
import { loadConfig } from "../config";
import { canExecute, recordSuccess, recordFailure } from "./circuit-breaker";
import { createSnapshot, rollbackLatestForAgent } from "./git-auto-snapshot";
import { createPlan, completeStep, shouldReplan, replan, getProgress } from "./replanner";
import { fire } from "./alert";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const PSI_DIR = join(PROJECT_ROOT, "ψ");
const ORACLE_URL = process.env.ORACLE_URL || loadConfig().oracleUrl || "http://localhost:47778";

interface Goal {
  lineNumber: number;
  status: string;
  date: string;
  description: string;
  assignee: string;
  raw: string;
}

interface InboxItem {
  filename: string;
  content: string;
}

interface TaskResult {
  type: "goal" | "inbox";
  action: string;
  success: boolean;
  detail: string;
}

/**
 * Parse goals.md into structured goals
 */
export function parseGoals(): Goal[] {
  const goalsFile = join(PSI_DIR, "memory", "goals.md");
  if (!existsSync(goalsFile)) return [];

  const content = readFileSync(goalsFile, "utf-8");
  const goals: Goal[] = [];

  content.split("\n").forEach((line, i) => {
    const match = line.match(/^- \[(.)\]\s*(?:\[([^\]]+)\]\s*)?(.+?)(?:\s*—\s*(.+))?$/);
    if (match) {
      goals.push({
        lineNumber: i,
        status: match[1],
        date: match[2] || "",
        description: match[3].trim(),
        assignee: (match[4] || "").replace(/^by\s+/, "").trim(),
        raw: line,
      });
    }
  });

  return goals;
}

/**
 * Get the first pending goal
 */
export function getNextPendingGoal(): Goal | null {
  const goals = parseGoals();
  return goals.find(g => g.status === " ") || null;
}

/**
 * Mark a goal as active
 */
export function markGoalActive(goal: Goal): void {
  const goalsFile = join(PSI_DIR, "memory", "goals.md");
  const content = readFileSync(goalsFile, "utf-8");
  const lines = content.split("\n");
  lines[goal.lineNumber] = lines[goal.lineNumber].replace(/^- \[ \]/, "- [~]");
  writeFileSync(goalsFile, lines.join("\n"));
}

/**
 * Mark a goal as done
 */
export function markGoalDone(goal: Goal): void {
  const goalsFile = join(PSI_DIR, "memory", "goals.md");
  const content = readFileSync(goalsFile, "utf-8");
  const lines = content.split("\n");
  lines[goal.lineNumber] = lines[goal.lineNumber].replace(/^- \[~\]/, "- [x]");
  writeFileSync(goalsFile, lines.join("\n"));
}

/**
 * Check if an agent session exists and is running
 */
export async function isAgentOnline(agentName: string): Promise<boolean> {
  const config = loadConfig();
  const sessionName = (config.sessions as Record<string, string>)?.[agentName] || `mawjs-${agentName}`;
  try {
    const sessions = await listSessions();
    return sessions.some(s => s.name === sessionName);
  } catch {
    return false;
  }
}

/**
 * Send a task to an agent via tmux
 */
export async function dispatchToAgent(agentName: string, task: string): Promise<boolean> {
  const config = loadConfig();
  const sessionName = (config.sessions as Record<string, string>)?.[agentName] || `mawjs-${agentName}`;

  try {
    const sessions = await listSessions();
    const session = sessions.find(s => s.name === sessionName);
    if (!session) {
      log(`Agent ${agentName} not online (session: ${sessionName})`);
      return false;
    }

    await sendKeys(sessionName, task);
    log(`Dispatched task to ${agentName}: ${task.slice(0, 100)}`);
    return true;
  } catch (e: any) {
    log(`Failed to dispatch to ${agentName}: ${e.message}`);
    return false;
  }
}

/**
 * Process inbox items — turn them into goals or dispatch directly
 */
export async function processInbox(): Promise<TaskResult[]> {
  const inboxDir = join(PSI_DIR, "inbox");
  if (!existsSync(inboxDir)) return [];

  const results: TaskResult[] = [];
  const files = readdirSync(inboxDir).filter(f => f.endsWith(".md") || f.endsWith(".txt") || f.endsWith(".json"));

  for (const file of files) {
    try {
      const content = readFileSync(join(inboxDir, file), "utf-8");

      // Check if it's a task definition
      if (content.startsWith("TASK:") || content.startsWith("task:")) {
        // Parse task
        const lines = content.split("\n");
        const taskDesc = lines[0].replace(/^TASK:\s*/i, "").trim();
        const assignee = lines.find(l => l.startsWith("AGENT:"))?.replace(/^AGENT:\s*/i, "").trim() || "god";

        // Add as goal
        const goalsFile = join(PSI_DIR, "memory", "goals.md");
        const date = new Date().toISOString().slice(0, 10);
        appendFileSync(goalsFile, `- [ ] [${date}] ${taskDesc} — by ${assignee}\n`);

        // Archive inbox item
        const archiveDir = join(inboxDir, "archive");
        mkdirSync(archiveDir, { recursive: true });
        renameSync(join(inboxDir, file), join(archiveDir, `${Date.now()}-${file}`));

        results.push({ type: "inbox", action: "converted-to-goal", success: true, detail: taskDesc });
        log(`Inbox item ${file} → goal: ${taskDesc}`);
      } else {
        // Just log it — agent will read manually
        results.push({ type: "inbox", action: "noted", success: true, detail: file });
      }
    } catch (e: any) {
      results.push({ type: "inbox", action: "error", success: false, detail: e.message });
    }
  }

  return results;
}

/**
 * Run the next pending goal — dispatch to assigned agent
 * with full integration: circuit breaker, snapshot, planning, retry, alerts
 */
export async function runNextGoal(): Promise<TaskResult> {
  const goal = getNextPendingGoal();

  if (!goal) {
    return { type: "goal", action: "none", success: true, detail: "No pending goals" };
  }

  const agent = goal.assignee || "god";

  // ─── 1. Circuit Breaker Check ───
  const circuit = canExecute(agent);
  if (!circuit.allowed) {
    log(`Goal "${goal.description}" blocked by circuit breaker: ${circuit.reason}`);
    fire("task-failed", `Task blocked: ${goal.description.slice(0, 50)}`, circuit.reason, {
      agent, severity: "warning",
      metadata: { goalDescription: goal.description },
    });
    return {
      type: "goal",
      action: "circuit-open",
      success: false,
      detail: `Agent ${agent} circuit breaker: ${circuit.reason}`,
    };
  }

  // ─── 2. Check agent online ───
  const online = await isAgentOnline(agent);
  if (!online) {
    log(`Goal "${goal.description}" — agent ${agent} is offline`);
    fire("agent-down", `Agent ${agent} offline`, `Cannot dispatch: ${goal.description}`, {
      agent, severity: "critical",
    });
    return {
      type: "goal",
      action: "agent-offline",
      success: false,
      detail: `Agent ${agent} is not online`,
    };
  }

  // ─── 3. Git Auto-Snapshot ───
  const snapshot = createSnapshot(agent, goal.description);
  if (snapshot) {
    log(`Snapshot created: ${snapshot.tag} before dispatching to ${agent}`);
    fire("snapshot-created", `Snapshot: ${snapshot.tag}`, `Before: ${goal.description.slice(0, 60)}`, {
      agent, severity: "info",
      metadata: { snapshotId: snapshot.id, tag: snapshot.tag },
    });
  }

  // ─── 4. Create Execution Plan ───
  const plan = createPlan(`goal-${goal.lineNumber}`, agent, goal.description);
  log(`Plan created: ${plan.id} with ${plan.steps.length} steps`);

  // ─── 5. Mark as active ───
  markGoalActive(goal);

  // ─── 6. Dispatch ───
  const taskMessage = `TASK: ${goal.description}\n\nPLAN_ID: ${plan.id}\nSTEPS:\n${plan.steps.map((s, i) => `${i + 1}. ${s.description}`).join("\n")}`;
  const dispatched = await dispatchToAgent(agent, taskMessage);

  if (!dispatched) {
    // Dispatch failed
    recordFailure(agent, "dispatch-failed");
    fire("task-failed", `Dispatch failed: ${goal.description.slice(0, 50)}`, `Could not send to ${agent}`, {
      agent, severity: "critical",
    });
  }

  // Log
  const logDir = join(PSI_DIR, "memory", "logs");
  mkdirSync(logDir, { recursive: true });
  appendFileSync(join(logDir, "task-runner.log"),
    `[${new Date().toISOString()}] ${dispatched ? "Dispatched" : "Failed"}: ${goal.description} → ${agent} (plan=${plan.id}, snapshot=${snapshot?.tag || "none"})\n`);

  return {
    type: "goal",
    action: dispatched ? "dispatched" : "dispatch-failed",
    success: dispatched,
    detail: `${goal.description} → ${agent} (plan: ${plan.id})`,
  };
}

/**
 * Report task outcome from agent feedback.
 * Called when an agent reports completion or failure.
 * Handles: success recording, circuit breaker, rollback, retry, replan.
 */
export async function reportOutcome(
  agent: string,
  planId: string,
  stepId: number,
  success: boolean,
  result: string,
): Promise<{ action: string; detail: string }> {

  if (success) {
    // ─── Success Path ───
    recordSuccess(agent);
    completeStep(planId, stepId, result);

    const progress = getProgress(planId);
    if (progress && progress.percent === 100) {
      fire("plan-completed", `Plan completed: ${planId}`, `All ${progress.total} steps done`, {
        agent, severity: "info",
      });
    }

    log(`Task success: agent=${agent}, plan=${planId}, step=${stepId}`);
    return { action: "success", detail: result };

  } else {
    // ─── Failure Path ───
    const { circuitOpened } = recordFailure(agent, result);

    if (circuitOpened) {
      // Circuit tripped — rollback and alert
      fire("circuit-opened", `Circuit OPENED: ${agent}`, `Too many failures. Agent disabled.`, {
        agent, severity: "critical",
        metadata: { error: result },
      });

      const rb = rollbackLatestForAgent(agent);
      if (rb.success) {
        fire("snapshot-rolled-back", `Rolled back: ${agent}`, rb.detail, {
          agent, severity: "warning",
        });
      }

      log(`Circuit opened for ${agent}, rolled back: ${rb.success}`);
      return { action: "circuit-opened", detail: `Agent disabled, rolled back: ${rb.detail}` };
    }

    // Circuit still closed — check if replan is possible
    const replanCheck = shouldReplan(planId);
    if (replanCheck.needed) {
      const trigger = replanCheck.triggers[0];
      const newPlan = replan(planId, trigger);

      if (newPlan) {
        fire("replan-triggered", `Replan: ${planId}`, trigger.detail, {
          agent, severity: "warning",
          metadata: { triggerType: trigger.type, replanCount: newPlan.replanCount },
        });

        log(`Replanned: ${planId} (trigger: ${trigger.type})`);
        return { action: "replanned", detail: `Replan #${newPlan.replanCount}: ${trigger.detail}` };
      }
    }

    // No replan possible — mark plan as failed
    fire("plan-failed", `Plan failed: ${planId}`, result, {
      agent, severity: "critical",
    });

    log(`Task failed: agent=${agent}, plan=${planId}, step=${stepId}, error=${result}`);
    return { action: "failed", detail: result };
  }
}

/**
 * Full task runner cycle — process inbox + run next goal
 */
export async function runTaskCycle(): Promise<TaskResult[]> {
  const results: TaskResult[] = [];

  // 1. Process inbox
  const inboxResults = await processInbox();
  results.push(...inboxResults);

  // 2. Run next pending goal
  const goalResult = await runNextGoal();
  results.push(goalResult);

  return results;
}

// ─── Logging ───

function log(msg: string): void {
  const logDir = join(PSI_DIR, "memory", "logs");
  mkdirSync(logDir, { recursive: true });
  appendFileSync(join(logDir, "task-runner.log"), `[${new Date().toISOString()}] ${msg}\n`);
}
