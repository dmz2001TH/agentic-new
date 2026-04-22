# 📋 Priority 2: Agent Architecture (6 items)

## Scripts ที่ใช้ได้แล้ว

### 6. Critic Agent (`critic/`)
Review code ของ builder ก่อน merge — จับ bug + suggest improvement
```bash
bash critic.sh --review "file.sh"       # review single file
bash critic.sh --review-dir "dir/"      # review directory
bash critic.sh --diff                   # review git changes
bash critic.sh --approve "review_id"    # approve review
bash critic.sh --reject "review_id" "reason"
```
**Rules:** no-hardcoded-secrets, no-rm-rf, no-curl-pipe-bash, file-size, error-handling

### 7. Researcher Agent (`researcher/`)
ค้น GitHub, docs, web → หา solution ให้ builder
```bash
bash researcher.sh --github "query"     # search GitHub repos
bash researcher.sh --docs "query" [url] # search documentation
bash researcher.sh --error "error_msg"  # research error
bash researcher.sh --research "topic"   # general research
bash researcher.sh --history            # research history
```

### 8. Planner Agent (`planner/`)
แตก task + prioritize + dependency management
```bash
bash planner.sh --plan "goal" "complexity"  # create plan
bash planner.sh --status "plan_id"          # check progress
bash planner.sh --next "plan_id"            # show next tasks
bash planner.sh --complete "plan_id" "num"  # mark done
bash planner.sh --auto "goal" "template"    # use template (debug|feature|refactor|learn)
```

### 9. Learner Agent (`learner/`)
อ่าน error + success pattern → knowledge base
```bash
bash learner.sh --learn "event" "outcome" "context"
bash learner.sh --pattern "keyword"     # find patterns
bash learner.sh --promote "description" # promote to rule
bash learner.sh --knowledge             # show knowledge base
bash learner.sh --weekly-review         # weekly analysis
```

### 10. Agent Communication Protocol (`agent-comm/`)
JSON message queue สำหรับ agent-to-agent communication
```bash
bash agent-comm.sh --send "from" "to" "type" "payload"
bash agent-comm.sh --receive "agent_name"
bash agent-comm.sh --broadcast "from" "type" "payload"
bash agent-comm.sh --status
```
**Types:** task, result, question, answer, alert, handoff, status, learn

### 11. Agent Health Monitor (`agent-monitor/`)
ตรวจ agent ไหน hang/crash/หลุด identity
```bash
bash agent-monitor.sh --register "name" [pid]
bash agent-monitor.sh --heartbeat "name"
bash agent-monitor.sh --check
bash agent-monitor.sh --dashboard
bash agent-monitor.sh --alerts
bash agent-monitor.sh --check-identity "text"
```

---
_Generated: 2026-04-22_
