All three features work in the running Electron app, not just in unit tests. Each is marked `passing` in `feature_list.json` with the commands I ran and their output, and everything is committed (one commit per feature, plus separate fixes and docs).

**The starter app was broken in two ways, which I fixed first in their own commits:**
- `init.sh` failed on type errors.
- **`window.knowledgeBase` didn't exist in the running app.** Electron runs the preload script in a sandbox, and a sandboxed preload can't load the other project file it imported. The script failed at startup, so nothing the page needed was ever exposed. The build now bundles the preload into one file with esbuild, and the sandbox stays on.
- I also fixed three smaller bugs on the way:
  - The status bar showed `Index: undefined`.
  - The "+ Import" button only logged to the console.
  - Indexing a single document didn't make its chunks available to Q&A, so answers about it had no citations.

**The features:**
1. **Answer feedback:** every answer from `qa.ask` has a unique string `id`. `feedback.submit(answerId, 'up'|'down')` saves the rating to disk, and `feedback.list()` returns `[{answerId, rating, timestamp}]`. Rating the same answer again replaces the old rating. An invalid rating or an id that isn't in the Q&A history is rejected with an error. Each answer shows the "Mark answer helpful" and "Mark answer not helpful" buttons.
2. **Reset:** `app.reset()` deletes the whole data folder (documents, chunks, history and feedback). The "Reset all data" button shows a confirm/cancel step inside the page before resetting.
3. **Conversation:** the question panel now shows the full history as a chat. Questions are on the right; answers are on the left with collapsible citations that open to the excerpt, a High/Medium/Low confidence bar, the rating buttons and a timestamp. It replaces the old "Show History" toggle.

**How it was verified:**
- `bash init.sh` passes.
- `npm test` runs 22 tests, all passing.
- `bash scripts/verify-app.sh` passes for all three features. This is a new script: it starts the real built app with a temporary data folder and drives the page through `window.knowledgeBase` and the UI, closing and relaunching Electron between steps to test persistence. It covers:
  - asking, rating, restarting, and checking the ratings are still there
  - importing, asking, rating, resetting, and checking it stays empty after a restart, both through the UI's confirm step and by calling `app.reset()` directly
  - asking two questions, reloading, restarting, and expanding citations

**Still open:**
- **Deleting a document leaves its chunks behind** (this was already the case), so it can still show up in citations as "Unknown Document". I left it alone because it's outside these three features; it's the suggested next step in `session-handoff.md`.
- The native file picker behind "+ Import" was never actually opened during testing. The tests imported documents by calling `documents.import(path)` instead.
- If you call `app.reset()` from devtools, the open window doesn't update until you click Refresh or restart. The Reset button does update it.