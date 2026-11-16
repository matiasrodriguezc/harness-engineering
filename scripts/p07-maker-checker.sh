#!/usr/bin/env bash
# P07 · Experimento 3: loop maker-checker sin humano. Para con 2 PASS seguidos del checker o a las 6 vueltas.
# Uso: p07-maker-checker.sh <repo-base-terminado-en-P06>
set -u
BASE="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p07/3-maker-checker"; P="$HERE/../p07/prompts"
R="$HOME/harness-runs/p07-maker-checker"
rm -rf "$R"; cp -R "$BASE" "$R"; rm -rf "$R/.git" "$R/node_modules" "$R/dist" "$R/checker-verdict.md"
cp "$P/maker.md" "$R/maker.md"; cp "$P/checker.md" "$R/checker.md"
printf '# loop-state.md\n\nLoop: maker-checker para búsqueda de documentos. Para con 2 PASS seguidos o 6 vueltas.\n' > "$R/loop-state.md"
(cd "$R" && npm install --silent >/dev/null 2>&1 && git init -q && printf 'node_modules/\ndist/\n' >> .git/info/exclude \
  && git add -A && git -c user.name=run -c user.email=run@local commit -qm "base P07 (fin de P06) + prompts maker/checker")
mkdir -p "$EV"; SUM="$EV/resumen-vueltas.md"
echo "| Vuelta | ¿Trabajó el maker? | Veredicto del checker | Defectos | Costo maker | Costo checker |" > "$SUM"
echo "|---|---|---|---|---|---|" >> "$SUM"
cost() { python3 -I -c "import json,sys; L=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]; print('US\$%.2f' % [d for d in L if d.get('type')=='result'][-1].get('total_cost_usd',0))" "$1" 2>/dev/null || echo "—"; }
passes=0; last="none"
for r in 1 2 3 4 5 6; do
  printf '\n## Vuelta %s\n' "$r" >> "$R/loop-state.md"
  if [ "$last" != "PASS" ]; then
    "$HERE/run-session.sh" "$R" "$EV/vuelta-$r-maker" "Read maker.md and do this round (round $r)."; MC=$(cost "$EV/vuelta-$r-maker/transcript.jsonl"); MW="Sí"
  else MC="—"; MW="No (confirmación)"; fi
  "$HERE/run-session.sh" "$R" "$EV/vuelta-$r-checker" "Read checker.md and verify this round (round $r)."
  cp "$R/checker-verdict.md" "$EV/vuelta-$r-checker/checker-verdict.md" 2>/dev/null || true
  V=$(head -1 "$R/checker-verdict.md" 2>/dev/null | grep -o 'PASS\|FAIL' || echo "SIN VEREDICTO")
  N=$(grep -cE '^[0-9]+\.' "$R/checker-verdict.md" 2>/dev/null || echo 0)
  echo "| $r | $MW | $V | $N | $MC | $(cost "$EV/vuelta-$r-checker/transcript.jsonl") |" >> "$SUM"
  if [ "$V" = "PASS" ]; then passes=$((passes+1)); else passes=0; fi
  last="$V"
  [ "$passes" -ge 2 ] && { echo "PARADA: 2 PASS seguidos en la vuelta $r" >> "$SUM"; break; }
done
cp "$R/loop-state.md" "$EV/loop-state-final.md"; (cd "$R" && git log --oneline > "$EV/historial-git.txt")
