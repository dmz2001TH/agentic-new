/**
 * enhanced-agent.ts — Enhanced Agent Orchestrator
 * Pipeline: raw answer → repetition guard → CoT → self-reflection → final cleanup
 */

import { runChainOfThought, type CoTConfig, type CoTResult } from "./chain-of-thought";
import { runSelfReflection, type ReflectionConfig, type ReflectionResult } from "./self-reflection";
import { detectRepetition, guardOutput, type RepetitionReport } from "./repetition-guard";

export interface EnhancedAgentConfig {
  modelCall: (prompt: string) => Promise<string>;
  cotMaxSteps?: number; cotMinConfidence?: number;
  reflectionMaxIterations?: number; reflectionQualityThreshold?: number;
  enableOptimization?: boolean; enableCoT?: boolean;
  enableReflection?: boolean; enableRepetitionGuard?: boolean;
  verbose?: boolean;
}

export interface EnhancedResult {
  task: string; rawAnswer: string; enhancedAnswer: string; pipeline: string[];
  cotResult?: CoTResult; reflectionResult?: ReflectionResult; repetitionReport?: RepetitionReport;
  totalModelCalls: number; totalDurationMs: number; improvementDetected: boolean; qualityGain: number;
}

export function createEnhancedAgent(config: EnhancedAgentConfig) {
  const {
    modelCall, cotMaxSteps = 4, cotMinConfidence = 0.5,
    reflectionMaxIterations = 3, reflectionQualityThreshold = 7,
    enableOptimization = true, enableCoT = true,
    enableReflection = true, enableRepetitionGuard = true, verbose = false,
  } = config;

  let callCount = 0;
  const tracked = async (p: string): Promise<string> => { callCount++; return modelCall(p); };

  return {
    async solve(task: string, ctx: string = ""): Promise<EnhancedResult> {
      const start = Date.now();
      callCount = 0;
      const pipeline: string[] = [];

      let raw = await tracked(ctx ? `Task: ${task}\n\nContext:\n${ctx}\n\nตอบให้ดีที่สุด` : task);
      pipeline.push("raw-answer");

      let repReport: RepetitionReport | undefined;
      if (enableRepetitionGuard) {
        const g = await guardOutput(raw, task, { modelCall: tracked });
        raw = g.output; repReport = g.report;
        if (g.wasCleaned || g.wasReprompted) pipeline.push("repetition-guard");
      }

      let cur = raw;
      if (enableOptimization) pipeline.push("prompt-optimization");

      let cotR: CoTResult | undefined;
      if (enableCoT) {
        cotR = await runChainOfThought(task, ctx, { maxSteps: cotMaxSteps, minConfidence: cotMinConfidence, verbose, modelCall: tracked });
        cur = cotR.finalAnswer;
        pipeline.push("chain-of-thought");
      }

      let refR: ReflectionResult | undefined;
      if (enableReflection) {
        refR = await runSelfReflection(task, cur, { maxIterations: reflectionMaxIterations, qualityThreshold: reflectionQualityThreshold, modelCall: tracked, verbose });
        cur = refR.finalAnswer;
        pipeline.push("self-reflection");
      }

      if (enableRepetitionGuard) {
        const fg = await guardOutput(cur, task, { modelCall: tracked });
        cur = fg.output;
        if (fg.wasCleaned) pipeline.push("final-cleanup");
      }

      return {
        task, rawAnswer: raw, enhancedAnswer: cur, pipeline,
        cotResult: cotR, reflectionResult: refR, repetitionReport: repReport,
        totalModelCalls: callCount, totalDurationMs: Date.now() - start,
        improvementDetected: refR?.wasCorrected || (cotR ? cotR.avgConfidence > 0.7 : false),
        qualityGain: refR ? refR.qualityScore / 10 : (cotR ? cotR.avgConfidence : 0.5),
      };
    },

    async compare(task: string, ctx: string = "") {
      const base = await createEnhancedAgent({ modelCall, enableCoT: false, enableReflection: false, enableOptimization: false, enableRepetitionGuard: false }).solve(task, ctx);
      const enh = await createEnhancedAgent({ modelCall, enableCoT: true, enableReflection: true, enableOptimization: true, enableRepetitionGuard: true }).solve(task, ctx);
      return { baseline: base, enhanced: enh, improvement: `${enh.totalModelCalls - base.totalModelCalls} extra calls` };
    },

    getConfig() { return { cotMaxSteps, cotMinConfidence, reflectionMaxIterations, reflectionQualityThreshold, enableOptimization, enableCoT, enableReflection, enableRepetitionGuard }; },
  };
}

export type EnhancedAgent = ReturnType<typeof createEnhancedAgent>;
export default { createEnhancedAgent };
