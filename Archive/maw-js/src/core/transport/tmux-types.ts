import { loadConfig } from "../../config";

/** Resolve tmux socket path from env or config. */
export function resolveSocket(): string | undefined {
  return process.env.MAW_TMUX_SOCKET || loadConfig().tmuxSocket || undefined;
}

/** Build the `tmux` (or `tmux -S <socket>`) prefix for raw commands.
 * On Windows, tmux lives in WSL. We force the default socket path
 * for the first WSL user (UID 1000) to ensure visibility across contexts.
 */
export function tmuxCmd(): string {
  const isWin = process.platform === "win32";
  const socket = resolveSocket() || (isWin ? "/tmp/tmux-1000/default" : undefined);
  const prefix = isWin ? "wsl " : "";
  
  return socket ? `${prefix}tmux -S '${socket}'` : `${prefix}tmux`;
}

export interface TmuxPane {
  id: string;
  command: string;
  target: string;
  title: string;
  pid?: number;
  cwd?: string;
}

export interface TmuxWindow {
  index: number;
  name: string;
  active: boolean;
  cwd?: string;
}

export interface TmuxSession {
  name: string;
  windows: TmuxWindow[];
}

/**
 * Shell-quote a single argument for tmux commands.
 * @internal
 */
export function q(s: string | number): string {
  const str = String(s);
  // Safe chars only → no quoting needed
  if (/^[a-zA-Z0-9_.:\-\/]+$/.test(str)) return str;
  // Wrap in single quotes, escape inner single quotes
  return `'${str.replace(/'/g, "'\\''")}'`;
}
