#!/bin/bash
# Plugin System — ให้ user อื่นเขียน plugin ให้ GOD
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; PLUGINS="${DIR}/plugins"; REGISTRY="${DIR}/registry.json"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
mkdir -p "$PLUGINS"; [ ! -f "$REGISTRY" ] && echo '{"plugins":[]}' > "$REGISTRY"

install() { local name="$1" source="$2"; [ -z "$name" ] && return 1
    local plugin_dir="${PLUGINS}/${name}"; mkdir -p "$plugin_dir"
    if [[ "$source" == http* ]]; then curl -sL "$source" -o "${plugin_dir}/plugin.sh" 2>/dev/null; fi
    chmod +x "${plugin_dir}/plugin.sh" 2>/dev/null
    local tmp=$(mktemp); jq --arg n "$name" --arg s "$source" '.plugins += [{"name":$n,"source":$s,"installed":"'"$(date +%Y-%m-%d)"'","status":"active"}]' "$REGISTRY" > "$tmp" && mv "$tmp" "$REGISTRY"
    echo -e "${GREEN}✓ Installed:${NC} $name"; }
run() { local name="$1"; local plugin="${PLUGINS}/${name}/plugin.sh"; [ ! -f "$plugin" ] && echo "Plugin not found: $name" && return 1; echo -e "${CYAN}Running plugin: ${name}${NC}"; bash "$plugin" "${@:2}"; }
list() { echo -e "${CYAN}Plugins:${NC}\n"; jq -r '.plugins[] | "  🔌 \(.name) [\(.status)] — \(.source)"' "$REGISTRY" 2>/dev/null || echo "  (none)"; }
case "${1:-}" in --install) install "$2" "$3";; --run) run "$2" "${@:3}";; --list) list;; --remove) jq --arg n "$2" '.plugins = [.plugins[] | select(.name != $n)]' "$REGISTRY" > /tmp/p.json && mv /tmp/p.json "$REGISTRY"; echo "Removed: $2";; *) echo "Usage: plugin-system.sh [--install|--run|--list|--remove]";; esac
