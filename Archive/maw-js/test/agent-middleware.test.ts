import { describe, test, expect } from "bun:test";
import { enhanceOutgoingMessage, cleanAgentOutput } from "../src/enhancements/agent-middleware";

describe("Agent Middleware", () => {
  describe("Outgoing Enhancement", () => {
    test("wraps long messages", () => {
      const msg = "ช่วยวิเคราะห์ code นี้แล้วหา bug ให้หน่อย มี error เกิดขึ้นที่ line 42";
      const enhanced = enhanceOutgoingMessage(msg);
      expect(enhanced).toContain("CHAIN OF THOUGHT");
      expect(enhanced).toContain(msg);
    });
    test("NOT wrap short", () => { expect(enhanceOutgoingMessage("ok")).toBe("ok"); });
    test("NOT wrap /commands", () => { expect(enhanceOutgoingMessage("/help test")).toBe("/help test"); });
    test("NOT wrap system", () => { expect(enhanceOutgoingMessage("[SYSTEM RULES] x")).toBe("[SYSTEM RULES] x"); });
    test("NOT wrap chat", () => { expect(enhanceOutgoingMessage("[CHAT from:god] hi")).toBe("[CHAT from:god] hi"); });
    test("NOT double-wrap", () => {
      const msg = "[SYSTEM RULES] CHAIN OF THOUGHT: test";
      expect(enhanceOutgoingMessage(msg)).toBe(msg);
    });
  });
  describe("Output Cleaning", () => {
    test("clean passes through", () => {
      const r = cleanAgentOutput("Clean line one\nClean line two");
      expect(r.wasModified).toBe(false);
    });
    test("cleans repeated lines", () => {
      const r = cleanAgentOutput("Start\nRepeated line of text\nRepeated line of text\nRepeated line of text\nEnd");
      expect(r.wasModified).toBe(true);
    });
    test("cleans ✦ pattern", () => {
      const txt = "✦ รับทราบครับ ผมได้ทำการอ่าน GEMINI.md แล้วเรียบร้อย\n✦ รับทราบครับ ผมได้ทำการอ่าน GEMINI.md แล้วเรียบร้อย\n✦ รับทราบครับ ผมได้ทำการอ่าน GEMINI.md แล้วเรียบร้อย";
      const r = cleanAgentOutput(txt);
      expect(r.wasModified).toBe(true);
    });
    test("short unchanged", () => { expect(cleanAgentOutput("Hi").wasModified).toBe(false); });
  });
  describe("Integration", () => {
    test("enhance → clean pipeline", () => {
      const enhanced = enhanceOutgoingMessage("ช่วยวิเคราะห์ bug นี้");
      expect(enhanced).toContain("CHAIN OF THOUGHT");
      const repeated = "ผลวิเคราะห์: พบปัญหา\nผลวิเคราะห์: พบปัญหา\nผลวิเคราะห์: พบปัญหา\nวิธีแก้: เพิ่ม null check";
      const cleaned = cleanAgentOutput(repeated);
      expect(cleaned.wasModified).toBe(true);
    });
  });
});
