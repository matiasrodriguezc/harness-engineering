#!/usr/bin/env bash
# init.sh: verifica que el entorno esté sano antes de trabajar. Si falla, no se agrega trabajo nuevo.
set -euo pipefail
echo "== 1/5 Entorno =="
if [[ "${NODE_OPTIONS:-}" == *openssl-legacy-provider* ]]; then
  echo "WARN: NODE_OPTIONS contains --openssl-legacy-provider, which Electron rejects."
  echo "      To launch by hand use: env -u NODE_OPTIONS npm run dev"
fi
echo "== 2/5 Dependencias ==";  npm install --silent
echo "== 3/5 Tipos ==";         npm run check
echo "== 4/5 Build ==";         env -u NODE_OPTIONS npm run build
echo "== 5/5 Arquitectura ==";  bash scripts/check-architecture.sh
echo "init.sh OK"
