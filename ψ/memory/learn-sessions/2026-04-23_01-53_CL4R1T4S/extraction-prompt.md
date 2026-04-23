# Extraction Instructions

For each source in sources/, extract:

1. **Key Facts** (type: fact) — verifiable claims with evidence
2. **Code Snippets** (type: code) — actual code examples that work
3. **Direct Quotes** (type: quote) — important passages word-for-word
4. **Insights** (type: insight) — your analysis connecting multiple sources

## Rules:
- Every extraction MUST reference the source file
- Code must be complete enough to verify (not fragments)
- Facts must be verifiable (include where to check)
- No paraphrasing as "summary" — extract actual content
- Rate your confidence: high/medium/low for each item

## Output format for evidence/log.jsonl:
Each line: {"source":"filename","type":"fact|code|quote|insight","content":"...","confidence":"high|medium|low"}
