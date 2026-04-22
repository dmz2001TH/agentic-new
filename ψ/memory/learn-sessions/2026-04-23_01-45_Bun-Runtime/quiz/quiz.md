# Quiz: Bun Runtime

## Factual Questions
1. What JavaScript engine does Bun use? → JavaScriptCore (JSC) from WebKit, not V8 like Node.js
2. What are the 4 tools Bun replaces? → Runtime, bundler, transpiler, package manager
3. How much faster is Bun vs Node for HTTP? → ~4x faster (hello-world benchmark)

## Code Questions
4. How to run TypeScript with Bun? → `bun run script.ts` (no compilation step needed)

## Synthesis
5. How does Bun position itself vs Node.js and Deno? → Drop-in Node replacement but faster, TS-first like Deno but with Node compat

## Self-Assessment
- ตอบได้ 5/5 ข้อ
- Confidence: medium — fetched content is large (288K chars) but only scanned key sections
- สิ่งที่ยังไม่เข้าใจ: Bun's internal memory model, SQLite integration details, how JSC differs from V8 in practice
