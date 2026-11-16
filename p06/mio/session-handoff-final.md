# Session Handoff

## Verified Now

- What is currently working: all three features in feature_list.json are `passing`: answer-feedback, reset-all-data, conversation-history. The UI reaches `window.knowledgeBase` (documents, indexing, qa, feedback, app).
- What verification actually ran (2026-11-15, cleanup pass, no feature work): `bash init.sh` -> 'init.sh OK' (types, build, 'PASS: All architecture boundary checks passed', smoke keys 'documents,indexing,qa,feedback,app' 'PASS: the running app exposes window.knowledgeBase'); `npm test` -> 'Test Files 4 passed (4), Tests 22 passed (22)'; real-app e2e re-run: `scripts/e2e/answer-feedback.mjs` 7/7, `scripts/e2e/reset-all-data.mjs` 6/6, `scripts/e2e/conversation-history.mjs` 13/13 (each includes a real app restart on the same data dir and deletes its temp data dir).

## Changed This Session

- Cleanup pass (latest): added `.gitignore` (`node_modules/`, `dist/`; before, these were only ignored via `.git/info/exclude`, so a fresh clone would see them as untracked). `docs/RELIABILITY.md` now says `scripts/benchmark.sh` and `scripts/cleanup-scanner.sh` are not implemented (the doc described them as existing). No source or feature changes.

Earlier in the session:

- Baseline fix (own commit): the preload required `../shared/types`, which a sandboxed preload cannot load, so `window.knowledgeBase` was undefined in the running app. It is now bundled with esbuild (`scripts/build-preload.js`, wired into `npm run build` and `scripts/dev.js`). Fixed renderer type errors (wrong shared-types path, unused React imports).
- answer-feedback: `QAResponse.id` (uuid; old history entries get a stable id on first read), `FeedbackService` (feedback.json, one rating per answer, rejects bad ratings and unknown answer ids), `feedback:submit`/`feedback:list` IPC, `AnswerFeedback` buttons.
- reset-all-data: `app:reset` -> `PersistenceService.resetAll()`, `window.knowledgeBase.app.reset()`, `ResetDataButton` with in-page confirmation dialog.
- conversation-history: App owns history + ratings; `ConversationHistory` chat with `ConfidenceIndicator` and `CitationList` (expand to excerpt); document view switches via sidebar, header "Conversation" button returns. The old "Show History" toggle and single last-answer block are gone.
- Harness: `vitest.config.ts` (tests in `tests/`), `scripts/e2e/app-session.mjs` (launch app, CDP evaluate, restart).

## Broken Or Unverified

- Known defect (pre-existing, not fixed): StatusBar shows "Index:" and "Documents:" with no values. `indexing.status()` returns `{status, currentIndexed, totalDocuments}` but the renderer types it as `AppStatus {indexStatus, documentsLoaded, lastActivity}`.
- Known gap (pre-existing): the "+ Import" button only logs; there is no file picker in the UI. Import works through `window.knowledgeBase.documents.import(path)`. `ImportPanel` exists but is unused.
- Unverified path: the DocumentDetail "Index Document" button does not refresh the document list afterwards.
- Stale doc: `quality-document.md` is the starter's grading snapshot (says no tests, no feedback, no reset). It no longer matches the repo; left untouched as a historical document.
- Missing tooling: `scripts/benchmark.sh` and `scripts/cleanup-scanner.sh` (described in docs/RELIABILITY.md) do not exist.
- Outside the repo: `$TMPDIR/kb-e2e-XXXXXX` dirs (4, dated 2026-11-15 20:49-20:54) predate this repo (created 23:24) and are not produced by any script here; left alone.
- Design choices to know: feedback for an unknown answer id is rejected; rating an answer again replaces the earlier rating, so `feedback.list()` has at most one entry per answer.

## Next Best Step

- Highest-priority unfinished feature: none in feature_list.json. Suggested: fix the StatusBar/indexing status shape mismatch, then a real import file picker.
- Why it is next: both are visible to the user in the running app.
- What counts as passing: same three layers as AGENTS.md; add an e2e script under `scripts/e2e/`.
- What must not change: the preload bundling and the sandbox; the bridge names `feedback.submit/list`, `app.reset`, `qa.ask` returning `id`; the aria-labels 'Mark answer helpful', 'Mark answer not helpful', 'Reset all data'.

## Commands

- Startup: `bash init.sh`
- Verification: `npm test` and, after `env -u NODE_OPTIONS npm run build`, `node --experimental-websocket scripts/e2e/<feature>.mjs`
- Focused debug command: `env -u NODE_OPTIONS npm run dev` (launch by hand)
