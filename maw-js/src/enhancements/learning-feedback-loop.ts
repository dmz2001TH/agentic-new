/**
 * learning-feedback-loop.ts — Track what works, improve over time
 *
 * Problem: Agent makes the same mistakes repeatedly because it doesn't learn.
 * Solution: Track every task execution, store patterns of what works/fails,
 * and inject relevant past experience into future prompts.
 *
 * This creates a feedback loop:
 *   Execute → Observe outcome → Store pattern → Use pattern next time → Better result
 */

export interface LearningEntry {
  id: string;
  taskType: string;
  taskSummary: string;
  approach: string;
  outcome: "success" | "partial" | "failure";
  quality: number; // 0-10
  lesson: string; // What we learned
  timestamp: string;
  tags: string[];
}

export interface LearningConfig {
  oracleUrl: string;
  maxHistorySize: number;
  minQualityForSuccess: number; // Minimum quality to count as success (default: 6)
  verbose: boolean;
}

/**
 * In-memory learning store (loaded from Oracle on init).
 */
let learningStore: LearningEntry[] = [];

/**
 * Detect task type for categorization.
 */
function categorizeTask(task: string): string {
  const l = task.toLowerCase();
  if (/debug|error|bug|fix|แก้ไข/i.test(l)) return "debug";
  if (/code|function|implement|เขียน/i.test(l)) return "code";
  if (/analyze|วิเคราะห์|data/i.test(l)) return "analyze";
  if (/design|architect|ออกแบบ/i.test(l)) return "design";
  if (/test|เทส/i.test(l)) return "test";
  if (/deploy|วาง/i.test(l)) return "deploy";
  return "general";
}

/**
 * Generate a summary of a task for pattern matching.
 */
function summarizeTask(task: string): string {
  return task
    .slice(0, 100)
    .replace(/[?!。，]/g, " ")
    .split(/\s+/)
    .filter(w => w.length > 2)
    .slice(0, 10)
    .join(" ")
    .toLowerCase();
}

/**
 * Find similar past experiences.
 */
function findSimilarExperiences(
  task: string,
  taskType: string,
  maxResults: number = 3,
): LearningEntry[] {
  const summary = summarizeTask(task);
  const summaryWords = new Set(summary.split(" "));

  return learningStore
    .filter(e => e.taskType === taskType || e.taskType === "general")
    .map(e => {
      // Simple word overlap similarity
      const eWords = new Set(e.taskSummary.split(" "));
      let overlap = 0;
      for (const w of summaryWords) if (eWords.has(w)) overlap++;
      const similarity = overlap / Math.max(summaryWords.size, eWords.size, 1);
      return { entry: e, similarity };
    })
    .filter(e => e.similarity > 0.2)
    .sort((a, b) => {
      // Prefer: high similarity > success > high quality > recent
      if (Math.abs(a.similarity - b.similarity) > 0.1) return b.similarity - a.similarity;
      if (a.entry.outcome !== b.entry.outcome) {
        if (a.entry.outcome === "success") return -1;
        if (b.entry.outcome === "success") return 1;
      }
      return b.entry.quality - a.entry.quality;
    })
    .slice(0, maxResults)
    .map(e => e.entry);
}

/**
 * Record a learning entry.
 */
export async function recordLearning(
  task: string,
  approach: string,
  outcome: "success" | "partial" | "failure",
  quality: number,
  lesson: string,
  tags: string[] = [],
  config?: Partial<LearningConfig>,
): Promise<LearningEntry> {
  const entry: LearningEntry = {
    id: `learn_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    taskType: categorizeTask(task),
    taskSummary: summarizeTask(task),
    approach,
    outcome,
    quality,
    lesson,
    timestamp: new Date().toISOString(),
    tags: ["auto-learned", ...tags],
  };

  learningStore.push(entry);

  // Keep store bounded
  const maxSize = config?.maxHistorySize || 100;
  if (learningStore.length > maxSize) {
    // Keep best entries (success + high quality)
    learningStore = learningStore
      .sort((a, b) => {
        if (a.outcome !== b.outcome) {
          if (a.outcome === "success") return -1;
          if (b.outcome === "success") return 1;
        }
        return b.quality - a.quality;
      })
      .slice(0, maxSize);
  }

  // Save to Oracle if configured
  if (config?.oracleUrl) {
    try {
      await fetch(`${config.oracleUrl}/api/learn`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          pattern: `[${entry.outcome.toUpperCase()}] ${task}\nApproach: ${approach}\nLesson: ${lesson}`,
          type: `learning-${entry.outcome}`,
          tags: entry.tags,
        }),
      });
    } catch { /* best effort */ }
  }

  return entry;
}

/**
 * Get relevant past experiences for a new task.
 * Returns a formatted string ready to inject into prompts.
 */
export function getRelevantExperience(task: string): {
  hasExperience: boolean;
  experiences: LearningEntry[];
  promptInjection: string;
} {
  const taskType = categorizeTask(task);
  const relevant = findSimilarExperiences(task, taskType);

  if (relevant.length === 0) {
    return { hasExperience: false, experiences: [], promptInjection: "" };
  }

  let injection = "## 📝 ประสบการณ์ที่เกี่ยวข้อง (จาก past executions)\n\n";

  for (const exp of relevant) {
    const emoji = exp.outcome === "success" ? "✅" : exp.outcome === "partial" ? "⚠️" : "❌";
    injection += `${emoji} **${exp.taskType}** (quality: ${exp.quality}/10)\n`;
    injection += `- Task: ${exp.taskSummary}\n`;
    injection += `- Approach: ${exp.approach.slice(0, 100)}\n`;
    if (exp.outcome === "success") {
      injection += `- ✅ สำเร็จ — ใช้ approach นี้เป็นต้นแบบ\n`;
    } else {
      injection += `- ❌ ไม่สำเร็จ — ${exp.lesson.slice(0, 100)}\n`;
      injection += `- 💡 หลีกเลี่ยง approach นี้ ลองวิธีอื่น\n`;
    }
    injection += `\n`;
  }

  injection += "---\ใช้ประสบการณ์ข้างต้นประกอบ: เลียนแบบสิ่งที่สำเร็จ หลีกเลี่ยงสิ่งที่ล้มเหลว\n";

  return { hasExperience: true, experiences: relevant, promptInjection: injection };
}

/**
 * Load learning history from Oracle on startup.
 */
export async function loadLearningHistory(oracleUrl: string): Promise<number> {
  try {
    const res = await fetch(`${oracleUrl}/api/search?q=learning&type=learning&limit=50`);
    const data = await res.json() as any;

    if (data.results) {
      for (const r of data.results) {
        const content = r.content || "";
        const isFailure = content.includes("[FAILURE]") || content.includes("[LESSON]");
        const isSuccess = content.includes("[SUCCESS]");

        learningStore.push({
          id: r.id || `loaded_${Date.now()}`,
          taskType: "general",
          taskSummary: content.slice(0, 100).toLowerCase(),
          approach: "loaded from oracle",
          outcome: isSuccess ? "success" : isFailure ? "failure" : "partial",
          quality: isSuccess ? 8 : 3,
          lesson: content.slice(0, 200),
          timestamp: r.indexed_at ? new Date(r.indexed_at).toISOString() : new Date().toISOString(),
          tags: ["loaded"],
        });
      }
    }

    return learningStore.length;
  } catch {
    return 0;
  }
}

/**
 * Get learning stats.
 */
export function getLearningStats(): {
  total: number;
  byOutcome: Record<string, number>;
  byTaskType: Record<string, number>;
  avgQuality: number;
} {
  const byOutcome: Record<string, number> = {};
  const byTaskType: Record<string, number> = {};
  let totalQuality = 0;

  for (const e of learningStore) {
    byOutcome[e.outcome] = (byOutcome[e.outcome] || 0) + 1;
    byTaskType[e.taskType] = (byTaskType[e.taskType] || 0) + 1;
    totalQuality += e.quality;
  }

  return {
    total: learningStore.length,
    byOutcome,
    byTaskType,
    avgQuality: learningStore.length > 0 ? totalQuality / learningStore.length : 0,
  };
}

export default { recordLearning, getRelevantExperience, loadLearningHistory, getLearningStats };
