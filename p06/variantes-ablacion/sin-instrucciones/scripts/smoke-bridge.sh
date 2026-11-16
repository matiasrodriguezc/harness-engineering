#!/usr/bin/env bash
# Abre la app real y comprueba que la interfaz tenga acceso a la API (window.knowledgeBase).
# Es la verificación de capa 3 mínima: si falla, la app compila pero el usuario no puede hacer nada.
set -u
PORT="${1:-9350}"
DATA="$(mktemp -d)"
env -u NODE_OPTIONS npx electron . --remote-debugging-port="$PORT" --user-data-dir="$DATA" >/dev/null 2>&1 &
PID=$!
OUT=""
for i in $(seq 1 30); do
  OUT="$(node --experimental-websocket scripts/check-bridge.mjs "$PORT" 2>/dev/null)" && break
  sleep 1
done
kill "$PID" 2>/dev/null; rm -rf "$DATA"
echo "$OUT"
if echo "$OUT" | grep -q '"bridge": "object"'; then
  echo "PASS: the running app exposes window.knowledgeBase"
else
  echo "FAIL: the running app does not expose window.knowledgeBase"
  echo "WHY: the preload did not load, so every button in the UI is disconnected from the app"
  echo "FIX: run 'bash scripts/check-architecture.sh' and follow its preload instructions, rebuild, and run this script again"
  exit 1
fi
