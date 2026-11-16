#!/usr/bin/env bash
# P07 · Experimento 1: corrida "manual" de una pasada contra un loop de objetivo (estilo Ralph).
# Uso: p07-goal.sh <repo-base-terminado-en-P06>
set -u
BASE="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p07/1-goal"; P="$HERE/../p07/prompts"
setup() {
  rm -rf "$1"; cp -R "$BASE" "$1"; rm -rf "$1/.git" "$1/node_modules" "$1/dist"
  cp "$P/goal.md" "$1/goal.md"; cp "$P/check-goal.sh" "$1/scripts/check-goal.sh"; chmod +x "$1/scripts/check-goal.sh"
  # La herramienta de cobertura va a package.json (--save-dev): con --no-save, el `npm install` de init.sh
  # la borraba y check-goal.sh no podía medir (pasó en la corrida original; ver p07/metricas.md).
  (cd "$1" && npm install --silent >/dev/null 2>&1 && npm install --silent --save-dev @vitest/coverage-v8@2 >/dev/null 2>&1 \
     && printf '.coverage-goal/\n.coverage-goal.log\n' >> .gitignore \
     && git init -q && printf 'node_modules/\ndist/\n' >> .git/info/exclude && git add -A \
     && git -c user.name=run -c user.email=run@local commit -qm "base P07 (fin de P06) + goal.md")
}
mkdir -p "$EV"
# A) Una sola pasada, sin loop
A="$HOME/harness-runs/p07-goal-manual"; setup "$A"
(cd "$A" && bash scripts/check-goal.sh) > "$EV/manual-antes.txt"
"$HERE/run-session.sh" "$A" "$EV/manual" "Read goal.md and achieve the goal."
(cd "$A" && bash scripts/check-goal.sh) > "$EV/manual-despues.txt"
# B) Loop de objetivo: sesiones nuevas con tope hasta que check-goal pase, 6 vueltas o 2 sin progreso
B="$HOME/harness-runs/p07-goal-loop"; setup "$B"
(cd "$B" && bash scripts/check-goal.sh) > "$EV/loop-antes.txt"
prev=$(grep -o 'coverage_lines=[0-9.]*' "$EV/loop-antes.txt" | cut -d= -f2); stall=0
for i in 1 2 3 4 5 6; do
  "$HERE/run-session.sh" "$B" "$EV/loop-vuelta-$i" "Read goal.md and loop-state.md, then make one round of progress toward the goal as goal.md describes." --max-budget-usd 0.60
  (cd "$B" && bash scripts/check-goal.sh) > "$EV/loop-vuelta-$i/check.txt"
  cur=$(grep -o 'coverage_lines=[0-9.]*' "$EV/loop-vuelta-$i/check.txt" | cut -d= -f2)
  echo "vuelta $i: cobertura $prev -> $cur $(tail -n +2 "$EV/loop-vuelta-$i/check.txt" | head -1)" | tee -a "$EV/loop-resumen.txt"
  grep -q "GOAL: PASS" "$EV/loop-vuelta-$i/check.txt" && { echo "PARADA: objetivo cumplido en la vuelta $i" | tee -a "$EV/loop-resumen.txt"; break; }
  if node -e "process.exit($cur > $prev ? 0 : 1)"; then stall=0; else stall=$((stall+1)); fi
  [ "$stall" -ge 2 ] && { echo "PARADA: 2 vueltas sin progreso" | tee -a "$EV/loop-resumen.txt"; break; }
  prev=$cur
done
cp "$B/loop-state.md" "$EV/loop-state-final.md" 2>/dev/null || true
