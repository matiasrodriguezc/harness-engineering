#!/usr/bin/env bash
# Runs every P06 variant in order (one at a time, so the apps do not collide).
# Usage: run-p06-all.sh <folder-with-the-harnesses>
set -u
H="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p06"
"$HERE/run-p06.sh" weak              -                           "$EV/weak"
"$HERE/run-p06.sh" mine              "$H/p06-harness"             "$EV/mine" cleanup
"$HERE/run-p06.sh" no-e2e            "$H/p06-h-sin-e2e"           "$EV/ablation-no-e2e"
"$HERE/run-p06.sh" no-feature-list   "$H/p06-h-sin-lista"         "$EV/ablation-no-feature-list"
"$HERE/run-p06.sh" no-instructions   "$H/p06-h-sin-instrucciones" "$EV/ablation-no-instructions"
