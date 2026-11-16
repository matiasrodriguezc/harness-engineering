#!/usr/bin/env bash
# init.sh: checks that the environment is healthy before working. If it fails, no new work is added.
set -euo pipefail
echo "== 1/6 Environment =="
if [[ "${NODE_OPTIONS:-}" == *openssl-legacy-provider* ]]; then
  echo "WARN: NODE_OPTIONS contains --openssl-legacy-provider, which Electron rejects."
  echo "      This script and scripts/smoke-bridge.sh remove it for Electron. To launch by hand use: env -u NODE_OPTIONS npm run dev"
fi
echo "== 2/6 Dependencies ==";  npm install --silent
echo "== 3/6 Types ==";         npm run check
echo "== 4/6 Build ==";         env -u NODE_OPTIONS npm run build
echo "== 5/6 Architecture ==";  bash scripts/check-architecture.sh
echo "== 6/6 Real app (UI bridge) =="; bash scripts/smoke-bridge.sh
echo "init.sh OK"
