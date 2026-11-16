#!/usr/bin/env bash
# Corre una variante del P06: arma la carpeta, corre la sesión del agente con la tarea fija,
# opcionalmente una pasada de limpieza, compila y corre la suite de aceptación oculta.
# Uso: run-p06.sh <nombre> <carpeta-del-harness|-> <carpeta-de-evidencia> [limpieza]
set -u
NAME="$1"; HARNESS="$2"; EV="$3"; CLEANUP="${4:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
STARTER=/Users/matiasrodriguezc/Desktop/learn-harness-engineering/projects/project-06/starter
RUN="$HOME/harness-runs/p06-$NAME"

TASK="Implement these three features in this knowledge base app.
1. Answer feedback: users can rate each answer as helpful or not helpful. Every answer returned by window.knowledgeBase.qa.ask must include a unique string id. Expose window.knowledgeBase.feedback.submit(answerId, rating), where rating is 'up' or 'down', and window.knowledgeBase.feedback.list(), which returns an array of {answerId, rating, timestamp}. Ratings persist across app restarts. In the UI, each answer has two buttons with aria-label 'Mark answer helpful' and 'Mark answer not helpful'.
2. Reset all data: expose window.knowledgeBase.app.reset(), which deletes all documents, chunks, Q&A history and feedback, so the app returns to an empty state that persists after a restart. In the UI, a button with aria-label 'Reset all data' asks for confirmation before resetting.
3. Conversation history: the question panel shows the full Q&A history as a conversation, each answer with its citations (expandable to show the excerpt) and a confidence indicator.
The features must work in the running app."

rm -rf "$RUN"; cp -R "$STARTER" "$RUN"
if [ "$HARNESS" != "-" ]; then cp -R "$HARNESS"/. "$RUN"/; fi
mkdir -p "$EV"
(cd "$RUN" && git init -q && printf 'node_modules/\ndist/\n' >> .git/info/exclude && git add -A && git -c user.name=run -c user.email=run@local commit -qm "starter P06 ($NAME)")

"$HERE/run-session.sh" "$RUN" "$EV/1-tarea" "$TASK"
if [ "$CLEANUP" = "limpieza" ]; then
  (cd "$RUN" && npm install --silent >/dev/null 2>&1; env -u NODE_OPTIONS npm run build >/dev/null 2>&1)
  node --experimental-websocket "$HERE/p06-acceptance.mjs" "$RUN" 9343 2>/dev/null > "$EV/aceptacion-antes-de-limpieza.json"
  "$HERE/run-session.sh" "$RUN" "$EV/2-limpieza" "Do a cleanup pass on this repository: run bash init.sh, go through clean-state-checklist.md, remove leftovers, fix anything that fails, make sure every feature marked passing in feature_list.json still passes its verification, and update session-handoff.md and claude-progress.md. Do not add new features."
fi
(cd "$RUN" && npm install --silent >/dev/null 2>&1; env -u NODE_OPTIONS npm run build > "$EV/build.txt" 2>&1; echo "build-exit=$?" >> "$EV/build.txt")
node --experimental-websocket "$HERE/p06-acceptance.mjs" "$RUN" 9343 2>/dev/null > "$EV/aceptacion.json"
(cd "$RUN" && git log --oneline > "$EV/historial-git.txt"; git diff HEAD~0 --stat >/dev/null)
python3 -I -c "import json,sys; d=json.load(open(sys.argv[1])); print(sys.argv[2], d['passed'], '/', d['total'])" "$EV/aceptacion.json" "$NAME" | tee -a "$(dirname "$EV")/resumen-aceptacion.txt"
