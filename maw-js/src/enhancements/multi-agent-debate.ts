/**
 * multi-agent-debate.ts — 2 agents argue, then synthesize best answer
 *
 * Problem: Single model has blind spots, biases, and may miss alternatives.
 * Solution: Have two "agents" (different prompt perspectives) debate,
 * then synthesize the best answer from both.
 *
 * This simulates adversarial thinking without needing 2 actual models.
 * Same model, different roles → different perspectives → better answer.
 */

export interface DebateConfig {
  modelCall: (prompt: string) => Promise<string>;
  rounds: number; // How many debate rounds (default: 2)
  verbose: boolean;
}

export interface DebateRound {
  round: number;
  proponent: string;  // Agent A's argument
  critic: string;     // Agent B's criticism
  timestamp: string;
}

export interface DebateResult {
  task: string;
  rounds: DebateRound[];
  proponentFinal: string;
  criticFinal: string;
  synthesis: string;
  winner: "proponent" | "critic" | "synthesis";
  confidence: number;
  durationMs: number;
}

const PROPONENT_PROMPT = (task: string, context: string, prevRounds: string) => `
เธอเป็น "ผู้เสนอ" (Proponent) ในการอภิปราย

## Task
${task}

${context ? `## Context\n${context}\n` : ""}
${prevRounds ? `## การอภิปรายก่อนหน้า\n${prevRounds}\n` : ""}

## หน้าที่
เสนอคำตอบที่ดีที่สุดสำหรับ task นี้
- ให้เหตุผลที่ชัดเจน
- ยกตัวอย่างประกอบ
- ตอบอย่างมั่นใจ

สุดท้ายบอก confidence (0.0-1.0)
`;

const CRITIC_PROMPT = (task: string, context: string, proponentAnswer: string, prevRounds: string) => `
เธอเป็น "ผู้วิจารณ์" (Critic) ในการอภิปราย

## Task
${task}

${context ? `## Context\n${context}\n` : ""}
${prevRounds ? `## การอภิปรายก่อนหน้า\n${prevRounds}\n` : ""}

## คำตอบจากผู้เสนอ
${proponentAnswer}

## หน้าที่
วิจารณ์คำตอบข้างต้นอย่างละเอียด:
- จุดที่ถูก: อะไรที่เห็นด้วย?
- จุดที่ผิด: อะไรที่ไม่ถูกต้อง?
- จุดที่ขาด: อะไรที่ลืมพูดถึง?
- ทางเลือกอื่น: มีวิธีที่ดีกว่ามั้ย?

ถ้าคำตอบดีอยู่แล้ว บอกว่าดี แต่ยังเสนอปรับปรุงเล็กๆ ได้
สุดท้ายบอก confidence (0.0-1.0) ว่าวิจารณ์ได้แม่นแค่ไหน
`;

const SYNTHESIS_PROMPT = (task: string, context: string, allRounds: string) => `
เธอเป็น "ผู้สรุป" (Synthesizer) 

## Task
${task}

${context ? `## Context\n${context}\n` : ""}

## การอภิปรายทั้งหมด
${allRounds}

## หน้าที่
สรุปคำตอบที่ดีที่สุดจากการอภิปราย:
- รวมจุดเด่นของทั้งสองฝ่าย
- ตัดจุดที่อ่อนแอออก
- ให้คำตอบสุดท้ายที่ชัดเจนและครอบคลุม

สุดท้ายบอก confidence (0.0-1.0)
`;

function extractConfidence(output: string): number {
  const m = output.match(/confidence[:\s]*(\d+\.?\d*)/i);
  if (m) { const v = parseFloat(m[1]); return v > 1 ? v / 100 : v; }
  return 0.7;
}

/**
 * Run multi-agent debate.
 *
 * Flow:
 * Round 1: Proponent proposes → Critic criticizes
 * Round 2: Proponent refines based on criticism → Critic re-evaluates
 * ...
 * Final: Synthesizer combines best parts
 */
export async function runDebate(
  task: string,
  context: string,
  config: DebateConfig,
): Promise<DebateResult> {
  const startTime = Date.now();
  const rounds: DebateRound[] = [];
  let allRoundsText = "";
  let lastProponent = "";
  let lastCritic = "";

  for (let i = 0; i < config.rounds; i++) {
    if (config.verbose) console.log(`[Debate] Round ${i + 1}/${config.rounds}`);

    // Proponent: propose or refine
    const proponentPrompt = PROPONENT_PROMPT(task, context, allRoundsText);
    const proponentAnswer = await config.modelCall(proponentPrompt);

    // Critic: criticize the proposal
    const criticPrompt = CRITIC_PROMPT(task, context, proponentAnswer, allRoundsText);
    const criticAnswer = await config.modelCall(criticPrompt);

    const round: DebateRound = {
      round: i + 1,
      proponent: proponentAnswer,
      critic: criticAnswer,
      timestamp: new Date().toISOString(),
    };
    rounds.push(round);

    lastProponent = proponentAnswer;
    lastCritic = criticAnswer;

    allRoundsText += `\n### Round ${i + 1}\n**ผู้เสนอ:**\n${proponentAnswer}\n\n**ผู้วิจารณ์:**\n${criticAnswer}\n\n`;
  }

  // Synthesize final answer
  const synthesisPrompt = SYNTHESIS_PROMPT(task, context, allRoundsText);
  const synthesis = await config.modelCall(synthesisPrompt);

  const proponentConf = extractConfidence(lastProponent);
  const criticConf = extractConfidence(lastCritic);
  const synthesisConf = extractConfidence(synthesis);

  // Determine winner
  let winner: DebateResult["winner"] = "synthesis";
  if (proponentConf > synthesisConf && proponentConf > criticConf + 0.1) winner = "proponent";
  if (criticConf > synthesisConf && criticConf > proponentConf + 0.1) winner = "critic";

  // Use the winning answer as final
  const finalAnswer = winner === "proponent" ? lastProponent
    : winner === "critic" ? lastCritic
    : synthesis;

  return {
    task,
    rounds,
    proponentFinal: lastProponent,
    criticFinal: lastCritic,
    synthesis: finalAnswer,
    winner,
    confidence: Math.max(proponentConf, criticConf, synthesisConf),
    durationMs: Date.now() - startTime,
  };
}

export default { runDebate, generateSearchQueries: undefined };
