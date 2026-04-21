/**
 * memory-augmented-reasoning.ts — Agent ค้น Oracle ระหว่างคิด
 *
 * Problem: Agents คิดคำตอบโดยไม่มีข้อมูลจริง → มั่ว/เดา
 * Solution: ทุก step ของการคิด ให้ค้น Oracle knowledge base ก่อน
 *
 * Instead of: Model thinks alone → wrong answer
 * Do: Model searches Oracle → gets facts → reasons with facts → correct answer
 */

export interface MemorySearchResult {
  query: string;
  found: boolean;
  results: { content: string; source: string; relevance: number }[];
  searchedAt: string;
}

export interface AugmentedReasoningConfig {
  oracleUrl: string;
  maxResultsPerQuery: number;
  relevanceThreshold: number;
  autoSearch: boolean; // Auto-generate search queries from task
  verbose: boolean;
}

/**
 * Generate search queries from a task/question.
 * Breaks down the task into searchable sub-queries.
 */
export function generateSearchQueries(task: string, context: string): string[] {
  const queries: string[] = [];

  // Direct task as query
  queries.push(task);

  // Extract key terms for additional queries
  const terms = task
    .replace(/[?!.،]/g, " ")
    .split(/\s+/)
    .filter(w => w.length > 3)
    .filter(w => !/^(what|how|why|when|where|which|that|this|from|with|about|the|and|for|แต่|แล้ว|ที่|ของ|ใน|ได้|มี|จะ|เป็น)$/i.test(w));

  if (terms.length > 2) {
    // Key terms query
    queries.push(terms.slice(0, 5).join(" "));

    // Context + key terms
    if (context) {
      const ctxTerms = context.split(/\s+/).filter(w => w.length > 3).slice(0, 3);
      queries.push([...ctxTerms, ...terms.slice(0, 3)].join(" "));
    }
  }

  return [...new Set(queries)].slice(0, 3); // Max 3 unique queries
}

/**
 * Search Oracle knowledge base.
 */
export async function searchOracle(
  query: string,
  config: AugmentedReasoningConfig,
): Promise<MemorySearchResult> {
  try {
    const url = `${config.oracleUrl}/api/search?q=${encodeURIComponent(query)}&limit=${config.maxResultsPerQuery}`;
    const res = await fetch(url);
    const data = await res.json() as any;

    const results = (data.results || [])
      .filter((r: any) => (r.score || 0.5) >= config.relevanceThreshold)
      .map((r: any) => ({
        content: r.content || "",
        source: r.source_file || "oracle",
        relevance: r.score || 0.5,
      }));

    return {
      query,
      found: results.length > 0,
      results,
      searchedAt: new Date().toISOString(),
    };
  } catch (err) {
    if (config.verbose) console.log(`[Memory] Search failed for "${query}": ${err}`);
    return { query, found: false, results: [], searchedAt: new Date().toISOString() };
  }
}

/**
 * Run memory-augmented reasoning:
 * 1. Generate search queries from task
 * 2. Search Oracle for each query
 * 3. Compile relevant knowledge
 * 4. Return enriched context for model
 */
export async function augmentWithMemory(
  task: string,
  context: string,
  config: AugmentedReasoningConfig,
): Promise<{
  enrichedContext: string;
  searches: MemorySearchResult[];
  knowledgeFound: boolean;
}> {
  if (!config.autoSearch) {
    return { enrichedContext: context, searches: [], knowledgeFound: false };
  }

  const queries = generateSearchQueries(task, context);
  const searches: MemorySearchResult[] = [];

  for (const q of queries) {
    const result = await searchOracle(q, config);
    searches.push(result);
  }

  // Compile all found knowledge
  const allKnowledge = searches
    .filter(s => s.found)
    .flatMap(s => s.results)
    .sort((a, b) => b.relevance - a.relevance)
    .slice(0, 5); // Top 5 most relevant

  if (allKnowledge.length === 0) {
    return { enrichedContext: context, searches, knowledgeFound: false };
  }

  // Build enriched context
  let enriched = context ? context + "\n\n" : "";
  enriched += "## 📚 ความรู้จาก Oracle (ใช้ประกอบการคิด)\n\n";

  for (let i = 0; i < allKnowledge.length; i++) {
    const k = allKnowledge[i];
    enriched += `### แหล่งที่ ${i + 1} (${k.source}, relevance: ${k.relevance.toFixed(2)})\n`;
    enriched += k.content.slice(0, 500) + "\n\n";
  }

  enriched += "---\nใช้ความรู้ข้างต้นประกอบการคิด ถ้าข้อมูลไม่เกี่ยว ให้ ignore\n";

  return { enrichedContext: enriched, searches, knowledgeFound: true };
}

/**
 * Learn from outcome — save successful/failed patterns to Oracle.
 */
export async function learnFromOutcome(
  task: string,
  approach: string,
  outcome: "success" | "failure",
  oracleUrl: string,
): Promise<boolean> {
  try {
    const pattern = outcome === "success"
      ? `[SUCCESS] Task: ${task}\nApproach: ${approach}\nOutcome: สำเร็จ`
      : `[LESSON] Task: ${task}\nApproach: ${approach}\nOutcome: ล้มเหลว — ต้องปรับปรุง`;

    await fetch(`${oracleUrl}/api/learn`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        pattern,
        type: outcome === "success" ? "success-pattern" : "failure-lesson",
        tags: ["agent-learning", outcome],
      }),
    });
    return true;
  } catch {
    return false;
  }
}

export default { generateSearchQueries, searchOracle, augmentWithMemory, learnFromOutcome };
