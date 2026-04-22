import { readFileSync, writeFileSync, existsSync, rmSync, mkdirSync } from "fs";
import { join, dirname } from "path";
import { homedir } from "os";

// Exported for testing — override with _setDirs
export let TEAMS_DIR = join(homedir(), ".claude/teams");
export let TASKS_DIR = join(homedir(), ".claude/tasks");

/** @internal — for tests only */
export function _setDirs(teams: string, tasks: string) {
  TEAMS_DIR = teams;
  TASKS_DIR = tasks;
}

export interface TeamMember {
  name: string;
  agentId?: string;
  agentType?: string;
  tmuxPaneId?: string;
  color?: string;
  model?: string;
  backendType?: string;
}

export interface TeamConfig {
  name: string;
  description?: string;
  members: TeamMember[];
  createdAt?: number;
}

export function loadTeam(name: string): TeamConfig | null {
  const configPath = join(TEAMS_DIR, name, "config.json");
  if (!existsSync(configPath)) return null;
  try { return JSON.parse(readFileSync(configPath, "utf-8")); }
  catch { return null; }
}

/**
 * Resolve ψ/ directory by walking UP from cwd looking for an oracle root
 * (marked by CLAUDE.md + ψ/). Falls back to cwd/ψ for backward compat when
 * no marker is found. Prevents rogue nested vaults when the CLI is run from
 * a sub-directory (#393 — Bug A).
 */
export function resolvePsi(): string {
  let dir = process.cwd();
  // Walk up looking for an oracle root (CLAUDE.md + ψ/ both present)
  while (true) {
    const psi = join(dir, "ψ");
    if (existsSync(psi) && existsSync(join(dir, "CLAUDE.md"))) return psi;
    const parent = dirname(dir);
    if (parent === dir) break; // reached filesystem root
    dir = parent;
  }
  // Fallback: legacy behavior — cwd/ψ, callers mkdir as needed
  return join(process.cwd(), "ψ");
}

/**
 * Write a shutdown_request message to a teammate's inbox file.
 * This is the same protocol Claude Code uses internally via SendMessage.
 */
export function writeShutdownRequest(teamName: string, memberName: string, reason: string): void {
  const inboxPath = join(TEAMS_DIR, teamName, "inboxes", `${memberName}.json`);
  let messages: any[] = [];
  if (existsSync(inboxPath)) {
    try { messages = JSON.parse(readFileSync(inboxPath, "utf-8")); } catch { messages = []; }
  }
  const requestId = `shutdown-${Date.now()}@${memberName}`;
  messages.push({
    from: "maw-team-shutdown",
    text: JSON.stringify({ type: "shutdown_request", reason, request_id: requestId }),
    summary: `Shutdown request: ${reason}`,
    timestamp: new Date().toISOString(),
    read: false,
  });
  writeFileSync(inboxPath, JSON.stringify(messages, null, 2));
}

/**
 * Write a generic message to a teammate's inbox file.
 * Same protocol as writeShutdownRequest but with type: "message".
 */
export function writeMessage(teamName: string, memberName: string, from: string, text: string): void {
  const inboxPath = join(TEAMS_DIR, teamName, "inboxes", `${memberName}.json`);
  let messages: any[] = [];
  if (existsSync(inboxPath)) {
    try { messages = JSON.parse(readFileSync(inboxPath, "utf-8")); } catch { messages = []; }
  }
  messages.push({
    from,
    text: JSON.stringify({ type: "message", content: text }),
    summary: text.slice(0, 80),
    timestamp: new Date().toISOString(),
    read: false,
  });
  const dir = join(TEAMS_DIR, teamName, "inboxes");
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  writeFileSync(inboxPath, JSON.stringify(messages, null, 2));
}

/**
 * Bridge: sync a team's config.json to the tool store (~/.claude/teams/<name>/config.json)
 * so that ls, status, and shutdown can find CLI-created teams (#393 two-store split fix).
 *
 * Creates or updates the tool-store config from the vault manifest + member data.
 * Safe to call multiple times — idempotent merge on members.
 */
export function syncToToolStore(
  teamName: string,
  opts: {
    description?: string;
    members?: Array<string | TeamMember>;
    createdAt?: number;
  } = {},
) {
  const toolDir = join(TEAMS_DIR, teamName);
  mkdirSync(toolDir, { recursive: true });

  const configPath = join(toolDir, "config.json");
  let existing: TeamConfig | null = null;
  if (existsSync(configPath)) {
    try { existing = JSON.parse(readFileSync(configPath, "utf-8")); } catch { /* overwrite */ }
  }

  const incomingMembers: TeamMember[] = (opts.members ?? []).map(m => {
    if (typeof m === "string") return { name: m };
    return m;
  });

  // Merge: keep existing members, add/update incoming by name
  const mergedByName = new Map<string, TeamMember>();
  if (existing?.members) {
    for (const m of existing.members) mergedByName.set(m.name, m);
  }
  for (const m of incomingMembers) {
    const prev = mergedByName.get(m.name);
    mergedByName.set(m.name, prev ? { ...prev, ...m } : m);
  }

  const config: TeamConfig = {
    name: teamName,
    description: opts.description ?? existing?.description ?? "",
    members: Array.from(mergedByName.values()),
    createdAt: opts.createdAt ?? existing?.createdAt ?? Date.now(),
  };

  writeFileSync(configPath, JSON.stringify(config, null, 2));
}

/**
 * Clean up all stores for a team: tool store, vault, and task store.
 * #393 — unified cleanup across all three stores.
 *
 * @param name - team name
 * @param opts.vault - also remove vault manifest (default: false for backward compat;
 *   set to true when shutting down CLI-created teams so they don't reappear in ls)
 */
export function cleanupTeamDir(name: string, opts: { vault?: boolean } = {}) {
  const teamDir = join(TEAMS_DIR, name);
  const tasksDir = join(TASKS_DIR, name);
  if (existsSync(teamDir)) { try { rmSync(teamDir, { recursive: true }); } catch {} }
  if (existsSync(tasksDir)) { try { rmSync(tasksDir, { recursive: true }); } catch {} }

  // #393: Also clean up vault store so CLI-created teams don't reappear
  if (opts.vault) {
    try {
      const vaultTeamDir = join(resolvePsi(), "memory", "mailbox", "teams", name);
      if (existsSync(vaultTeamDir)) { rmSync(vaultTeamDir, { recursive: true }); }
    } catch { /* best effort */ }
  }
}
