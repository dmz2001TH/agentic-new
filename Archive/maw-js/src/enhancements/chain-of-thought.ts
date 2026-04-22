/**
 * chain-of-thought.ts — Step-by-step reasoning engine for weak models
 *
 * Problem: Weak models skip reasoning steps and give shallow answers.
 * Solution: Force step-by-step execution via separate API calls per step.
 */

export interface CoTStep {
  id: number;
  name: string;
  instruction: string;
  context: string;
  output: string;
  confidence: number;
  timestamp: string;
}

export interface CoTResult {
  task: string;
  steps: CoTStep[];
  finalAnswer: string;
  totalSteps: number;
  avgConfidence: number;
  durationMs: number;
}

export interface CoTConfig {
  maxSteps: number;
  minConfidence: number;
  verbose: boolean;
  modelCall: (prompt: string) => Promise<string>;
}

export const STEP_TEMPLATES: Record<string, { name: string; instruction: string }[]> = {
  analyze: [
    { name: "observe", instruction: "อ่านข้อมูลที่ให้มาทั้งหมด แล้ว列出 fact ที่เห็น (ไม่ต้องตีความ)" },
    { name: "identify-patterns", instruction: "จาก facts มี pattern อะไรเกิดขึ้นบ้าง? ความสัมพันธ์คือ什么" },
    { name: "draw-conclusions", instruction: "从 patterns 得出什么结论? 什么是最重要的?" },
    { name: "recommend", instruction: "จาก conclusions แนะนำ下一步应该怎么ทำ" },
  ],
  code: [
    { name: "understand-requirements", instruction: "列出: 1) input 2) output 3) edge cases" },
    { name: "design-approach", instruction: "เลือก algorithm, data structure, 为什么" },
    { name: "write-code", instruction: "เขียน code ตาม design ให้ถูกต้อง" },
    { name: "verify", instruction: "ตรวจ code: ตรง requirements, edge cases, bugs" },
  ],
  debug: [
    { name: "read-error", instruction: "อ่าน error: 什么 error, เกิดที่ไหน, context" },
    { name: "hypothesize", instruction: "提出 hypothesis อย่างน้อย 3 ข้อ" },
    { name: "verify-hypothesis", instruction: "检验 hypothesis 排除ที่เป็นไปไม่ได้" },
    { name: "fix", instruction: "บอกวิธีแก้具体: เปลี่ยน什么, ตรงไหน" },
  ],
  summarize: [
    { name: "extract-key-points", instruction: "列出 key points (ไม่เกิน 7 ข้อ)" },
    { name: "organize", instruction: "排序ตามความสำคัญ" },
    { name: "write-summary", instruction: "สรุป ไม่เกิน 3 ย่อหน้า" },
  ],
  generic: [
    { name: "understand", instruction: "理解 task: scope, success criteria" },
    { name: "plan", instruction: "วางแผน: steps, ลำดับ, ข้อมูลที่ใช้" },
    { name: "execute", instruction: "ทำตาม plan" },
    { name: "review", instruction: "ตรวจผล: ครบ, ถูก, ปรับปรุงได้" },
  ],
};

export function detectTaskType(task: string): string {
  const l = task.toLowerCase();
  if (/debug|error|bug|แก้ไข|แก้บัค|ไม่ทำงาน/i.test(l)) return "debug";
  if (/summarize|สรุป|summary|รวม/i.test(l)) return "summarize";
  if (/analyze|วิเคราะห์|ดู|เปรียบเทียบ|compare/i.test(l)) return "analyze";
  if (/code|function|script|เขียน.*โค้ด|implement|เขียนโปรแกรม/i.test(l)) return "code";
  return "generic";
}

function extractConfidence(output: string): number {
  const m = output.match(/confidence[:\s]*(\d+\.?\d*)/i);
  if (m) { const v = parseFloat(m[1]); return v > 1 ? v / 100 : v; }
  if (/มั่นใจมาก|แน่ใจ/i.test(output)) return 0.9;
  if (/มั่นใจปานกลาง|พอได้/i.test(output)) return 0.7;
  if (/ไม่แน่ใจ|อาจจะ/i.test(output)) return 0.4;
  return 0.7;
}

function buildStepPrompt(task: string, stepDef: { name: string; instruction: string }, context: string, prevSteps: CoTStep[], idx: number): string {
  let p = `เธอทำงานทีละ step ตอนนี้ step ที่ ${idx + 1}\n\n## Task\n${task}\n\n`;
  if (prevSteps.length) {
    p += `## ผลก่อนหน้า\n`;
    for (const s of prevSteps) p += `### Step ${s.id}: ${s.name}\n${s.output}\n\n`;
  }
  p += `## Step ตอนนี้: ${stepDef.name}\n${stepDef.instruction}\n\n`;
  if (context) p += `## Context\n${context}\n\n`;
  p += `ตอบเฉพาะ step นี้\nสุดท้ายบอก confidence (0.0-1.0)\n`;
  return p;
}

export async function runChainOfThought(task: string, context: string, config: CoTConfig): Promise<CoTResult> {
  const start = Date.now();
  const template = STEP_TEMPLATES[detectTaskType(task)] || STEP_TEMPLATES.generic;
  const steps = template.slice(0, config.maxSteps);
  const results: CoTStep[] = [];
  let ctx = context;

  for (let i = 0; i < steps.length; i++) {
    const s = steps[i];
    const prompt = buildStepPrompt(task, s, ctx, results, i);
    if (config.verbose) console.log(`[CoT] Step ${i + 1}/${steps.length}: ${s.name}`);
    const output = await config.modelCall(prompt);
    const confidence = extractConfidence(output);
    results.push({ id: i + 1, name: s.name, instruction: s.instruction, context: ctx.slice(0, 500), output, confidence, timestamp: new Date().toISOString() });
    ctx += `\n\n--- Step ${i + 1} (${s.name}) ---\n${output}`;

    if (confidence < config.minConfidence && i < steps.length - 1) {
      const retry = await config.modelCall(`ความมั่นใจต่ำ (${confidence.toFixed(1)}) ลองใหม่:\n\n${prompt}`);
      const rc = extractConfidence(retry);
      if (rc > confidence) { results[results.length - 1].output = retry; results[results.length - 1].confidence = rc; }
    }
  }

  const avg = results.reduce((s, r) => s + r.confidence, 0) / results.length;
  return { task, steps: results, finalAnswer: results[results.length - 1]?.output || "", totalSteps: results.length, avgConfidence: avg, durationMs: Date.now() - start };
}

export default { runChainOfThought, detectTaskType, STEP_TEMPLATES };
