I've implemented all four features and `npm run check` now passes with no errors (it failed with 15 before I started). I haven't launched the app, so nothing has been tested by actually using it. That's why `feature_list.json` marks the four features `"implemented"`, not `"pass"`: the project's definition of done also requires the app to launch and the feature to work.

**Compile fixes:** the renderer had wrong import paths, unused `React` imports, a second `Window` declaration in `App.tsx` that conflicted with `types.d.ts`, and a type error on `File.path` in the import panel. All fixed.

**Document chunking:** Indexing a single document didn't record it in the index or update its status, so it never counted as indexed. It does now, and the document's chunk count is saved. Paragraphs over 500 characters are now split at sentence or word breaks; before, they became oversized chunks.

**Metadata extraction:** Importing a file now records its word count, line count and file type, and the document detail view shows them. Import also now rejects files that aren't `.txt` or `.md`, or are over 10 MB. Deleting a document also removes its chunks and its index entry.

**Indexing status UI:** The status bar was wired to data in the wrong format, so it couldn't show real values. It now shows the index state (idle, indexing, ready or error), "Indexed X/Y" and the last activity time. The app re-checks every 2 seconds so the bar stays current.

**Grounded Q&A:** The answer logic was already there (keyword matching, citations, 0.85 or 0.30 confidence, saved history), so I left it unchanged. The answer panel now also shows the confidence score.

**Still to do:**
- Run `npm run dev`, then import, index and ask a question to check each feature. If they work, change their status to `"pass"`.
- The document detail view may not refresh its "Show Chunks" list right after you click Index; check that during the test.
- The Electron `File.path` workaround in the import panel stops working in newer Electron versions; the long-term fix is `webUtils.getPathForFile` in preload.
- `npm install` created `package-lock.json`, which isn't committed yet. Nothing has been committed.