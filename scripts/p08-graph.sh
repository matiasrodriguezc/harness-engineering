#!/usr/bin/env bash
# P08 · Explicit graph: plan → implement → (verify-functional ∥ verify-review) → route → approval (human) → merge.
# Agent nodes are new sessions; routing, the approval request and the timeout are code.
# Usage: p08-graph.sh start <base-repo>      (runs until the approval node and stops)
#        p08-graph.sh resume [timeout-min]   (reads the human decision in state.md and continues)
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; EV="$HERE/../p08/3-graph"; P="$HERE/../p08/prompts"
R="$HOME/harness-runs/p08-graph"; S="$HERE/run-session.sh"; MAX_ROUNDS=4
mkdir -p "$EV"
st() { grep -m1 "^$1:" "$R/state.md" | sed "s/^$1: *//"; }
set_st() { python3 -I -c "import re,sys; p,k,v=sys.argv[1:]; s=open(p).read(); s=re.sub(r'(?m)^'+re.escape(k)+r':.*$', k+': '+v, s) if re.search(r'(?m)^'+re.escape(k)+r':', s) else s.replace('## Feedback', k+': '+v+'\n\n## Feedback',1); open(p,'w').write(s)" "$R/state.md" "$1" "$2"; }
log() { echo "- $(date '+%H:%M:%S') · $*" | tee -a "$EV/run-log.md"; }
commit_state() { (cd "$R" && git add state.md && git -c user.name=graph -c user.email=g@local commit -qm "state: $1" || true); }

node_plan() { log "plan node (round $1)"; "$S" "$R" "$EV/r$1-plan" "Follow the section '## plan' of nodes.md."; set_st last_node plan; commit_state "plan r$1"; }
node_implement() { log "implement node (round $1)"; "$S" "$R" "$EV/r$1-implement" "Follow the section '## implement' of nodes.md."; set_st last_node implement; commit_state "implement r$1"; }

verify_one() { # $1 name (functional|review) $2 evidence-dir $3 worktree
  "$S" "$3" "$2" "Follow the section '## verify-$1' of nodes.md."
  cp "$3/verdict-$1.md" "$R/verdict-$1.md" 2>/dev/null || printf 'VERDICT: FAIL\nLAYER: implementation\n1. The verifier did not write verdict-%s.md\n' "$1" > "$R/verdict-$1.md"
  cp "$R/verdict-$1.md" "$2/" 2>/dev/null || true
}
mk_wt() { (cd "$R" && git worktree remove --force "$1" >/dev/null 2>&1; git worktree add -q --detach "$1" HEAD) && ln -s "$R/node_modules" "$1/node_modules"; }
node_verify() { # $1 round, $2 mode (parallel|sequential)
  local W1="$HOME/harness-runs/p08-wt-func" W2="$HOME/harness-runs/p08-wt-review" T0 T1
  mk_wt "$W1"; mk_wt "$W2"; T0=$(date +%s)
  if [ "$2" = "parallel" ]; then
    log "fan-out: verify-functional ∥ verify-review (round $1, separate worktrees)"
    verify_one functional "$EV/r$1-verify-functional" "$W1" & verify_one review "$EV/r$1-verify-review" "$W2" & wait
  else
    log "sequential verification (round $1, only to measure against the parallel one)"
    verify_one functional "$EV/r$1-seq-verify-functional" "$W1"; verify_one review "$EV/r$1-seq-verify-review" "$W2"
  fi
  T1=$(date +%s); log "fan-in ($2): $((T1-T0)) s wall clock · functional=$(head -1 "$R/verdict-functional.md") · review=$(head -1 "$R/verdict-review.md")"
  echo "$2,$1,$((T1-T0))" >> "$EV/verification-times.csv"
  (cd "$R" && git worktree remove --force "$W1"; git worktree remove --force "$W2") >/dev/null 2>&1
  set_st verify_functional "$(head -1 "$R/verdict-functional.md" | sed 's/VERDICT: //')"
  set_st verify_review "$(head -1 "$R/verdict-review.md" | sed 's/VERDICT: //')"
  (cd "$R" && git add verdict-*.md && git -c user.name=graph -c user.email=g@local commit -qm "verdicts r$1" || true)
}
route() { # returns: approval | plan | implement
  local F R2 LF LR; F=$(st verify_functional); R2=$(st verify_review)
  LF=$(sed -n '2p' "$R/verdict-functional.md"); LR=$(sed -n '2p' "$R/verdict-review.md")
  if [ "$F" = "PASS" ] && [ "$R2" = "PASS" ]; then echo approval
  elif echo "$LF $LR" | grep -q "LAYER: requirements"; then echo plan
  else echo implement; fi
}
node_approval() {
  set_st approval pending; set_st requested_at "$(date '+%Y-%m-%dT%H:%M:%S')"; set_st last_node approval
  { echo "# Approval request"; echo
    echo "**What happened:** the graph implemented the feature in feature.md and both verifiers gave PASS (round $(st round))."; echo
    echo "**What changed:**"; echo '```'; (cd "$R" && git diff --stat "$(git rev-list --max-parents=0 HEAD | tail -1)" HEAD -- . ':(exclude)package-lock.json' | tail -15); echo '```'; echo
    echo "**Verdicts:**"; echo; echo "- Functional: $(head -1 "$R/verdict-functional.md")"; echo "- Review: $(head -1 "$R/verdict-review.md")"; echo
    echo "**Why a person is needed:** the merge makes the change final; the verifiers are agents and can share the same blind spot."; echo
    echo "**If you approve:** the merge node marks the commit as approved (tag \`approved\`)."; echo
    echo "**If you reject:** write the reason under \`## Feedback\` in state.md; the graph goes back to implement with that reason."; echo
    echo "**How to decide:** in state.md change \`approval: pending\` to \`approval: approved\` or \`approval: rejected\` and run \`scripts/p08-graph.sh resume\`."; echo
    echo "**Timeout:** if nobody answers within the configured time, \`resume\` escalates (writes ESCALATION.md) instead of approving on its own."
  } > "$R/approval-request.md"
  cp "$R/approval-request.md" "$EV/approval-request.md"; commit_state "approval requested"
  (cd "$R" && git add approval-request.md && git -c user.name=graph -c user.email=g@local commit -qm "approval request" || true)
  log "approval node: the graph stops and waits for a human decision in state.md"
}
run_rounds() {
  local next="$1" r
  while :; do
    r=$(( $(st round) + 1 )); [ "$r" -gt "$MAX_ROUNDS" ] && { log "STOP: $MAX_ROUNDS rounds without approval from the verifiers"; set_st last_node stopped; return; }
    set_st round "$r"; commit_state "round $r"
    [ "$next" = "plan" ] && node_plan "$r"
    node_implement "$r"
    if [ "$r" -eq 1 ] && [ ! -f "$EV/.measured" ]; then node_verify "$r" sequential; touch "$EV/.measured"; fi
    node_verify "$r" parallel
    next=$(route); log "route → $next"
    [ "$next" = "approval" ] && { node_approval; return; }
  done
}

case "${1:-}" in
  start)
    BASE="$2"; rm -rf "$R" "$EV"; mkdir -p "$EV"; echo "# Graph run log" > "$EV/run-log.md"; echo "mode,round,seconds" > "$EV/verification-times.csv"
    cp -R "$BASE" "$R"; rm -rf "$R/.git" "$R/node_modules" "$R/dist" "$R"/verdict-*.md "$R/checker-verdict.md"
    cp "$P/feature.md" "$P/nodes.md" "$R/"
    printf '# state.md (shared graph state)\n\nfeature: feature.md\nround: 0\nlast_node: start\nverify_functional: none\nverify_review: none\napproval: none\nrequested_at: none\n\n## Feedback\n' > "$R/state.md"
    (cd "$R" && npm install --silent >/dev/null 2>&1 && git init -q && printf 'node_modules/\ndist/\n' >> .git/info/exclude && git add -A && git -c user.name=graph -c user.email=g@local commit -qm "base P08")
    log "start"; run_rounds plan ;;
  resume)
    TIMEOUT_MIN="${2:-1440}"; A=$(st approval)
    log "resume: approval=$A (timeout $TIMEOUT_MIN min)"
    case "$A" in
      approved) (cd "$R" && git tag -f approved >/dev/null); set_st last_node merge; commit_state "merged"; log "merge node: approved by a person, tag 'approved'" ;;
      rejected) set_st approval none; commit_state "rejected"; log "rejected: back to implement with the human feedback"; run_rounds implement ;;
      pending)
        AGE=$(( ( $(date +%s) - $(date -j -f '%Y-%m-%dT%H:%M:%S' "$(st requested_at)" +%s) ) / 60 ))
        if [ "$AGE" -ge "$TIMEOUT_MIN" ]; then
          set_st approval escalated; printf '# Escalated\n\nThe approval request has gone %s min without an answer (timeout: %s min). It does not approve itself: it is escalated to another person.\n' "$AGE" "$TIMEOUT_MIN" > "$R/ESCALATION.md"
          commit_state "escalated"; log "timeout: $AGE min ≥ $TIMEOUT_MIN → escalated (ESCALATION.md), not approved"
        else log "still pending ($AGE min < $TIMEOUT_MIN): does nothing"; fi ;;
      *) log "there is no pending approval" ;;
    esac ;;
  *) echo "usage: p08-graph.sh start <base-repo> | resume [timeout-min]"; exit 1 ;;
esac
cp "$R/state.md" "$EV/state-current.md" 2>/dev/null || true
