#!/bin/bash
# Federation — GOD หลายเครื่อง sync memory ข้ามกัน
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; NODES="${DIR}/nodes.json"; SYNC_LOG="${DIR}/sync-log.jsonl"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
[ ! -f "$NODES" ] && echo '{"nodes":[],"last_sync":null}' > "$NODES"; [ ! -f "$SYNC_LOG" ] && touch "$SYNC_LOG"

register_node() { local name="$1" endpoint="$2"; local tmp=$(mktemp); jq --arg n "$name" --arg e "$endpoint" '.nodes += [{"name":$n,"endpoint":$e,"registered":"'"$(date +%Y-%m-%d)"'","status":"active"}]' "$NODES" > "$tmp" && mv "$tmp" "$NODES"; echo -e "${GREEN}✓ Node registered:${NC} $name → $endpoint"; }
sync_to() { local node="$1" dir="${2:-.}"; echo -e "${CYAN}Syncing to: ${node}${NC}"; local endpoint=$(jq -r --arg n "$node" '.nodes[] | select(.name == $n) | .endpoint' "$NODES" 2>/dev/null); [ -z "$endpoint" ] && echo "Node not found" && return 1
    echo "  Endpoint: ${endpoint}"; echo "  Method: rsync/scp (configure endpoint)"; echo "{\"action\":\"sync_to\",\"node\":\"${node}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$SYNC_LOG"; }
pull_from() { local node="$1"; echo -e "${CYAN}Pulling from: ${node}${NC}"; echo "{\"action\":\"pull_from\",\"node\":\"${node}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" >> "$SYNC_LOG"; }
case "${1:-}" in --register) register_node "$2" "$3";; --sync) sync_to "$2" "$3";; --pull) pull_from "$2";; --nodes) jq -r '.nodes[] | "  🌐 \(.name) → \(.endpoint) [\(.status)]"' "$NODES" 2>/dev/null;; *) echo "Usage: federation.sh [--register|--sync|--pull|--nodes]";; esac
