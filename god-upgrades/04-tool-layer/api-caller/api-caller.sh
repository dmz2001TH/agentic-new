#!/bin/bash
# API Caller — เรียก external API + จัดการ auth/retry
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="${DIR}/api-log.jsonl"
AUTH="${DIR}/auth.json"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; NC='\033[0m'

[ ! -f "$LOG" ] && touch "$LOG"
[ ! -f "$AUTH" ] && echo '{"endpoints":{}}' > "$AUTH"

call() {
    local method="${1:-GET}" url="$2" data="${3:-}" headers="${4:-}" retries="${5:-3}"
    [ -z "$url" ] && echo "Usage: --call [GET|POST] 'url' 'data' 'headers' [retries]" && return 1
    
    local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local attempt=0 response="" code=""
    
    while [ "$attempt" -lt "$retries" ]; do
        attempt=$((attempt+1))
        echo -e "${CYAN}API ${method} ${url} (attempt ${attempt}/${retries})${NC}"
        
        local curl_cmd="curl -s -w '\n%{http_code}' -X ${method}"
        [ -n "$headers" ] && curl_cmd="$curl_cmd -H '${headers}'"
        [ -n "$data" ] && curl_cmd="$curl_cmd -d '${data}'"
        curl_cmd="$curl_cmd '${url}'"
        
        local result=$(eval "$curl_cmd" 2>/dev/null)
        code=$(echo "$result" | tail -1)
        response=$(echo "$result" | sed '$d')
        
        if [ "$code" -ge 200 ] 2>/dev/null && [ "$code" -lt 300 ] 2>/dev/null; then
            echo -e "${GREEN}✓ ${code}${NC}"
            echo "$response" | jq '.' 2>/dev/null || echo "$response" | head -20
            break
        elif [ "$code" -eq 429 ] 2>/dev/null; then
            echo -e "${RED}Rate limited. Waiting...${NC}"
            sleep 5
        else
            echo -e "${RED}✗ ${code}${NC}"
            [ "$attempt" -lt "$retries" ] && sleep 2
        fi
    done
    
    echo "{\"method\":\"${method}\",\"url\":\"${url}\",\"code\":${code:-0},\"attempt\":${attempt},\"timestamp\":\"${ts}\"}" >> "$LOG"
}

save_auth() {
    local name="$1" header="$2"
    [ -z "$name" ] && echo "Usage: --save-auth 'name' 'header_value'" && return 1
    local tmp=$(mktemp)
    jq --arg n "$name" --arg h "$header" '.endpoints[$n] = {"header":$h,"saved":"'"$(date +%Y-%m-%d)"'"}' "$AUTH" > "$tmp" && mv "$tmp" "$AUTH"
    echo -e "${GREEN}✓ Auth saved:${NC} $name"
}

case "${1:-}" in
    --call) call "$2" "$3" "$4" "$5" "$6" ;;
    --save-auth) save_auth "$2" "$3" ;;
    --log) tail -10 "$LOG" | jq -r '"  [\(.timestamp)] \(.method) \(.url) → \(.code)"' 2>/dev/null;;
    *) echo "Usage: api-caller.sh [--call|--save-auth|--log]" ;;
esac
