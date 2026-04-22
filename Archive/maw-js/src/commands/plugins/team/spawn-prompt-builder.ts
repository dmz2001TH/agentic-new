import { existsSync, readdirSync, readFileSync, statSync } from "fs";
import { join } from "path";

/**
 * Scan a project directory and build a context summary for the spawn prompt.
 * Gives the agent a mental map of the codebase before it starts working.
 */
export function scanProjectContext(projectRoot: string, maxFiles: number = 30): string {
  if (!existsSync(projectRoot)) return "";

  const lines: string[] = [];
  lines.push("## Project Context\n");

  // Scan top-level structure
  const entries = readdirSync(projectRoot, { withFileTypes: true })
    .filter(e => !e.name.startsWith(".") && e.name !== "node_modules" && e.name !== "dist")
    .slice(0, maxFiles);

  const dirs = entries.filter(e => e.isDirectory()).map(e => e.name + "/");
  const files = entries.filter(e => e.isFile()).map(e => e.name);

  if (dirs.length) lines.push(`**Directories:** ${dirs.join(", ")}`);
  if (files.length) lines.push(`**Files:** ${files.join(", ")}`);

  // Read package.json if exists (for tech stack info)
  const pkgPath = join(projectRoot, "package.json");
  if (existsSync(pkgPath)) {
    try {
      const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"));
      if (pkg.dependencies) {
        const keyDeps = Object.keys(pkg.dependencies)
          .filter(k => !k.startsWith("@types/"))
          .slice(0, 15);
        lines.push(`**Dependencies:** ${keyDeps.join(", ")}`);
      }
      if (pkg.scripts) {
        lines.push(`**Scripts:** ${Object.keys(pkg.scripts).join(", ")}`);
      }
    } catch { /* skip malformed package.json */ }
  }

  // Read pyproject.toml if exists
  const pyprojectPath = join(projectRoot, "pyproject.toml");
  if (existsSync(pyprojectPath)) {
    try {
      const content = readFileSync(pyprojectPath, "utf-8");
      const depsMatch = content.match(/\[project\][\s\S]*?dependencies\s*=\s*\[([\s\S]*?)\]/);
      if (depsMatch) {
        lines.push(`**Python deps:** ${depsMatch[1].trim().slice(0, 200)}`);
      }
    } catch { /* skip */ }
  }

  // Read CLAUDE.md if exists (project conventions)
  const claudePath = join(projectRoot, "CLAUDE.md");
  if (existsSync(claudePath)) {
    const claude = readFileSync(claudePath, "utf-8");
    // Take first 15 lines as convention summary
    const claudeLines = claude.split("\n").slice(0, 15).join("\n");
    lines.push(`\n**Project Conventions (from CLAUDE.md):**\n${claudeLines}`);
  }

  return lines.join("\n");
}

/**
 * Build a structured spawn prompt that works well for ALL models,
 * especially Gemini which needs explicit step-by-step guidance.
 *
 * Structure:
 * 1. Role definition
 * 2. Task with validation criteria
 * 3. Step-by-step process
 * 4. Output format
 * 5. Error handling
 * 6. Context (past life, project, standing orders)
 */
export function buildEnhancedSpawnPrompt(opts: {
  role: string;
  teamName: string;
  userPrompt: string;
  projectRoot?: string;
  standingOrders?: string;
  latestFindings?: string;
  teammates?: string[];
  model?: string;
}): string {
  const parts: string[] = [];

  // ── 1. Role Definition ──
  parts.push(`# Role: ${opts.role}`);
  parts.push(`**Team:** ${opts.teamName}`);
  parts.push(`You are an autonomous AI agent. Your job is to complete your assigned task`);
  parts.push(`independently, validate your work, and report results.\n`);

  // ── 2. Task ──
  parts.push(`## Task`);
  parts.push(opts.userPrompt);

  // ── 3. Process (structured steps) ──
  parts.push(`\n## Process`);
  parts.push(`Follow these steps IN ORDER. Do not skip steps.`);
  parts.push(``);
  parts.push(`1. **Understand** — Read the task carefully. If anything is unclear, make a reasonable assumption and note it.`);
  parts.push(`2. **Explore** — Look at existing code/files before writing anything. Understand the current state.`);
  parts.push(`3. **Plan** — Write a brief plan (3-5 bullet points) of what you'll do.`);
  parts.push(`4. **Execute** — Implement step by step. After each file change, verify it compiles/runs.`);
  parts.push(`5. **Validate** — Run tests if available. Check for errors. Review your output.`);
  parts.push(`6. **Report** — Write a findings report (see Output Format below).`);

  // ── 4. Output Format ──
  parts.push(`\n## Output Format`);
  parts.push(`When you finish (or hit a blocker), write to your findings file:`);
  parts.push(`\`\`\``);
  parts.push(`## Summary`);
  parts.push(`<1-2 sentence summary of what you did>`);
  parts.push(``);
  parts.push(`## Changes Made`);
  parts.push(`- <file>: <what changed>`);
  parts.push(``);
  parts.push(`## Blockers (if any)`);
  parts.push(`- <what blocked you and what you need>`);
  parts.push(``);
  parts.push(`## Next Steps`);
  parts.push(`- <what should happen next>`);
  parts.push(`\`\`\``);

  // ── 5. Rules ──
  parts.push(`\n## Rules`);
  parts.push(`- Do NOT delete existing code without explicit instruction`);
  parts.push(`- Do NOT install new dependencies without asking`);
  parts.push(`- Do NOT commit directly — report changes for review`);
  parts.push(`- If you encounter an error, try 2 different approaches before reporting a blocker`);
  parts.push(`- Keep changes minimal and focused on your task`);

  // ── 6. Teammates ──
  if (opts.teammates && opts.teammates.length > 0) {
    parts.push(`\n## Teammates`);
    const others = opts.teammates.filter(t => t !== opts.role);
    if (others.length) {
      parts.push(`You are working with: ${others.join(", ")}`);
      parts.push(`Use \`maw team send ${opts.teamName} <name> <message>\` to communicate.`);
    }
  }

  // ── 7. Project Context ──
  if (opts.projectRoot) {
    const ctx = scanProjectContext(opts.projectRoot);
    if (ctx) parts.push(`\n${ctx}`);
  }

  // ── 8. Standing Orders (past life) ──
  if (opts.standingOrders) {
    parts.push(`\n## Standing Orders (from past life)`);
    parts.push(opts.standingOrders);
  }

  // ── 9. Latest Findings ──
  if (opts.latestFindings) {
    parts.push(`\n## Last Known Findings`);
    parts.push(opts.latestFindings);
  }

  return parts.join("\n");
}
