/**
 * repetition-guard.ts — Detect and break repetition loops
 * Fixes the ✦ repetition problem where models repeat the same text.
 */

export interface RepetitionReport {
  hasRepetition: boolean;
  type: "none" | "line" | "ngram" | "semantic" | "truncation" | "mixed";
  severity: "none" | "low" | "medium" | "high" | "critical";
  repeatedBlock: string;
  repeatCount: number;
  cleanedOutput: string;
  originalLength: number;
  cleanedLength: number;
  details: string[];
}

export interface GuardConfig {
  maxLineRepeats: number;
  maxNgramRepeats: number;
  ngramSize: number;
  similarityThreshold: number;
  blockCheckSize: number;
  modelCall?: (prompt: string) => Promise<string>;
}

const DEFAULT_CONFIG: GuardConfig = {
  maxLineRepeats: 2,
  maxNgramRepeats: 2,
  ngramSize: 5,
  similarityThreshold: 0.85,
  blockCheckSize: 3,
};

function calculateSimilarity(a: string, b: string): number {
  if (a === b) return 1;
  if (!a.length || !b.length) return 0;
  const bgA = new Set<string>(), bgB = new Set<string>();
  for (let i = 0; i < a.length - 1; i++) bgA.add(a.slice(i, i + 2));
  for (let i = 0; i < b.length - 1; i++) bgB.add(b.slice(i, i + 2));
  let inter = 0;
  for (const g of bgA) if (bgB.has(g)) inter++;
  const union = bgA.size + bgB.size - inter;
  return union === 0 ? 0 : inter / union;
}

function detectLineRepetition(lines: string[], maxRepeats: number) {
  for (let i = 0; i < lines.length - 1; i++) {
    const line = lines[i].trim();
    if (line.length < 10) continue;
    let count = 1;
    for (let j = i + 1; j < lines.length; j++) {
      if (lines[j].trim() === line) count++; else break;
    }
    if (count > maxRepeats) return { found: true, line, count, startIndex: i };
  }
  return { found: false, line: "", count: 0, startIndex: -1 };
}

function detectTruncationRepetition(text: string) {
  const starLines = text.match(/^✦[^\n]*/gm);
  if (starLines && starLines.length >= 3) {
    const contents = starLines.map(l => l.replace(/^✦\s*/, "").trim());
    const first = contents[0];
    let simCount = 1;
    for (let i = 1; i < contents.length; i++) {
      if (calculateSimilarity(first, contents[i]) > 0.7) simCount++;
    }
    if (simCount >= 3) return { found: true, pattern: "✦-repetition", count: simCount };
  }
  const blockPattern = text.match(/▄+/g);
  if (blockPattern && blockPattern.length >= 3) {
    return { found: true, pattern: "▄-separator-repetition", count: blockPattern.length };
  }
  return { found: false, pattern: "", count: 0 };
}

function cleanRepeatedLines(lines: string[], maxRepeats: number): string[] {
  const cleaned: string[] = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trim();
    if (line.length < 10) { cleaned.push(lines[i]); i++; continue; }
    let repeatCount = 1;
    for (let j = i + 1; j < lines.length; j++) {
      if (lines[j].trim() === line) repeatCount++; else break;
    }
    for (let k = 0; k < Math.min(repeatCount, maxRepeats); k++) cleaned.push(lines[i]);
    i += repeatCount;
  }
  return cleaned;
}

function cleanTruncationMarkers(text: string): string {
  let cleaned = text.replace(/^▄+.*$/gm, "").trim();
  const starBlocks = cleaned.split(/(?=^✦)/m);
  if (starBlocks.length > 2) {
    let longest = starBlocks[0];
    for (const b of starBlocks) {
      if (b.trim().startsWith("✦") && b.length > longest.length) longest = b;
    }
    cleaned = longest;
  }
  return cleaned.trim();
}

export function detectRepetition(output: string, config: Partial<GuardConfig> = {}): RepetitionReport {
  const cfg = { ...DEFAULT_CONFIG, ...config };
  const lines = output.split("\n");
  const details: string[] = [];

  const lineResult = detectLineRepetition(lines, cfg.maxLineRepeats);
  const truncResult = detectTruncationRepetition(output);

  const types: string[] = [];
  let maxRepeats = 0;

  if (lineResult.found) {
    types.push("line");
    maxRepeats = Math.max(maxRepeats, lineResult.count);
    details.push(`Line "${lineResult.line.slice(0, 60)}..." repeated ${lineResult.count} times`);
  }
  if (truncResult.found) {
    types.push("truncation");
    maxRepeats = Math.max(maxRepeats, truncResult.count);
    details.push(`Truncation: ${truncResult.pattern} (${truncResult.count} times)`);
  }

  const hasRepetition = types.length > 0;
  let type: RepetitionReport["type"] = "none";
  if (types.length === 1) type = types[0] as any;
  else if (types.length > 1) type = "mixed";

  let severity: RepetitionReport["severity"] = "none";
  if (hasRepetition) {
    if (maxRepeats >= 10 || output.length > 5000) severity = "critical";
    else if (maxRepeats >= 5) severity = "high";
    else if (maxRepeats >= 3) severity = "medium";
    else severity = "low";
  }

  let cleaned = output;
  if (lineResult.found) cleaned = cleanRepeatedLines(cleaned.split("\n"), cfg.maxLineRepeats).join("\n");
  if (truncResult.found) cleaned = cleanTruncationMarkers(cleaned);
  cleaned = cleaned.replace(/^\s+/, "").replace(/\s+$/, "").replace(/\n{3,}/g, "\n\n");

  return {
    hasRepetition, type, severity,
    repeatedBlock: lineResult.found ? lineResult.line : "",
    repeatCount: maxRepeats,
    cleanedOutput: cleaned,
    originalLength: output.length,
    cleanedLength: cleaned.length,
    details,
  };
}

export async function guardOutput(
  output: string, originalPrompt: string, config: Partial<GuardConfig> = {}
): Promise<{ output: string; wasCleaned: boolean; wasReprompted: boolean; report: RepetitionReport }> {
  const report = detectRepetition(output, config);
  if (!report.hasRepetition) return { output, wasCleaned: false, wasReprompted: false, report };

  if (report.severity === "low" || report.severity === "medium") {
    return { output: report.cleanedOutput, wasCleaned: true, wasReprompted: false, report };
  }

  const cfg = { ...DEFAULT_CONFIG, ...config };
  if (cfg.modelCall && (report.severity === "high" || report.severity === "critical")) {
    const retryPrompt = `${originalPrompt}\n\n⚠️ ห้ามพิมพ์ซ้ำ! ก่อนหน้า: ${report.details.join(", ")}\nตอบครั้งเดียว กระชับ ตรงประเด็น`;
    const newOutput = await cfg.modelCall(retryPrompt);
    const newReport = detectRepetition(newOutput, config);
    if (newReport.hasRepetition) return { output: newReport.cleanedOutput, wasCleaned: true, wasReprompted: true, report: newReport };
    return { output: newOutput, wasCleaned: false, wasReprompted: true, report: newReport };
  }

  return { output: report.cleanedOutput, wasCleaned: true, wasReprompted: false, report };
}

export default { detectRepetition, guardOutput };
