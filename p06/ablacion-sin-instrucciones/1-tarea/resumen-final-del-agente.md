All three features work in the running Electron app. I checked them with a script that launches the real app, uses both the API and the UI, and restarts it twice. All 22 checks pass, as do the type check, `bash init.sh` and the 7 new unit tests.

**Fixes needed first.** The starter couldn't work as shipped:
- **Type errors:** `npm run check` failed because of wrong import paths and unused imports.
- **No API in the window:** the preload loaded a local file (`../shared/types`), which Electron's sandbox blocks. So `window.knowledgeBase` didn't exist and no button in the UI could reach the app. The preload is now bundled into one file with esbuild, in both `build` and `dev`. I added esbuild as a dev dependency, at the version that was already installed.
- **Launch failure:** `npm run dev` now removes `NODE_OPTIONS` before starting Electron. Your shell has `--openssl-legacy-provider` set, and Electron refuses to start with it.

**1. Answer feedback**
- Every answer now has a unique string `id`. Older saved history entries get an id the first time they load, and keep it.
- `feedback.submit(answerId, 'up'|'down')` rejects any other rating. Rating the same answer again replaces the earlier rating, so each answer has at most one.
- `feedback.list()` returns `{answerId, rating, timestamp}`. Ratings are saved in `feedback.json` and survive restarts.
- Each answer shows 👍 / 👎 buttons with the aria-labels you specified. The saved rating shows as pressed.

**2. Reset all data**
- `app.reset()` deletes the whole data folder (documents, chunks, history and feedback) and recreates it empty. It stays empty after a restart.
- The "Reset all data" button asks for confirmation on the page itself, with "Yes, reset" and "Cancel".

**3. Conversation history**
- The question panel shows the full history as chat bubbles. It loads on startup and scrolls to the newest message.
- Each answer lists its sources. Clicking one expands it to show the excerpt.
- Each answer has a confidence bar and label, e.g. "85% (High)".
- I removed the old Show/Hide History toggle, since the panel now always shows everything.

**Tests and scripts added**
- `tests/services.test.ts`, run with `npm test`.
- `scripts/e2e-features.mjs`, run with `npm run test:e2e`. It builds the app, then checks all three features in the real app.
- I updated `feature_list.json` (all three features marked passing, with evidence), `claude-progress.md` and `session-handoff.md`.

**Still not working (unchanged from the starter):**
- The "+ Import" button only writes a message to the console. Documents can only be added by calling `window.knowledgeBase.documents.import(path)` from the developer console.
- The "Index Document" button doesn't refresh the document list.
- When documents exist but none match the question, the answer still says "No relevant documents have been indexed yet".

Nothing is committed yet; that includes the new `package-lock.json`. Tell me if you want me to commit.