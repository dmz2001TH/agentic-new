# Windsurf Workflow Optimization - ทำให้ Flow การทำงานเก่งขึ้นฉลาดขึ้น

อัพเดทล่าสุด: 17 เมษายน 2026

---

## 📋 ภาพรวม

Windsurf เป็น AI-powered IDE ที่มี Cascade เป็น AI agent หลัก การปรับแต่งและใช้งานอย่างถูกวิธีจะช่วยให้ flow การทำงานเก่งขึ้น ฉลาดขึ้น และลดการทำงานซ้ำ

---

## 🚀 6 เทคนิคหลักที่ต้องรู้ (จาก Community Tips)

### 1. เก็บ Thread ไว้โฟกัส - งานเดียวต่อ Session
- **ปัญหา**: Thread ยาวๆ ที่ผสมหลายหัวข้อทำให้ AI สับสนและ context drift
- **วิธีแก้**: เปิด thread ใหม่สำหรับทุก task ที่แตกต่างกัน
- **ตัวอย่าง**:
  - Thread 1: Debug code snippet
  - Thread 2: Integrate new library
  - Thread 3: UI improvements
- **ผล**: ลด cascade calls, ลด context drift, ประหยัด tokens

### 2. ค้นหา Docs แบบ Inline ด้วย @docs
- **คำสั่ง**: `/docs:<source>` เพื่อดึง documentation snippets
- **ข้อดี**:
  - ไม่ต้อง switch tabs
  - Ground model ใน reference materials ลด hallucinations
  - ประหยัด tokens เพราะดึงเฉพาะ snippet ที่ต้องการ
- **เงื่อนไข**: Docs ต้องมี `/llms.txt` index file (Mintlify ให้มาอัตโนมัติ)

### 3. ให้ AI จัดการ Build Loop
- **Windsurf**: Terminal integration + Auto-executed commands
- **Cursor**: YOLO/Auto-Run mode
- **ข้อดี**: AI รัน npm install, tsc และ retry จนผ่านอัตโนมัติ
- **ความปลอดภัย**: 
  - Windsurf มี Auto/Turbo modes
  - Auto: auto-execute safe commands
  - Turbo: execute ทุกอย่างยกเว้น deny list
- **แนะนำ**: เปิด auto-execution เฉพาะ trusted codebases

### 4. Reference Files เต็ม ไม่ใช่ Chat Snippets
- **คำสั่ง**: `/Reference Open Editors` (Cursor)
- **ข้อดี**:
  - AI เห็นภาพรวม codebase
  - เข้าใจ structure และ flow ของ functions/variables
  - ลด token usage
- **Best Practices**:
  - เปิดเฉพาะ relevant files
  - ปิด tabs ที่ไม่จำเป็น
  - เก็บ files ให้ modular และ clean

### 5. Prompt เหมือน Product Spec
- **โครงสร้าง Prompt**:
  ```
  Goal: [สิ่งที่จะสร้าง]
  Existing: [ไฟล์/ฟังก์ชันที่มีอยู่]
  Constraints: [performance, library, style, browser compatibility]
  Edge Cases: [empty data, errors, null values]
  Preferences: [coding style, file structure]
  ```
- **ตัวอย่าง**:
  ```
  Goal: เพิ่ม loading และ error states ให้ BookListView
  Existing: ใน views.py มีการ fetch books แต่ render เฉพาะตอนมี data
  Constraints: ใช้เฉพาะ Django built-in, ไม่ใช้ packages เพิ่ม
  Edge Cases: Empty lists แสดง "No books found", DB errors แสดง "Failed to load books"
  Preferences: ใช้ Bootstrap classes, format error messages สม่ำเสมอ
  ```
- **ผล**: ลด back-and-forth clarifications, ได้ solution ถูกต้องในครั้งเดียว

### 6. Reboot Messy Sessions ด้วย Standup Format
- **เมื่อไร**: Thread drift, mix errors/commands, AI ติดอยู่กับ old context
- **โครงสร้าง**:
  ```
  Goal: สิ่งที่ต้องการทำ
  Attempts: สิ่งที่ลองไปแล้ว
  Roadblocks: อะไรที่ fail หรือไม่ work ตามที่คาด
  ```
- **ตัวอย่าง**:
  ```
  Goal: Debug failed database migration หลัง update Django version
  Attempts: re-ran migrations
  Roadblocks: Still getting "django.db.utils.OperationalError: no such table: reviews_review"
  ```
- **ผล**: Clear stale context, ลด token waste, sharpen AI's next answer

---

## 🎯 Cascade Skills - การใช้งานอย่างมืออาชีพ

### Step-by-Step การใช้ Cascade Skills

#### Step 1: เปิด Cascade และเลือก Skill
- เปิด project ใน Windsurf
- เปิด Cascade panel
- เลือก Skill ที่ match กับ task (tests, docs, refactor, scaffold, migration)

#### Step 2: ตั้ง Scope ให้ Cascade edit ไฟล์ที่ถูก
- Limit scope ไปที่ folder หรือ module
- List key files ถ้ารู้อยู่แล้ว
- ระบุสิ่งที่ Cascade **ต้องไม่** touch (เช่น "do not change public API names")

#### Step 3: ให้ Inputs ในรูปแบบที่ชัดเจน
ใช้ template:
- **Goal**: ประโยคเดียว
- **Context**: framework, language, constraints
- **Inputs**: endpoints, schemas, file paths, examples
- **Acceptance criteria**: "done" คืออะไร
- **Validation**: commands ที่จะรัน (tests, lint, build)

#### Step 4: ขอ Plan ก่อน
- บอก Cascade ให้ propose steps ก่อน edit
- ขอให้ list files ที่จะเปลี่ยน
- ขอให้ note risks และ open questions

#### Step 5: Apply changes เป็น small batches
- Approve edits เป็น chunks
- Run tests หลังแต่ละ chunk
- Stop และ correct direction ถ้า outputs drift

#### Step 6: Review diffs เหมือน review PR
- Check hidden behavior changes
- Check naming, error handling, edge cases
- Check ว่า Skill ทำตาม constraints

---

## 📝 Rules สำหรับ Prompt ที่มีประสิทธิภาพ

### Use "Inputs + Constraints + Checks" ในทุก Prompt
- **Inputs**: exact endpoints, schemas, file paths, examples
- **Constraints**: style, libraries, patterns, "do not change"
- **Checks**: tests, lint, typecheck, build, manual steps

### Prefer Deterministic Instructions
- ❌ "Improve test coverage"
- ✅ "Add unit tests for these functions"
- ❌ "Use common tools"
- ✅ "Use Jest and Testing Library"
- ❌ "Try not to break anything"
- ✅ "Keep function signatures unchanged"

### Use Two-Pass Workflow
- **Pass 1**: plan, file list, questions
- **Pass 2**: code edits, then tests

### Ask for Tradeoffs เมื่อมี options หลายตัว
- "Give two options. Pick one and explain why."
- ลด random choices ที่ไม่ match กับ team style

---

## 🛠️ Best Practices สำหรับการตั้งค่า Workspace

### 1. เลือก Hardware ที่เหมาะสม
- **Mac**: OS X Yosemite
- **Linux**: glibc >= 2.28, glibcxx >= 3.4.25 (Ubuntu >= 20.04)
- **Windows**: Windows 10 (64-bit)

### 2. Optimize Interface
- **Split View**: ดู multiple files พร้อมกัน
- **Customize Shortcuts**: assign shortcuts สำหรับ commands ที่ใช้บ่อย
- **Color Theme**: เลือก theme ที่ไม่ทำให้เมื่อยตา

### 3. Files & Workspace Management
- **Workspace Organization**: จัดเป็น logical structure, ใช้ folder names ชัดเจน
- **Version Control**: Integrate Git, ใช้ branching strategy ที่ดี

### 4. Embrace Cascade
- **Contextual Prompts**: ใช้ Cascade generate foundational code snippets สำหรับ features/libraries ใหม่
- **Real-Time Collaboration**: Cascade ช่วย code reviews และ feedback สำหรับทีม

### 5. Memory & Rules
- **Create Memories**: Save code snippets ที่ใช้บ่อยเป็น Memories
- **Set Up Rules**: ใช้ Windsurf Rules สอน IDE เกี่ยวกับ project structure

### 6. Smarter Task Management
- **Integrate Third-party Apps**: เชื่อมต่อกับ apps ที่ชอบ
- **Use Takeaways**: จด notes ว่าทำอะไรไปในแต่ละ session

### 7. Regular Maintenance
- **Performance Checks**: Clear cache และ old code generated data ทุกๆ 2-3 เดือน
- **Clear Cache Data**: Speed up workflow

---

## 🧠 Memories & Rules - ระบบจำและกฎเกณฑ์

### ความแตกต่างระหว่าง Features ต่างๆ

| Feature | ทำอะไร | Activation Mode | เมื่อไรควรใช้ |
|---------|---------|----------------|----------------|
| **Rules** | บอก Cascade ว่าควร behave ยังไง (เช่น "use bun, not npm") | always_on, glob, model_decision, manual | Coding conventions, style guides, project constraints |
| **AGENTS.md** | Location-scoped rules แบบ zero config | Automatic (root = always-on, subdirectory = glob) | Directory-specific conventions โดยไม่ต้อง frontmatter |
| **Workflows** | Prompt templates สำหรับ repeatable multi-step tasks | Manual only via `/[workflow-name]` | Deployments, PR reviews, release checklists |
| **Skills** | Multi-step procedures พร้อม supporting files (scripts, templates) | Dynamic by model หรือ `@mention` | Complex tasks ที่ Cascade ต้องการ reference files |
| **Memories** | Context ที่ Cascade auto-generate ระหว่าง conversation | Automatic retrieval when relevant | Let Cascade remember one-off facts |

### Recommendation
สำหรับ knowledge ที่ต้องการให้ Cascade reuse อย่างน่าเชื่อถือ:
- ✅ เขียนเป็น Rule ใน `.windsurf/rules/`
- ✅ เพิ่มใน `AGENTS.md` ใน repo
- ❌ อย่าพึ่ง auto-generated Memories เพราะไม่ version-controlled, ไม่ shareable กับทีม

### Rules Scope

| Scope | Location | Notes |
|-------|----------|-------|
| **Global** | `~/.codeium/windsurf/memories/global_rules.md` | Single file, apply across all workspaces, always on, limited to 6,000 chars |
| **Workspace** | `.windsurf/rules/*.md` | One file per rule, each with activation mode, limited to 12,000 chars per file |
| **AGENTS.md** | Any directory in workspace | Root-level = always-on, subdirectory = auto-glob for that directory |
| **System (Enterprise)** | OS-specific (e.g., `/etc/windsurf/rules/`) | Deployed by IT, read-only for end users |

### Writing Effective Rules
- **Be Specific, Not Vague**: ระบุชัดเจน ไม่คลุมเครือ
- **Use Positive Instructions**: บอกว่าควรทำอะไร ไม่ใช่ไม่ควรทำอะไร
- **Organize with Headings**: ใช้ headings จัดระเบียบ
- **Include Examples**: ใส่ตัวอย่างประกอบ
- **Keep Rules Focused**: เก็บ rule เดียวต่อไฟล์

---

## 🔧 Cascade Skills Use Cases (10 ตัวอย่าง)

### 1) Deploy to Production (safe, repeatable release)
```
@deploy-to-production Deploy current branch to prod, run checks, and document rollback.
```
**Supporting files**: deployment-checklist.md, rollback-procedure.md, env-prod.example, release-commands.md

### 2) Deploy to Staging (preview, QA, stakeholder review)
```
@deploy-to-staging Deploy PR to staging and generate QA checklist.
```
**Supporting files**: staging-deploy-steps.md, qa-checklist.md, seed-data.sql, staging-env.example

### 3) Hotfix + Rollback (minimize blast radius)
- ใช้สำหรับ urgent fixes
- มี rollback plan ชัดเจน

### 4) Code Review (style + security + performance)
- Review code ตาม standards
- Check security vulnerabilities
- Analyze performance implications

### 5) Add Feature with Tests (TDD-ish workflow)
- Write tests ก่อน
- Implement feature
- Verify tests pass

### 6) Refactor Safely (no behavior changes, add guardrails)
- Refactor โดยไม่เปลี่ยน behavior
- Add tests เพื่อ guardrails

### 7) Run Tests Like CI (local parity, faster debugging)
- Run tests แบบ CI
- Debug ได้เร็วขึ้น

### 8) Database Migration (safe schema changes + rollback)
- Safe schema changes
- Rollback plan

### 9) Incident Triage (debug fast, communicate clearly)
- Debug incidents
- Communicate clearly

### 10) Release Notes (from commits and PRs, consistent format)
- Generate release notes
- Consistent format

---

## ⚠️ Common Mistakes และวิธีแก้

### Mistake 1: Asking for "improve code quality" with no target
- **แก้**: ระบุชัดเจนว่าอยาก improve อะไร (performance, readability, maintainability)

### Mistake 2: Letting Cascade edit too many files at once
- **แก้**: Limit scope, approve ใน small batches

### Mistake 3: Skipping the plan step
- **แก้**: Always ask for plan first, review before execute

### Mistake 4: No acceptance criteria
- **แก้**: ระบุชัดเจนว่า "done" คืออะไร

### Mistake 5: No regression test for a bug fix
- **แก้**: Add tests ก่อน fix bug

---

## 📚 Prompt Templates ที่ใช้ซ้ำได้

### Template A: Plan-first template
```
Goal: [brief description]
Context: [framework, language, constraints]
Inputs: [endpoints, schemas, file paths]
Acceptance criteria: [what "done" means]
Validation: [tests, lint, build commands]

First, create a plan. List files you'll change. Note risks and questions.
```

### Template B: Edit-only template (after approving plan)
```
Apply the plan we discussed. Make changes in small batches.
After each batch, run: [validation commands]
Stop if outputs drift from the plan.
```

### Template C: "Do not touch" rules
```
Edit these files: [file list]
DO NOT CHANGE: [public APIs, critical paths, etc.]
Constraints: [style, libraries, patterns]
Validation: [tests, lint, build]
```

---

## 🎨 Best Practices สรุป

### Organizational Best Practices
- **Organize Rules by Concern**: Group rules ตาม category
- **Use Descriptive Filenames**: ใช้ filenames ที่บอกความหมาย
- **Version Control Your Rules**: Commit rules ไว้ใน git
- **Write Clear Descriptions**: เขียน descriptions ชัดเจนใน frontmatter
- **Review and Update Regularly**: Review rules อย่างสม่ำเสมอ
- **Balance Global and Workspace Rules**: ใช้ global สำหรับ common standards, workspace สำหรับ project-specific
- **Explore Community Rules**: ดู rules จาก community

### Workflow Best Practices
- **Keep Sessions Focused**: งานเดียวต่อ session
- **Use Inline Docs**: `/docs` สำหรับ quick reference
- **Let AI Handle Build Loop**: Auto-execute safe commands
- **Reference Full Files**: ไม่ copy-paste snippets
- **Prompt Like a Spec**: Use structured prompts
- **Reboot Messy Sessions**: Use standup format
- **Plan Before Execute**: Always ask for plan first
- **Review Like a PR**: Check diffs carefully

---

## 🔗 Resources ที่เป็นประโยชน์

- [Windsurf Best Practices GitHub](https://github.com/kamusis/windsurf_best_practice)
- [Windsurf Cascade Documentation](https://docs.windsurf.com/windsurf/cascade)
- [Windsurf Rules Guide](https://design.dev/guides/windsurf-rules/)
- [How to Use Windsurf Cascade Skills](https://copyrocket.ai/how-to-use-windsurf-cascade-skills)
- [6 Tips for Cursor and Windsurf](https://www.mintlify.com/resources/6-tips-every-developer-should-know-when-using-cursor-and-windsurf)
- [Setting Up Workspace with Windsurf](https://www.arsturn.com/blog/setting-up-your-workspace-with-windsurf-best-practices)

---

## 📊 สรุป Action Items

### ทันที (วันนี้)
1. ✅ เริ่มใช้ 6 เทคนิคหลัก (keep threads focused, query docs inline, etc.)
2. ✅ ตั้งค่า workspace ตาม best practices
3. ✅ สร้าง global rules พื้นฐาน

### สัปดาห์หน้า
1. ✅ สร้าง workspace rules สำหรับ project
2. ✅ ทดลองใช้ Cascade Skills สำหรับ tasks ที่ซ้ำๆ
3. ✅ ตั้งค่า AGENTS.md ใน repo

### เดือนหน้า
1. ✅ สร้าง custom Skills สำหรับ workflows เฉพาะทีม
2. ✅ ปรับปรุง rules ตาม feedback
3. ✅ Integrate third-party apps สำหรับ task management

---

*สรุปโดย Cascade - 17 เมษายน 2026*
