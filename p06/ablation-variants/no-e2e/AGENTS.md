# AGENTS.md

Electron + TypeScript + React knowledge base: document import, indexing, grounded Q&A with citations, conversation history.

## Start of session

1. Read `session-handoff.md` and `feature_list.json`.
2. Run `bash init.sh`. If it fails, fix the starting state first and commit that fix on its own. Do not stack feature work on a broken baseline.
3. Pick exactly one feature from `feature_list.json` whose `state` is not `passing`.

## Working rules

- One feature at a time. Do not refactor unrelated code while implementing a feature.
- Commit after each feature that passes, with the feature id in the message.
- Keep the layer boundaries in `docs/ARCHITECTURE.md`: the renderer only talks to the app through `window.knowledgeBase` (exposed by the preload).

## Definition of done

1. `npm run check` and `bash scripts/check-architecture.sh` pass.
2. Automated tests for the feature exist and pass (`npm test`), and you ran the feature's `verification` from `feature_list.json`.

Only then set the feature's `state` to `passing` and write the evidence: the commands you ran and what they printed. "The code looks right" is not evidence.

## End of session

1. Run `bash init.sh` again.
2. Go through `clean-state-checklist.md`.
3. Update `session-handoff.md` (verified, broken or unverified, next step, what must not change) and add an entry to `claude-progress.md`.
4. Commit.

## Map

- Architecture and data flow: `docs/ARCHITECTURE.md`
- Product behavior: `docs/PRODUCT.md`
- Reliability and logging: `docs/RELIABILITY.md`
- Launch by hand: `env -u NODE_OPTIONS npm run dev` (this shell's NODE_OPTIONS breaks Electron)
