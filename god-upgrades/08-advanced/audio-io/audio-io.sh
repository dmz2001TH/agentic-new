#!/bin/bash
# Audio I/O — รับ command เสียง + ตอบเป็นเสียง (wrapper)
set -e; DIR="$(cd "$(dirname "$0")" && pwd)"; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

transcribe() { local audio="$1"; [ ! -f "$audio" ] && echo "Not found: $audio" && return 1
    echo -e "${CYAN}🎤 Transcribing: ${audio}${NC}"
    local ext="${audio##*.}"; echo "  Format: ${ext}"; echo "  Duration: $(ffprobe -i "$audio" -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null || echo '?')s"
    command -v whisper &>/dev/null && whisper "$audio" --model base 2>/dev/null | head -20 || echo "  whisper not installed. Use TTS API instead."; }
speak() { local text="$1"; [ -z "$text" ] && return 1; echo -e "${CYAN}🔊 Speaking:${NC} ${text:0:100}..."
    command -v say &>/dev/null && say "$text" || command -v espeak &>/dev/null && espeak "$text" 2>/dev/null || echo "  TTS engine not available. Use MiMo TTS skill instead."; }
case "${1:-}" in --transcribe) transcribe "$2";; --speak) speak "$2";; *) echo "Usage: audio-io.sh [--transcribe|--speak]";; esac
