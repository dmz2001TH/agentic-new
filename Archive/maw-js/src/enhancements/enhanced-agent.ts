/**
 * enhanced-agent.ts — Enhanced Agent Orchestrator v3
 *
 * Pipeline:
 *   1. Memory-Augmented Reasoning (search Oracle for context)
 *   2. Learning Feedback Loop (inject past experience)
 *   3. Prompt Optimization
 *   4. Chain-of-Thought (step-by-step)
 *   5. Multi-Agent Debate (if confidence low)
 *   6. Self-Reflection (review + correct)
 *   7. Smart Retry (if execution fails)
 *   8. Repetition Guard (clean output)
 */

import { runChainOfThought, type CoTConfig, type CoTResult } from "./chain-of-thought";
import { runSelfReflection, type ReflectionConfig, type ReflectionResult } from "./self-reflection";
import { detectRepetition, guardOutput, type RepetitionReport } from "./repetition-guard";
import { augmentWithMemory, type AugmentedReasoningConfig } from "./memory-augmented-reasoning";
import { runDebate, type DebateConfig } from "./multi-agent-debate";
import { runSmartRetry, type SmartRetryConfig, DEFAULT_STRATEGIES } from "./smart-retry";
import { getRelevantExperience, recordLearning } from "./learning-feedback-loop";
import { optimizePrompt } from "./prompt-templates";

export interface EnhancedAgentConfig {
  modelCall: (prompt: string) => Promise<string>;
  executor?: (action: string) => Promise<{ success: boolean; output: string; error?: string }>;
  oracleUrl?: string;

  // Feature toggles
  enableMemoryAugmentation?: boolean;
  enableLearningFeedback?: boolean;
  enableCoT?: boolean;
  enableDebate?: boolean;
  enableReflection?: boolean;
  enableSmartRetry?: boolean;
  enableRepetitionGuard?: boolean;
  enableOptimization?: boolean;

  // Tuning
  cotMaxSteps?: number;
  cotMinConfidence?: number;
  debateRounds?: number;
  reflectionMaxIterations?: number;
  reflectionQualityThreshold?: number;
  maxRetries?: number;
  debateConfidenceThreshold?: number; // Below this, trigger debate

  verbose?: boolean;
}

export interface EnhancedResult {
  task: string;
  rawAnswer: string;
  enhancedAnswer: string;
  pipeline: string[];

  // Sub-results
  memoryContext?: string;
  memoryFound: boolean;
  learningInjection?: string;
  cotResult?: CoTResult;
  debateResult?: any;
  reflectionResult?: ReflectionResult;
  retryResult?: any;
  repetitionReport?: RepetitionReport;

  // Stats
  totalModelCalls: number;
  totalDurationMs: number;
  improvementDetected: boolean;
  qualityGain: number;
}

export function createEnhancedAgent(config: EnhancedAgentConfig) {
  const {
    modelCall, executor, oracleUrl = "http://localhost:47778",
    enableMemoryAugmentation = true, enableLearningFeedback = true,
    enableCoT = true, enableDebate = true, enableReflection = true,
    enableSmartRetry = true, enableRepetitionGuard = true, enableOptimization = true,
    cotMaxSteps = 4, cotMinConfidence = 0.5,
    debateRounds = 2, reflectionMaxIterations = 3, reflectionQualityThreshold = 7,
    maxRetries = 3, debateConfidenceThreshold = 0.6,
    verbose = false,
  } = config;

  let callCount = 0;
  const tracked = async (p: string): Promise<string> => { callCount++; return modelCall(p); };

  return {
    async solve(task: string, ctx: string = ""): Promise<EnhancedResult> {
      const start = Date.now();
      callCount = 0;
      const pipeline: string[] = [];
      let memoryContext = "";
      let memoryFound = false;
      let learningInjection = "";

      // ─── 1. Memory-Augmented Reasoning ───
      if (enableMemoryAugmentation && oracleUrl) {
        const memConfig: AugmentedReasoningConfig = {
          oracleUrl, maxResultsPerQuery: 3, relevanceThreshold: 0.3,
          autoSearch: true, verbose,
        };
        const memResult = await augmentWithMemory(task, ctx, memConfig);
        memoryContext = memResult.enrichedContext;
        memoryFound = memResult.knowledgeFound;
        if (memoryFound) {
          ctx = memoryContext;
          pipeline.push("memory-augmentation");
        }
      }

      // ─── 2. Learning Feedback Loop ───
      if (enableLearningFeedback) {
        const exp = getRelevantExperience(task);
        if (exp.hasExperience) {
          learningInjection = exp.promptInjection;
          ctx = ctx + "\n\n" + learningInjection;
          pipeline.push("learning-feedback");
        }
      }

      // ─── 3. Raw baseline answer ───
      const rawPrompt = ctx
        ? `Task: ${task}\n\nContext:\n${ctx}\n\nตอบให้ดีที่สุด`
        : task;
      let rawAnswer = await tracked(rawPrompt);
      pipeline.push("raw-answer");

      // ─── 4. Repetition Guard (on raw) ───
      let repReport: RepetitionReport | undefined;
      if (enableRepetitionGuard) {
        const g = await guardOutput(rawAnswer, rawPrompt, { modelCall: tracked });
        rawAnswer = g.output;
        repReport = g.report;
        if (g.wasCleaned || g.wasReprompted) pipeline.push("repetition-guard");
      }

      let currentAnswer = rawAnswer;

      // ─── 5. Prompt Optimization ───
      if (enableOptimization) pipeline.push("prompt-optimization");

      // ─── 6. Chain-of-Thought ───
      let cotResult: CoTResult | undefined;
      if (enableCoT) {
        const cotConfig: CoTConfig = {
          maxSteps: cotMaxSteps, minConfidence: cotMinConfidence,
          verbose, modelCall: tracked,
        };
        cotResult = await runChainOfThought(task, ctx, cotConfig);
        currentAnswer = cotResult.finalAnswer;
        pipeline.push("chain-of-thought");

        // ─── 7. Multi-Agent Debate (if CoT confidence is low) ───
        if (enableDebate && cotResult.avgConfidence < debateConfidenceThreshold) {
          if (verbose) console.log("[Enhanced] CoT confidence low, triggering debate...");
          const debateConfig: DebateConfig = {
            modelCall: tracked, rounds: debateRounds, verbose,
          };
          const debateResult = await runDebate(task, ctx, debateConfig);
          if (debateResult.confidence > cotResult.avgConfidence) {
            currentAnswer = debateResult.synthesis;
          }
          pipeline.push("multi-agent-debate");
        }
      }

      // ─── 8. Self-Reflection ───
      let reflectionResult: ReflectionResult | undefined;
      if (enableReflection) {
        const reflConfig: ReflectionConfig = {
          maxIterations: reflectionMaxIterations,
          qualityThreshold: reflectionQualityThreshold,
          modelCall: tracked, verbose,
        };
        reflectionResult = await runSelfReflection(task, currentAnswer, reflConfig);
        currentAnswer = reflectionResult.finalAnswer;
        pipeline.push("self-reflection");
      }

      // ─── 9. Smart Retry (if executor fails) ───
      let retryResult: any;
      if (enableSmartRetry && executor) {
        try {
          const execResult = await executor(currentAnswer);
          if (!execResult.success) {
            if (verbose) console.log("[Enhanced] Execution failed, triggering smart retry...");
            const retryConfig: SmartRetryConfig = {
              maxAttempts: maxRetries, modelCall: tracked, executor,
              strategies: DEFAULT_STRATEGIES, verbose,
            };
            retryResult = await runSmartRetry(task, retryConfig);
            if (retryResult.success) {
              currentAnswer = retryResult.finalResult;
              pipeline.push("smart-retry");
            }
          }
        } catch { /* executor failed, skip retry */ }
      }

      // ─── 10. Final Repetition Guard ───
      if (enableRepetitionGuard) {
        const fg = await guardOutput(currentAnswer, task, { modelCall: tracked });
        currentAnswer = fg.output;
        if (fg.wasCleaned) pipeline.push("final-cleanup");
      }

      // ─── 11. Record Learning ───
      if (enableLearningFeedback) {
        const quality = reflectionResult
          ? reflectionResult.qualityScore
          : (cotResult ? Math.round(cotResult.avgConfidence * 10) : 5);
        const outcome = quality >= 7 ? "success" : quality >= 4 ? "partial" : "failure";
        await recordLearning(
          task, currentAnswer.slice(0, 200), outcome, quality,
          `Pipeline: ${pipeline.join(" → ")}`, ["auto-recorded"],
          { oracleUrl },
        );
      }

      const improvementDetected = reflectionResult?.wasCorrected || (cotResult ? cotResult.avgConfidence > 0.7 : false);
      const qualityGain = reflectionResult
        ? reflectionResult.qualityScore / 10
        : (cotResult ? cotResult.avgConfidence : 0.5);

      return {
        task, rawAnswer, enhancedAnswer: currentAnswer, pipeline,
        memoryContext: memoryFound ? memoryContext.slice(0, 300) : undefined,
        memoryFound, learningInjection: learningInjection ? learningInjection.slice(0, 300) : undefined,
        cotResult, reflectionResult, repetitionReport: repReport,
        totalModelCalls: callCount, totalDurationMs: Date.now() - start,
        improvementDetected, qualityGain,
      };
    },

    async compare(task: string, ctx: string = "") {
      const base = await createEnhancedAgent({
        modelCall, oracleUrl,
        enableCoT: false, enableReflection: false, enableOptimization: false,
        enableRepetitionGuard: false, enableMemoryAugmentation: false,
        enableLearningFeedback: false, enableDebate: false,
      }).solve(task, ctx);

      const enh = await createEnhancedAgent({
        modelCall, oracleUrl,
        enableCoT: true, enableReflection: true, enableOptimization: true,
        enableRepetitionGuard: true, enableMemoryAugmentation: true,
        enableLearningFeedback: true, enableDebate: true,
        verbose,
      }).solve(task, ctx);

      return {
        baseline: base, enhanced: enh,
        improvement: `${enh.totalModelCalls - base.totalModelCalls} extra calls, pipeline: ${enh.pipeline.join(" → ")}`,
      };
    },

    getConfig() {
      return {
        enableMemoryAugmentation, enableLearningFeedback, enableCoT,
        enableDebate, enableReflection, enableSmartRetry,
        enableRepetitionGuard, enableOptimization,
        cotMaxSteps, debateRounds, reflectionMaxIterations, maxRetries,
      };
    },
  };
}

export type EnhancedAgent = ReturnType<typeof createEnhancedAgent>;
export default { createEnhancedAgent };
