/**
 * alert.ts — Real-time alerting via WebSocket feed
 *
 * Pushes critical events to connected dashboard clients instantly.
 * No polling. No manual scan. Agent goes down → dashboard knows NOW.
 *
 * Integrates with existing MawEngine feed system.
 * Events are also persisted to ψ/memory/logs/alerts.log for audit.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "fs";
import { join, resolve } from "path";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const PSI_DIR = join(PROJECT_ROOT, "ψ");
const ALERTS_FILE = join(PSI_DIR, "memory", "alerts-state.json");
const LOG_DIR = join(PSI_DIR, "memory", "logs");

export type AlertSeverity = "info" | "warning" | "critical";
export type AlertCategory =
  | "agent-down"
  | "agent-recovered"
  | "circuit-opened"
  | "circuit-closed"
  | "task-failed"
  | "task-timeout"
  | "snapshot-created"
  | "snapshot-rolled-back"
  | "replan-triggered"
  | "plan-completed"
  | "plan-failed"
  | "fleet-health";

export interface Alert {
  id: string;
  category: AlertCategory;
  severity: AlertSeverity;
  title: string;
  detail: string;
  agent: string | null;
  timestamp: string;
  acknowledged: boolean;
  acknowledgedAt: string | null;
  metadata: Record<string, any>;
}

export interface AlertConfig {
  /** Min severity to push to WebSocket (default: "warning") */
  minPushSeverity: AlertSeverity;
  /** Cooldown between same-category alerts in ms (default: 30s) */
  dedupCooldownMs: number;
  /** Max alerts to keep in memory (default: 200) */
  maxAlerts: number;
  /** Optional WebSocket broadcast function (set by MawEngine) */
  broadcast?: (event: { type: string; data: any }) => void;
}

const DEFAULT_CONFIG: AlertConfig = {
  minPushSeverity: "warning",
  dedupCooldownMs: 30 * 1000,
  maxAlerts: 200,
};

// ─── Severity Weights ───

const SEVERITY_WEIGHT: Record<AlertSeverity, number> = {
  info: 0,
  warning: 1,
  critical: 2,
};

// ─── State Management ───

let currentConfig: AlertConfig = { ...DEFAULT_CONFIG };
let recentAlerts: Alert[] = [];
let lastAlertByCategory: Record<string, string> = {};

function loadState(): void {
  if (!existsSync(ALERTS_FILE)) return;
  try {
    const data = JSON.parse(readFileSync(ALERTS_FILE, "utf-8"));
    recentAlerts = data.alerts || [];
    lastAlertByCategory = data.lastByCategory || {};
  } catch { /* fresh start */ }
}

function saveState(): void {
  mkdirSync(PSI_DIR, { recursive: true });
  const trimmed = recentAlerts.slice(-currentConfig.maxAlerts);
  writeFileSync(ALERTS_FILE, JSON.stringify({
    alerts: trimmed,
    lastByCategory: lastAlertByCategory,
  }, null, 2));
}

// Load on module init
loadState();

// ─── Core Logic ───

/**
 * Configure the alert system. Call once at server startup.
 */
export function configure(config: Partial<AlertConfig>): void {
  currentConfig = { ...DEFAULT_CONFIG, ...config };
}

/**
 * Fire an alert. Handles dedup, push, and persistence.
 */
export function fire(
  category: AlertCategory,
  title: string,
  detail: string,
  options: {
    agent?: string | null;
    severity?: AlertSeverity;
    metadata?: Record<string, any>;
  } = {},
): Alert {
  const severity = options.severity || inferSeverity(category);
  const agent = options.agent || null;

  // Dedup check
  const now = Date.now();
  const lastTime = lastAlertByCategory[`${category}:${agent}`] || lastAlertByCategory[category];
  if (lastTime) {
    const elapsed = now - new Date(lastTime).getTime();
    if (elapsed < currentConfig.dedupCooldownMs) {
      // Suppressed — too soon after last same-category alert
      log(`Alert suppressed (dedup): ${category} (${Math.round(elapsed / 1000)}s ago)`);
      // Return the previous alert
      return recentAlerts[recentAlerts.length - 1] || createStubAlert(category, title, detail);
    }
  }

  const alert: Alert = {
    id: `alert-${now}-${Math.random().toString(36).slice(2, 6)}`,
    category,
    severity,
    title,
    detail,
    agent,
    timestamp: new Date().toISOString(),
    acknowledged: false,
    acknowledgedAt: null,
    metadata: options.metadata || {},
  };

  // Store
  recentAlerts.push(alert);
  lastAlertByCategory[`${category}:${agent}`] = alert.timestamp;
  lastAlertByCategory[category] = alert.timestamp;
  saveState();

  // Log
  log(`ALERT [${severity.toUpperCase()}] ${category}: ${title} — ${detail}`);

  // Push to WebSocket if meets threshold
  if (currentConfig.broadcast && SEVERITY_WEIGHT[severity] >= SEVERITY_WEIGHT[currentConfig.minPushSeverity]) {
    try {
      currentConfig.broadcast({
        type: "alert",
        data: {
          id: alert.id,
          category: alert.category,
          severity: alert.severity,
          title: alert.title,
          detail: alert.detail,
          agent: alert.agent,
          timestamp: alert.timestamp,
        },
      });
    } catch (e: any) {
      log(`Broadcast failed: ${e.message}`);
    }
  }

  return alert;
}

/**
 * Acknowledge an alert (mark as seen/handled).
 */
export function acknowledge(alertId: string): boolean {
  const alert = recentAlerts.find(a => a.id === alertId);
  if (!alert) return false;

  alert.acknowledged = true;
  alert.acknowledgedAt = new Date().toISOString();
  saveState();
  return true;
}

/**
 * Acknowledge all unacknowledged alerts.
 */
export function acknowledgeAll(): number {
  let count = 0;
  for (const alert of recentAlerts) {
    if (!alert.acknowledged) {
      alert.acknowledged = true;
      alert.acknowledgedAt = new Date().toISOString();
      count++;
    }
  }
  if (count > 0) saveState();
  return count;
}

/**
 * Get recent alerts, optionally filtered.
 */
export function getAlerts(options: {
  category?: AlertCategory;
  severity?: AlertSeverity;
  agent?: string;
  unacknowledgedOnly?: boolean;
  limit?: number;
} = {}): Alert[] {
  let filtered = [...recentAlerts];

  if (options.category) filtered = filtered.filter(a => a.category === options.category);
  if (options.severity) filtered = filtered.filter(a => a.severity === options.severity);
  if (options.agent) filtered = filtered.filter(a => a.agent === options.agent);
  if (options.unacknowledgedOnly) filtered = filtered.filter(a => !a.acknowledged);

  filtered.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
  return filtered.slice(0, options.limit || 50);
}

/**
 * Get alert summary stats.
 */
export function getStats(): {
  total: number;
  unacknowledged: number;
  bySeverity: Record<AlertSeverity, number>;
  byCategory: Record<string, number>;
} {
  const bySeverity: Record<AlertSeverity, number> = { info: 0, warning: 0, critical: 0 };
  const byCategory: Record<string, number> = {};
  let unacknowledged = 0;

  for (const alert of recentAlerts) {
    bySeverity[alert.severity]++;
    byCategory[alert.category] = (byCategory[alert.category] || 0) + 1;
    if (!alert.acknowledged) unacknowledged++;
  }

  return { total: recentAlerts.length, unacknowledged, bySeverity, byCategory };
}

/**
 * Infer severity from category.
 */
function inferSeverity(category: AlertCategory): AlertSeverity {
  switch (category) {
    case "agent-down":
    case "circuit-opened":
    case "plan-failed":
      return "critical";
    case "task-failed":
    case "task-timeout":
    case "replan-triggered":
    case "snapshot-rolled-back":
      return "warning";
    default:
      return "info";
  }
}

function createStubAlert(category: string, title: string, detail: string): Alert {
  return {
    id: "dedup-stub",
    category: category as AlertCategory,
    severity: "info",
    title, detail, agent: null,
    timestamp: new Date().toISOString(),
    acknowledged: true,
    acknowledgedAt: new Date().toISOString(),
    metadata: {},
  };
}

// ─── Logging ───

function log(msg: string): void {
  mkdirSync(LOG_DIR, { recursive: true });
  appendFileSync(join(LOG_DIR, "alerts.log"), `[${new Date().toISOString()}] ${msg}\n`);
}

export default {
  configure, fire, acknowledge, acknowledgeAll, getAlerts, getStats,
};
