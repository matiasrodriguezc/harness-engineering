#!/usr/bin/env bash
# Corre todas las variantes del P06 en orden (una por vez, para que las apps no choquen).
# Uso: run-p06-all.sh <carpeta-con-los-harness>
set -u
H="$1"; HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p06"
"$HERE/run-p06.sh" debil              -                          "$EV/debil"
"$HERE/run-p06.sh" mio                "$H/p06-harness"            "$EV/mio" limpieza
"$HERE/run-p06.sh" sin-e2e            "$H/p06-h-sin-e2e"          "$EV/ablacion-sin-e2e"
"$HERE/run-p06.sh" sin-lista          "$H/p06-h-sin-lista"        "$EV/ablacion-sin-lista"
"$HERE/run-p06.sh" sin-instrucciones  "$H/p06-h-sin-instrucciones" "$EV/ablacion-sin-instrucciones"
