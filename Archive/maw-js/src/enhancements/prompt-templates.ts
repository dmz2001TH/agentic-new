/**
 * prompt-templates.ts — Optimized prompts for weak models
 * Adds system hints, constraints, and structure to improve weak model output.
 */

export const SYSTEM_HINTS = {
  coder: "เธอเป็น developer ที่เขียน code ทีละบรรทัด ตรวจทีละจุด\nไม่เดา ไม่มั่ว ถ้าไม่แน่ใจบอกว่าไม่แน่ใจ",
  analyzer: "เธอเป็น analyst ที่ดูข้อมูลอย่างละเอียด\n列出 fact ก่อน แล้วค่อยตีความ อย่าสรุปก่อนดูข้อมูล",
  reviewer: "เธอเป็น code reviewer ที่ตรวจจุดผิดพลาด\nตรวจอย่างละเอียด แม้แต่จุดเล็กๆ ก็ต้องรายงาน",
  writer: "เธอเป็น writer ที่เขียนชัดเจน กระชับ\nไม่ใช้คำฟุ่มเฟือย ทุกประโยคมีสาระ",
  planner: "เธอเป็น planner ที่คิดเป็นลำดับ\n列出 step ก่อน แล้วค่อยทำทีละ step อย่าข้าม",
  debugger: "เธอเป็น debugger ที่หาสาเหตุของปัญหา\nอ่าน error ก่อน คิด hypothesis แล้ว检验 อย่าเดา",
};

export const CONSTRAINTS = {
  noSpeculation: "อย่าเดา ถ้าไม่รู้ให้บอกว่าไม่รู้",
  beSpecific: "给出具体的例子 อย่า泛泛而谈",
  limitLength: (max: number) => `ตอบไม่เกิน ${max} คำ`,
  noHallucination: "อย่าแต่งข้อมูล ใช้เฉพาะสิ่งที่มีอยู่จริง",
  stepByStep: "คิดทีละ step อย่าข้าม",
  checkBeforeAnswer: "ตรวจคำตอบก่อนส่ง ว่าถูกต้องจริงมั้ย",
};

function inferRole(prompt: string): keyof typeof SYSTEM_HINTS {
  const l = prompt.toLowerCase();
  if (/debug|error|bug|แก้ไข/i.test(l)) return "debugger";
  if (/review|ตรวจ|check/i.test(l)) return "reviewer";
  if (/plan|ออกแบบ|architecture/i.test(l)) return "planner";
  if (/code|function|script|implement|เขียนโค้ด|เขียน.*func/i.test(l)) return "coder";
  if (/write|เขียน|essay|summarize/i.test(l)) return "writer";
  if (/analyze|วิเคราะห์|compare|ดูข้อมูล/i.test(l)) return "analyzer";
  return "analyzer";
}

function inferConstraints(prompt: string): string[] {
  const cs: string[] = [CONSTRAINTS.noSpeculation, CONSTRAINTS.checkBeforeAnswer];
  const l = prompt.toLowerCase();
  if (/code|function|script/i.test(l)) { cs.push("เขียน code ที่รันได้จริง ไม่ใช่ pseudocode"); cs.push("ใส่ comment ภาษาไทยอธิบาย key logic"); }
  if (/analyze|วิเคราะห์/i.test(l)) { cs.push(CONSTRAINTS.beSpecific); cs.push("列出 fact ก่อน แล้วค่อยสรุป"); }
  if (/summarize|สรุป/i.test(l)) cs.push(CONSTRAINTS.limitLength(300));
  return cs;
}

export function optimizePrompt(rawPrompt: string, options: { role?: keyof typeof SYSTEM_HINTS; maxWords?: number } = {}): string {
  const parts: string[] = [];
  const role = options.role || inferRole(rawPrompt);
  parts.push(SYSTEM_HINTS[role] || SYSTEM_HINTS.analyzer);
  parts.push("");
  const constraints = inferConstraints(rawPrompt);
  if (constraints.length > 0) { parts.push("## กติกา"); constraints.forEach(c => parts.push(`- ${c}`)); parts.push(""); }
  parts.push("## Task"); parts.push(rawPrompt); parts.push("");
  if (options.maxWords) parts.push(`ตอบไม่เกิน ${options.maxWords} คำ`);
  return parts.join("\n");
}

export default { SYSTEM_HINTS, CONSTRAINTS, optimizePrompt };
