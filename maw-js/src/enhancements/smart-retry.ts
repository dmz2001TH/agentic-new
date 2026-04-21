/**
 * smart-retry.ts — Auto-retry with different strategies when execution fails
 *
 * Problem: When an agent's code/tool execution fails, it either:
 * 1. Gives up immediately
 * 2. Retries with the EXACT same approach (and fails again)
 *
 * Solution: On failure, analyze WHY it failed, generate alternative approaches,
 * and try a different strategy. Track what works for future reference.
 */

export interface RetryStrategy {
  name: string;
  description: string;
  promptModifier: string; // Extra instruction added to retry prompt
}

export interface RetryAttempt {
  attempt: number;
  strategy: string;
  prompt: string;
  result: string;
  success: boolean;
  error?: string;
  durationMs: number;
}

export interface RetryResult {
  task: string;
  attempts: RetryAttempt[];
  finalResult: string;
  success: boolean;
  totalAttempts: number;
  successfulStrategy: string | null;
  durationMs: number;
}

export interface SmartRetryConfig {
  maxAttempts: number;
  modelCall: (prompt: string) => Promise<string>;
  executor?: (action: string) => Promise<{ success: boolean; output: string; error?: string }>;
  strategies: RetryStrategy[];
  verbose: boolean;
}

/**
 * Default retry strategies — each gives a different approach to the same problem.
 */
export const DEFAULT_STRATEGIES: RetryStrategy[] = [
  {
    name: "simplify",
    description: "ลดความซับซ้อน — ทำทีละส่วนเล็กๆ",
    promptModifier: "วิธีเดิมซับซ้อนเกินไป ลองใหม่โดย: ทำทีละ step เล็กๆ อย่าทำหลายอย่างพร้อมกัน",
  },
  {
    name: "different-approach",
    description: "เปลี่ยนวิธีทั้งหมด — ลอง algorithm/library อื่น",
    promptModifier: "วิธีเดิมไม่เวิร์ค ลอง approach ที่ต่างไปเลย: ใช้ algorithm อื่น, library อื่น, หรือ logic ต่างกัน",
  },
  {
    name: "add-error-handling",
    description: "เพิ่ม error handling — จัดการ edge cases",
    promptModifier: "วิธีเดิมไม่จัดการ error ลองใหม่โดย: เพิ่ม try-catch, null checks, validation, จัดการ edge cases",
  },
  {
    name: "decompose",
    description: "แตกเป็นชิ้นเล็ก — แก้ทีละจุด",
    promptModifier: "วิธีเดิมทำมากเกินไปทีเดียว แตกเป็นชิ้นเล็กๆ แล้วแก้ทีละชิ้น",
  },
  {
    name: "ask-clarity",
    description: "ถามหาความชัดเจน — อะไรคือ requirement จริงๆ?",
    promptModifier: "ก่อนแก้ ถามตัวเอง: task นี้ต้องการอะไรจริงๆ? requirement ชัดเจนมั้ย? ถ้าไม่ชัด ลอง assumption ที่ต่างกัน",
  },
];

/**
 * Analyze error to select the best retry strategy.
 */
function selectStrategy(
  error: string,
  previousStrategies: string[],
  availableStrategies: RetryStrategy[],
): RetryStrategy {
  const errorLower = error.toLowerCase();

  // Match error type to strategy
  if (/undefined|null|cannot read|is not/i.test(errorLower)) {
    const s = availableStrategies.find(s => s.name === "add-error-handling" && !previousStrategies.includes(s.name));
    if (s) return s;
  }

  if (/timeout|slow|hang/i.test(errorLower)) {
    const s = availableStrategies.find(s => s.name === "simplify" && !previousStrategies.includes(s.name));
    if (s) return s;
  }

  if (/syntax|unexpected|parse/i.test(errorLower)) {
    const s = availableStrategies.find(s => s.name === "different-approach" && !previousStrategies.includes(s.name));
    if (s) return s;
  }

  if (/not found|missing|import/i.test(errorLower)) {
    const s = availableStrategies.find(s => s.name === "decompose" && !previousStrategies.includes(s.name));
    if (s) return s;
  }

  // Fallback: pick first unused strategy
  for (const s of availableStrategies) {
    if (!previousStrategies.includes(s.name)) return s;
  }

  // All used — cycle back
  return availableStrategies[previousStrategies.length % availableStrategies.length];
}

/**
 * Build retry prompt with strategy modification.
 */
function buildRetryPrompt(
  task: string,
  previousAttempts: RetryAttempt[],
  strategy: RetryStrategy,
): string {
  let prompt = `## Task\n${task}\n\n`;

  if (previousAttempts.length > 0) {
    prompt += `## ลองมาแล้ว ${previousAttempts.length} ครั้ง ยังไม่สำเร็จ\n\n`;

    for (const attempt of previousAttempts) {
      prompt += `### Attempt ${attempt.attempt} (${attempt.strategy})\n`;
      prompt += `Result: ${attempt.success ? "✅ สำเร็จ" : "❌ ล้มเหลว"}\n`;
      if (attempt.error) prompt += `Error: ${attempt.error}\n`;
      prompt += `\n`;
    }
  }

  prompt += `## กลยุทธ์ใหม่: ${strategy.name}\n`;
  prompt += `${strategy.description}\n\n`;
  prompt += `**${strategy.promptModifier}**\n`;

  return prompt;
}

/**
 * Run smart retry loop.
 *
 * @param task - The task to execute
 * @param config - Retry configuration
 */
export async function runSmartRetry(
  task: string,
  config: SmartRetryConfig,
): Promise<RetryResult> {
  const startTime = Date.now();
  const attempts: RetryAttempt[] = [];
  const strategies = config.strategies.length > 0 ? config.strategies : DEFAULT_STRATEGIES;
  const usedStrategies: string[] = [];
  let finalResult = "";
  let success = false;

  for (let i = 0; i < config.maxAttempts; i++) {
    const attemptStart = Date.now();

    // Select strategy
    const previousErrors = attempts.filter(a => !a.success).map(a => a.error || "unknown");
    const strategy = selectStrategy(
      previousErrors[previousErrors.length - 1] || "",
      usedStrategies,
      strategies,
    );
    usedStrategies.push(strategy.name);

    if (config.verbose) {
      console.log(`[SmartRetry] Attempt ${i + 1}/${config.maxAttempts}: strategy="${strategy.name}"`);
    }

    // Build retry prompt
    const prompt = buildRetryPrompt(task, attempts, strategy);

    // Generate solution with new strategy
    const result = await config.modelCall(prompt);
    finalResult = result;

    // Try to execute if executor is provided
    let attemptSuccess = true;
    let attemptError: string | undefined;

    if (config.executor) {
      try {
        const execResult = await config.executor(result);
        attemptSuccess = execResult.success;
        attemptError = execResult.error;
        if (execResult.success) finalResult = execResult.output;
      } catch (e: any) {
        attemptSuccess = false;
        attemptError = e.message;
      }
    }

    const attempt: RetryAttempt = {
      attempt: i + 1,
      strategy: strategy.name,
      prompt,
      result,
      success: attemptSuccess,
      error: attemptError,
      durationMs: Date.now() - attemptStart,
    };
    attempts.push(attempt);

    if (attemptSuccess) {
      success = true;
      if (config.verbose) console.log(`[SmartRetry] Success on attempt ${i + 1} with strategy "${strategy.name}"`);
      break;
    }

    if (config.verbose) {
      console.log(`[SmartRetry] Attempt ${i + 1} failed: ${attemptError || "unknown error"}`);
    }
  }

  return {
    task,
    attempts,
    finalResult,
    success,
    totalAttempts: attempts.length,
    successfulStrategy: success ? attempts[attempts.length - 1].strategy : null,
    durationMs: Date.now() - startTime,
  };
}

export default { runSmartRetry, DEFAULT_STRATEGIES };
