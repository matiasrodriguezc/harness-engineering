#!/usr/bin/env bash
# P07 · Experiment 1: a single-pass run versus a goal loop (Ralph style).
# Usage: p07-goal.sh <base-repo-finished-in-P06>
set -u
BASE="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p07/1-goal"; P="$HERE/../p07/prompts"
setup() {
  rm -rf "$1"; cp -R "$BASE" "$1"; rm -rf "$1/.git" "$1/node_modules" "$1/dist"
  cp "$P/goal.md" "$1/goal.md"; cp "$P/check-goal.sh" "$1/scripts/check-goal.sh"; chmod +x "$1/scripts/check-goal.sh"
  # The coverage tool goes into package.json (--save-dev): with --no-save, init.sh's `npm install`
  # removed it and check-goal.sh could not measure (it happened in the original run; see p07/metrics.md).
  (cd "$1" && npm install --silent >/dev/null 2>&1 && npm install --silent --save-dev @vitest/coverage-v8@2 >/dev/null 2>&1 \
     && printf '.coverage-goal/\n.coverage-goal.log\n' >> .gitignore \
     && git init -q && printf 'node_modules/\ndist/\n' >> .git/info/exclude && git add -A \
     && git -c user.name=run -c user.email=run@local commit -qm "base P07 (end of P06) + goal.md")
}
mkdir -p "$EV"
# A) A single pass, no loop
A="$HOME/harness-runs/p07-goal-manual"; setup "$A"
(cd "$A" && bash scripts/check-goal.sh) > "$EV/single-pass-before.txt"
"$HERE/run-session.sh" "$A" "$EV/single-pass" "Read goal.md and achieve the goal."
(cd "$A" && bash scripts/check-goal.sh) > "$EV/single-pass-after.txt"
# B) Goal loop: new capped sessions until check-goal passes, 6 rounds or 2 without progress
B="$HOME/harness-runs/p07-goal-loop"; setup "$B"
(cd "$B" && bash scripts/check-goal.sh) > "$EV/loop-before.txt"
prev=$(grep -o 'coverage_lines=[0-9.]*' "$EV/loop-before.txt" | cut -d= -f2); stall=0
for i in 1 2 3 4 5 6; do
  "$HERE/run-session.sh" "$B" "$EV/loop-round-$i" "Read goal.md and loop-state.md, then make one round of progress toward the goal as goal.md describes." --max-budget-usd 0.60
  (cd "$B" && bash scripts/check-goal.sh) > "$EV/loop-round-$i/check.txt"
  cur=$(grep -o 'coverage_lines=[0-9.]*' "$EV/loop-round-$i/check.txt" | cut -d= -f2)
  echo "round $i: coverage $prev -> $cur $(tail -n +2 "$EV/loop-round-$i/check.txt" | head -1)" | tee -a "$EV/loop-summary.txt"
  grep -q "GOAL: PASS" "$EV/loop-round-$i/check.txt" && { echo "STOP: goal met in round $i" | tee -a "$EV/loop-summary.txt"; break; }
  if node -e "process.exit($cur > $prev ? 0 : 1)"; then stall=0; else stall=$((stall+1)); fi
  [ "$stall" -ge 2 ] && { echo "STOP: 2 rounds without progress" | tee -a "$EV/loop-summary.txt"; break; }
  prev=$cur
done
cp "$B/loop-state.md" "$EV/loop-state-final.md" 2>/dev/null || true
