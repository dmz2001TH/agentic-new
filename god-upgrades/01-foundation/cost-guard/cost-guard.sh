#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Token/Cost Guard — ตั้ง limit + alert กัน burn token
# ═══════════════════════════════════════════════════════════
# Usage:
#   bash cost-guard.sh --init                    # setup config
#   bash cost-guard.sh --log 1500 3200           # log tokens (prompt completion)
#   bash cost-guard.sh --check                   # check limits
#   bash cost-guard.sh --report [daily|weekly]
#   bash cost-guard.sh --reset                   # reset daily counter

set -e
GUARD_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${GUARD_DIR}/config.json"
USAGE_FILE="${GUARD_DIR}/usage.jsonl"
REPORT_FILE="${GUARD_DIR}/report.md"
ALERT_FILE="${GUARD_DIR}/alerts.log"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

mkdir -p "$GUARD_DIR"

# Initialize config with defaults
init_config() {
    [ -f "$CONFIG_FILE" ] && echo "Config exists. Delete to reinit." && return
    cat > "$CONFIG_FILE" << 'EOF'
{
  "daily_token_limit": 500000,
  "daily_cost_limit_usd": 10.00,
  "cost_per_1k_prompt": 0.001,
  "cost_per_1k_completion": 0.003,
  "warning_threshold": 0.8,
  "critical_threshold": 0.95,
  "auto_pause_at": 1.0,
  "tracking_since": "2026-04-22"
}
EOF
    echo -e "${GREEN}✓ Config created:${NC} $CONFIG_FILE"
}

# Log token usage
log_usage() {
    local prompt_tokens="${1:-0}"
    local completion_tokens="${2:-0}"
    local model="${3:-unknown}"
    local session="${4:-default}"
    
    [ ! -f "$CONFIG_FILE" ] && init_config
    
    local total=$((prompt_tokens + completion_tokens))
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local date_today=$(date +%Y-%m-%d)
    
    # Calculate cost
    local cost_prompt=$(echo "scale=6; $prompt_tokens * $(jq -r '.cost_per_1k_prompt' "$CONFIG_FILE") / 1000" | bc)
    local cost_completion=$(echo "scale=6; $completion_tokens * $(jq -r '.cost_per_1k_completion' "$CONFIG_FILE") / 1000" | bc)
    local cost_total=$(echo "scale=6; $cost_prompt + $cost_completion" | bc)
    
    echo "{\"date\":\"${date_today}\",\"timestamp\":\"${ts}\",\"prompt\":${prompt_tokens},\"completion\":${completion_tokens},\"total\":${total},\"cost_usd\":${cost_total},\"model\":\"${model}\",\"session\":\"${session}\"}" >> "$USAGE_FILE"
    
    echo -e "${GREEN}✓ Logged:${NC} ${total} tokens (\$${cost_total}) [${model}]"
    
    # Check limits after logging
    check_limits
}

# Check current usage against limits
check_limits() {
    [ ! -f "$CONFIG_FILE" ] && echo "No config. Run --init first." && return 1
    
    local date_today=$(date +%Y-%m-%d)
    local daily_limit=$(jq -r '.daily_token_limit' "$CONFIG_FILE")
    local cost_limit=$(jq -r '.daily_cost_limit_usd' "$CONFIG_FILE")
    local warning=$(jq -r '.warning_threshold' "$CONFIG_FILE")
    local critical=$(jq -r '.critical_threshold' "$CONFIG_FILE")
    
    # Get today's usage
    local today_tokens=$(jq -s "[.[] | select(.date == \"${date_today}\")] | map(.total) | add // 0" "$USAGE_FILE" 2>/dev/null || echo "0")
    local today_cost=$(jq -s "[.[] | select(.date == \"${date_today}\")] | map(.cost_usd) | add // 0" "$USAGE_FILE" 2>/dev/null || echo "0")
    
    local pct_tokens=$(echo "scale=1; $today_tokens * 100 / $daily_limit" | bc 2>/dev/null || echo "0")
    local pct_cost=$(echo "scale=1; $today_cost * 100 / $cost_limit" | bc 2>/dev/null || echo "0")
    
    echo -e "\n${CYAN}── Token Guard Status (${date_today}) ──${NC}"
    echo -e "  Tokens: ${today_tokens}/${daily_limit} (${pct_tokens}%)"
    echo -e "  Cost:   \$${today_cost}/\$${cost_limit} (${pct_cost}%)"
    
    # Alert levels
    local token_pct_int=${pct_tokens%.*}
    if [ "$token_pct_int" -ge 95 ] 2>/dev/null; then
        echo -e "  ${RED}🔴 CRITICAL — ใกล้ limit แล้ว!${NC}"
        echo "$(date) CRITICAL tokens=${today_tokens}/${daily_limit}" >> "$ALERT_FILE"
    elif [ "$token_pct_int" -ge 80 ] 2>/dev/null; then
        echo -e "  ${YELLOW}🟡 WARNING — ใช้ไปมากแล้ว${NC}"
    else
        echo -e "  ${GREEN}🟢 HEALTHY${NC}"
    fi
    echo ""
}

# Generate report
generate_report() {
    local period="${1:-daily}"
    local date_today=$(date +%Y-%m-%d)
    
    echo -e "${CYAN}Generating ${period} report...${NC}"
    
    if [ "$period" = "daily" ]; then
        local total_tokens=$(jq -s "[.[] | select(.date == \"${date_today}\")] | map(.total) | add // 0" "$USAGE_FILE" 2>/dev/null)
        local total_cost=$(jq -s "[.[] | select(.date == \"${date_today}\")] | map(.cost_usd) | add // 0" "$USAGE_FILE" 2>/dev/null)
        local calls=$(jq -s "[.[] | select(.date == \"${date_today}\")] | length" "$USAGE_FILE" 2>/dev/null)
        
        cat > "$REPORT_FILE" << EOF
# Token/Cost Report — ${date_today}
- Total tokens: ${total_tokens}
- Total cost: \$${total_cost}
- API calls: ${calls}
- Avg tokens/call: $([ "$calls" -gt 0 ] 2>/dev/null && echo $((total_tokens / calls)) || echo 0)
## Top models used
$(jq -s "[.[] | select(.date == \"${date_today}\")] | group_by(.model) | map({model: .[0].model, tokens: (map(.total) | add), calls: length}) | sort_by(-.tokens) | .[:5][] | \"- \(.model): \(.tokens) tokens (\(.calls) calls)\"" "$USAGE_FILE" 2>/dev/null)
EOF
    else
        # Weekly: last 7 days
        cat > "$REPORT_FILE" << EOF
# Token/Cost Report — Weekly
## Daily Breakdown
$(jq -s 'group_by(.date) | map({date: .[0].date, tokens: (map(.total) | add), cost: (map(.cost_usd) | add), calls: length}) | sort_by(-.date) | .[:7][] | "- \(.date): \(.tokens) tokens, \$\(.cost | tostring | .[:6]) (\(.calls) calls)"' "$USAGE_FILE" 2>/dev/null)
EOF
    fi
    
    echo -e "${GREEN}✓ Report:${NC} $REPORT_FILE"
}

# Reset daily counter (run at midnight via cron)
reset_daily() {
    echo -e "${GREEN}✓ Daily counter reset${NC}"
    # Don't delete old data — just noting the reset
    echo "{\"event\":\"daily_reset\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$USAGE_FILE"
}

case "${1:-}" in
    --init) init_config ;;
    --log) log_usage "$2" "$3" "$4" "$5" ;;
    --check) check_limits ;;
    --report) generate_report "$2" ;;
    --reset) reset_daily ;;
    *) echo "Usage: cost-guard.sh [--init|--log|--check|--report|--reset]" ;;
esac
