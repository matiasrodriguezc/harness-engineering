# AGENTS.md

Electron + TypeScript + React knowledge base: document import, indexing, grounded Q&A with citations, conversation history.

## Start of session

1. Read `session-handoff.md`.
2. Run `bash init.sh`. If it fails, fix the starting state first and commit that fix on its own. Do not stack feature work on a broken baseline.
3. Pick exactly one of the requested features that is not done yet.

## Working rules

- One feature at a time. Do not refactor unrelated code while implementing a feature.
- Commit after each feature that passes, with the feature id in the message.
- Keep the layer boundaries in `docs/ARCHITECTURE.md`: the renderer only talks to the app through `window.knowledgeBase` (exposed by the preload).
- Do not disable Electron's sandbox. If the preload needs shared code, bundle it.

## Definition of done (all three layers, in order)

1. **Static:** `npm run check` and `bash scripts/check-architecture.sh` pass.
2. **Runtime:** automated tests for the feature exist and pass (`npm test`), and `bash scripts/smoke-bridge.sh` passes.
3. **End to end:** you exercised the feature in the running app through `window.knowledgeBase` and the UI (for example with a Chrome DevTools script like `scripts/check-bridge.mjs`).

Only then consider the feature done, and record the evidence (the commands you ran and what they printed) in `session-handoff.md`. "The code looks right" is not evidence.

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
