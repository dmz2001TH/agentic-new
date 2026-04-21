/**
 * replanner.ts — Dynamic re-planning when task scope changes mid-execution
 *
 * Problem: Static goals don't adapt. Agent picks up a goal, starts working,
 * but discovers the task is harder/easier/different than expected.
 * With static planning: agent either gives up or pushes through wrong path.
 *
 * Solution: Monitor task progress and re-plan when:
 * 1. Task takes much longer than expected
 * 2. Agent reports blockers or new requirements
 * 3. Sub-tasks emerge that weren't in the original plan
 * 4. Quality check reveals the approach is wrong
 *
 * Flow:
 *   Original plan → Execute step → Observe → Detect drift → Re-plan → Continue
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "fs";
import { join, resolve } from "path";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const PSI_DIR = join(PROJECT_ROOT, "ψ");
const PLANS_DIR = join(PSI_DIR, "memory", "plans");
const LOG_DIR = join(PSI_DIR, "memory", "logs");

export interface PlanStep {
  id: number;
  description: string;
  status: "pending" | "active" | "done" | "failed" | "skipped";
  startedAt: string | null;
  completedAt: string | null;
  result: string | null;
  estimatedMinutes: number;
}

export interface Plan {
  id: string;
  goalId: string;
  agent: string;
  originalTask: string;
  steps: PlanStep[];
  currentStepIndex: number;
  createdAt: string;
  lastReplanAt: string | null;
  replanCount: number;
  status: "active" | "completed" | "failed" | "replanning";
  history: PlanHistoryEntry[];
}

export interface PlanHistoryEntry {
  timestamp: string;
  action: string;
  detail: string;
  previousSteps?: string[];
}

export interface ReplanTrigger {
  type: "timeout" | "blocker" | "new-requirement" | "quality-fail" | "agent-request";
  detail: string;
  stepId?: number;
}

export interface ReplanConfig {
  maxReplans: number;              // Max re-plans per goal (default: 3)
  stepTimeoutMs: number;           // Max time per step (default: 15 min)
  minProgressForContinue: number;  // Min completed steps to continue (default: 0.3)
}

const DEFAULT_CONFIG: ReplanConfig = {
  maxReplans: 3,
  stepTimeoutMs: 15 * 60 * 1000,
  minProgressForContinue: 0.3,
};

// ─── State Management ───

function planFile(planId: string): string {
  return join(PLANS_DIR, `${planId}.json`);
}

function loadPlan(planId: string): Plan | null {
  const file = planFile(planId);
  if (!existsSync(file)) return null;
  try {
    return JSON.parse(readFileSync(file, "utf-8"));
  } catch {
    return null;
  }
}

function savePlan(plan: Plan): void {
  mkdirSync(PLANS_DIR, { recursive: true });
  writeFileSync(planFile(plan.id), JSON.stringify(plan, null, 2));
}

// ─── Plan Creation ───

/**
 * Create a new plan from a task description.
 * Breaks task into steps using simple heuristics.
 */
export function createPlan(
  goalId: string,
  agent: string,
  task: string,
  steps?: string[],
): Plan {
  const planId = `plan-${goalId}-${Date.now()}`;
  const autoSteps: PlanStep[] = (steps || autoDecompose(task)).map((desc, i) => ({
    id: i + 1,
    description: desc,
    status: i === 0 ? "active" : "pending",
    startedAt: i === 0 ? new Date().toISOString() : null,
    completedAt: null,
    result: null,
    estimatedMinutes: 5,
  }));

  const plan: Plan = {
    id: planId,
    goalId,
    agent,
    originalTask: task,
    steps: autoSteps,
    currentStepIndex: 0,
    createdAt: new Date().toISOString(),
    lastReplanAt: null,
    replanCount: 0,
    status: "active",
    history: [{
      timestamp: new Date().toISOString(),
      action: "plan-created",
      detail: `${autoSteps.length} steps created`,
    }],
  };

  savePlan(plan);
  log(`Plan created: ${planId} for goal=${goalId}, ${autoSteps.length} steps`);
  return plan;
}

/**
 * Simple task decomposition — split by common patterns.
 */
function autoDecompose(task: string): string[] {
  const lines = task.split("\n").map(l => l.trim()).filter(l => l.length > 0);

  // If task has numbered/lettered items, use those
  const numbered = lines.filter(l => /^\d+[.)]\s/.test(l) || /^-\s/.test(l));
  if (numbered.length >= 2) {
    return numbered.map(l => l.replace(/^(\d+[.)]\s*|-\s*)/, "").trim());
  }

  // If task mentions "and" or "then", split
  if (/\b(then|and|แล้ว|และ)\b/i.test(task) && task.length > 100) {
    return task.split(/\b(then|and|แล้ว|และ)\b/i)
      .map(s => s.trim())
      .filter(s => s.length > 10 && !/^(then|and|แล้ว|และ)$/i.test(s));
  }

  // Default: treat as single step
  return [task];
}

// ─── Step Execution ───

/**
 * Mark current step as completed and advance.
 */
export function completeStep(
  planId: string,
  stepId: number,
  result: string,
): Plan | null {
  const plan = loadPlan(planId);
  if (!plan) return null;

  const step = plan.steps.find(s => s.id === stepId);
  if (!step) return null;

  step.status = "done";
  step.completedAt = new Date().toISOString();
  step.result = result;

  // Advance to next pending step
  const nextPending = plan.steps.find(s => s.status === "pending");
  if (nextPending) {
    nextPending.status = "active";
    nextPending.startedAt = new Date().toISOString();
    plan.currentStepIndex = plan.steps.indexOf(nextPending);
  } else {
    plan.status = "completed";
  }

  plan.history.push({
    timestamp: new Date().toISOString(),
    action: "step-completed",
    detail: `Step ${stepId}: ${step.description} → ${result.slice(0, 100)}`,
  });

  savePlan(plan);
  return plan;
}

/**
 * Mark current step as failed.
 */
export function failStep(
  planId: string,
  stepId: number,
  error: string,
): Plan | null {
  const plan = loadPlan(planId);
  if (!plan) return null;

  const step = plan.steps.find(s => s.id === stepId);
  if (!step) return null;

  step.status = "failed";
  step.completedAt = new Date().toISOString();
  step.result = `FAILED: ${error}`;

  plan.history.push({
    timestamp: new Date().toISOString(),
    action: "step-failed",
    detail: `Step ${stepId}: ${error}`,
  });

  savePlan(plan);
  return plan;
}

// ─── Re-planning Logic ───

/**
 * Check if re-planning is needed based on current state.
 */
export function shouldReplan(
  planId: string,
  config: ReplanConfig = DEFAULT_CONFIG,
): { needed: boolean; triggers: ReplanTrigger[] } {
  const plan = loadPlan(planId);
  if (!plan) return { needed: false, triggers: [] };

  const triggers: ReplanTrigger[] = [];

  // 1. Check replan limit
  if (plan.replanCount >= config.maxReplans) {
    return { needed: false, triggers: [] };
  }

  // 2. Check for timed-out steps
  for (const step of plan.steps) {
    if (step.status === "active" && step.startedAt) {
      const elapsed = Date.now() - new Date(step.startedAt).getTime();
      if (elapsed > config.stepTimeoutMs) {
        triggers.push({
          type: "timeout",
          detail: `Step ${step.id} timed out (${Math.round(elapsed / 60000)}min)`,
          stepId: step.id,
        });
      }
    }
  }

  // 3. Check for failed steps that block progress
  const failedSteps = plan.steps.filter(s => s.status === "failed");
  const completedSteps = plan.steps.filter(s => s.status === "done");
  const totalSteps = plan.steps.length;

  if (failedSteps.length > 0 && totalSteps > 0) {
    const progressRate = completedSteps.length / totalSteps;
    if (progressRate < config.minProgressForContinue && completedSteps.length < totalSteps - 1) {
      triggers.push({
        type: "quality-fail",
        detail: `Progress too low: ${completedSteps.length}/${totalSteps} done, ${failedSteps.length} failed`,
      });
    }
  }

  return { needed: triggers.length > 0, triggers };
}

/**
 * Re-plan: adjust steps based on trigger.
 * Returns new plan or null if replanning not possible.
 */
export function replan(
  planId: string,
  trigger: ReplanTrigger,
  newSteps?: string[],
  config: ReplanConfig = DEFAULT_CONFIG,
): Plan | null {
  const plan = loadPlan(planId);
  if (!plan) return null;

  if (plan.replanCount >= config.maxReplans) {
    log(`Cannot replan ${planId}: max replans (${config.maxReplans}) reached`);
    return null;
  }

  const previousSteps = plan.steps.map(s => `${s.status}: ${s.description}`);

  // Preserve completed steps
  const completedSteps = plan.steps.filter(s => s.status === "done");
  const failedStepIds = plan.steps.filter(s => s.status === "failed").map(s => s.id);

  let adjustedSteps: PlanStep[];

  if (newSteps && newSteps.length > 0) {
    // Use provided new steps
    adjustedSteps = newSteps.map((desc, i) => ({
      id: completedSteps.length + i + 1,
      description: desc,
      status: i === 0 ? "active" as const : "pending" as const,
      startedAt: i === 0 ? new Date().toISOString() : null,
      completedAt: null,
      result: null,
      estimatedMinutes: 5,
    }));
  } else {
    // Smart replan: retry failed steps with simplified description
    adjustedSteps = plan.steps.map(step => {
      if (step.status === "done") return step;
      if (step.status === "failed") {
        return {
          ...step,
          description: `[RETRY] ${step.description} — ลองวิธี simpler`,
          status: "pending" as const,
          completedAt: null,
          result: null,
        };
      }
      return step;
    });
  }

  const allSteps = [...completedSteps, ...adjustedSteps];

  // Activate first non-done step
  const firstPending = allSteps.find(s => s.status === "pending");
  if (firstPending) {
    firstPending.status = "active";
    firstPending.startedAt = new Date().toISOString();
  }

  plan.steps = allSteps;
  plan.replanCount++;
  plan.lastReplanAt = new Date().toISOString();
  plan.status = "active";
  plan.history.push({
    timestamp: new Date().toISOString(),
    action: "replanned",
    detail: `Trigger: ${trigger.type} — ${trigger.detail}`,
    previousSteps,
  });

  savePlan(plan);
  log(`Plan replanned: ${planId} (replan #${plan.replanCount}, trigger: ${trigger.type})`);
  return plan;
}

/**
 * Get current step for a plan.
 */
export function getCurrentStep(planId: string): PlanStep | null {
  const plan = loadPlan(planId);
  if (!plan) return null;
  return plan.steps.find(s => s.status === "active") || null;
}

/**
 * Get plan progress summary.
 */
export function getProgress(planId: string): {
  total: number;
  done: number;
  failed: number;
  pending: number;
  percent: number;
  currentStep: string | null;
} | null {
  const plan = loadPlan(planId);
  if (!plan) return null;

  const done = plan.steps.filter(s => s.status === "done").length;
  const failed = plan.steps.filter(s => s.status === "failed").length;
  const pending = plan.steps.filter(s => s.status === "pending" || s.status === "active").length;
  const current = plan.steps.find(s => s.status === "active");

  return {
    total: plan.steps.length,
    done,
    failed,
    pending,
    percent: plan.steps.length > 0 ? Math.round((done / plan.steps.length) * 100) : 0,
    currentStep: current?.description || null,
  };
}

// ─── Logging ───

function log(msg: string): void {
  mkdirSync(LOG_DIR, { recursive: true });
  appendFileSync(join(LOG_DIR, "replanner.log"), `[${new Date().toISOString()}] ${msg}\n`);
}

export default {
  createPlan, completeStep, failStep, shouldReplan, replan,
  getCurrentStep, getProgress, DEFAULT_CONFIG,
};
