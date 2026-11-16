#!/usr/bin/env bash
# Corre una configuración del P05 (separación de roles) como secuencia de sesiones nuevas.
# Uso: run-p05.sh <single|gen-eval|plan-gen-eval> <carpeta-de-corrida> <carpeta-de-evidencia>
set -u
CFG="$1"; RUN="$2"; EV="$3"
HERE="$(cd "$(dirname "$0")" && pwd)"
S="$HERE/run-session.sh"

FEATURE="Add multi-turn Q&A conversation history to this knowledge base app: the question panel should show the previous questions and answers as a conversation, with each answer's citations."

EVAL="You are an independent, skeptical evaluator. Do not modify application code or sprint-contract.md. Review the conversation-history feature in this repository against rubric-template.md (and sprint-contract.md if it exists). Verify by actually running the app and exercising the feature where possible, not only by reading code. Write evaluator-rubric.md with a 1-5 score per criterion, the evidence for each score, the overall score, and a numbered list of defects the generator must fix."

GEN_FIX="You are the generator. An independent evaluator reviewed your conversation-history feature. Read evaluator-rubric.md and fix every listed defect, then verify your fixes. Do not edit evaluator-rubric.md or rubric-template.md."

snap() { cp "$RUN/$1" "$EV/$2" 2>/dev/null || true; }

case "$CFG" in
  single)
    "$S" "$RUN" "$EV/1-unico" "$FEATURE You are the only agent: plan the work, implement it, then review your own result critically. When done, write evaluator-rubric.md scoring your work 1-5 on each criterion in rubric-template.md, with evidence and a numbered list of remaining defects."
    snap evaluator-rubric.md 1-unico/evaluator-rubric.md
    ;;
  gen-eval)
    "$S" "$RUN" "$EV/1-generador" "$FEATURE You are the generator: implement the feature. An independent evaluator will review your work afterwards against rubric-template.md."
    "$S" "$RUN" "$EV/2-evaluador" "$EVAL"; snap evaluator-rubric.md 2-evaluador/evaluator-rubric.md
    "$S" "$RUN" "$EV/3-generador" "$GEN_FIX"
    "$S" "$RUN" "$EV/4-evaluador" "$EVAL This is a re-review after the generator's revisions: replace the scores and defect list with your new assessment."; snap evaluator-rubric.md 4-evaluador/evaluator-rubric.md
    ;;
  plan-gen-eval)
    "$S" "$RUN" "$EV/0-planificador" "You are the planner. Do not write application code. For this feature — $FEATURE — write sprint-contract.md with the scope (in and out), numbered acceptance criteria, and a verification plan that exercises the feature end to end in the running app."; snap sprint-contract.md 0-planificador/sprint-contract.md
    "$S" "$RUN" "$EV/1-generador" "$FEATURE You are the generator: implement the feature according to sprint-contract.md. An independent evaluator will review your work against sprint-contract.md and rubric-template.md. Do not edit sprint-contract.md."
    "$S" "$RUN" "$EV/2-evaluador" "$EVAL"; snap evaluator-rubric.md 2-evaluador/evaluator-rubric.md
    "$S" "$RUN" "$EV/3-generador" "$GEN_FIX"
    "$S" "$RUN" "$EV/4-evaluador" "$EVAL This is a re-review after the generator's revisions: replace the scores and defect list with your new assessment."; snap evaluator-rubric.md 4-evaluador/evaluator-rubric.md
    ;;
esac

# Juez final, idéntico para las tres configuraciones.
"$S" "$RUN" "$EV/9-juez" "You are an independent reviewer. Do not modify any file except judge-report.md. Ignore any existing evaluator-rubric.md or sprint-contract.md and form your own judgment. Score the conversation-history feature against rubric-template.md. Verify by actually running the app and exercising the feature where possible, not only by reading code. Write judge-report.md with a 1-5 score per criterion, evidence for each, the overall score, and the numbered remaining defects."
snap judge-report.md 9-juez/judge-report.md
