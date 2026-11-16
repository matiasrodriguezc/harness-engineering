#!/usr/bin/env bash
# Runs the three P07 experiments in order on the final P06 repo (my harness).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; BASE="$1"
"$HERE/p07-goal.sh" "$BASE"
"$HERE/p07-timer.sh" "$BASE" 5 240
"$HERE/p07-maker-checker.sh" "$BASE"
(cd "$HOME/harness-runs/p07-maker-checker" && env -u NODE_OPTIONS npm run build >/dev/null 2>&1)
node --experimental-websocket "$HERE/p07-search-accept.mjs" "$HOME/harness-runs/p07-maker-checker" 9344 2>/dev/null > "$HERE/../p07/3-maker-checker/independent-check.json"
