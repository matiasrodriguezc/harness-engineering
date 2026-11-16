#!/usr/bin/env bash
# Runs a non-interactive Claude Code session in a run folder and saves the evidence.
# Usage: run-session.sh <run-folder> <evidence-folder> "<prompt>" [extra claude flags...]
# Each call is a new session: it inherits nothing from the previous one except what is in the files.
# Example extra flag: --max-budget-usd 1.20 (cuts the session off at the cap, like a restart).
set -u
RUN_DIR="$1"; EVID="$2"; PROMPT="$3"; shift 3
mkdir -p "$EVID"
cd "$RUN_DIR" || exit 1
printf '%s\n' "$PROMPT" > "$EVID/prompt.txt"
date '+%Y-%m-%d %H:%M:%S' > "$EVID/start.txt"
claude -p "$PROMPT" \
  --disable-slash-commands --strict-mcp-config \
  --permission-mode auto \
  --output-format stream-json --verbose \
  "$@" \
  > "$EVID/transcript.jsonl" 2> "$EVID/stderr.txt"
echo "exit=$?" >> "$EVID/stderr.txt"
date '+%Y-%m-%d %H:%M:%S' > "$EVID/end.txt"
# Snapshot of the repo state at the end of the session (without package-lock).
# node_modules and dist are ignored locally (in .git/info/exclude, which the agent does not see as a
# project file) in case the agent did not create a .gitignore.
grep -qx 'node_modules/' .git/info/exclude 2>/dev/null || printf 'node_modules/\ndist/\n' >> .git/info/exclude
git add -A
git -c user.name=run -c user.email=run@local commit -qm "end of session: $(basename "$EVID")" || true
git show --stat --format='%h %s' HEAD > "$EVID/diff-stat.txt"
git show HEAD -- . ':(exclude)package-lock.json' > "$EVID/changes.patch"
