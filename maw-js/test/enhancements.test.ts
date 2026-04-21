import { describe, test, expect } from "bun:test";
import { runChainOfThought, detectTaskType } from "../src/enhancements/chain-of-thought";
import { runSelfReflection } from "../src/enhancements/self-reflection";
import { optimizePrompt } from "../src/enhancements/prompt-templates";
import { detectRepetition, guardOutput } from "../src/enhancements/repetition-guard";
import { createEnhancedAgent } from "../src/enhancements/enhanced-agent";

function mock() {
  let n = 0;
  return {
    call: async (p: string) => { n++; await new Promise(r => setTimeout(r, 5));
      if (/review|ตรวจ/i.test(p)) return n % 3 === 0 ? "QUALITY: 5\nISSUES:\n- [high] Bug\nFIX: Fix" : "QUALITY: 8\nISSUES: none\nOK";
      if (/step/i.test(p)) return `Step result.\nconfidence: 0.75`;
      return "Result.\nconfidence: 0.7"; },
    n: () => n,
  };
}

describe("Repetition Guard", () => {
  test("clean output → no detection", () => {
    const r = detectRepetition("Clean line one\nClean line two\nClean line three");
    expect(r.hasRepetition).toBe(false);
  });
  test("line repetition detected", () => {
    const r = detectRepetition("Start\nRepeated line of text\nRepeated line of text\nRepeated line of text\nEnd");
    expect(r.hasRepetition).toBe(true);
  });
  test("✦ truncation detected", () => {
    const txt = "✦ รับทราบครับ ผมได้ทำการอ่าน GEMINI.md แล้วเรียบร้อย\n✦ รับทราบครับ ผมได้ทำการอ่าน GEMINI.md แล้วเรียบร้อย\n✦ รับทราบครับ ผมได้ทำการอ่าน GEMINI.md แล้วเรียบร้อย\n✦ รับทราบครับ ผมได้ทำการอ่าน GEMINI.md แล้วเรียบร้อย";
    const r = detectRepetition(txt);
    expect(r.hasRepetition).toBe(true);
  });
  test("guardOutput cleans", async () => {
    const m = mock();
    const line = "This is a problematic repeated line that needs fixing";
    const bad = ["Start", ...Array(10).fill(line), "End"].join("\n");
    const r = await guardOutput(bad, "test", { modelCall: m.call });
    expect(r.wasCleaned || r.wasReprompted).toBe(true);
  });
});

describe("Chain-of-Thought", () => {
  test("task type detection", () => {
    expect(detectTaskType("debug error")).toBe("debug");
    expect(detectTaskType("สรุปบทความ")).toBe("summarize");
    expect(detectTaskType("วิเคราะห์ data")).toBe("analyze");
    expect(detectTaskType("เขียน function")).toBe("code");
  });
  test("runs 4 steps", async () => {
    const m = mock();
    const r = await runChainOfThought("Analyze", "ctx", { maxSteps: 4, minConfidence: 0.5, verbose: false, modelCall: m.call });
    expect(r.totalSteps).toBe(4);
  });
});

describe("Self-Reflection", () => {
  test("accepts good answer", async () => {
    const m = mock();
    const r = await runSelfReflection("2+2?", "4", { maxIterations: 3, qualityThreshold: 7, modelCall: m.call, verbose: false });
    expect(r.wasCorrected).toBe(false);
  });
  test("corrects bad answer", async () => {
    let n = 0;
    const c = { call: async (p: string) => { n++; if (/review/i.test(p)) return "QUALITY: 3\nISSUES:\n- [high] Bug\nFIX: Fix"; return "Fixed"; } };
    const r = await runSelfReflection("T", "Bad", { maxIterations: 3, qualityThreshold: 7, modelCall: c.call, verbose: false });
    expect(r.wasCorrected).toBe(true);
  });
});

describe("Prompt Optimization", () => {
  test("adds correct role", () => {
    expect(optimizePrompt("debug error")).toContain("debugger");
    expect(optimizePrompt("วิเคราะห์ data")).toContain("analyst");
    expect(optimizePrompt("เขียน function sort")).toContain("developer");
  });
  test("adds constraints", () => { expect(optimizePrompt("Test")).toContain("กติกา"); });
  test("respects maxWords", () => { expect(optimizePrompt("Test", { maxWords: 100 })).toContain("100 คำ"); });
});

describe("Enhanced Agent", () => {
  test("full pipeline", async () => {
    const m = mock();
    const a = createEnhancedAgent({ modelCall: m.call, verbose: false });
    const r = await a.solve("Test", "ctx");
    expect(r.pipeline).toContain("chain-of-thought");
    expect(r.totalModelCalls).toBeGreaterThan(1);
  });
  test("compare shows diff", async () => {
    const m = mock();
    const a = createEnhancedAgent({ modelCall: m.call });
    const c = await a.compare("Test", "");
    expect(c.baseline.totalModelCalls).toBeLessThan(c.enhanced.totalModelCalls);
  });
});
