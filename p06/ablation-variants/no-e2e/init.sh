#!/usr/bin/env bash
# init.sh: checks that the environment is healthy before working. If it fails, no new work is added.
set -euo pipefail
echo "== 1/5 Environment =="
if [[ "${NODE_OPTIONS:-}" == *openssl-legacy-provider* ]]; then
  echo "WARN: NODE_OPTIONS contains --openssl-legacy-provider, which Electron rejects."
  echo "      To launch by hand use: env -u NODE_OPTIONS npm run dev"
fi
echo "== 2/5 Dependencies ==";  npm install --silent
echo "== 3/5 Types ==";         npm run check
echo "== 4/5 Build ==";         env -u NODE_OPTIONS npm run build
echo "== 5/5 Architecture ==";  bash scripts/check-architecture.sh
echo "init.sh OK"
