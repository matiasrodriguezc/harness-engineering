#!/usr/bin/env bash
# P08 · Grafo explícito: plan → implement → (verify-functional ∥ verify-review) → route → approval (humano) → merge.
# Los nodos de agente son sesiones nuevas; el ruteo, la solicitud de aprobación y el timeout son código.
# Uso: p08-graph.sh start <repo-base>      (corre hasta el nodo de aprobación y se detiene)
#      p08-graph.sh resume [timeout-min]   (lee la decisión humana en state.md y sigue)
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p08/3-grafo"; P="$HERE/../p08/prompts"
R="$HOME/harness-runs/p08-graph"; S="$HERE/run-session.sh"; MAX_ROUNDS=4
mkdir -p "$EV"
st() { grep -m1 "^$1:" "$R/state.md" | sed "s/^$1: *//"; }
set_st() { python3 -I -c "import re,sys; p,k,v=sys.argv[1:]; s=open(p).read(); s=re.sub(r'(?m)^'+re.escape(k)+r':.*$', k+': '+v, s) if re.search(r'(?m)^'+re.escape(k)+r':', s) else s.replace('## Feedback', k+': '+v+'\n\n## Feedback',1); open(p,'w').write(s)" "$R/state.md" "$1" "$2"; }
log() { echo "- $(date '+%H:%M:%S') · $*" | tee -a "$EV/recorrido.md"; }
commit_state() { (cd "$R" && git add state.md && git -c user.name=grafo -c user.email=g@local commit -qm "state: $1" || true); }

node_plan() { log "nodo plan (ronda $1)"; "$S" "$R" "$EV/r$1-plan" "Follow the section '## plan' of nodes.md."; set_st last_node plan; commit_state "plan r$1"; }
node_implement() { log "nodo implement (ronda $1)"; "$S" "$R" "$EV/r$1-implement" "Follow the section '## implement' of nodes.md."; set_st last_node implement; commit_state "implement r$1"; }

verify_one() { # $1 nombre (functional|review) $2 dir-evidencia $3 worktree
  "$S" "$3" "$2" "Follow the section '## verify-$1' of nodes.md."
  cp "$3/verdict-$1.md" "$R/verdict-$1.md" 2>/dev/null || printf 'VERDICT: FAIL\nLAYER: implementation\n1. The verifier did not write verdict-%s.md\n' "$1" > "$R/verdict-$1.md"
  cp "$R/verdict-$1.md" "$2/" 2>/dev/null || true
}
mk_wt() { (cd "$R" && git worktree remove --force "$1" >/dev/null 2>&1; git worktree add -q --detach "$1" HEAD) && ln -s "$R/node_modules" "$1/node_modules"; }
node_verify() { # $1 ronda, $2 modo (paralelo|secuencial)
  local W1="$HOME/harness-runs/p08-wt-func" W2="$HOME/harness-runs/p08-wt-review" T0 T1
  mk_wt "$W1"; mk_wt "$W2"; T0=$(date +%s)
  if [ "$2" = "paralelo" ]; then
    log "fan-out: verify-functional ∥ verify-review (ronda $1, worktrees separados)"
    verify_one functional "$EV/r$1-verify-functional" "$W1" & verify_one review "$EV/r$1-verify-review" "$W2" & wait
  else
    log "verificación secuencial (ronda $1, solo para medir contra el paralelo)"
    verify_one functional "$EV/r$1-seq-verify-functional" "$W1"; verify_one review "$EV/r$1-seq-verify-review" "$W2"
  fi
  T1=$(date +%s); log "fan-in ($2): $((T1-T0)) s de reloj · funcional=$(head -1 "$R/verdict-functional.md") · revisión=$(head -1 "$R/verdict-review.md")"
  echo "$2,$1,$((T1-T0))" >> "$EV/tiempos-verificacion.csv"
  (cd "$R" && git worktree remove --force "$W1"; git worktree remove --force "$W2") >/dev/null 2>&1
  set_st verify_functional "$(head -1 "$R/verdict-functional.md" | sed 's/VERDICT: //')"
  set_st verify_review "$(head -1 "$R/verdict-review.md" | sed 's/VERDICT: //')"
  (cd "$R" && git add verdict-*.md && git -c user.name=grafo -c user.email=g@local commit -qm "verdicts r$1" || true)
}
route() { # devuelve: approval | plan | implement
  local F R2 LF LR; F=$(st verify_functional); R2=$(st verify_review)
  LF=$(sed -n '2p' "$R/verdict-functional.md"); LR=$(sed -n '2p' "$R/verdict-review.md")
  if [ "$F" = "PASS" ] && [ "$R2" = "PASS" ]; then echo approval
  elif echo "$LF $LR" | grep -q "LAYER: requirements"; then echo plan
  else echo implement; fi
}
node_approval() {
  set_st approval pending; set_st requested_at "$(date '+%Y-%m-%dT%H:%M:%S')"; set_st last_node approval
  { echo "# Solicitud de aprobación"; echo
    echo "**Qué pasó:** el grafo implementó la función de feature.md y los dos verificadores dieron PASS (ronda $(st round))."; echo
    echo "**Qué cambió:**"; echo '```'; (cd "$R" && git diff --stat "$(git rev-list --max-parents=0 HEAD | tail -1)" HEAD -- . ':(exclude)package-lock.json' | tail -15); echo '```'; echo
    echo "**Veredictos:**"; echo; echo "- Funcional: $(head -1 "$R/verdict-functional.md")"; echo "- Revisión: $(head -1 "$R/verdict-review.md")"; echo
    echo "**Por qué hace falta una persona:** el merge deja el cambio como definitivo; los verificadores son agentes y pueden coincidir en el mismo punto ciego."; echo
    echo "**Si aprobás:** el nodo merge marca el commit como aprobado (tag \`approved\`)."; echo
    echo "**Si rechazás:** escribí el motivo debajo de \`## Feedback\` en state.md; el grafo vuelve a implement con ese motivo."; echo
    echo "**Cómo decidir:** en state.md cambiá \`approval: pending\` por \`approval: approved\` o \`approval: rejected\` y corré \`scripts/p08-graph.sh resume\`."; echo
    echo "**Timeout:** si nadie responde en el plazo configurado, \`resume\` escala (escribe ESCALATION.md) en lugar de aprobar solo."
  } > "$R/approval-request.md"
  cp "$R/approval-request.md" "$EV/approval-request.md"; commit_state "approval requested"
  (cd "$R" && git add approval-request.md && git -c user.name=grafo -c user.email=g@local commit -qm "approval request" || true)
  log "nodo approval: el grafo se detiene y espera una decisión humana en state.md"
}
run_rounds() {
  local next="$1" r
  while :; do
    r=$(( $(st round) + 1 )); [ "$r" -gt "$MAX_ROUNDS" ] && { log "PARADA: $MAX_ROUNDS rondas sin aprobación de los verificadores"; set_st last_node stopped; return; }
    set_st round "$r"; commit_state "round $r"
    [ "$next" = "plan" ] && node_plan "$r"
    node_implement "$r"
    if [ "$r" -eq 1 ] && [ ! -f "$EV/.medido" ]; then node_verify "$r" secuencial; touch "$EV/.medido"; fi
    node_verify "$r" paralelo
    next=$(route); log "route → $next"
    [ "$next" = "approval" ] && { node_approval; return; }
  done
}

case "${1:-}" in
  start)
    BASE="$2"; rm -rf "$R" "$EV"; mkdir -p "$EV"; echo "# Recorrido del grafo" > "$EV/recorrido.md"; echo "modo,ronda,segundos" > "$EV/tiempos-verificacion.csv"
    cp -R "$BASE" "$R"; rm -rf "$R/.git" "$R/node_modules" "$R/dist" "$R"/verdict-*.md "$R/checker-verdict.md"
    cp "$P/feature.md" "$P/nodes.md" "$R/"
    printf '# state.md (estado compartido del grafo)\n\nfeature: feature.md\nround: 0\nlast_node: start\nverify_functional: none\nverify_review: none\napproval: none\nrequested_at: none\n\n## Feedback\n' > "$R/state.md"
    (cd "$R" && npm install --silent >/dev/null 2>&1 && git init -q && printf 'node_modules/\ndist/\n' >> .git/info/exclude && git add -A && git -c user.name=grafo -c user.email=g@local commit -qm "base P08")
    log "start"; run_rounds plan ;;
  resume)
    TIMEOUT_MIN="${2:-1440}"; A=$(st approval)
    log "resume: approval=$A (timeout $TIMEOUT_MIN min)"
    case "$A" in
      approved) (cd "$R" && git tag -f approved >/dev/null); set_st last_node merge; commit_state "merged"; log "nodo merge: aprobado por una persona, tag 'approved'" ;;
      rejected) set_st approval none; commit_state "rejected"; log "rechazado: vuelve a implement con el feedback humano"; run_rounds implement ;;
      pending)
        AGE=$(( ( $(date +%s) - $(date -j -f '%Y-%m-%dT%H:%M:%S' "$(st requested_at)" +%s) ) / 60 ))
        if [ "$AGE" -ge "$TIMEOUT_MIN" ]; then
          set_st approval escalated; printf '# Escalado\n\nLa solicitud de aprobación lleva %s min sin respuesta (timeout: %s min). No se aprueba sola: queda escalada a otra persona.\n' "$AGE" "$TIMEOUT_MIN" > "$R/ESCALATION.md"
          commit_state "escalated"; log "timeout: $AGE min ≥ $TIMEOUT_MIN → escalado (ESCALATION.md), sin aprobar"
        else log "sigue pendiente ($AGE min < $TIMEOUT_MIN): no hace nada"; fi ;;
      *) log "no hay una aprobación pendiente" ;;
    esac ;;
  *) echo "uso: p08-graph.sh start <repo-base> | resume [timeout-min]"; exit 1 ;;
esac
cp "$R/state.md" "$EV/state-actual.md" 2>/dev/null || true
