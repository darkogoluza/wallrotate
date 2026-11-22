#!/usr/bin/env bash
# Remove wallrotate: the program, its rotation history and cache.
# Your config (~/.config/wallrotate) and autostart are left as they are.
set -euo pipefail

BIN="$HOME/.local/bin"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/wallrotate.json"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/wallrotate"

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

# stop a running copy, or it would keep going without its program file
pkill -f "python3 [^ ]*/wallrotate$" 2>/dev/null && say "stopped wallrotate" || true
rm -f "$BIN/wallrotate"
say "removed $BIN/wallrotate"
rm -f "$STATE"
rm -rf "$CACHE"
say "removed rotation history and cache (config kept)"
