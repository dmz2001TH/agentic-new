import { describe, test, expect } from "bun:test";
import { buildEnhancedSpawnPrompt, scanProjectContext } from "../src/commands/plugins/team/spawn-prompt-builder";

describe("buildEnhancedSpawnPrompt", () => {
  test("includes role and team name", () => {
    const prompt = buildEnhancedSpawnPrompt({
      role: "backend-dev",
      teamName: "erp-restaurant",
      userPrompt: "Build REST APIs",
    });
    expect(prompt).toContain("# Role: backend-dev");
    expect(prompt).toContain("**Team:** erp-restaurant");
  });

  test("includes structured process steps", () => {
    const prompt = buildEnhancedSpawnPrompt({
      role: "coder",
      teamName: "sprint-1",
      userPrompt: "Write code",
    });
    expect(prompt).toContain("## Process");
    expect(prompt).toContain("1. **Understand**");
    expect(prompt).toContain("2. **Explore**");
    expect(prompt).toContain("3. **Plan**");
    expect(prompt).toContain("4. **Execute**");
    expect(prompt).toContain("5. **Validate**");
    expect(prompt).toContain("6. **Report**");
  });

  test("includes output format template", () => {
    const prompt = buildEnhancedSpawnPrompt({
      role: "coder",
      teamName: "sprint-1",
      userPrompt: "Write code",
    });
    expect(prompt).toContain("## Output Format");
    expect(prompt).toContain("## Summary");
    expect(prompt).toContain("## Changes Made");
    expect(prompt).toContain("## Blockers");
    expect(prompt).toContain("## Next Steps");
  });

  test("includes rules section", () => {
    const prompt = buildEnhancedSpawnPrompt({
      role: "coder",
      teamName: "sprint-1",
      userPrompt: "Write code",
    });
    expect(prompt).toContain("## Rules");
    expect(prompt).toContain("Do NOT delete existing code");
    expect(prompt).toContain("try 2 different approaches");
  });

  test("includes teammates for cross-agent comms", () => {
    const prompt = buildEnhancedSpawnPrompt({
      role: "backend-dev",
      teamName: "erp",
      userPrompt: "Build APIs",
      teammates: ["backend-dev", "frontend-dev", "tester"],
    });
    expect(prompt).toContain("## Teammates");
    expect(prompt).toContain("frontend-dev");
    expect(prompt).toContain("tester");
    expect(prompt).not.toContain("backend-dev,"); // self excluded
    expect(prompt).toContain("maw team send erp");
  });

  test("includes standing orders from past life", () => {
    const prompt = buildEnhancedSpawnPrompt({
      role: "agent-x",
      teamName: "team-1",
      userPrompt: "Do stuff",
      standingOrders: "Always use TypeScript",
    });
    expect(prompt).toContain("## Standing Orders");
    expect(prompt).toContain("Always use TypeScript");
  });

  test("includes latest findings", () => {
    const prompt = buildEnhancedSpawnPrompt({
      role: "agent-x",
      teamName: "team-1",
      userPrompt: "Do stuff",
      latestFindings: "Found 3 bugs in auth module",
    });
    expect(prompt).toContain("## Last Known Findings");
    expect(prompt).toContain("Found 3 bugs in auth module");
  });

  test("enhanced prompt is significantly longer than basic prompt", () => {
    const enhanced = buildEnhancedSpawnPrompt({
      role: "dev",
      teamName: "team",
      userPrompt: "Build stuff",
    });
    const basic = `You are 'dev' on team 'team'.\n\nBuild stuff`;
    // Enhanced should be at least 5x longer
    expect(enhanced.length).toBeGreaterThan(basic.length * 5);
  });
});

describe("scanProjectContext", () => {
  test("returns empty string for non-existent path", () => {
    expect(scanProjectContext("/nonexistent/path")).toBe("");
  });

  test("scans maw-js project and finds package.json deps", () => {
    const ctx = scanProjectContext("/root/.openclaw/workspace/agentic-new/maw-js");
    expect(ctx).toContain("## Project Context");
    expect(ctx).toContain("Dependencies:");
    // Should find key deps
    expect(ctx).toContain("@elysiajs");
  });

  test("scans arra-oracle-v3 project", () => {
    const ctx = scanProjectContext("/root/.openclaw/workspace/agentic-new/arra-oracle-v3");
    expect(ctx).toContain("## Project Context");
    expect(ctx).toContain("Dependencies:");
    expect(ctx).toContain("hono");
  });

  test("respects maxFiles limit", () => {
    const ctx = scanProjectContext("/root/.openclaw/workspace/agentic-new/maw-js", 5);
    // Should be shorter than unlimited scan
    const full = scanProjectContext("/root/.openclaw/workspace/agentic-new/maw-js", 100);
    expect(ctx.length).toBeLessThanOrEqual(full.length);
  });
});
