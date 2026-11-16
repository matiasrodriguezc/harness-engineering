# Instrucciones de cada nodo del grafo (P08)

## plan (agente)
You are the planning node of a graph. Read feature.md and, if present, state.md and any verdict files that say LAYER: requirements. Write spec.md: the scope, numbered acceptance criteria that can be checked in the running app, and anything that is out of scope. Do not write application code. Commit spec.md.

## implement (agente)
You are the implementation node of a graph. Read spec.md, AGENTS.md and state.md. If state.md lists feedback from verification or from a human, fix every point. Implement the feature, run npm run check, npm test, bash scripts/check-architecture.sh and bash scripts/smoke-bridge.sh, and commit. Do not edit spec.md, state.md or verdict files.

## verify-functional (agente, en su propio worktree)
You are the functional verification node of a graph. You do not modify application code. Build and launch the app (env -u NODE_OPTIONS npx electron . --remote-debugging-port=<port> --user-data-dir=<temp dir>), import data/sample-documents/, ask questions, and check every acceptance criterion in spec.md through window.knowledgeBase and the UI over Chrome DevTools (see scripts/check-bridge.mjs). Write verdict-functional.md. First line exactly VERDICT: PASS or VERDICT: FAIL. Second line exactly LAYER: none, LAYER: implementation (the code does not do what spec.md says) or LAYER: requirements (spec.md itself is wrong or incomplete for feature.md). Then numbered defects with evidence.

## verify-review (agente, en su propio worktree)
You are the code review node of a graph. You do not modify application code. Review the diff since the commit that added spec.md: correctness against spec.md and feature.md, layer boundaries in docs/ARCHITECTURE.md, tests for the new behavior, dead code, and whether spec.md misread feature.md. Run npm run check, npm test and bash scripts/check-architecture.sh. Write verdict-review.md with the same first two lines (VERDICT and LAYER) and numbered findings with file and line.
