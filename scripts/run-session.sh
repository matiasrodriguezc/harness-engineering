#!/usr/bin/env bash
# Corre una sesión no interactiva de Claude Code en una carpeta de corrida y guarda la evidencia.
# Uso: run-session.sh <carpeta-de-corrida> <carpeta-de-evidencia> "<prompt>" [flags extra de claude...]
# Cada llamada es una sesión nueva: no hereda nada de la anterior salvo lo que esté en los archivos.
# Ejemplo de flag extra: --max-budget-usd 1.20 (corta la sesión al llegar al tope, como un reinicio).
set -u
RUN_DIR="$1"; EVID="$2"; PROMPT="$3"; shift 3
mkdir -p "$EVID"
cd "$RUN_DIR" || exit 1
printf '%s\n' "$PROMPT" > "$EVID/prompt.txt"
date '+%Y-%m-%d %H:%M:%S' > "$EVID/inicio.txt"
claude -p "$PROMPT" \
  --disable-slash-commands --strict-mcp-config \
  --permission-mode auto \
  --output-format stream-json --verbose \
  "$@" \
  > "$EVID/transcript.jsonl" 2> "$EVID/stderr.txt"
echo "exit=$?" >> "$EVID/stderr.txt"
date '+%Y-%m-%d %H:%M:%S' > "$EVID/fin.txt"
# Foto del estado del repo al terminar la sesión (sin package-lock).
# node_modules y dist se ignoran localmente (en .git/info/exclude, que el agente no ve como archivo
# del proyecto) por si el agente no creó un .gitignore.
grep -qx 'node_modules/' .git/info/exclude 2>/dev/null || printf 'node_modules/\ndist/\n' >> .git/info/exclude
git add -A
git -c user.name=run -c user.email=run@local commit -qm "fin de sesión: $(basename "$EVID")" || true
git show --stat --format='%h %s' HEAD > "$EVID/diff-stat.txt"
git show HEAD -- . ':(exclude)package-lock.json' > "$EVID/cambios.patch"
