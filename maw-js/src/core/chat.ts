/**
 * chat.ts — Agent-to-Agent Chat System
 *
 * Agents can send messages to each other via inbox files.
 * The chat system creates message files in ψ/inbox/ with naming convention:
 *   chat-{from}-{to}-{timestamp}.md
 *
 * Format:
 *   ---
 *   from: god
 *   to: builder
 *   timestamp: 2026-04-21T00:20:00Z
 *   ---
 *   Message content here...
 *
 * The task runner picks up chat messages and dispatches them to the
 * target agent via tmux send-keys.
 */

import { readFileSync, writeFileSync, existsSync, readdirSync, mkdirSync, renameSync, appendFileSync } from "fs";
import { join, resolve } from "path";
import { sendKeys, listSessions } from "./transport/ssh";
import { loadConfig } from "../config";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");
const PSI_DIR = join(PROJECT_ROOT, "ψ");
const INBOX_DIR = join(PSI_DIR, "inbox");
const CHAT_ARCHIVE_DIR = join(INBOX_DIR, "archive", "chat");

export interface ChatMessage {
  filename: string;
  from: string;
  to: string;
  timestamp: string;
  content: string;
  read: boolean;
}

/**
 * Send a chat message from one agent to another.
 * Creates a file in ψ/inbox/ that the task runner will pick up.
 */
export function sendChatMessage(from: string, to: string, message: string): ChatMessage {
  mkdirSync(INBOX_DIR, { recursive: true });

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  const filename = `chat-${from}-${to}-${timestamp}.md`;
  const filepath = join(INBOX_DIR, filename);

  const content = [
    "---",
    `from: ${from}`,
    `to: ${to}`,
    `timestamp: ${new Date().toISOString()}`,
    "type: chat",
    "---",
    "",
    message,
  ].join("\n");

  writeFileSync(filepath, content, "utf-8");
  log(`Chat sent: ${from} → ${to}: ${message.slice(0, 80)}`);

  return { filename, from, to, timestamp: new Date().toISOString(), content: message, read: false };
}

/**
 * Get all unread chat messages for an agent.
 */
export function getChatMessages(agentName: string): ChatMessage[] {
  if (!existsSync(INBOX_DIR)) return [];

  const files = readdirSync(INBOX_DIR);
  const messages: ChatMessage[] = [];

  for (const file of files) {
    if (!file.startsWith("chat-") || !file.endsWith(".md")) continue;
    if (!file.includes(`-${agentName}-`)) continue;

    try {
      const content = readFileSync(join(INBOX_DIR, file), "utf-8");
      const parsed = parseChatFile(file, content);
      if (parsed && !parsed.read) {
        messages.push(parsed);
      }
    } catch { /* skip */ }
  }

  return messages.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
}

/**
 * Mark a chat message as read (archive it).
 */
export function markChatRead(filename: string): void {
  const src = join(INBOX_DIR, filename);
  if (!existsSync(src)) return;

  mkdirSync(CHAT_ARCHIVE_DIR, { recursive: true });
  const dest = join(CHAT_ARCHIVE_DIR, `${Date.now()}-${filename}`);
  renameSync(src, dest);
}

/**
 * Dispatch a chat message to the target agent via tmux.
 */
export async function dispatchChat(message: ChatMessage): Promise<boolean> {
  const config = loadConfig();
  const sessionName = (config.sessions as Record<string, string>)?.[message.to] || `mawjs-${message.to}`;

  try {
    const sessions = await listSessions();
    const session = sessions.find(s => s.name === sessionName);
    if (!session) {
      log(`Chat dispatch failed: ${message.to} offline (session: ${sessionName})`);
      return false;
    }

    const formatted = `[CHAT from:${message.from}] ${message.content}`;
    await sendKeys(sessionName, formatted);
    log(`Chat dispatched: ${message.from} → ${message.to} via ${sessionName}`);
    return true;
  } catch (e: any) {
    log(`Chat dispatch error: ${e.message}`);
    return false;
  }
}

/**
 * Get chat history between two agents (from archive).
 */
export function getChatHistory(agent1: string, agent2: string, limit = 20): ChatMessage[] {
  if (!existsSync(CHAT_ARCHIVE_DIR)) return [];

  const files = readdirSync(CHAT_ARCHIVE_DIR);
  const messages: ChatMessage[] = [];

  for (const file of files) {
    const isAtoB = file.includes(`chat-${agent1}-${agent2}-`);
    const isBtoA = file.includes(`chat-${agent2}-${agent1}-`);
    if (!isAtoB && !isBtoA) continue;

    try {
      const content = readFileSync(join(CHAT_ARCHIVE_DIR, file), "utf-8");
      const parsed = parseChatFile(file, content);
      if (parsed) messages.push(parsed);
    } catch { /* skip */ }
  }

  return messages.sort((a, b) => b.timestamp.localeCompare(a.timestamp)).slice(0, limit);
}

/**
 * List all active (unread) chat messages.
 */
export function listAllChats(): ChatMessage[] {
  if (!existsSync(INBOX_DIR)) return [];

  const files = readdirSync(INBOX_DIR);
  const messages: ChatMessage[] = [];

  for (const file of files) {
    if (!file.startsWith("chat-") || !file.endsWith(".md")) continue;
    try {
      const content = readFileSync(join(INBOX_DIR, file), "utf-8");
      const parsed = parseChatFile(file, content);
      if (parsed) messages.push(parsed);
    } catch { /* skip */ }
  }

  return messages.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
}

// ─── Internal ───

function parseChatFile(filename: string, content: string): ChatMessage | null {
  const lines = content.split("\n");
  let from = "", to = "", timestamp = "";
  let bodyStart = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.startsWith("from:")) from = line.slice(5).trim();
    else if (line.startsWith("to:")) to = line.slice(3).trim();
    else if (line.startsWith("timestamp:")) timestamp = line.slice(10).trim();
    else if (line === "---" && i > 0) { bodyStart = i + 1; break; }
  }

  if (!from || !to) return null;

  return {
    filename, from, to,
    timestamp: timestamp || new Date().toISOString(),
    content: lines.slice(bodyStart).join("\n").trim(),
    read: false,
  };
}

function log(msg: string): void {
  const logDir = join(PSI_DIR, "memory", "logs");
  mkdirSync(logDir, { recursive: true });
  appendFileSync(join(logDir, "chat.log"), `[${new Date().toISOString()}] ${msg}\n`);
}
