import { loadConfig } from "../../config";
import { tmuxCmd } from "./tmux";

const DEFAULT_HOST = process.env.MAW_HOST || loadConfig().host || "local";

/** Supreme Transport Layer — รองรับการคุยข้าม OS/Layer ด้วยความเสถียรสูงสุด */
export async function hostExec(cmd: string, host = DEFAULT_HOST): Promise<string> {
  const isWin = process.platform === "win32";
  const isLocal = host === "local" || host === "localhost" || host === "127.0.0.1";

  // ใช้รูปแบบ command ที่ปลอดภัยต่อระบบ Shell ทั้งหมด
  const args = isWin && isLocal 
    ? ["wsl", "bash", "-c", cmd.replace(/'/g, "'\\''")] // Escape single quotes for bash
    : ["ssh", host, cmd];

  const proc = Bun.spawn(args, { stdout: "pipe", stderr: "pipe", windowsHide: true });
  
  // รอผลลัพธ์พร้อม timeout ป้องกันการค้าง
  const [stdout, stderr] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text()
  ]);
  
  const code = await proc.exited;
  if (code !== 0) throw new Error(stderr.trim() || `Exit ${code}: ${cmd}`);
  return stdout.trim();
}

/** Robust Session Lister: ขจัดขยะ \r\n ออกจากชื่อ Session */
export async function listSessions(host?: string): Promise<any[]> {
  const raw = await hostExec(`${tmuxCmd()} list-sessions -F '#{session_name}' 2>/dev/null`, host).catch(() => "");
  return raw.split(/\r?\n/).map(s => s.trim()).filter(Boolean).map(name => ({ name }));
}

/** Robust Key Sender: ป้องกันปัญหาโหมด Shell ค้าง */
export async function sendKeys(target: string, text: string, host?: string): Promise<void> {
  const { Tmux } = await import("./tmux");
  const t = new Tmux(host);
  
  // ล้างโหมด Shell/Input ก่อนส่งคำสั่งเสมอ
  await t.run("send-keys", "-t", target, "C-u", "Escape", "C-c");
  await t.sendText(target, text);
}
