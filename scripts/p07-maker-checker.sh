#!/usr/bin/env bash
# P07 · Experiment 3: maker-checker loop with no human. Stops after 2 consecutive checker PASSes or at 6 rounds.
# Usage: p07-maker-checker.sh <base-repo-finished-in-P06>
set -u
BASE="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p07/3-maker-checker"; P="$HERE/../p07/prompts"
R="$HOME/harness-runs/p07-maker-checker"
rm -rf "$R"; cp -R "$BASE" "$R"; rm -rf "$R/.git" "$R/node_modules" "$R/dist" "$R/checker-verdict.md"
cp "$P/maker.md" "$R/maker.md"; cp "$P/checker.md" "$R/checker.md"
printf '# loop-state.md\n\nLoop: maker-checker for document search. Stops after 2 consecutive PASSes or 6 rounds.\n' > "$R/loop-state.md"
(cd "$R" && npm install --silent >/dev/null 2>&1 && git init -q && printf 'node_modules/\ndist/\n' >> .git/info/exclude \
  && git add -A && git -c user.name=run -c user.email=run@local commit -qm "base P07 (end of P06) + maker/checker prompts")
mkdir -p "$EV"; SUM="$EV/rounds-summary.md"
echo "| Round | Did the maker work? | Checker verdict | Defects | Maker cost | Checker cost |" > "$SUM"
echo "|---|---|---|---|---|---|" >> "$SUM"
cost() { python3 -I -c "import json,sys; L=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]; print('US\$%.2f' % [d for d in L if d.get('type')=='result'][-1].get('total_cost_usd',0))" "$1" 2>/dev/null || echo "—"; }
passes=0; last="none"
for r in 1 2 3 4 5 6; do
  printf '\n## Round %s\n' "$r" >> "$R/loop-state.md"
  if [ "$last" != "PASS" ]; then
    "$HERE/run-session.sh" "$R" "$EV/round-$r-maker" "Read maker.md and do this round (round $r)."; MC=$(cost "$EV/round-$r-maker/transcript.jsonl"); MW="Yes"
  else MC="—"; MW="No (confirmation)"; fi
  "$HERE/run-session.sh" "$R" "$EV/round-$r-checker" "Read checker.md and verify this round (round $r)."
  cp "$R/checker-verdict.md" "$EV/round-$r-checker/checker-verdict.md" 2>/dev/null || true
  V=$(head -1 "$R/checker-verdict.md" 2>/dev/null | grep -o 'PASS\|FAIL' || echo "NO VERDICT")
  N=$(grep -cE '^[0-9]+\.' "$R/checker-verdict.md" 2>/dev/null || echo 0)
  echo "| $r | $MW | $V | $N | $MC | $(cost "$EV/round-$r-checker/transcript.jsonl") |" >> "$SUM"
  if [ "$V" = "PASS" ]; then passes=$((passes+1)); else passes=0; fi
  last="$V"
  [ "$passes" -ge 2 ] && { echo "STOP: 2 consecutive PASSes in round $r" >> "$SUM"; break; }
done
cp "$R/loop-state.md" "$EV/loop-state-final.md"; (cd "$R" && git log --oneline > "$EV/git-log.txt")
