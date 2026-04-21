/**
 * enhancements API — Test endpoints for agent enhancement features
 */

import { Elysia } from "elysia";
import { createEnhancedAgent } from "../enhancements/enhanced-agent";
import { runChainOfThought } from "../enhancements/chain-of-thought";
import { runSelfReflection } from "../enhancements/self-reflection";
import { optimizePrompt } from "../enhancements/prompt-templates";
import { detectRepetition, guardOutput } from "../enhancements/repetition-guard";

function createModelCall(mode: "simulate" | "oracle" = "simulate") {
  return async (prompt: string): Promise<string> => {
    if (mode === "oracle") {
      try {
        const ORACLE_URL = process.env.ORACLE_URL || "http://localhost:47778";
        const res = await fetch(`${ORACLE_URL}/api/search?q=${encodeURIComponent(prompt.slice(0, 200))}`);
        const data = await res.json() as any;
        if (data.results?.length > 0) return data.results.map((r: any) => r.content).join("\n\n");
        return `[Oracle] No knowledge found`;
      } catch { return `[Oracle Error]`; }
    }
    await new Promise(r => setTimeout(r, 50));
    if (/review|ตรวจ|check|verify/i.test(prompt)) {
      if (Math.random() > 0.5) return `QUALITY: 5\nISSUES:\n- [high] Missing null check\n- [medium] No error handling\nFIX: Add defensive coding`;
      return `QUALITY: 8\nISSUES: none\nOK`;
    }
    if (/step.*ก่อนหน้า|step ที่/i.test(prompt)) {
      const m = prompt.match(/step ที่ (\d+)/i);
      const n = m ? parseInt(m[1]) : 1;
      return `Step ${n} result: found pattern.\nconfidence: ${0.6 + n * 0.1}`;
    }
    return `Analysis: key insight found.\nconfidence: 0.7`;
  };
}

export const enhancementsApi = new Elysia({ prefix: "/enhance" })
  .post("/solve", async ({ body }) => {
    const { task, context, mode, verbose } = body as any;
    if (!task) return { error: "Missing: task" };
    const agent = createEnhancedAgent({ modelCall: createModelCall(mode || "simulate"), verbose: verbose ?? false });
    const r = await agent.solve(task, context || "");
    return { success: true, result: { task: r.task, rawAnswer: r.rawAnswer, enhancedAnswer: r.enhancedAnswer, pipeline: r.pipeline, totalModelCalls: r.totalModelCalls, totalDurationMs: r.totalDurationMs, improvementDetected: r.improvementDetected, qualityGain: r.qualityGain, cotSteps: r.cotResult?.totalSteps, cotAvgConfidence: r.cotResult?.avgConfidence, reflectionIterations: r.reflectionResult?.iterations, reflectionQuality: r.reflectionResult?.qualityScore, repetitionDetected: r.repetitionReport?.hasRepetition, repetitionSeverity: r.repetitionReport?.severity } };
  })
  .post("/cot", async ({ body }) => {
    const { task, context, maxSteps, mode } = body as any;
    if (!task) return { error: "Missing: task" };
    const r = await runChainOfThought(task, context || "", { maxSteps: maxSteps || 4, minConfidence: 0.5, verbose: false, modelCall: createModelCall(mode || "simulate") });
    return { success: true, result: { task: r.task, totalSteps: r.totalSteps, avgConfidence: r.avgConfidence, durationMs: r.durationMs, finalAnswer: r.finalAnswer, steps: r.steps.map(s => ({ id: s.id, name: s.name, confidence: s.confidence, outputPreview: s.output.slice(0, 200) })) } };
  })
  .post("/reflect", async ({ body }) => {
    const { task, answer, maxIterations, mode } = body as any;
    if (!task || !answer) return { error: "Missing: task, answer" };
    const r = await runSelfReflection(task, answer, { maxIterations: maxIterations || 3, qualityThreshold: 7, modelCall: createModelCall(mode || "simulate"), verbose: false });
    return { success: true, result: { wasCorrected: r.wasCorrected, iterations: r.iterations, qualityScore: r.qualityScore, issuesFound: r.issuesFound, durationMs: r.durationMs } };
  })
  .post("/optimize", async ({ body }) => {
    const { prompt, role, maxWords } = body as any;
    if (!prompt) return { error: "Missing: prompt" };
    return { success: true, optimized: optimizePrompt(prompt, { role, maxWords: maxWords || 2000 }), originalLength: prompt.length };
  })
  .post("/guard", async ({ body }) => {
    const { text, mode } = body as any;
    if (!text) return { error: "Missing: text" };
    const report = detectRepetition(text);
    let guarded = { output: text, wasCleaned: false, wasReprompted: false };
    if (report.hasRepetition) {
      guarded = await guardOutput(text, "original prompt", { modelCall: createModelCall(mode || "simulate") });
    }
    return { success: true, report: { hasRepetition: report.hasRepetition, type: report.type, severity: report.severity, repeatCount: report.repeatCount, originalLength: report.originalLength, cleanedLength: report.cleanedLength, details: report.details }, cleaned: guarded.wasCleaned ? guarded.output : null };
  })
  .post("/compare", async ({ body }) => {
    const { task, context, mode } = body as any;
    if (!task) return { error: "Missing: task" };
    const agent = createEnhancedAgent({ modelCall: createModelCall(mode || "simulate") });
    const comp = await agent.compare(task, context || "");
    return { success: true, baseline: { modelCalls: comp.baseline.totalModelCalls, durationMs: comp.baseline.totalDurationMs }, enhanced: { pipeline: comp.enhanced.pipeline, modelCalls: comp.enhanced.totalModelCalls, durationMs: comp.enhanced.totalDurationMs, cotSteps: comp.enhanced.cotResult?.totalSteps, reflectionQuality: comp.enhanced.reflectionResult?.qualityScore }, comparison: { extraCalls: comp.enhanced.totalModelCalls - comp.baseline.totalModelCalls, improvement: comp.improvement } };
  })
  .get("/config", () => ({
    features: { "chain-of-thought": "Step-by-step reasoning", "self-reflection": "Review and correct", "prompt-optimization": "Weak model prompts", "repetition-guard": "Detect & break repetition loops" },
    stepTemplates: ["analyze", "code", "debug", "summarize", "generic"],
    modes: ["simulate", "oracle"],
  }));
