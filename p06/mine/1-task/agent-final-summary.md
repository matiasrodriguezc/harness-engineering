All three features now work in the running app and are marked `passing` in `feature_list.json`. Each one passed type checking, the architecture check, `npm test` (22/22) and the bridge smoke test. Each one also has an end-to-end script that drives the real app and restarts it on the same data folder.

**The starting code was broken, so I fixed that first, in its own commit.** In the running app `window.knowledgeBase` was `undefined`, so no button in the UI could reach the app. The cause was that the preload imported `../shared/types`, which Electron's sandboxed preload can't load. The build now bundles the preload into a single file with esbuild (`scripts/build-preload.js`), and the sandbox stays on. I also fixed the TypeScript errors that were making `init.sh` fail.

**1. Answer feedback** (end-to-end 7/7)
- Every answer from `qa.ask` has a unique id. Answers saved before this change get an id the first time history is read, and it doesn't change after that.
- `feedback.submit(answerId, 'up'|'down')` and `feedback.list()` work, and ratings are still there after a restart.
- Each answer shows the two buttons, labelled 'Mark answer helpful' and 'Mark answer not helpful'. The active one stays highlighted.
- I made two choices you may want changed:
  - A rating with any value other than `'up'` or `'down'` is rejected, and so is an answer id that doesn't exist.
  - Rating the same answer again replaces the earlier rating, so `feedback.list()` has at most one entry per answer.

**2. Reset all data** (end-to-end 6/6)
- `app.reset()` deletes documents, chunks, the index, Q&A history and feedback, and everything is still empty after a restart.
- The 'Reset all data' button opens a confirmation box in the page. Cancel deletes nothing.

**3. Conversation history** (end-to-end 13/13)
- The main panel above the question box is now the conversation: questions on the right, answers on the left, loaded from saved history when the app starts.
- Each answer shows a confidence meter (high/medium/low with a percentage), sources that expand to show the excerpt, the feedback buttons and a time.
- It checks out after asking, after a reload and after a restart. I also looked at a screenshot to confirm the layout.
- Clicking a document in the sidebar shows its details; the new "Conversation" button in the header goes back. This replaces the old "Show History" toggle and the single last-answer box.

**Problems from the starting code that I left alone:**
- **Status bar:** it shows "Index:" and "Documents:" with no values. The app sends a different set of status fields than the status bar reads. Before the fix the UI had no data at all, so this didn't show.
- **Import button:** "+ Import" only writes to the console. In the UI there is no way to pick a file, so documents can only be imported through `window.knowledgeBase.documents.import(path)`.

Both are written up in `session-handoff.md` as suggested next steps.

To re-run a check yourself, build with `env -u NODE_OPTIONS npm run build`, then run `node --experimental-websocket scripts/e2e/<feature>.mjs`. There is one script per feature, all built on a shared helper in `scripts/e2e/app-session.mjs`.

There are five commits: the baseline fix, one per feature, and a final one updating the docs, handoff and progress log.