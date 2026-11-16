#!/usr/bin/env bash
# Chains new sessions on the same folder until every feature in
# feature_list.json is "pass" or the maximum number of sessions is reached.
# Usage: run-multi.sh <run-folder> <evidence-folder> <max-sessions> <cap-usd> "<session-1-prompt>" "<next-prompts>"
set -u
RUN_DIR="$1"; EVID="$2"; MAX="$3"; BUDGET="$4"; P1="$5"; PN="$6"
HERE="$(cd "$(dirname "$0")" && pwd)"
pending() {
  python3 -I -c "import json,sys; d=json.load(open(sys.argv[1])); print(sum(f['status']!='pass' for f in d['features']))" "$RUN_DIR/feature_list.json"
}
for i in $(seq 1 "$MAX"); do
  if [ "$i" -eq 1 ]; then P="$P1"; else P="$PN"; fi
  "$HERE/run-session.sh" "$RUN_DIR" "$EVID/session-$i" "$P" --max-budget-usd "$BUDGET"
  left=$(pending)
  echo "session-$i: pending features according to feature_list.json = $left" | tee -a "$EVID/sessions-summary.txt"
  [ "$left" -eq 0 ] && break
done
