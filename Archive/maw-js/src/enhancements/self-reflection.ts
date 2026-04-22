/**
 * self-reflection.ts — Answer validation and correction loop
 * Detecting errors is easier than producing correct answers. We exploit this.
 */

export interface ReflectionResult {
  originalAnswer: string; finalAnswer: string; iterations: number;
  issuesFound: ReflectionIssue[]; wasCorrected: boolean; qualityScore: number; durationMs: number;
}
export interface ReflectionIssue {
  iteration: number; type: "factual" | "logical" | "completeness" | "formatting" | "safety";
  description: string; severity: "low" | "medium" | "high";
}
export interface ReflectionConfig {
  maxIterations: number; qualityThreshold: number;
  modelCall: (prompt: string) => Promise<string>; verbose: boolean;
}

const REVIEWER_PROMPTS: Record<string, string> = {
  code: `ตรวจ code:\n\`\`\`\n{answer}\n\`\`\`\nTask: {task}\nตรวจ: correctness, edge cases, bugs, style\nFormat: "QUALITY: N" + "ISSUES: ..." + "FIX: ..."`,
  text: `ตรวจคำตอบ:\n"{answer}"\nTask: {task}\nตรวจ: accuracy, completeness, logic\nFormat: "QUALITY: N" + "ISSUES: ..."`,
  analysis: `ตรวิเคราะห์:\n"{answer}"\nTask: {task}\nตรวจ: evidence, bias, depth\nFormat: "QUALITY: N" + "ISSUES: ..."`,
};

function detectReviewType(task: string, answer: string): string {
  const c = `${task} ${answer}`.toLowerCase();
  if (/function|code|script|const |let |var /i.test(c)) return "code";
  if (/analyze|วิเคราะห์|compare/i.test(c)) return "analysis";
  return "text";
}

function extractQuality(o: string): number {
  const m = o.match(/quality[:\s]*(\d+\.?\d*)/i);
  if (m) return parseFloat(m[1]);
  if (/ไม่มีปัญหา|perfect/i.test(o)) return 9;
  if (/minor/i.test(o)) return 7;
  if (/major|ปัญหาใหญ่/i.test(o)) return 3;
  return 5;
}

function extractIssues(o: string, iter: number): ReflectionIssue[] {
  const issues: ReflectionIssue[] = [];
  for (const l of o.split("\n")) {
    const m = l.match(/- \[(high|medium|low)\]\s*(.+)/i);
    if (m) issues.push({ iteration: iter, type: "logical", description: m[2].trim(), severity: m[1].toLowerCase() as any });
  }
  return issues;
}

export async function runSelfReflection(task: string, initialAnswer: string, config: ReflectionConfig): Promise<ReflectionResult> {
  const start = Date.now();
  let cur = initialAnswer;
  let allIssues: ReflectionIssue[] = [];
  let iters = 0;
  let corrected = false;
  let qual = 0;

  for (let i = 0; i < config.maxIterations; i++) {
    iters = i + 1;
    const reviewType = detectReviewType(task, cur);
    const template = REVIEWER_PROMPTS[reviewType] || REVIEWER_PROMPTS.text;
    const reviewPrompt = template.replace("{answer}", cur).replace("{task}", task);
    if (config.verbose) console.log(`[Reflection] Iteration ${iters}: reviewing (${reviewType})`);

    const reviewOutput = await config.modelCall(reviewPrompt);
    qual = extractQuality(reviewOutput);
    const issues = extractIssues(reviewOutput, iters);
    allIssues.push(...issues);

    if (config.verbose) console.log(`[Reflection] Quality: ${qual}/10, Issues: ${issues.length}`);
    if (qual >= config.qualityThreshold || issues.length === 0) break;

    const fixPrompt = `คำตอบมีปัญหา แก้ไข:\n\n## Task\n${task}\n\n## เดิม\n${cur}\n\n## Feedback\n${reviewOutput}\n\nแก้ให้ถูกต้อง`;
    cur = await config.modelCall(fixPrompt);
    corrected = true;
  }

  return { originalAnswer: initialAnswer, finalAnswer: cur, iterations: iters, issuesFound: allIssues, wasCorrected: corrected, qualityScore: qual, durationMs: Date.now() - start };
}

export default { runSelfReflection };
