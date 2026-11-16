All three features work in the running app. Each passed type check, the architecture check, unit/integration tests (18 of 18) and an end-to-end script. Those scripts launch the real Electron app with its own data folder, use the UI and `window.knowledgeBase`, then restart it to check what was saved.

**First I had to fix the starting point (separate commit).** It didn't type-check: wrong import paths and unused imports. The preload also loaded a local file, which Electron's sandbox blocks, so `window.knowledgeBase` would not have existed. I fixed this by bundling the preload with esbuild; the sandbox stays on.

**1. Answer feedback**
- Every answer from `qa.ask` now has a unique string `id`. Answers saved earlier without one get an id the first time history is loaded.
- `feedback.submit(answerId, 'up'|'down')` and `feedback.list()` return `{answerId, rating, timestamp}` and are saved in `feedback.json`.
- Each answer has the two buttons with the requested labels, and the chosen one stays highlighted.
- Each answer keeps one rating; rating it again replaces the old one. Any rating other than `'up'` or `'down'` is rejected.
- Checked: clicking in the UI and calling the API both save ratings, and they are identical after a restart.

**2. Reset all data**
- `app.reset()` deletes the whole data folder: documents, chunks, index, Q&A history and feedback.
- The 'Reset all data' button opens a confirmation dialog inside the page. Cancel keeps everything.
- Checked: confirming empties everything (18 chunks before, 0 after), the UI shows the empty state, it stays empty after a restart, and you can import again afterwards.

**3. Conversation history**
- The question panel always shows the full saved history as a chat.
- Each answer has citations that start collapsed and expand to the excerpt, a high/medium/low confidence bar with a percentage, a timestamp and the feedback buttons.
- Checked: answers appear in order and match the saved history, expanding a citation shows the exact excerpt, and the conversation comes back unchanged after a restart. I also looked at a screenshot.
- This replaced the old "Show History" toggle and the single latest-answer box. If you open a document, its details show above the conversation.

**Existing bugs I left alone (written up in `session-handoff.md`):**
- The status bar shows empty values because it expects a different format from the indexing status it receives.
- Documents still show "imported" after indexing.
- The "+ Import" button only writes to the console, so for now you can only import through `window.knowledgeBase.documents.import(path)`.
- If you reset while a question is still being answered, that answer could be written back into the new history.

To re-run the checks: `bash init.sh`, `npm test`, then `env -u NODE_OPTIONS npm run build && npm run e2e`. There are five commits: the baseline fix, one per feature, and the session notes.