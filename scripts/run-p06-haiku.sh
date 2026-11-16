#!/usr/bin/env bash
# Repeats the P06 benchmark with a smaller model: the same task, the same hidden acceptance suite
# and the same two harnesses (weak = untouched starter, mine = my full harness, with the cleanup pass).
# Only the model changes. Results go to p06/haiku/ so the Opus results stay untouched.
# Usage: run-p06-haiku.sh <folder-with-my-original-harness> [model-id]
set -u
H="$1"; MODEL="${2:-claude-haiku-5-5}"; HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p06/haiku"
mkdir -p "$EV"; : > "$EV/acceptance-summary.txt"
echo "model: $MODEL" > "$EV/model.txt"
CLAUDE_MODEL="$MODEL" "$HERE/run-p06.sh" haiku-weak -   "$EV/weak"
CLAUDE_MODEL="$MODEL" "$HERE/run-p06.sh" haiku-mine "$H" "$EV/mine" cleanup
