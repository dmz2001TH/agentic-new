/**
 * enhancements API v3 — Test endpoints for all enhancement features
 */

import { Elysia } from "elysia";
import { createEnhancedAgent } from "../enhancements/enhanced-agent";
import { runChainOfThought } from "../enhancements/chain-of-thought";
import { runSelfReflection } from "../enhancements/self-reflection";
import { optimizePrompt } from "../enhancements/prompt-templates";
import { detectRepetition, guardOutput } from "../enhancements/repetition-guard";
import { augmentWithMemory } from "../enhancements/memory-augmented-reasoning";
import { runDebate } from "../enhancements/multi-agent-debate";
import { runSmartRetry, DEFAULT_STRATEGIES } from "../enhancements/smart-retry";
import { recordLearning, getRelevantExperience, getLearningStats } from "../enhancements/learning-feedback-loop";

function mockModel(mode: string) {
  return async (prompt: string): Promise<string> => {
    await new Promise(r => setTimeout(r, 30));
    if (/review|ตรวจ/i.test(prompt)) {
      return Math.random() > 0.4 ? "QUALITY: 8\nISSUES: none\nOK" : "QUALITY: 5\nISSUES:\n- [high] Missing check\nFIX: Add validation";
    }
    if (/proponent|เสนอ/i.test(prompt)) return "คำตอบ: วิเคราะห์จากข้อมูลแล้ว แนะนำ approach A\nconfidence: 0.75";
    if (/critic|วิจารณ์/i.test(prompt)) return "จุดดี: logic ถูก\nจุดขาด: ไม่พูดถึง edge case\nconfidence: 0.8";
    if (/synthesiz|สรุป/i.test(prompt)) return "สรุป: ใช้ approach A พร้อม edge case handling\nconfidence: 0.85";
    if (/step/i.test(prompt)) return `Step completed: found pattern\nconfidence: 0.7`;
    return "Result: analysis complete\nconfidence: 0.7";
  };
}

const ORACLE_URL = process.env.ORACLE_URL || "http://localhost:47778";

export const enhancementsApi = new Elysia({ prefix: "/enhance" })

  // ─── v3: Full enhanced solve ───
  .post("/solve", async ({ body }) => {
    const { task, context, verbose } = body as any;
    if (!task) return { error: "Missing: task" };
    const agent = createEnhancedAgent({ modelCall: mockModel("simulate"), oracleUrl: ORACLE_URL, verbose: verbose ?? false });
    const r = await agent.solve(task, context || "");
    return { success: true, result: { task: r.task, pipeline: r.pipeline, totalModelCalls: r.totalModelCalls, totalDurationMs: r.totalDurationMs, memoryFound: r.memoryFound, improvementDetected: r.improvementDetected, qualityGain: r.qualityGain } };
  })

  // ─── v3: Memory-Augmented Reasoning ───
  .post("/memory", async ({ body }) => {
    const { task, context } = body as any;
    if (!task) return { error: "Missing: task" };
    const r = await augmentWithMemory(task, context || "", {
      oracleUrl: ORACLE_URL, maxResultsPerQuery: 3, relevanceThreshold: 0.3,
      autoSearch: true, verbose: false,
    });
    return { success: true, result: { knowledgeFound: r.knowledgeFound, searchesCount: r.searches.length, enrichedContextLength: r.enrichedContext.length, topResults: r.searches.flatMap(s => s.results).slice(0, 3) } };
  })

  // ─── v3: Multi-Agent Debate ───
  .post("/debate", async ({ body }) => {
    const { task, context, rounds } = body as any;
    if (!task) return { error: "Missing: task" };
    const r = await runDebate(task, context || "", { modelCall: mockModel("simulate"), rounds: rounds || 2, verbose: false });
    return { success: true, result: { roundsCompleted: r.rounds.length, winner: r.winner, confidence: r.confidence, durationMs: r.durationMs, synthesisPreview: r.synthesis.slice(0, 200) } };
  })

  // ─── v3: Smart Retry ───
  .post("/retry", async ({ body }) => {
    const { task, maxAttempts } = body as any;
    if (!task) return { error: "Missing: task" };
    let failCount = 0;
    const executor = async (answer: string) => {
      failCount++;
      if (failCount < 3) return { success: false, output: answer, error: `Attempt ${failCount} failed: simulated error` };
      return { success: true, output: answer + " [fixed]", error: undefined };
    };
    const r = await runSmartRetry(task, {
      maxAttempts: maxAttempts || 5, modelCall: mockModel("simulate"),
      executor, strategies: DEFAULT_STRATEGIES, verbose: false,
    });
    return { success: true, result: { totalAttempts: r.totalAttempts, successfulStrategy: r.successfulStrategy, durationMs: r.durationMs, strategiesUsed: r.attempts.map(a => a.strategy) } };
  })

  // ─── v3: Learning Feedback ───
  .post("/learn", async ({ body }) => {
    const { task, approach, outcome, quality, lesson } = body as any;
    if (!task) return { error: "Missing: task" };
    const entry = await recordLearning(task, approach || "manual", outcome || "success", quality || 7, lesson || "User recorded", ["manual"], { oracleUrl: ORACLE_URL });
    return { success: true, entry };
  })
  .post("/experience", async ({ body }) => {
    const { task } = body as any;
    if (!task) return { error: "Missing: task" };
    const exp = getRelevantExperience(task);
    return { success: true, hasExperience: exp.hasExperience, count: exp.experiences.length, experiences: exp.experiences.slice(0, 3) };
  })
  .get("/learning-stats", () => {
    return { success: true, stats: getLearningStats() };
  })

  // ─── Existing endpoints ───
  .post("/cot", async ({ body }) => {
    const { task, context, maxSteps } = body as any;
    if (!task) return { error: "Missing: task" };
    const r = await runChainOfThought(task, context || "", { maxSteps: maxSteps || 4, minConfidence: 0.5, verbose: false, modelCall: mockModel("simulate") });
    return { success: true, result: { totalSteps: r.totalSteps, avgConfidence: r.avgConfidence, durationMs: r.durationMs, steps: r.steps.map(s => ({ id: s.id, name: s.name, confidence: s.confidence })) } };
  })
  .post("/reflect", async ({ body }) => {
    const { task, answer } = body as any;
    if (!task || !answer) return { error: "Missing: task, answer" };
    const r = await runSelfReflection(task, answer, { maxIterations: 3, qualityThreshold: 7, modelCall: mockModel("simulate"), verbose: false });
    return { success: true, result: { wasCorrected: r.wasCorrected, iterations: r.iterations, qualityScore: r.qualityScore, issuesFound: r.issuesFound } };
  })
  .post("/optimize", async ({ body }) => {
    const { prompt, role, maxWords } = body as any;
    if (!prompt) return { error: "Missing: prompt" };
    return { success: true, optimized: optimizePrompt(prompt, { role, maxWords: maxWords || 2000 }) };
  })
  .post("/guard", async ({ body }) => {
    const { text } = body as any;
    if (!text) return { error: "Missing: text" };
    const report = detectRepetition(text);
    return { success: true, report: { hasRepetition: report.hasRepetition, type: report.type, severity: report.severity, repeatCount: report.repeatCount, cleanedLength: report.cleanedLength } };
  })
  .post("/compare", async ({ body }) => {
    const { task, context } = body as any;
    if (!task) return { error: "Missing: task" };
    const agent = createEnhancedAgent({ modelCall: mockModel("simulate"), oracleUrl: ORACLE_URL });
    const comp = await agent.compare(task, context || "");
    return { success: true, baseline: { pipeline: comp.baseline.pipeline, calls: comp.baseline.totalModelCalls }, enhanced: { pipeline: comp.enhanced.pipeline, calls: comp.enhanced.totalModelCalls }, improvement: comp.improvement };
  })
  .get("/config", () => ({
    version: "3.0",
    features: {
      "memory-augmented-reasoning": "Search Oracle during reasoning",
      "multi-agent-debate": "Two perspectives argue then synthesize",
      "smart-retry": "Auto-retry with different strategies on failure",
      "learning-feedback-loop": "Learn from past executions",
      "chain-of-thought": "Step-by-step reasoning",
      "self-reflection": "Review and correct",
      "prompt-optimization": "Weak model prompts",
      "repetition-guard": "Detect & break repetition loops",
    },
    endpoints: [
      "POST /solve — Full v3 pipeline",
      "POST /memory — Memory augmentation",
      "POST /debate — Multi-agent debate",
      "POST /retry — Smart retry",
      "POST /learn — Record learning",
      "POST /experience — Get past experience",
      "GET  /learning-stats — Learning statistics",
      "POST /cot — Chain-of-thought only",
      "POST /reflect — Self-reflection only",
      "POST /optimize — Prompt optimization",
      "POST /guard — Repetition guard",
      "POST /compare — Baseline vs enhanced",
      "GET  /config — This endpoint",
    ],
  }));
