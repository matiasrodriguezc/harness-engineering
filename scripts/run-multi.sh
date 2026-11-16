#!/usr/bin/env bash
# Encadena sesiones nuevas sobre la misma carpeta hasta que todas las funciones de
# feature_list.json estén en "pass" o se llegue al máximo de sesiones.
# Uso: run-multi.sh <carpeta-de-corrida> <carpeta-de-evidencia> <max-sesiones> <tope-usd> "<prompt-sesión-1>" "<prompt-siguientes>"
set -u
RUN_DIR="$1"; EVID="$2"; MAX="$3"; BUDGET="$4"; P1="$5"; PN="$6"
HERE="$(cd "$(dirname "$0")" && pwd)"
pending() {
  python3 -I -c "import json,sys; d=json.load(open(sys.argv[1])); print(sum(f['status']!='pass' for f in d['features']))" "$RUN_DIR/feature_list.json"
}
for i in $(seq 1 "$MAX"); do
  if [ "$i" -eq 1 ]; then P="$P1"; else P="$PN"; fi
  "$HERE/run-session.sh" "$RUN_DIR" "$EVID/sesion-$i" "$P" --max-budget-usd "$BUDGET"
  left=$(pending)
  echo "sesion-$i: funciones pendientes según feature_list.json = $left" | tee -a "$EVID/resumen-sesiones.txt"
  [ "$left" -eq 0 ] && break
done
