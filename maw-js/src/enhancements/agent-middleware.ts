/**
 * agent-middleware.ts — Auto-inject enhancements into agent I/O
 * 
 * Hooks into maw-js runtime to automatically:
 * 1. PRE-PROCESS: Wrap outgoing prompts with enhancement instructions
 * 2. POST-PROCESS: Clean repetitive output from captured agent responses
 * 
 * No code changes needed by users — installMiddleware() in server.ts handles everything.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync, appendFileSync } from "fs";
import { join, resolve } from "path";
import { detectRepetition } from "./repetition-guard";

const PROJECT_ROOT = resolve(import.meta.dir, "..", "..", "..");

const ENHANCEMENT_PREFIX = `[SYSTEM RULES — ทำตามเสมอ ไม่มีข้อยกเว้น]

1. CHAIN OF THOUGHT: คิดทีละ step ก่อนตอบ อย่าข้าม
   - Step 1: เข้าใจปัญหา (อ่านทั้งหมดก่อน)
   - Step 2: คิดวิธีแก้ (อย่างน้อย 2 ทาง)
   - Step 3: เลือกวิธีที่ดีสุด (บอกเหตุผล)
   - Step 4: ลงมือทำ

2. SELF-CHECK: ก่อนส่งคำตอบ ตรวจตัวเอง:
   - ตอบครบทุกส่วนของคำถามมั้ย?
   - ข้อมูลถูกต้องมั้ย? (อย่าเดา อย่ามั่ว)
   - มีส่วนที่ซ้ำหรือ冗余มั้ย?

3. ห้ามพิมพ์ซ้ำ: ทุกประโยคต้องมีสาระใหม่ ห้าม loop
   ห้ามเริ่มต้นประโยคเดิมซ้ำ ห้ามพิมพ์ ✦ ซ้ำ

4. กระชับ: ตอบให้สั้นที่สุดที่ยังครบถ้วน อย่าฟุ่มเฟือย

---

`;

export function cleanAgentOutput(output: string): { cleaned: string; wasModified: boolean } {
  if (!output || output.length < 50) return { cleaned: output, wasModified: false };

  const report = detectRepetition(output, {
    maxLineRepeats: 2,
    maxNgramRepeats: 2,
    ngramSize: 5,
  });

  if (!report.hasRepetition) return { cleaned: output, wasModified: false };

  try {
    const logDir = join(PROJECT_ROOT, "ψ", "memory", "logs");
    mkdirSync(logDir, { recursive: true });
    appendFileSync(
      join(logDir, "repetition-guard.log"),
      `[${new Date().toISOString()}] Cleaned: ${report.type} severity=${report.severity} repeats=${report.repeatCount} (${report.originalLength}→${report.cleanedLength} chars)\n`,
    );
  } catch { /* best effort */ }

  return { cleaned: report.cleanedOutput, wasModified: true };
}

export function enhanceOutgoingMessage(text: string): string {
  if (text.length < 20) return text;
  if (text.startsWith("/")) return text;
  if (text.startsWith("[SYSTEM")) return text;
  if (text.startsWith("[CHAT")) return text;
  if (/^(ok|ขอบคุณ|thanks|yes|no|ใช่|ไม่|ตกลง)$/i.test(text.trim())) return text;
  if (text.includes("CHAIN OF THOUGHT")) return text;
  return ENHANCEMENT_PREFIX + text;
}

export function patchGeminiMd(geminiMdPath: string): boolean {
  if (!existsSync(geminiMdPath)) return false;

  const content = readFileSync(geminiMdPath, "utf-8");
  const marker = "<!-- ENHANCEMENT_RULES_V2 -->";

  if (content.includes(marker)) return false;

  const enhancementSection = `

${marker}
## 🧠 Enhancement Rules (Auto-Injected)

### Chain-of-Thought (คิดทีละ Step)
ทุกครั้งที่ตอบคำถาม ให้คิดเป็นลำดับ:
1. **เข้าใจ**: อ่านคำถามทั้งหมด อย่าข้าม อย่าเดา
2. **คิด**: หาวิธีแก้ อย่างน้อย 2 ทางเลือก
3. **เลือก**: เลือกวิธีที่ดีสุด บอกเหตุผล
4. **ทำ**: ลงมือทำตามที่เลือก

### Self-Reflection (ตรวจตัวเอง)
ก่อนส่งคำตอบทุกครั้ง:
- ตอบครบทุกส่วนของคำถามมั้ย?
- ข้อมูลถูกต้องมั้ย? (ถ้าไม่แน่ใจ บอกว่าไม่แน่ใจ)
- มีส่วนที่ซ้ำหรือ冗余มั้ย?

### Anti-Repetition (ห้ามพิมพ์ซ้ำ)
- ทุกประโยคต้องมีสาระใหม่
- ห้าม loop: ห้ามเริ่มต้นประโยคเดิมซ้ำ
- ห้ามพิมพ์ ✦ หรือสัญลักษณ์ซ้ำๆ
- ถ้าจับตัวเองกำลังพิมพ์ซ้ำ → หยุด แล้วเปลี่ยนวิธีพูด

### Conciseness (กระชับ)
- ตอบสั้นที่สุดที่ยังครบถ้วน
- อย่าฟุ่มเฟือย อย่า重复
- ถ้า 1 ประโยคพอ → ใช้ 1 ประโยค
${marker}
`;

  const newContent = content.trimEnd() + "\n" + enhancementSection;
  writeFileSync(geminiMdPath, newContent, "utf-8");
  console.log(`[middleware] Patched GEMINI.md with enhancement rules`);
  return true;
}

export function installMiddleware(): { geminiPatched: boolean; installed: boolean } {
  const logDir = join(PROJECT_ROOT, "ψ", "memory", "logs");
  mkdirSync(logDir, { recursive: true });

  let geminiPatched = false;
  const possiblePaths = [
    join(PROJECT_ROOT, "GEMINI.md"),
    join(PROJECT_ROOT, ".gemini", "GEMINI.md"),
  ];

  for (const p of possiblePaths) {
    if (existsSync(p)) {
      geminiPatched = patchGeminiMd(p);
      if (geminiPatched) break;
    }
  }

  appendFileSync(
    join(logDir, "middleware.log"),
    `[${new Date().toISOString()}] Enhancement middleware installed (geminiPatched=${geminiPatched})\n`,
  );

  console.log(`[middleware] Enhancement middleware installed (GEMINI.md patched: ${geminiPatched})`);
  return { geminiPatched, installed: true };
}

export default { installMiddleware, enhanceOutgoingMessage, cleanAgentOutput, patchGeminiMd };
