#!/usr/bin/env bash
# init.sh: verifica que el entorno esté sano antes de trabajar. Si falla, no se agrega trabajo nuevo.
set -euo pipefail
echo "== 1/6 Entorno =="
if [[ "${NODE_OPTIONS:-}" == *openssl-legacy-provider* ]]; then
  echo "WARN: NODE_OPTIONS contains --openssl-legacy-provider, which Electron rejects."
  echo "      This script and scripts/smoke-bridge.sh remove it for Electron. To launch by hand use: env -u NODE_OPTIONS npm run dev"
fi
echo "== 2/6 Dependencias ==";  npm install --silent
echo "== 3/6 Tipos ==";         npm run check
echo "== 4/6 Build ==";         env -u NODE_OPTIONS npm run build
echo "== 5/6 Arquitectura ==";  bash scripts/check-architecture.sh
echo "== 6/6 App real (puente de la interfaz) =="; bash scripts/smoke-bridge.sh
echo "init.sh OK"
