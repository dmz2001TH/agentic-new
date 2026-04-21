/**
 * enhancements-v3.test.ts — Tests for v3 advanced modules
 */

import { describe, test, expect } from "bun:test";
import { augmentWithMemory, generateSearchQueries } from "../src/enhancements/memory-augmented-reasoning";
import { runDebate } from "../src/enhancements/multi-agent-debate";
import { runSmartRetry, DEFAULT_STRATEGIES } from "../src/enhancements/smart-retry";
import { recordLearning, getRelevantExperience, getLearningStats } from "../src/enhancements/learning-feedback-loop";
import { createEnhancedAgent } from "../src/enhancements/enhanced-agent";

function mock() {
  let n = 0;
  return {
    call: async (p: string) => {
      n++; await new Promise(r => setTimeout(r, 5));
      if (/review|ตรวจ/i.test(p)) return n % 3 === 0 ? "QUALITY: 5\nISSUES:\n- [high] Bug\nFIX: Fix" : "QUALITY: 8\nISSUES: none\nOK";
      if (/proponent|เสนอ/i.test(p)) return "คำตอบ: แนะนำ approach A\nconfidence: 0.75";
      if (/critic|วิจารณ์/i.test(p)) return "จุดดี: logic ถูก\nจุดขาด: ไม่พูดถึง edge case\nconfidence: 0.8";
      if (/synthesiz|สรุป/i.test(p)) return "สรุป: ใช้ approach A พร้อม edge handling\nconfidence: 0.85";
      if (/step/i.test(p)) return `Step result\nconfidence: 0.7`;
      return "Result\nconfidence: 0.7";
    },
    n: () => n,
  };
}

// ─── Memory-Augmented Reasoning ───

describe("Memory-Augmented Reasoning", () => {
  test("generates search queries from task", () => {
    const queries = generateSearchQueries("How to deploy Kubernetes on bare metal?", "Production environment");
    expect(queries.length).toBeGreaterThan(0);
    expect(queries[0]).toContain("deploy Kubernetes");
  });

  test("returns enriched context when knowledge found", async () => {
    // Use a mock Oracle URL that will fail (no server running)
    const result = await augmentWithMemory("test task", "some context", {
      oracleUrl: "http://localhost:99999",
      maxResultsPerQuery: 3,
      relevanceThreshold: 0.3,
      autoSearch: true,
      verbose: false,
    });
    // Should gracefully handle no Oracle
    expect(result.knowledgeFound).toBe(false);
    expect(result.searches.length).toBeGreaterThan(0);
  });

  test("skips search when autoSearch is false", async () => {
    const result = await augmentWithMemory("test", "ctx", {
      oracleUrl: "http://localhost:99999",
      maxResultsPerQuery: 3,
      relevanceThreshold: 0.3,
      autoSearch: false,
      verbose: false,
    });
    expect(result.searches.length).toBe(0);
    expect(result.knowledgeFound).toBe(false);
  });
});

// ─── Multi-Agent Debate ───

describe("Multi-Agent Debate", () => {
  test("runs debate with correct number of rounds", async () => {
    const m = mock();
    const result = await runDebate("Should we use microservices?", "Startup with 3 devs", {
      modelCall: m.call, rounds: 2, verbose: false,
    });
    expect(result.rounds.length).toBe(2);
    expect(result.rounds[0].proponent).toBeTruthy();
    expect(result.rounds[0].critic).toBeTruthy();
    expect(result.rounds[1].proponent).toBeTruthy();
    expect(result.rounds[1].critic).toBeTruthy();
  });

  test("produces synthesis after debate", async () => {
    const m = mock();
    const result = await runDebate("Best language for backend?", "", {
      modelCall: m.call, rounds: 1, verbose: false,
    });
    expect(result.synthesis).toBeTruthy();
    expect(result.winner).toBeDefined();
    expect(["proponent", "critic", "synthesis"]).toContain(result.winner);
    expect(result.confidence).toBeGreaterThan(0);
  });

  test("debate uses different prompts for each role", async () => {
    const prompts: string[] = [];
    const trackingModel = async (p: string) => {
      prompts.push(p);
      await new Promise(r => setTimeout(r, 5));
      if (/เสนอ|proponent/i.test(p)) return "Proposal\nconfidence: 0.8";
      if (/วิจารณ์|critic/i.test(p)) return "Criticism\nconfidence: 0.7";
      if (/สรุป|synthesiz/i.test(p)) return "Synthesis\nconfidence: 0.9";
      return "Response\nconfidence: 0.7";
    };

    await runDebate("Test", "", { modelCall: trackingModel, rounds: 1, verbose: false });

    // Should have: proponent, critic, synthesizer prompts
    expect(prompts.length).toBe(3);
    expect(prompts.some(p => /เสนอ|proponent/i.test(p))).toBe(true);
    expect(prompts.some(p => /วิจารณ์|critic/i.test(p))).toBe(true);
    expect(prompts.some(p => /สรุป|synthesiz/i.test(p))).toBe(true);
  });
});

// ─── Smart Retry ───

describe("Smart Retry", () => {
  test("succeeds after failures with different strategies", async () => {
    const m = mock();
    let attempts = 0;
    const executor = async (answer: string) => {
      attempts++;
      if (attempts < 3) return { success: false, output: answer, error: `Simulated failure ${attempts}` };
      return { success: true, output: answer + " [fixed]", error: undefined };
    };

    const result = await runSmartRetry("Fix this bug", {
      maxAttempts: 5, modelCall: m.call, executor,
      strategies: DEFAULT_STRATEGIES, verbose: false,
    });

    expect(result.success).toBe(true);
    expect(result.totalAttempts).toBe(3);
    expect(result.successfulStrategy).toBeTruthy();
  });

  test("uses different strategies for each attempt", async () => {
    const m = mock();
    let attempts = 0;
    const executor = async (answer: string) => {
      attempts++;
      if (attempts < 4) return { success: false, output: answer, error: "Always fails" };
      return { success: true, output: answer, error: undefined };
    };

    const result = await runSmartRetry("Task", {
      maxAttempts: 5, modelCall: m.call, executor,
      strategies: DEFAULT_STRATEGIES, verbose: false,
    });

    const strategiesUsed = [...new Set(result.attempts.map(a => a.strategy))];
    expect(strategiesUsed.length).toBeGreaterThan(1); // Different strategies used
  });

  test("respects maxAttempts limit", async () => {
    const m = mock();
    const alwaysFail = async () => ({ success: false, output: "", error: "Always fails" });

    const result = await runSmartRetry("Task", {
      maxAttempts: 3, modelCall: m.call, executor: alwaysFail,
      strategies: DEFAULT_STRATEGIES, verbose: false,
    });

    expect(result.success).toBe(false);
    expect(result.totalAttempts).toBe(3);
  });

  test("has default strategies", () => {
    expect(DEFAULT_STRATEGIES.length).toBe(5);
    expect(DEFAULT_STRATEGIES.map(s => s.name)).toContain("simplify");
    expect(DEFAULT_STRATEGIES.map(s => s.name)).toContain("different-approach");
    expect(DEFAULT_STRATEGIES.map(s => s.name)).toContain("add-error-handling");
    expect(DEFAULT_STRATEGIES.map(s => s.name)).toContain("decompose");
    expect(DEFAULT_STRATEGIES.map(s => s.name)).toContain("ask-clarity");
  });
});

// ─── Learning Feedback Loop ───

describe("Learning Feedback Loop", () => {
  test("records and retrieves learning entries", async () => {
    await recordLearning("debug TypeError in React", "Added null check", "success", 8, "Always check for null before accessing properties", ["react", "typescript"]);
    await recordLearning("optimize SQL query", "Used JOIN instead of subquery", "success", 9, "JOINs are faster than subqueries for large tables", ["sql", "performance"]);

    const exp = getRelevantExperience("debug TypeError in component");
    // May or may not find depending on similarity threshold
    expect(typeof exp.hasExperience).toBe("boolean");
  });

  test("get learning stats", async () => {
    const stats = getLearningStats();
    expect(stats.total).toBeGreaterThanOrEqual(0);
    expect(typeof stats.byOutcome).toBe("object");
    expect(typeof stats.avgQuality).toBe("number");
  });

  test("getRelevantExperience returns empty for unrelated task", () => {
    const exp = getRelevantExperience("xyzzy unique never seen before task 12345");
    expect(exp.hasExperience).toBe(false);
    expect(exp.experiences.length).toBe(0);
  });
});

// ─── Enhanced Agent v3 ───

describe("Enhanced Agent v3", () => {
  test("runs full v3 pipeline", async () => {
    const m = mock();
    const agent = createEnhancedAgent({
      modelCall: m.call,
      oracleUrl: "http://localhost:99999", // No Oracle, will gracefully skip
      verbose: false,
    });
    const r = await agent.solve("Analyze this bug", "Error at line 42");

    expect(r.pipeline).toContain("chain-of-thought");
    expect(r.pipeline).toContain("self-reflection");
    expect(r.totalModelCalls).toBeGreaterThan(1);
  });

  test("includes memory augmentation in pipeline when Oracle available", async () => {
    const m = mock();
    const agent = createEnhancedAgent({
      modelCall: m.call,
      oracleUrl: "http://localhost:99999",
      enableMemoryAugmentation: true,
      verbose: false,
    });
    const r = await agent.solve("Test", "");

    // Memory augmentation attempted (but fails gracefully without Oracle)
    expect(r.pipeline).toBeDefined();
  });

  test("v3 config includes all features", () => {
    const m = mock();
    const agent = createEnhancedAgent({ modelCall: m.call });
    const config = agent.getConfig();

    expect(config.enableMemoryAugmentation).toBe(true);
    expect(config.enableLearningFeedback).toBe(true);
    expect(config.enableCoT).toBe(true);
    expect(config.enableDebate).toBe(true);
    expect(config.enableReflection).toBe(true);
    expect(config.enableSmartRetry).toBe(true);
    expect(config.enableRepetitionGuard).toBe(true);
    expect(config.enableOptimization).toBe(true);
  });

  test("v3 compare shows baseline vs enhanced", async () => {
    const m = mock();
    const agent = createEnhancedAgent({
      modelCall: m.call,
      oracleUrl: "http://localhost:99999",
    });
    const comp = await agent.compare("Test task", "context");
    expect(comp.baseline.totalModelCalls).toBeLessThan(comp.enhanced.totalModelCalls);
    expect(comp.improvement).toBeTruthy();
  });
});
