#!/usr/bin/env bash
# Deterministic check of the loop goal: green tests, coverage of src/services
# (lines and functions >= 95% overall, each file >= 90% lines), types and architecture.
set -u
rm -rf .coverage-goal
npx vitest run --coverage --coverage.provider=v8 --coverage.include='src/services/**' \
  --coverage.reporter=json-summary --coverage.reportsDirectory=.coverage-goal > .coverage-goal.log 2>&1
TESTS=$?
read -r LINES FUNCS LOW <<<"$(node -e "
try{const s=require('./.coverage-goal/coverage-summary.json');
const low=Object.entries(s).filter(([f,v])=>f!=='total'&&v.lines.pct<90).map(([f,v])=>f.split('/').pop()+':'+v.lines.pct).join(',')||'none';
console.log(s.total.lines.pct, s.total.functions.pct, low)}catch(e){console.log('0 0 unknown')}")"
npm run check > /dev/null 2>&1; TYPES=$?
bash scripts/check-architecture.sh > /dev/null 2>&1; ARCH=$?
echo "tests_exit=$TESTS coverage_lines=$LINES coverage_functions=$FUNCS files_below_90=$LOW types_exit=$TYPES arch_exit=$ARCH"
if [ "$TESTS" -eq 0 ] && [ "$TYPES" -eq 0 ] && [ "$ARCH" -eq 0 ] && [ "$LOW" = "none" ] && node -e "process.exit($LINES >= 95 && $FUNCS >= 95 ? 0 : 1)"; then
  echo "GOAL: PASS"; exit 0
fi
echo "GOAL: FAIL"
[ "$TESTS" -ne 0 ] && echo "WHY: tests fail. FIX: see .coverage-goal.log"
[ "$LOW" != "none" ] && echo "WHY: files below 90% lines: $LOW. FIX: add tests for those files first"
node -e "process.exit($LINES >= 95 && $FUNCS >= 95 ? 0 : 1)" || echo "WHY: lines $LINES% / functions $FUNCS% (need 95/95). FIX: test the uncovered functions listed in .coverage-goal/coverage-summary.json"
exit 1
