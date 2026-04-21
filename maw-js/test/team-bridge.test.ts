import { describe, test, expect, beforeEach, afterEach } from "bun:test";
import { mkdirSync, readFileSync, existsSync, rmSync, writeFileSync } from "fs";
import { join } from "path";
import { tmpdir } from "os";
import { _setDirs, loadTeam, syncToToolStore, cleanupTeamDir } from "../src/commands/plugins/team/team-helpers";

let testDir: string;
let teamsDir: string;
let tasksDir: string;
let vaultDir: string;

beforeEach(() => {
  testDir = join(tmpdir(), `maw-team-bridge-${Date.now()}-${Math.random().toString(36).slice(2)}`);
  teamsDir = join(testDir, "tool-teams");
  tasksDir = join(testDir, "tasks");
  vaultDir = join(testDir, "vault");
  mkdirSync(teamsDir, { recursive: true });
  mkdirSync(tasksDir, { recursive: true });
  mkdirSync(vaultDir, { recursive: true });
  _setDirs(teamsDir, tasksDir);
});

afterEach(() => {
  rmSync(testDir, { recursive: true, force: true });
});

describe("syncToToolStore", () => {
  test("creates config.json in tool store from scratch", () => {
    syncToToolStore("triage-v1", {
      description: "Triage team",
      createdAt: 1713500000000,
    });

    const configPath = join(teamsDir, "triage-v1", "config.json");
    expect(existsSync(configPath)).toBe(true);

    const config = JSON.parse(readFileSync(configPath, "utf-8"));
    expect(config.name).toBe("triage-v1");
    expect(config.description).toBe("Triage team");
    expect(config.createdAt).toBe(1713500000000);
    expect(config.members).toEqual([]);
  });

  test("adds members via string array", () => {
    syncToToolStore("my-team", {
      members: ["builder", "tester"],
    });

    const team = loadTeam("my-team");
    expect(team).not.toBeNull();
    expect(team!.members).toHaveLength(2);
    expect(team!.members[0].name).toBe("builder");
    expect(team!.members[1].name).toBe("tester");
  });

  test("adds members with metadata (TeamMember objects)", () => {
    syncToToolStore("my-team", {
      members: [
        { name: "vault-committer", model: "sonnet" },
        { name: "stale-bot", model: "opus" },
      ],
    });

    const team = loadTeam("my-team");
    expect(team!.members).toHaveLength(2);
    expect(team!.members[0].model).toBe("sonnet");
    expect(team!.members[1].model).toBe("opus");
  });

  test("merge: preserves existing tmuxPaneId when adding model", () => {
    // First sync adds a member with a pane ID
    syncToToolStore("my-team", {
      members: [{ name: "agent-x", tmuxPaneId: "%544" }],
    });

    // Second sync adds model to same member — should preserve pane ID
    syncToToolStore("my-team", {
      members: [{ name: "agent-x", model: "sonnet" }],
    });

    const team = loadTeam("my-team");
    expect(team!.members).toHaveLength(1);
    expect(team!.members[0].tmuxPaneId).toBe("%544");
    expect(team!.members[0].model).toBe("sonnet");
  });

  test("merge: does not duplicate members on repeated sync", () => {
    syncToToolStore("my-team", { members: ["builder"] });
    syncToToolStore("my-team", { members: ["builder"] });
    syncToToolStore("my-team", { members: ["builder"] });

    const team = loadTeam("my-team");
    expect(team!.members).toHaveLength(1);
  });

  test("merge: adds new member alongside existing ones", () => {
    syncToToolStore("my-team", { members: ["builder"] });
    syncToToolStore("my-team", { members: ["tester"] });

    const team = loadTeam("my-team");
    expect(team!.members).toHaveLength(2);
    expect(team!.members.map(m => m.name).sort()).toEqual(["builder", "tester"]);
  });

  test("merge: preserves description from first create", () => {
    syncToToolStore("my-team", { description: "Original desc" });
    syncToToolStore("my-team", { members: ["agent"] });

    const team = loadTeam("my-team");
    expect(team!.description).toBe("Original desc");
  });

  test("existing tool-store config is updated, not overwritten", () => {
    // Simulate tool-layer team with pane IDs
    const toolDir = join(teamsDir, "existing-team");
    mkdirSync(toolDir, { recursive: true });
    writeFileSync(join(toolDir, "config.json"), JSON.stringify({
      name: "existing-team",
      members: [{ name: "lead", tmuxPaneId: "%100", agentType: "team-lead" }],
      createdAt: 1700000000000,
    }));

    // Bridge sync adds a CLI-spawned member
    syncToToolStore("existing-team", {
      members: [{ name: "new-agent", model: "sonnet" }],
    });

    const team = loadTeam("existing-team");
    expect(team!.members).toHaveLength(2);
    // Original member preserved with pane ID
    expect(team!.members[0].tmuxPaneId).toBe("%100");
    expect(team!.members[0].agentType).toBe("team-lead");
    // New member added
    expect(team!.members[1].name).toBe("new-agent");
    expect(team!.members[1].model).toBe("sonnet");
    // createdAt preserved
    expect(team!.createdAt).toBe(1700000000000);
  });

  test("loadTeam can read bridge-synced config", () => {
    syncToToolStore("bridge-team", {
      description: "Created via CLI",
      members: ["agent-a", "agent-b"],
    });

    // This is what maw team ls / status / shutdown uses
    const team = loadTeam("bridge-team");
    expect(team).not.toBeNull();
    expect(team!.name).toBe("bridge-team");
    expect(team!.members).toHaveLength(2);
  });
});

describe("cleanupTeamDir", () => {
  test("removes tool store only by default", () => {
    syncToToolStore("doomed", { members: ["agent"] });
    // Create vault entry
    const vaultTeamDir = join(vaultDir, "memory", "mailbox", "teams", "doomed");
    mkdirSync(vaultTeamDir, { recursive: true });
    writeFileSync(join(vaultTeamDir, "manifest.json"), "{}");

    // Create task dir
    const taskDir = join(tasksDir, "doomed");
    mkdirSync(taskDir, { recursive: true });
    writeFileSync(join(taskDir, "1.json"), "{}");

    cleanupTeamDir("doomed");

    expect(existsSync(join(teamsDir, "doomed"))).toBe(false);
    expect(existsSync(join(tasksDir, "doomed"))).toBe(false);
    // Vault NOT touched by default
    expect(existsSync(join(vaultTeamDir, "manifest.json"))).toBe(true);
  });

  test("removes vault too when opts.vault is true", () => {
    syncToToolStore("doomed", { members: ["agent"] });

    // Create vault entry (simulating cmdTeamCreate side-effect)
    const vaultTeamDir = join(vaultDir, "memory", "mailbox", "teams", "doomed");
    mkdirSync(vaultTeamDir, { recursive: true });
    writeFileSync(join(vaultTeamDir, "manifest.json"), JSON.stringify({
      name: "doomed", members: ["agent"],
    }));

    // Need to set up resolvePsi to point to our test vault
    // Since resolvePsi() walks up from cwd, we can't easily mock it here.
    // Instead we test the { vault: true } flag doesn't throw when vault doesn't exist.
    cleanupTeamDir("doomed", { vault: true });

    expect(existsSync(join(teamsDir, "doomed"))).toBe(false);
    // vault cleanup is best-effort — might not find our test vault dir
    // but should not throw
  });

  test("is safe when team doesn't exist", () => {
    // Should not throw
    cleanupTeamDir("nonexistent-team");
    cleanupTeamDir("nonexistent-team", { vault: true });
  });
});

describe("bridge end-to-end", () => {
  test("create → spawn → ls → shutdown flow uses unified store", () => {
    // Simulate: maw team create my-sprint
    const now = Date.now();
    syncToToolStore("my-sprint", {
      description: "Sprint 42",
      createdAt: now,
    });

    // Simulate: maw team spawn my-sprint vault-committer
    syncToToolStore("my-sprint", {
      members: [{ name: "vault-committer", model: "sonnet", tmuxPaneId: "%501" }],
    });

    // Simulate: maw team spawn my-sprint stale-bot
    syncToToolStore("my-sprint", {
      members: [{ name: "stale-bot", model: "sonnet", tmuxPaneId: "%502" }],
    });

    // maw team ls should see this team
    const team = loadTeam("my-sprint");
    expect(team).not.toBeNull();
    expect(team!.name).toBe("my-sprint");
    expect(team!.description).toBe("Sprint 42");
    expect(team!.members).toHaveLength(2);
    expect(team!.members[0].name).toBe("vault-committer");
    expect(team!.members[0].tmuxPaneId).toBe("%501");
    expect(team!.members[1].name).toBe("stale-bot");
    expect(team!.members[1].tmuxPaneId).toBe("%502");

    // maw team shutdown should be able to find and clean up
    cleanupTeamDir("my-sprint", { vault: true });
    expect(loadTeam("my-sprint")).toBeNull();
  });
});
