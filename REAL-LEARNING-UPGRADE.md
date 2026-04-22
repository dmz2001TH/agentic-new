# 🧠 GOD System — Real Learning & Verification Upgrade

**Updated:** 2026-04-23 01:55 GMT+8
**Author:** OpenClaw Agent (assisted by dmz2001TH / พีช)

---

## 📋 สิ่งที่เปลี่ยนแปลง (Changelog)

### 🎭 → ✅ Commands ที่แก้ไข (9 ตัว)

| # | Command | ก่อน (Theater) | หลัง (Real) |
|---|---------|---------------|-------------|
| 1 | `/learn` | summarize ลอยๆ ไม่มี verification | timed session + evidence extraction + quiz + verification scoring |
| 2 | `/rrr` | สร้าง retrospective สั้นๆ | สร้างจาก data จริง + verify ≥ 200 chars, ≥ 3 sections |
| 3 | `/recap` | เดาจากจินตนาการ | cat ไฟล์จริง (handoff, retro, inbox, notes) + verify |
| 4 | `/fyi` | บอก "จำแล้ว" ลอยๆ | echo ลงไฟล์จริง + tail verify ว่าบันทึกสำเร็จ |
| 5 | `/feel` | append ลอยๆ ไม่มี behavior change | echo ลง notes.md + user-preferences.md + verify |
| 6 | `/forward` | สร้าง handoff สั้นๆ | รวบรวมจาก inbox/learnings/decisions จริง + verify ≥ 300 chars |
| 7 | `/execute` | เปลี่ยน status ลอยๆ | sed เปลี่ยนไฟล์จริง + verify ว่าเปลี่ยนแล้ว |
| 8 | `/review` | checklist ลอยๆ | ตรวจไฟล์จริง + นับ subtasks + verify output จริง |
| 9 | `/full-install` | สร้างแล้วรายงานสวย | สร้างจริง + verify ทุกขั้นตอน (find, ls, wc) |

### 🔧 Scripts ที่แก้ไข/สร้างใหม่ (7 ไฟล์)

| # | File | สถานะ | คำอธิบาย |
|---|------|--------|---------|
| 1 | `scripts/oracle-tools.sh` | แก้ไข | Cross-platform (Linux/macOS/WSL/Git Bash), verify ทุก function |
| 2 | `brain-bridge.sh` | แก้ไข | Cross-platform, auto-detect OS, ไม่ hardcode Windows paths |
| 3 | `scripts/learn/timed-learn.sh` | สร้างใหม่ | Timed learning session + real source fetching + progress bar |
| 4 | `scripts/learn/real-learn.sh` | สร้างใหม่ | Full learning flow with evidence tracking |
| 5 | `scripts/learn/learn-verify.sh` | สร้างใหม่ | Verification scoring system (100 points, grade A-F) |
| 6 | `scripts/learn/learn-history.sh` | สร้างใหม่ | Learning session history & trends |
| 7 | `.gemini/commands/10-core/learn.toml` | แก้ไข | Replaced with real-learn version |

---

## 🏗️ Architecture Overview

### GOD System Components

```
agentic-new/
├── .gemini/
│   ├── agents/           ← Agent personas (GOD, Builder, Researcher, Nexus)
│   ├── commands/         ← 37+ Gemini CLI slash commands (10 categories)
│   │   ├── 00-init/      ← Installation & setup
│   │   ├── 10-core/      ← recap, rrr, learn, fyi, feel, forward, trace, standup
│   │   ├── 20-memory/    ← recall, remember, forget, export, import, status
│   │   ├── 30-workflow/  ← plan, execute, checkpoint, handoff, review, rollback
│   │   ├── 40-analysis/  ← analyze, brainstorm, compare, explain, summarize
│   │   ├── 50-code/      ← code-review, debug, doc-gen, refactor, test-gen
│   │   ├── 60-team/      ← agent-create, agent-list, agent-task, broadcast, fleet-status
│   │   ├── 70-vault/     ← vault-scan, vault-sync, vault-report, vault-cleanup
│   │   ├── 80-pulse/     ← pulse-board, pulse-github, pulse-task, pulse-timeline
│   │   └── 90-evolution/ ← evolve, family-connect, philosophy, self-assess
│   └── settings.json     ← Gemini CLI config
├── scripts/
│   ├── oracle-tools.sh   ← GOD's hands: API calls, file ops, goals, memory (cross-platform)
│   ├── learn/
│   │   ├── timed-learn.sh    ← Start timed learning session
│   │   ├── real-learn.sh     ← Full learning flow
│   │   ├── learn-verify.sh   ← Verification scoring
│   │   └── learn-history.sh  ← Session history
│   ├── backup-db.sh
│   ├── ensure-agents.sh
│   ├── setup.sh
│   └── validate-system.sh
├── brain-bridge.sh       ← Memory sync (Google Drive ↔ Local ↔ GitHub)
├── GEMINI.md             ← GOD system prompt (v4.0)
├── arra-oracle-skills-cli/  ← 60 skills for AI agents
├── arra-oracle-v3/          ← Oracle server + API
├── maw-js/                  ← Multi-agent workflow engine
├── multi-agent-workflow-kit/ ← Git worktree orchestrator
├── pulse-cli/               ← Pulse CLI + SDK
├── oracle-vault-report/     ← Vault report generator
├── oracle-maw-guide/        ← Documentation
└── opensource-nat-brain-oracle/ ← Brain knowledge base
```

### Agent Hierarchy

```
GOD (ผู้สร้าง)
 ├── Builder    — Coding specialist (tmux: mawjs-builder)
 ├── Researcher — Knowledge specialist (tmux: mawjs-researcher)
 ├── Nexus      — Memory/analysis support (tmux: mawjs-nexus)
 └── [spawn ได้ตามต้องการ]
```

### Memory System (ψ/)

```
ψ/
├── memory/
│   ├── identity.md         ← ตัวตนรวม
│   ├── patterns.md         ← Patterns ที่ค้นพบ
│   ├── learnings.md        ← สิ่งที่เรียนรู้
│   ├── notes.md            ← บันทึกด่วน
│   ├── decisions.md        ← การตัดสินใจสำคัญ
│   ├── people.md           ← คนที่เกี่ยวข้อง
│   ├── values.md           ← ค่านิยม
│   ├── handoff.md          ← สิ่งค้างจาก session ที่แล้ว
│   ├── goals.md            ← เป้าหมาย
│   ├── user-preferences.md ← สไตล์ผู้ใช้
│   ├── retrospective/      ← สรุปวัน
│   ├── learn-sessions/     ← Learning sessions with verification
│   │   └── YYYY-MM-DD_HH-MM_topic/
│   │       ├── manifest.json
│   │       ├── sources/        ← Raw fetched content
│   │       ├── evidence/log.jsonl  ← Extracted evidence
│   │       ├── quiz/           ← Knowledge tests
│   │       ├── report.md       ← Honest report
│   │       └── verification.json ← Score & grade
│   ├── reflections/        ← การทบทวน
│   ├── checkpoints/        ← Save points
│   ├── archive/            ← Archived (ไม่ลบ)
│   ├── locks/              ← Memory lock files
│   └── logs/               ← System logs
├── inbox/                  ← Tasks
├── agents/
│   └── god/memory/         ← GOD's private brain
├── vault/                  ← Exports & backups
├── writing/                ← Drafts
└── lab/                    ← Experiments
```

### Runtime Architecture

```
┌─────────────────────────────────────────────┐
│  Gemini CLI (tmux sessions)                 │
│  ├── god        ← Main GOD session         │
│  ├── builder    ← Coding agent             │
│  ├── researcher ← Research agent           │
│  └── nexus      ← Memory agent             │
├─────────────────────────────────────────────┤
│  Oracle API (port 47778)                    │
│  ├── /api/search   ← Knowledge search      │
│  ├── /api/learn    ← Store patterns        │
│  ├── /api/stats    ← Database stats        │
│  └── /api/health   ← Health check          │
├─────────────────────────────────────────────┤
│  Maw API (port 3456)                        │
│  ├── /api/tools/*  ← Tool endpoints        │
│  ├── /api/chat/*   ← Agent communication   │
│  ├── /api/git/*    ← Git operations        │
│  └── /api/health   ← Health check          │
├─────────────────────────────────────────────┤
│  Memory Layer                               │
│  ├── Google Drive (5TB) ← Primary brain    │
│  ├── Local SSD (~90GB)  ← Cache            │
│  └── GitHub             ← Version backup   │
└─────────────────────────────────────────────┘
```

---

## 🔄 Flow การทำงาน (Workflows)

### 1. Learning Flow (เรียนรู้)

```
User: /learn <topic> <urls>
  │
  ▼
timed-learn.sh → Fetch sources (จริงๆ, จับเวลา)
  │
  ▼
Agent reads sources/ → Extracts evidence → evidence/log.jsonl
  │
  ▼
Agent creates quiz → quiz/quiz.md (ตอบจาก evidence)
  │
  ▼
Agent writes report → report.md (honest assessment)
  │
  ▼
learn-verify.sh → Score (100 pts) → Grade (A-F)
  │
  ├── Grade ≥ B → ✅ Real learning session
  └── Grade < B → ⚠️ Superficial — redo
```

### 2. Daily Workflow (ทำงานรายวัน)

```
Morning:
  /recap → Read handoff.md + retro + inbox → สรุปสถานะจริง
  /standup → Read inbox → Tasks ที่ต้องทำ

During work:
  /execute <task> → sed เปลี่ยน status จริง → verify
  /fyi <info> → echo ลง notes.md → verify
  /feel <state> → echo ลง notes.md + user-preferences.md → verify

Before handoff:
  /forward → รวบรวมจาก inbox/learnings → handoff.md → verify ≥ 300 chars

End of day:
  /rrr → สร้าง retrospective จาก data จริง → verify ≥ 200 chars
```

### 3. Agent Communication Flow

```
GOD → send_to_agent builder "TASK: ..."
  │
  ▼
Builder (tmux: mawjs-builder) → receives task
  │
  ▼
Builder → reads code → makes changes → tests
  │
  ▼
Builder → curl chat/send → reports back to GOD
  │
  ▼
GOD → verify output → update goal status
```

### 4. Memory Sync Flow

```
brain-bridge.sh
  │
  ├── Google Drive → Local (pull สมองลง cache)
  ├── Local → GitHub (backup to git)
  └── Local → Google Drive (push cache กลับสมอง)

oracle-tools.sh
  ├── oracle_learn → POST /api/learn (or fallback to file)
  ├── oracle_search → GET /api/search
  ├── memory_write → echo >> file + lock + verify
  └── memory_read → cat file
```

---

## ⚡ Quick Reference สำหรับ Agent ตัวอื่น

### เริ่มต้นทำงานต่อ

```bash
# 1. Clone repo
git clone https://github.com/dmz2001TH/agentic-new.git
cd agentic-new

# 2. Source tools
source scripts/oracle-tools.sh

# 3. ดูสถานะ
bash scripts/oracle-tools.sh fleet

# 4. ดู goals ค้าง
bash scripts/oracle-tools.sh goals

# 5. เริ่ม learning session
bash scripts/learn/timed-learn.sh "topic" 10 https://url1 https://url2
```

### Commands ที่ต้อง verify เสมอ

| Command | Verification |
|---------|-------------|
| `/learn` | `learn-verify.sh` → grade ≥ B |
| `/rrr` | file ≥ 200 chars, ≥ 3 sections |
| `/recap` | must cat real files, no guessing |
| `/fyi` | `tail -1` must show saved content |
| `/feel` | `tail -1 notes.md` + `tail -3 user-preferences.md` |
| `/forward` | file ≥ 300 chars, ≥ 4 sections |
| `/execute` | `grep` status change in task file |
| `/review` | count subtasks, check file existence |

### สิ่งที่ห้ามทำ (Red Lines)

1. **ห้าม summarize ลอยๆ** — ต้องมี evidence/source reference
2. **ห้ามบอก "เสร็จ"** — ต้อง verify ก่อน
3. **ห้าม fake timeline** — ต้องจับเวลาจริง
4. **ห้ามอ้างว่า "อ่านแล้ว"** — ต้อง cat ไฟล์จริง
5. **ห้ามโกหก** — ไม่รู้ = บอกไม่รู้

---

## 🧪 ตัวอย่าง Learning Session ที่ผ่าน verification

```
Session: 2026-04-23_01-45_Bun-Runtime
Topic: Bun Runtime
Duration: 3 minutes (timed)
Sources: 2 URLs (bun.sh/docs, GitHub README)
Chars fetched: 311,431
Evidence: 6 items (3 facts, 1 code, 1 quote, 1 insight)
Quiz: 5/5 questions answered
Score: 100/100 — Grade: A
Verdict: REAL learning session ✅
```

---

## 📊 Status ปัจจุบัน

### ✅ พร้อมใช้งาน
- 48 Gemini CLI commands (9 แก้ไขแล้ว, 39 ใช้ได้เดิม)
- oracle-tools.sh (cross-platform)
- brain-bridge.sh (cross-platform)
- Learning system (timed-learn + verify)
- Memory system (ψ/ structure)

### 🟡 ต้อง Setup
- Oracle API (port 47778) — ต้องรัน arra-oracle-v3
- Maw API (port 3456) — ต้องรัน maw-js
- Google Drive sync — ต้องตั้ง GDRIVE_PSI env var

### 🔴 ยังไม่ทำ
- Multi-agent tmux sessions (ต้อง setup agents แต่ละตัว)
- Pulse CLI integration
- Vault report automation

---

## 📝 สำหรับ Agent ที่จะทำต่อ

### Priority 1: Setup Oracle API
```bash
cd arra-oracle-v3
bun install
bun run setup.sh
bun run src/index.ts  # → port 47778
```

### Priority 2: Setup Maw API
```bash
cd maw-js
bun install
bun run src/cli.ts start  # → port 3456
```

### Priority 3: Test Commands
```bash
# Test learn system
bash scripts/learn/timed-learn.sh "Test Topic" 5 https://example.com

# Test oracle tools
source scripts/oracle-tools.sh
oracle_health
fleet_status

# Test verification
bash scripts/learn/learn-verify.sh <session_id>
```

### Priority 4: Install arra-oracle-skills
```bash
cd arra-oracle-skills-cli
bun install
bun run src/cli.ts install -g -y --agent openclaw
```

---

*Document generated by OpenClaw Agent — 2026-04-23 01:55 GMT+8*
