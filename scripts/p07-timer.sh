#!/usr/bin/env bash
# P07 · Experiment 2: timer loop. Each tick runs a deterministic check (init.sh);
# only if it fails does it wake the agent. On ticks 2 and 4 a fault is injected, like a
# teammate's broken commit, so there is something to detect.
# Usage: p07-timer.sh <base-repo-finished-in-P06> [ticks] [seconds-between-ticks]
set -u
BASE="$1"; TICKS="${2:-5}"; EVERY="${3:-240}"
HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p07/2-timer"
R="$HOME/harness-runs/p07-timer"
rm -rf "$R"; cp -R "$BASE" "$R"; rm -rf "$R/.git" "$R/node_modules" "$R/dist"
(cd "$R" && npm install --silent >/dev/null 2>&1 && git init -q && printf 'node_modules/\ndist/\n' >> .git/info/exclude \
  && git add -A && git -c user.name=run -c user.email=run@local commit -qm "base P07 (end of P06)")
mkdir -p "$EV"; LOG="$EV/timer-log.md"
echo "# Timer loop log" > "$LOG"; echo "" >> "$LOG"
echo "| Tick | Time | Injected fault | Check | Was the agent woken? | Check after | Agent cost |" >> "$LOG"
echo "|---|---|---|---|---|---|---|" >> "$LOG"
inject() {
  case "$1" in
    2) printf "\nexport const brokenCount: number = 'not a number';\n" >> "$R/src/services/qa-service.ts"
       (cd "$R" && git add -A && git -c user.name=teammate -c user.email=x@local commit -qm "tweak qa service") ; echo "type error in qa-service.ts";;
    4) printf "import * as fs from 'fs';\nexport const leaked = typeof fs;\n" > "$R/src/renderer/fs-helper.ts"
       (cd "$R" && git add -A && git -c user.name=teammate -c user.email=x@local commit -qm "add fs helper for renderer") ; echo "fs import in the renderer (violates the architecture)";;
    *) echo "—";;
  esac
}
for t in $(seq 1 "$TICKS"); do
  [ "$t" -gt 1 ] && sleep "$EVERY"
  FAULT=$(inject "$t")
  NOW=$(date '+%H:%M:%S')
  OUT=$(cd "$R" && bash init.sh 2>&1); RC=$?
  echo "$OUT" > "$EV/tick-$t-check.txt"
  if [ "$RC" -eq 0 ]; then
    echo "| $t | $NOW | $FAULT | ✅ passes | No | — | US\$0 |" >> "$LOG"; continue
  fi
  TAIL=$(echo "$OUT" | tail -25)
  "$HERE/run-session.sh" "$R" "$EV/tick-$t-agent" "You are the monitoring agent for this repository. The scheduled health check (bash init.sh) just failed. Last lines of its output:

$TAIL

Find what changed (git log, git diff), fix the root cause with the smallest safe change, and run bash init.sh again. If you cannot fix it safely, do not guess: write ALERT.md for a human explaining what failed and why. Commit your fix with a message that starts with 'monitor:'."
  AFTER=$(cd "$R" && bash init.sh > "$EV/tick-$t-check-after.txt" 2>&1 && echo "✅ passes" || echo "❌ still failing")
  COST=$(python3 -I -c "import json,sys; L=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]; print('US\$%.2f' % [d for d in L if d.get('type')=='result'][-1].get('total_cost_usd',0))" "$EV/tick-$t-agent/transcript.jsonl" 2>/dev/null)
  ALERT=$([ -f "$R/ALERT.md" ] && echo " (wrote ALERT.md)" || echo "")
  echo "| $t | $NOW | $FAULT | ❌ fails | Yes$ALERT | $AFTER | $COST |" >> "$LOG"
done
(cd "$R" && git log --oneline > "$EV/git-log.txt")
