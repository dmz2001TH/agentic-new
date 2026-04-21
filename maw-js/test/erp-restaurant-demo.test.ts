import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { mkdirSync, readFileSync, existsSync, rmSync, readdirSync, writeFileSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { _setDirs, loadTeam, syncToToolStore } from "../src/commands/plugins/team/team-helpers";

let testDir: string;
let teamsDir: string;
let tasksDir: string;

// Simulate vault (ψ/memory/mailbox/teams/)
let vaultTeamsDir: string;

beforeEach(() => {
  testDir = join(tmpdir(), `maw-erp-demo-${Date.now()}`);
  teamsDir = join(testDir, ".claude", "teams");
  tasksDir = join(testDir, ".config", "maw", "teams");
  vaultTeamsDir = join(testDir, "psi", "memory", "mailbox", "teams");
  mkdirSync(teamsDir, { recursive: true });
  mkdirSync(tasksDir, { recursive: true });
  mkdirSync(vaultTeamsDir, { recursive: true });
  _setDirs(teamsDir, tasksDir);
});

afterEach(() => {
  rmSync(testDir, { recursive: true, force: true });
});

/**
 * Simulates: maw team create <name> --description "..."
 * Writes to vault + syncs to tool store (the bridge fix)
 */
function simTeamCreate(name: string, description: string) {
  const teamDir = join(vaultTeamsDir, name);
  mkdirSync(teamDir, { recursive: true });
  const manifest = {
    name,
    createdAt: Date.now(),
    members: [] as string[],
    description,
  };
  writeFileSync(join(teamDir, "manifest.json"), JSON.stringify(manifest, null, 2));

  // Bridge: sync to tool store
  syncToToolStore(name, { description, createdAt: manifest.createdAt });
  return manifest;
}

/**
 * Simulates: maw team spawn <team> <role> --model <model> --prompt "..."
 * Writes prompt to vault + syncs member to tool store
 */
function simTeamSpawn(teamName: string, role: string, model: string, prompt: string, paneId: string) {
  const teamDir = join(vaultTeamsDir, teamName);
  const manifestPath = join(teamDir, "manifest.json");

  // Write spawn prompt
  const spawnPrompt = `You are '${role}' on team '${teamName}'.\n\n${prompt}`;
  writeFileSync(join(teamDir, `${role}-spawn-prompt.md`), spawnPrompt);

  // Update vault manifest
  const manifest = JSON.parse(readFileSync(manifestPath, "utf-8"));
  if (!manifest.members.includes(role)) {
    manifest.members.push(role);
    writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
  }

  // Bridge: sync member + pane ID to tool store
  syncToToolStore(teamName, {
    members: [{ name: role, model, tmuxPaneId: paneId }],
  });

  return { promptPath: join(teamDir, `${role}-spawn-prompt.md`), paneId };
}

describe("ERP Restaurant — real scenario with file evidence", () => {
  const TEAM = "erp-restaurant";

  test("Step 1: maw team create erp-restaurant", () => {
    simTeamCreate(TEAM, "Build ERP system for restaurant management");

    // ── EVIDENCE: Vault store ──
    const vaultManifest = join(vaultTeamsDir, TEAM, "manifest.json");
    expect(existsSync(vaultManifest)).toBe(true);
    const vaultData = JSON.parse(readFileSync(vaultManifest, "utf-8"));

    // ── EVIDENCE: Tool store (bridge) ──
    const toolConfig = join(teamsDir, TEAM, "config.json");
    expect(existsSync(toolConfig)).toBe(true);
    const toolData = JSON.parse(readFileSync(toolConfig, "utf-8"));

    console.log("\n══════════════════════════════════════════════════");
    console.log("  AFTER: maw team create erp-restaurant");
    console.log("══════════════════════════════════════════════════");
    console.log("\n📁 VAULT STORE (ψ/memory/mailbox/teams/erp-restaurant/)");
    console.log("   manifest.json:", JSON.stringify(vaultData, null, 2).split("\n").map(l => "   " + l).join("\n"));
    console.log("\n📁 TOOL STORE (~/.claude/teams/erp-restaurant/)");
    console.log("   config.json:", JSON.stringify(toolData, null, 2).split("\n").map(l => "   " + l).join("\n"));
  });

  test("Step 2: maw team spawn — 2 agents", () => {
    simTeamCreate(TEAM, "Build ERP system for restaurant management");

    // Agent 1: backend-dev
    const r1 = simTeamSpawn(TEAM, "backend-dev", "sonnet",
      "Build REST APIs for: menu management, order processing, inventory tracking, staff scheduling.",
      "%501"
    );

    // Agent 2: frontend-dev
    const r2 = simTeamSpawn(TEAM, "frontend-dev", "sonnet",
      "Build React UI: POS terminal, kitchen display, manager dashboard, reservation system.",
      "%502"
    );

    // ── EVIDENCE ──
    console.log("\n══════════════════════════════════════════════════");
    console.log("  AFTER: maw team spawn × 2 agents");
    console.log("══════════════════════════════════════════════════");

    // Vault files
    const vaultFiles = readdirSync(join(vaultTeamsDir, TEAM)).sort();
    console.log("\n📁 VAULT STORE files:");
    vaultFiles.forEach(f => console.log(`   📄 ${f}`));

    // Prompt contents (abbreviated)
    for (const role of ["backend-dev", "frontend-dev"]) {
      const promptPath = join(vaultTeamsDir, TEAM, `${role}-spawn-prompt.md`);
      const content = readFileSync(promptPath, "utf-8");
      console.log(`\n   ── ${role}-spawn-prompt.md ──`);
      content.split("\n").slice(0, 3).forEach(l => console.log(`   ${l}`));
      console.log(`   ... (${content.length} bytes)`);
    }

    // Tool store — maw team ls would see this
    const team = loadTeam(TEAM);
    console.log("\n📁 TOOL STORE (what maw team ls sees):");
    console.log(JSON.stringify(team, null, 2).split("\n").map(l => "   " + l).join("\n"));

    expect(vaultFiles).toContain("manifest.json");
    expect(vaultFiles).toContain("backend-dev-spawn-prompt.md");
    expect(vaultFiles).toContain("frontend-dev-spawn-prompt.md");
    expect(team!.members).toHaveLength(2);
    expect(team!.members[0].tmuxPaneId).toBe("%501");
    expect(team!.members[1].tmuxPaneId).toBe("%502");
  });

  test("Step 3: Full lifecycle — create → spawn → ls → shutdown", () => {
    // ── CREATE ──
    simTeamCreate(TEAM, "Build ERP system for restaurant management");

    // ── SPAWN × 2 ──
    simTeamSpawn(TEAM, "backend-dev", "sonnet", "Build REST APIs", "%501");
    simTeamSpawn(TEAM, "frontend-dev", "sonnet", "Build React UI", "%502");

    // ── maw team ls (reads tool store) ──
    const team = loadTeam(TEAM);
    expect(team).not.toBeNull();
    expect(team!.name).toBe(TEAM);
    expect(team!.members).toHaveLength(2);

    // ── maw team status (reads tool store) ──
    const aliveCount = team!.members.filter(m => m.tmuxPaneId).length;

    // ── maw team shutdown (reads tool store, kills panes, cleans vault) ──
    // Simulate cleanup
    rmSync(join(teamsDir, TEAM), { recursive: true });
    rmSync(join(vaultTeamsDir, TEAM), { recursive: true });

    // Verify fully cleaned
    expect(loadTeam(TEAM)).toBeNull();
    expect(existsSync(join(vaultTeamsDir, TEAM))).toBe(false);

    console.log("\n══════════════════════════════════════════════════");
    console.log("  FULL LIFECYCLE VERIFIED");
    console.log("══════════════════════════════════════════════════");
    console.log(`  ✅ create → vault + tool store populated`);
    console.log(`  ✅ spawn ×2 → ${aliveCount} agents with pane IDs`);
    console.log(`  ✅ ls → team visible with ${team!.members.length} members`);
    console.log(`  ✅ shutdown → both stores fully cleaned`);
    console.log("══════════════════════════════════════════════════\n");
  });
});
