# 📋 Priority 1: Foundation (5 items)

## Scripts ที่ใช้ได้แล้ว

### 1. Self-Eval Suite (`self-eval/`)
วัดผล improvement ทุกครั้ง — before/after comparison
```bash
bash self-eval.sh "task" "before" "after" "result"
bash self-eval.sh --run-all        # run all test cases
bash self-eval.sh --report         # generate report
bash self-eval.sh --add-test "name" "input" "expected" "category"
```

### 2. Improvement Log (`improvement-log/`)
เก็บ history ว่าแก้อะไร + ผลเป็นไง + pattern ไหน work
```bash
bash log.sh "description" "category" "status"
bash log.sh --list [category]      # list entries
bash log.sh --stats                # show stats
```

### 3. Structured Memory (`structured-memory/`)
JSON index สำหรับ memory files — search ได้เร็วกว่า grep
```bash
bash memory-index.sh --build       # rebuild index from ψ/memory/
bash memory-index.sh --search "q"  # search index
bash memory-index.sh --stats       # show stats
```

### 4. Token/Cost Guard (`cost-guard/`)
ตั้ง limit + alert กัน burn token ไม่รู้ตัว
```bash
bash cost-guard.sh --log 1500 3200 "gemini"   # log tokens
bash cost-guard.sh --check                     # check limits
bash cost-guard.sh --report daily              # generate report
```
**Config:** 500K tokens/day, $10/day limit, warning at 80%, critical at 95%

### 5. Session Summarizer (`session-summarizer/`)
สรุปอัตโนมัติก่อน context เต็ม — auto-summarize at 80%
```bash
bash session-summarizer.sh --capture "session1" "message" "user"
bash session-summarizer.sh --summarize "session1"
bash session-summarizer.sh --context-check
bash session-summarizer.sh --handoff "session1"
```

---
_Generated: 2026-04-22_
