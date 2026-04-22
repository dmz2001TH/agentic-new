# 📋 HANDOFF — GOD Agent

## สถานะ
- **Branch:** god-upgrades-v4
- **Items:** 45/45 เสร็จแล้ว
- **Pushed:** 2026-04-22

## สิ่งที่ต้องทำต่อ

### 1. Merge branch
```
git checkout master
git merge god-upgrades-v4
```

### 2. ทดสอบทุกระบบ
```bash
# ทดสอบ foundation
bash god-upgrades/01-foundation/self-eval/self-eval.sh --run-all
bash god-upgrades/01-foundation/improvement-log/log.sh --stats
bash god-upgrades/01-foundation/cost-guard/cost-guard.sh --check
bash god-upgrades/01-foundation/structured-memory/memory-index.sh --build
bash god-upgrades/01-foundation/session-summarizer/session-summarizer.sh --context-check

# ทดสอบ agent arch
bash god-upgrades/02-agent-arch/critic/critic.sh --review-dir god-upgrades/
bash god-upgrades/02-agent-arch/planner/planner.sh --list
bash god-upgrades/02-agent-arch/learner/learner.sh --knowledge
bash god-upgrades/02-agent-arch/agent-comm/agent-comm.sh --status
bash god-upgrades/02-agent-arch/agent-monitor/agent-monitor.sh --dashboard

# ทดสอบ knowledge
bash god-upgrades/03-knowledge/vector-store/vector-store.sh --index .
bash god-upgrades/03-knowledge/repo-indexer/repo-indexer.sh --index .

# ทดสอบ tool layer
bash god-upgrades/04-tool-layer/tool-registry/tool-registry.sh --list
bash god-upgrades/04-tool-layer/file-guard/file-guard.sh --list-protected

# ทดสอบ self-improvement
bash god-upgrades/05-self-improvement/introspection/introspection.sh --generate
bash god-upgrades/05-self-improvement/capability-tracker/capability-tracker.sh --report
bash god-upgrades/05-self-improvement/pattern-engine/pattern-engine.sh --scan

# ทดสอบ observation
bash god-upgrades/06-observation/calendar-reminder/calendar-reminder.sh --upcoming

# ทดสอบ quality & safety
bash god-upgrades/07-quality-safety/code-review-gate/code-review-gate.sh --check .
bash god-upgrades/07-quality-safety/injection-guard/injection-guard.sh --scan "test text"

# ทดสอบ advanced
bash god-upgrades/08-advanced/dashboard/dashboard.sh
```

### 3. เชื่อมกับ GEMINI.md
เพิ่มใน GEMINI.md:
```
## GOD Upgrades (v4.0)
- ระบบ 45 upgrades อยู่ใน god-upgrades/
- เรียกใช้ก่อนทำงานทุกครั้ง:
  - bash god-upgrades/01-foundation/self-eval/self-eval.sh --run-all
  - bash god-upgrades/08-advanced/dashboard/dashboard.sh
```

### 4. ตั้ง daily workflow
```bash
# เช้า: dashboard + planner
bash god-upgrades/08-advanced/dashboard/dashboard.sh
bash god-upgrades/02-agent-arch/planner/planner.sh --list

# ก่อน commit: critic + code-review-gate
bash god-upgrades/02-agent-arch/critic/critic.sh --diff
bash god-upgrades/07-quality-safety/code-review-gate/code-review-gate.sh --check .

# เย็น: learner + introspection + improvement-log
bash god-upgrades/02-agent-arch/learner/learner.sh --weekly-review
bash god-upgrades/05-self-improvement/introspection/introspection.sh --generate
bash god-upgrades/01-foundation/improvement-log/log.sh --stats
```

### 5. Google Drive symlink (แก้ C: เต็ม)
```bash
# ย้ายไป G: + symlink
mv /mnt/c/Agentic /mnt/g/My\ Drive/Agentic
mklink /D C:\Agentic "G:\My Drive\Agentic"
```

---
_พีช: ทำต่อได้เลย เริ่มจาก merge + test_
