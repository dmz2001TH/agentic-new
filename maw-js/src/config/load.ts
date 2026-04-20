import { readFileSync, writeFileSync, existsSync } from "fs";
import { join } from "path";
import { execSync } from "child_process";
import { homedir } from "os";
import { CONFIG_FILE } from "../core/paths";
import { refreshContext } from "../lib/context";
import { verbose, info } from "../cli/verbosity";
import type { MawConfig } from "./types";
import { D } from "./types";
import { validateConfig } from "./validate-ext";

/** Detect ghq root — tries ghq CLI first, then common fallback paths. */
function detectGhqRoot(): string {
  // 1. Try ghq CLI
  try {
    const root = execSync("ghq root", { encoding: "utf-8" }).trim();
    const ghRoot = join(root, "github.com");
    if (existsSync(ghRoot)) return ghRoot;
    if (existsSync(root)) return root;
  } catch { /* ghq not installed */ }

  // 2. Try common paths
  const home = homedir();
  const candidates = [
    join(home, "Code/github.com"),
    join(home, "code"),
    join(home, "projects"),
    join(home, "repos"),
    join(home, "src"),
    process.cwd(),
  ];
  for (const p of candidates) {
    if (existsSync(p)) return p;
  }

  // 3. Last resort: cwd
  return process.cwd();
}

const DEFAULTS: MawConfig = {
  host: "localhost",
  port: 4000,
  ghqRoot: detectGhqRoot(),
  oracleUrl: "http://localhost:47778",
  env: {},
  commands: { 
    default: "gemini --yolo",
    nexus: "gemini --yolo" 
  },
  sessions: {
    "nexus": "02-nexus"
  },
};

let cached: MawConfig | null = null;

export function loadConfig(): MawConfig {
  if (cached) return cached;
  try {
    const raw = JSON.parse(readFileSync(CONFIG_FILE, "utf-8"));
    const validated = validateConfig(raw);
    cached = { ...DEFAULTS, ...validated, port: 3456, host: "localhost" };
  } catch {
    cached = { ...DEFAULTS, port: 3456, host: "localhost" };
  }
  // One-shot startup summary — fires unless --quiet/--silent (verbose-by-default).
  verbose(() => {
    const nT = cached!.triggers?.length ?? 0;
    const nP = cached!.pluginSources?.length ?? 0;
    const nPeers = (cached!.peers?.length ?? 0) + (cached!.namedPeers?.length ?? 0);
    info(`loaded config: ${nT} trigger${nT === 1 ? "" : "s"}, ${nP} declared plugin${nP === 1 ? "" : "s"}, ${nPeers} peer${nPeers === 1 ? "" : "s"}`);
  });
  return cached;
}

/** Reset cached config (for hot-reload or testing) */
export function resetConfig() {
  cached = null;
}

/** Write config to maw.config.json and reset cache */
export function saveConfig(update: Partial<MawConfig>) {
  const current = loadConfig();
  const merged = { ...current, ...update };
  writeFileSync(CONFIG_FILE, JSON.stringify(merged, null, 2) + "\n", "utf-8");
  resetConfig(); // clear cache so next loadConfig() reads fresh
  refreshContext(); // clear DI cache so middleware picks up new config
  return loadConfig();
}

/** Return config with env values masked for display */
export function configForDisplay(): MawConfig & { envMasked: Record<string, string> } {
  const config = loadConfig();
  const envMasked: Record<string, string> = {};
  for (const [k, v] of Object.entries(config.env)) {
    if (v.length <= 4) {
      envMasked[k] = "\u2022".repeat(v.length);
    } else {
      envMasked[k] = v.slice(0, 3) + "\u2022".repeat(Math.min(v.length - 3, 20));
    }
  }
  const result: any = { ...config, env: {}, envMasked };
  // Mask federation token (show first 4 chars only)
  if (result.federationToken) {
    result.federationToken = result.federationToken.slice(0, 4) + "\u2022".repeat(12);
  }
  return result;
}

/** Get a config interval with typed default fallback */
export function cfgInterval(key: keyof typeof D.intervals): number {
  return loadConfig().intervals?.[key] ?? D.intervals[key];
}

/** Get a config timeout with typed default fallback */
export function cfgTimeout(key: keyof typeof D.timeouts): number {
  return loadConfig().timeouts?.[key] ?? D.timeouts[key];
}

/** Get a config limit with typed default fallback */
export function cfgLimit(key: keyof typeof D.limits): number {
  return loadConfig().limits?.[key] ?? D.limits[key];
}

/** Get a top-level config value with default fallback */
export function cfg<K extends keyof MawConfig>(key: K): MawConfig[K] {
  return loadConfig()[key] ?? (DEFAULTS as MawConfig)[key];
}
