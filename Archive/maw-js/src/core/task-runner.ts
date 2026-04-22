/**
 * task-runner.ts — Autonomous goal execution engine
 *
 * Runs as part of the Maw server. Processes inbox items and pending goals
 * by dispatching tasks to the appropriate agent via tmux send-keys.
 *
 * Flow:
 *   1. Check inbox/ for new task files
 *   2. Check goals.md for pending [ ] goals
 *   3. Mark goal as active [~]
 *   4. Send task to assigned agent
 *   5. Log activity
 */

import { readFileSync, writeFileSync, existsSync, readdirSync, mkdirSync, appendFileSync, renameSync } from "fs";
import { join, resolve } from "path";
import { sendKeys, listSessions } from "../core/transport/ssh";
import { loadConfig } from "../config";
import { sendChatMessage, getChatMessages, dispatchChat, markChatRead } from "./chat";

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
 */
export async function runNextGoal(): Promise<TaskResult> {
  const goal = getNextPendingGoal();

  if (!goal) {
    return { type: "goal", action: "none", success: true, detail: "No pending goals" };
  }

  // Mark as active
  markGoalActive(goal);

  // Check if agent is online
  const agent = goal.assignee || "god";
  const online = await isAgentOnline(agent);

  if (!online) {
    log(`Goal "${goal.description}" assigned to ${agent} but agent is offline`);
    return {
      type: "goal",
      action: "agent-offline",
      success: false,
      detail: `Agent ${agent} is not online`,
    };
  }

  // Dispatch
  const taskMessage = `TASK: ${goal.description}`;
  const dispatched = await dispatchToAgent(agent, taskMessage);

  // Log
  const logDir = join(PSI_DIR, "memory", "logs");
  mkdirSync(logDir, { recursive: true });
  appendFileSync(join(logDir, "task-runner.log"),
    `[${new Date().toISOString()}] ${dispatched ? "Dispatched" : "Failed"}: ${goal.description} → ${agent}\n`);

  return {
    type: "goal",
    action: dispatched ? "dispatched" : "dispatch-failed",
    success: dispatched,
    detail: `${goal.description} → ${agent}`,
  };
}

/**
 * Full task runner cycle — process inbox + run next goal
 */
export async function runTaskCycle(): Promise<TaskResult[]> {
  const results: TaskResult[] = [];

  // 1. Process inbox (tasks)
  const inboxResults = await processInbox();
  results.push(...inboxResults);

  // 2. Process chat messages
  const allChats = readdirSync(join(PSI_DIR, "inbox")).filter(f => f.startsWith("chat-") && f.endsWith(".md"));
  for (const file of allChats) {
    try {
      const content = readFileSync(join(PSI_DIR, "inbox", file), "utf-8");
      const lines = content.split("\n");
      let to = "";
      for (const line of lines) {
        if (line.startsWith("to:")) { to = line.slice(3).trim(); break; }
      }
      
      if (to) {
        const { parseChatFile } = await import("./chat");
        const msg = parseChatFile(file, content);
        if (msg) {
          const dispatched = await dispatchChat(msg);
          if (dispatched) {
            markChatRead(file);
            results.push({ type: "inbox", action: "chat-dispatched", success: true, detail: file });
          }
        }
      }
    } catch (e: any) {
      log(`Failed to process chat ${file}: ${e.message}`);
    }
  }

  // 3. Run next pending goal
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
