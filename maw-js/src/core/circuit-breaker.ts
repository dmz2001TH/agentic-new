/**
 * circuit-breaker.ts — Auto-disable agents that fail repeatedly
 *
 * Pattern: 3-state circuit breaker (CLOSED → OPEN → HALF_OPEN)
 *
 * CLOSED:   Agent runs normally. Failures counted.
 * OPEN:     Agent disabled. Task rejected immediately.
 * HALF_OPEN: After cooldown, try one task. Success → CLOSED, Failure → OPEN.
 *
 * This prevents:
 * - Wasting resources on broken agents
 * - Cascade failures across the fleet
 * - Infinite retry loops on the same broken task
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "fs";
import { join, resolve } from "path";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const PSI_DIR = join(PROJECT_ROOT, "ψ");
const STATE_FILE = join(PSI_DIR, "memory", "circuit-breakers.json");
const LOG_DIR = join(PSI_DIR, "memory", "logs");

export type CircuitState = "CLOSED" | "OPEN" | "HALF_OPEN";

export interface CircuitBreakerEntry {
  agent: string;
  state: CircuitState;
  failureCount: number;
  successCount: number;
  lastFailure: string | null;
  lastStateChange: string;
  openedAt: string | null;
  cooldownMs: number;
  failureThreshold: number;
  halfOpenAttempts: number;
}

export interface CircuitBreakerConfig {
  failureThreshold: number;    // Failures before OPEN (default: 3)
  cooldownMs: number;          // Time before HALF_OPEN (default: 5 min)
  halfOpenMaxAttempts: number; // Max tasks in HALF_OPEN state (default: 1)
  resetOnSuccess: boolean;     // Reset failure count on success (default: true)
}

const DEFAULT_CONFIG: CircuitBreakerConfig = {
  failureThreshold: 3,
  cooldownMs: 5 * 60 * 1000,  // 5 minutes
  halfOpenMaxAttempts: 1,
  resetOnSuccess: true,
};

// ─── State Management ───

function loadState(): Record<string, CircuitBreakerEntry> {
  if (!existsSync(STATE_FILE)) return {};
  try {
    return JSON.parse(readFileSync(STATE_FILE, "utf-8"));
  } catch {
    return {};
  }
}

function saveState(state: Record<string, CircuitBreakerEntry>): void {
  mkdirSync(PSI_DIR, { recursive: true });
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function getOrCreateEntry(agent: string, config: CircuitBreakerConfig): CircuitBreakerEntry {
  const state = loadState();
  if (state[agent]) return state[agent];

  const entry: CircuitBreakerEntry = {
    agent,
    state: "CLOSED",
    failureCount: 0,
    successCount: 0,
    lastFailure: null,
    lastStateChange: new Date().toISOString(),
    openedAt: null,
    cooldownMs: config.cooldownMs,
    failureThreshold: config.failureThreshold,
    halfOpenAttempts: 0,
  };
  state[agent] = entry;
  saveState(state);
  return entry;
}

// ─── Core Logic ───

/**
 * Check if an agent is allowed to run a task.
 * Returns { allowed, reason, entry }
 */
export function canExecute(
  agent: string,
  config: CircuitBreakerConfig = DEFAULT_CONFIG,
): { allowed: boolean; reason: string; entry: CircuitBreakerEntry } {
  const entry = getOrCreateEntry(agent, config);

  switch (entry.state) {
    case "CLOSED":
      return { allowed: true, reason: "Circuit CLOSED — normal operation", entry };

    case "OPEN": {
      // Check if cooldown has passed
      const elapsed = Date.now() - new Date(entry.openedAt || 0).getTime();
      if (elapsed >= entry.cooldownMs) {
        // Transition to HALF_OPEN
        entry.state = "HALF_OPEN";
        entry.halfOpenAttempts = 0;
        entry.lastStateChange = new Date().toISOString();
        const state = loadState();
        state[agent] = entry;
        saveState(state);
        log(`Circuit ${agent}: OPEN → HALF_OPEN (cooldown elapsed)`);
        return { allowed: true, reason: "Circuit HALF_OPEN — testing recovery", entry };
      }
      const remainingSec = Math.round((entry.cooldownMs - elapsed) / 1000);
      return {
        allowed: false,
        reason: `Circuit OPEN — agent disabled (${remainingSec}s remaining)`,
        entry,
      };
    }

    case "HALF_OPEN": {
      if (entry.halfOpenAttempts >= config.halfOpenMaxAttempts) {
        return {
          allowed: false,
          reason: `Circuit HALF_OPEN — max test attempts reached, waiting for result`,
          entry,
        };
      }
      return { allowed: true, reason: "Circuit HALF_OPEN — test attempt allowed", entry };
    }

    default:
      return { allowed: true, reason: "Unknown state — allowing", entry };
  }
}

/**
 * Record a successful execution.
 */
export function recordSuccess(
  agent: string,
  config: CircuitBreakerConfig = DEFAULT_CONFIG,
): void {
  const state = loadState();
  const entry = state[agent] || getOrCreateEntry(agent, config);

  if (entry.state === "HALF_OPEN") {
    // Recovery confirmed
    entry.state = "CLOSED";
    entry.failureCount = 0;
    entry.halfOpenAttempts = 0;
    entry.lastStateChange = new Date().toISOString();
    entry.openedAt = null;
    log(`Circuit ${agent}: HALF_OPEN → CLOSED (recovery confirmed)`);
  } else if (config.resetOnSuccess) {
    entry.failureCount = 0;
  }

  entry.successCount++;
  state[agent] = entry;
  saveState(state);
}

/**
 * Record a failed execution.
 * May transition CLOSED→OPEN or HALF_OPEN→OPEN.
 */
export function recordFailure(
  agent: string,
  error: string,
  config: CircuitBreakerConfig = DEFAULT_CONFIG,
): { circuitOpened: boolean } {
  const state = loadState();
  const entry = state[agent] || getOrCreateEntry(agent, config);

  entry.failureCount++;
  entry.lastFailure = new Date().toISOString();

  let circuitOpened = false;

  if (entry.state === "HALF_OPEN") {
    // Recovery failed — back to OPEN
    entry.state = "OPEN";
    entry.openedAt = new Date().toISOString();
    entry.lastStateChange = new Date().toISOString();
    entry.halfOpenAttempts = 0;
    circuitOpened = true;
    log(`Circuit ${agent}: HALF_OPEN → OPEN (recovery failed: ${error})`);
  } else if (entry.state === "CLOSED" && entry.failureCount >= entry.failureThreshold) {
    // Threshold exceeded — trip the breaker
    entry.state = "OPEN";
    entry.openedAt = new Date().toISOString();
    entry.lastStateChange = new Date().toISOString();
    circuitOpened = true;
    log(`Circuit ${agent}: CLOSED → OPEN (${entry.failureCount} failures, threshold: ${entry.failureThreshold})`);
  }

  state[agent] = entry;
  saveState(state);
  return { circuitOpened };
}

/**
 * Manually reset a circuit breaker (force CLOSED).
 */
export function forceReset(agent: string): void {
  const state = loadState();
  if (state[agent]) {
    state[agent].state = "CLOSED";
    state[agent].failureCount = 0;
    state[agent].halfOpenAttempts = 0;
    state[agent].openedAt = null;
    state[agent].lastStateChange = new Date().toISOString();
    saveState(state);
    log(`Circuit ${agent}: manual reset → CLOSED`);
  }
}

/**
 * Get status of all circuit breakers.
 */
export function getAllStatuses(): CircuitBreakerEntry[] {
  const state = loadState();
  return Object.values(state);
}

/**
 * Get status for a specific agent.
 */
export function getStatus(agent: string): CircuitBreakerEntry | null {
  const state = loadState();
  return state[agent] || null;
}

// ─── Logging ───

function log(msg: string): void {
  mkdirSync(LOG_DIR, { recursive: true });
  appendFileSync(join(LOG_DIR, "circuit-breaker.log"), `[${new Date().toISOString()}] ${msg}\n`);
}

export default {
  canExecute, recordSuccess, recordFailure, forceReset, getAllStatuses, getStatus, DEFAULT_CONFIG,
};
