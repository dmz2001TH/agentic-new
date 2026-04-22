#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Planner Agent — แตก task + prioritize + dependency
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash planner.sh --plan "goal" "complexity"
#   bash planner.sh --add-task "plan_id" "task" "priority" "depends_on"
#   bash planner.sh --status "plan_id"
#   bash planner.sh --next "plan_id"
#   bash planner.sh --complete "plan_id" "task_num"
#   bash planner.sh --list

set -e
PLAN_DIR="$(cd "$(dirname "$0")" && pwd)"
PLANS_FILE="${PLAN_DIR}/plans.jsonl"
TEMPLATES_FILE="${PLAN_DIR}/templates.json"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

mkdir -p "$PLAN_DIR"
[ ! -f "$PLANS_FILE" ] && touch "$PLANS_FILE"

# Task templates for common patterns
if [ ! -f "$TEMPLATES_FILE" ]; then
    cat > "$TEMPLATES_FILE" << 'EOF'
{
  "templates": {
    "debug": [
      {"task":"Reproduce the issue","priority":"high","depends_on":[]},
      {"task":"Identify root cause","priority":"high","depends_on":[1]},
      {"task":"Research solution","priority":"medium","depends_on":[2]},
      {"task":"Implement fix","priority":"high","depends_on":[3]},
      {"task":"Test fix","priority":"high","depends_on":[4]},
      {"task":"Document solution","priority":"low","depends_on":[5]}
    ],
    "feature": [
      {"task":"Define requirements","priority":"high","depends_on":[]},
      {"task":"Design architecture","priority":"high","depends_on":[1]},
      {"task":"Implement core","priority":"high","depends_on":[2]},
      {"task":"Add tests","priority":"medium","depends_on":[3]},
      {"task":"Code review","priority":"medium","depends_on":[3]},
      {"task":"Documentation","priority":"low","depends_on":[4]},
      {"task":"Deploy/integrate","priority":"high","depends_on":[4,5]}
    ],
    "refactor": [
      {"task":"Analyze current code","priority":"high","depends_on":[]},
      {"task":"Identify improvement areas","priority":"high","depends_on":[1]},
      {"task":"Create refactor plan","priority":"high","depends_on":[2]},
      {"task":"Implement changes","priority":"high","depends_on":[3]},
      {"task":"Run tests","priority":"high","depends_on":[4]},
      {"task":"Compare before/after","priority":"medium","depends_on":[5]}
    ],
    "learn": [
      {"task":"Gather resources","priority":"high","depends_on":[]},
      {"task":"Read/study primary source","priority":"high","depends_on":[1]},
      {"task":"Practice with examples","priority":"high","depends_on":[2]},
      {"task":"Summarize learnings","priority":"medium","depends_on":[3]},
      {"task":"Apply to project","priority":"medium","depends_on":[4]}
    ]
  }
}
EOF
fi

create_plan() {
    local goal="$1" complexity="${2:-medium}"
    [ -z "$goal" ] && echo "Usage: --plan 'goal' [complexity]" && return 1
    
    local plan_id="plan-$(date +%Y%m%d%H%M%S)"
    local num_tasks=5
    
    case "$complexity" in
        simple) num_tasks=3 ;;
        medium) num_tasks=5 ;;
        complex) num_tasks=7 ;;
    esac
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📋 Plan: ${goal}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "  ID: ${plan_id}"
    echo -e "  Complexity: ${complexity}"
    echo -e "  Target tasks: ${num_tasks}"
    echo ""
    
    # Auto-decompose goal into steps
    echo -e "${YELLOW}Auto-decomposition:${NC}"
    local tasks="[]"
    local words=($goal)
    local step=1
    
    # Generate tasks based on complexity
    for i in $(seq 1 $num_tasks); do
        local dep="[]"
        [ "$i" -gt 1 ] && dep="[${step}]"
        local priority="medium"
        [ "$i" -le 2 ] && priority="high"
        [ "$i" -eq $num_tasks ] && priority="low"
        
        local task_name=""
        case "$i" in
            1) task_name="Analyze & understand: ${goal}" ;;
            2) task_name="Design approach for: ${goal}" ;;
            $num_tasks) task_name="Verify & document: ${goal}" ;;
            *) task_name="Implement step $((i-1)): ${goal}" ;;
        esac
        
        echo -e "  ${step}. [${priority}] ${task_name}"
        tasks=$(echo "$tasks" | jq -c --arg t "$task_name" --arg p "$priority" --argjson d "$dep" \
            '. += [{"num":'"$step"',"task":$t,"priority":$p,"depends_on":$d,"status":"pending"}]')
        ((step++))
    done
    
    # Save plan
    echo "{\"id\":\"${plan_id}\",\"goal\":$(echo "$goal" | jq -Rs .),\"complexity\":\"${complexity}\",\"tasks\":${tasks},\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"status\":\"active\"}" >> "$PLANS_FILE"
    
    echo -e "\n${GREEN}✓ Plan created:${NC} ${plan_id}"
    echo -e "  Next: bash planner.sh --next ${plan_id}"
}

show_status() {
    local plan_id="$1"
    [ -z "$plan_id" ] && echo "Usage: --status 'plan_id'" && return 1
    
    local plan=$(grep "$plan_id" "$PLANS_FILE" | tail -1)
    [ -z "$plan" ] && echo "Plan not found: $plan_id" && return 1
    
    local goal=$(echo "$plan" | jq -r '.goal')
    local total=$(echo "$plan" | jq '.tasks | length')
    local completed=$(echo "$plan" | jq '[.tasks[] | select(.status == "completed")] | length')
    local blocked=$(echo "$plan" | jq '[.tasks[] | select(.status == "blocked")] | length')
    
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📊 Plan Status: ${goal}${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "  Progress: ${completed}/${total} ($((completed * 100 / total))%)"
    echo -e "  Blocked: ${blocked}"
    echo ""
    
    echo "$plan" | jq -r '.tasks[] | "  \(if .status == "completed" then "✅" elif .status == "blocked" then "🚫" elif .status == "in_progress" then "🔄" else "⬜" end) #\(.num) [\(.priority)] \(.task)"' 2>/dev/null
}

show_next() {
    local plan_id="$1"
    [ -z "$plan_id" ] && echo "Usage: --next 'plan_id'" && return 1
    
    local plan=$(grep "$plan_id" "$PLANS_FILE" | tail -1)
    [ -z "$plan" ] && echo "Plan not found: $plan_id" && return 1
    
    echo -e "${CYAN}Next available tasks:${NC}\n"
    
    # Find tasks where all dependencies are completed
    echo "$plan" | jq -r '
        .tasks[] | 
        select(.status == "pending") |
        select(all(.depends_on[]; . as $dep | $ARGS.positional.tasks | map(.num) | contains([$dep])))
    ' 2>/dev/null || {
        # Simpler approach: just show first pending task
        echo "$plan" | jq -r '.tasks[] | select(.status == "pending") | "  → #\(.num) [\(.priority)] \(.task)"' 2>/dev/null | head -3
    }
}

complete_task() {
    local plan_id="$1" task_num="$2"
    [ -z "$plan_id" ] && echo "Usage: --complete 'plan_id' 'task_num'" && return 1
    
    # Read, update, write back
    local tmp=$(mktemp)
    while IFS= read -r line; do
        if echo "$line" | grep -q "$plan_id"; then
            echo "$line" | jq --argjson n "$task_num" '
                .tasks = [.tasks[] | if .num == $n then .status = "completed" else . end]
            '
        else
            echo "$line"
        fi
    done < "$PLANS_FILE" > "$tmp" && mv "$tmp" "$PLANS_FILE"
    
    echo -e "${GREEN}✓ Task #${task_num} completed${NC}"
}

list_plans() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  📋 All Plans${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local id=$(echo "$line" | jq -r '.id')
        local goal=$(echo "$line" | jq -r '.goal')
        local total=$(echo "$line" | jq '.tasks | length')
        local done=$(echo "$line" | jq '[.tasks[] | select(.status == "completed")] | length')
        echo -e "  ${id}: ${goal} (${done}/${total})"
    done < "$PLANS_FILE"
}

# Auto-plan using template
auto_plan() {
    local goal="$1" template="${2:-feature}"
    [ -z "$goal" ] && echo "Usage: --auto 'goal' [template: debug|feature|refactor|learn]" && return 1
    
    local plan_id="plan-$(date +%Y%m%d%H%M%S)"
    echo -e "${CYAN}Auto-planning: ${goal} (template: ${template})${NC}\n"
    
    local tasks=$(jq -r --arg t "$template" '.templates[$t] // .templates["feature"]' "$TEMPLATES_FILE")
    local step=1
    
    echo "$tasks" | jq -c '.[]' | while read task; do
        local name=$(echo "$task" | jq -r '.task')
        local priority=$(echo "$task" | jq -r '.priority')
        echo -e "  ${step}. [${priority}] ${name} — ${goal}"
        ((step++))
    done
    
    echo -e "\n${GREEN}✓ Use --plan for full plan creation${NC}"
}

case "${1:-}" in
    --plan) create_plan "$2" "$3" ;;
    --status) show_status "$2" ;;
    --next) show_next "$2" ;;
    --complete) complete_task "$2" "$3" ;;
    --list) list_plans ;;
    --auto) auto_plan "$2" "$3" ;;
    *) echo "Usage: planner.sh [--plan|--status|--next|--complete|--list|--auto]" ;;
esac

