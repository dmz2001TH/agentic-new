// Enhancement modules — v3
export { runChainOfThought, detectTaskType, STEP_TEMPLATES } from "./chain-of-thought";
export type { CoTStep, CoTResult, CoTConfig } from "./chain-of-thought";
export { runSelfReflection } from "./self-reflection";
export type { ReflectionResult, ReflectionIssue, ReflectionConfig } from "./self-reflection";
export { optimizePrompt, SYSTEM_HINTS, CONSTRAINTS } from "./prompt-templates";
export { createEnhancedAgent } from "./enhanced-agent";
export type { EnhancedAgent, EnhancedAgentConfig, EnhancedResult } from "./enhanced-agent";
export { detectRepetition, guardOutput } from "./repetition-guard";
export type { RepetitionReport, GuardConfig } from "./repetition-guard";
export { installMiddleware, enhanceOutgoingMessage, cleanAgentOutput, patchGeminiMd } from "./agent-middleware";

// v3 — Advanced modules
export { augmentWithMemory, searchOracle, generateSearchQueries, learnFromOutcome } from "./memory-augmented-reasoning";
export type { AugmentedReasoningConfig, MemorySearchResult } from "./memory-augmented-reasoning";
export { runDebate } from "./multi-agent-debate";
export type { DebateConfig, DebateRound, DebateResult } from "./multi-agent-debate";
export { runSmartRetry, DEFAULT_STRATEGIES } from "./smart-retry";
export type { SmartRetryConfig, RetryStrategy, RetryAttempt, RetryResult } from "./smart-retry";
export { recordLearning, getRelevantExperience, loadLearningHistory, getLearningStats } from "./learning-feedback-loop";
export type { LearningEntry, LearningConfig } from "./learning-feedback-loop";
