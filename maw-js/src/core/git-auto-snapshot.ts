/**
 * git-auto-snapshot.ts — Auto-commit before agent runs, rollback on failure
 *
 * Creates a Git snapshot (auto commit with tag) before an agent starts working.
 * On failure, can rollback to the snapshot instantly.
 *
 * Flow:
 *   Before task:  git add -A → git commit "auto-snapshot: {task}" → git tag "snapshot-{timestamp}"
 *   On success:   tag is kept as audit trail
 *   On failure:   git reset --hard {tag} → workspace restored
 *
 * This ensures:
 * - No work is ever permanently lost
 * - Failed agent runs can be instantly reverted
 * - Full audit trail of every agent action
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "fs";
import { join, resolve } from "path";
import { execSync } from "child_process";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const PSI_DIR = join(PROJECT_ROOT, "ψ");
const SNAPSHOTS_FILE = join(PSI_DIR, "memory", "git-snapshots.json");
const LOG_DIR = join(PSI_DIR, "memory", "logs");

export interface Snapshot {
  id: string;
  tag: string;
  commitHash: string;
  agent: string;
  taskDescription: string;
  createdAt: string;
  rolledBack: boolean;
  rolledBackAt: string | null;
}

export interface SnapshotConfig {
  repoDir: string;                    // Git repo to snapshot (default: PROJECT_ROOT)
  autoPush: boolean;                  // Push after snapshot (default: false)
  maxSnapshots: number;               // Max snapshots to keep (default: 50)
  tagPrefix: string;                  // Tag prefix (default: "auto-snapshot")
}

const DEFAULT_CONFIG: SnapshotConfig = {
  repoDir: PROJECT_ROOT,
  autoPush: false,
  maxSnapshots: 50,
  tagPrefix: "auto-snapshot",
};

// ─── State Management ───

function loadSnapshots(): Snapshot[] {
  if (!existsSync(SNAPSHOTS_FILE)) return [];
  try {
    return JSON.parse(readFileSync(SNAPSHOTS_FILE, "utf-8"));
  } catch {
    return [];
  }
}

function saveSnapshots(snapshots: Snapshot[]): void {
  mkdirSync(PSI_DIR, { recursive: true });
  // Keep only recent snapshots
  const trimmed = snapshots.slice(-50);
  writeFileSync(SNAPSHOTS_FILE, JSON.stringify(trimmed, null, 2));
}

// ─── Git Helpers ───

function git(cmd: string, config: SnapshotConfig): string {
  try {
    return execSync(`git ${cmd}`, {
      cwd: config.repoDir,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
  } catch (e: any) {
    throw new Error(`git ${cmd} failed: ${e.stderr || e.message}`);
  }
}

function isGitRepo(config: SnapshotConfig): boolean {
  try {
    git("rev-parse --git-dir", config);
    return true;
  } catch {
    return false;
  }
}

function hasChanges(config: SnapshotConfig): boolean {
  try {
    const status = git("status --porcelain", config);
    return status.length > 0;
  } catch {
    return false;
  }
}

// ─── Core Logic ───

/**
 * Create a snapshot before an agent starts working.
 * Returns the snapshot info, or null if no changes to snapshot.
 */
export function createSnapshot(
  agent: string,
  taskDescription: string,
  config: SnapshotConfig = DEFAULT_CONFIG,
): Snapshot | null {
  if (!isGitRepo(config)) {
    log(`Cannot snapshot: ${config.repoDir} is not a git repo`);
    return null;
  }

  if (!hasChanges(config)) {
    log(`No changes to snapshot for agent=${agent}, task="${taskDescription}"`);
    return null;
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const tag = `${config.tagPrefix}-${timestamp}`;
  const id = `snap-${Date.now()}`;

  try {
    // Stage all changes
    git("add -A", config);

    // Create commit
    const commitMsg = `auto-snapshot: ${taskDescription.slice(0, 80)} [agent=${agent}]`;
    git(`commit -m "${commitMsg.replace(/"/g, '\\"')}" --allow-empty-message`, config);

    // Get commit hash
    const commitHash = git("rev-parse HEAD", config);

    // Create tag
    git(`tag ${tag}`, config);

    // Optional push
    if (config.autoPush) {
      try {
        git("push --follow-tags", config);
      } catch (e: any) {
        log(`Warning: push failed: ${e.message}`);
      }
    }

    const snapshot: Snapshot = {
      id,
      tag,
      commitHash,
      agent,
      taskDescription,
      createdAt: new Date().toISOString(),
      rolledBack: false,
      rolledBackAt: null,
    };

    // Save to state
    const snapshots = loadSnapshots();
    snapshots.push(snapshot);
    saveSnapshots(snapshots);

    log(`Created snapshot: ${tag} (${commitHash}) for agent=${agent}`);
    return snapshot;

  } catch (e: any) {
    log(`Failed to create snapshot: ${e.message}`);
    return null;
  }
}

/**
 * Rollback to a specific snapshot.
 * Restores the workspace to the state it was in when the snapshot was taken.
 */
export function rollback(
  snapshotId: string,
  config: SnapshotConfig = DEFAULT_CONFIG,
): { success: boolean; message: string } {
  const snapshots = loadSnapshots();
  const snapshot = snapshots.find(s => s.id === snapshotId);

  if (!snapshot) {
    return { success: false, message: `Snapshot ${snapshotId} not found` };
  }

  if (snapshot.rolledBack) {
    return { success: false, message: `Snapshot ${snapshotId} already rolled back` };
  }

  try {
    // Reset to the snapshot commit
    git(`reset --hard ${snapshot.commitHash}`, config);

    // Mark as rolled back
    snapshot.rolledBack = true;
    snapshot.rolledBackAt = new Date().toISOString();
    saveSnapshots(snapshots);

    log(`Rolled back to snapshot: ${snapshot.tag} (${snapshot.commitHash})`);
    return { success: true, message: `Rolled back to ${snapshot.tag}` };

  } catch (e: any) {
    log(`Rollback failed: ${e.message}`);
    return { success: false, message: `Rollback failed: ${e.message}` };
  }
}

/**
 * Rollback to the most recent snapshot for an agent.
 */
export function rollbackLatestForAgent(
  agent: string,
  config: SnapshotConfig = DEFAULT_CONFIG,
): { success: boolean; message: string } {
  const snapshots = loadSnapshots();
  const agentSnapshot = [...snapshots]
    .reverse()
    .find(s => s.agent === agent && !s.rolledBack);

  if (!agentSnapshot) {
    return { success: false, message: `No snapshots found for agent ${agent}` };
  }

  return rollback(agentSnapshot.id, config);
}

/**
 * List all snapshots, optionally filtered by agent.
 */
export function listSnapshots(agent?: string): Snapshot[] {
  const snapshots = loadSnapshots();
  if (agent) return snapshots.filter(s => s.agent === agent);
  return snapshots;
}

/**
 * Clean up old snapshots (keep only recent N).
 */
export function cleanupSnapshots(maxAge: number = 30 * 24 * 60 * 60 * 1000): number {
  const snapshots = loadSnapshots();
  const cutoff = Date.now() - maxAge;
  const fresh = snapshots.filter(s => new Date(s.createdAt).getTime() > cutoff);
  const removed = snapshots.length - fresh.length;

  // Also remove old git tags
  for (const s of snapshots) {
    if (new Date(s.createdAt).getTime() <= cutoff) {
      try {
        git(`tag -d ${s.tag}`, DEFAULT_CONFIG);
      } catch { /* tag may already be gone */ }
    }
  }

  saveSnapshots(fresh);
  if (removed > 0) log(`Cleaned up ${removed} old snapshots`);
  return removed;
}

// ─── Logging ───

function log(msg: string): void {
  mkdirSync(LOG_DIR, { recursive: true });
  appendFileSync(join(LOG_DIR, "git-snapshots.log"), `[${new Date().toISOString()}] ${msg}\n`);
}

export default {
  createSnapshot, rollback, rollbackLatestForAgent, listSnapshots, cleanupSnapshots, DEFAULT_CONFIG,
};
