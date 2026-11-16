# loop-state.md

Loop: maker-checker for document search. Stops after 2 PASS in a row or 6 rounds.

## Round 1

### Maker (round 1)

**What changed**
- `DocumentService.searchDocuments(query)`: case-insensitive substring match on `title` or stored content (`content/<id>.txt`). Blank query (`''`, whitespace, `undefined`/`null`) returns `listDocuments()`. Non-blank query is trimmed. Literal text, not regex. Non-string query -> `TypeError`.
- New IPC channel `documents:search` (`IPC_CHANNELS.SEARCH_DOCUMENTS`) -> handler -> preload `documents.search(query)`; renderer type in `types.d.ts`.
- UI: `DocumentList` now always renders `<input type="search" aria-label="Search documents">`. `App` keeps `searchQuery`; on every change (and when the document set changes) it calls `documents.search`; a sequence counter makes only the latest response apply. Blank query shows `documents` directly (no IPC). No match -> "No documents match "<q>"." (role=status). Zero documents -> the existing "No documents imported yet." message (input still shown). Reset clears the query. Header "Documents (N)" still shows the total, not the filtered count.
- Docs: `docs/ARCHITECTURE.md` (preload API, 15 channels, table row, DocumentList). `feature_list.json`: new `document-search`, state `active` (left for the Checker to decide).

**Files**: `src/services/document-service.ts`, `src/shared/types.ts`, `src/main/ipc-handlers.ts`, `src/preload/preload.ts`, `src/renderer/types.d.ts`, `src/renderer/App.tsx`, `src/renderer/components/DocumentList.tsx`, `tests/document-search.test.tsx` (new, 16 tests), `scripts/e2e/document-search.mjs` (new), `docs/ARCHITECTURE.md`, `feature_list.json`, `session-handoff.md`, `claude-progress.md`.

**Verification (Maker, 2026-11-16)**
- `bash init.sh` (start) -> `init.sh OK` on the untouched baseline.
- `npm run check` -> no errors.
- `npm test` -> `Test Files 5 passed (5)`, `Tests 38 passed (38)` (was 22; +16 in document-search.test.tsx: title/content match, case, multiple matches, blank query, no match, literal `$5.00 (approx`, deleted docs excluded, restart, non-string rejected, preload channel, IPC handler, DocumentList input/filtered/no-match/empty).
- `bash scripts/check-architecture.sh` -> `PASS: All architecture boundary checks passed`.
- `bash scripts/smoke-bridge.sh` -> keys `documents,indexing,qa,feedback,app`, `PASS: the running app exposes window.knowledgeBase`.
- `env -u NODE_OPTIONS npm run build && node --experimental-websocket scripts/e2e/document-search.mjs` -> `all 10 checks passed` (real app, 3 sample docs: bridge title/content/empty/no-match; UI typing "ATTENDEES" keystroke-by-keystroke -> only meeting-summary; "Design-Notes" -> only design-notes; no match -> empty list + message; clearing -> all 3).
- Regression e2e: answer-feedback 7/7, reset-all-data 6/6, conversation-history 13/13.
- `bash init.sh` (end) -> `init.sh OK`.
- First e2e run failed on MY test expectation: I expected "design" to match only design-notes, but retrieval-plan's content contains "design"; the app was right. Changed the query to "Design-Notes" (title-only).

**Unsure about (please check)**
1. Trimming: `"  zebra "` searches for `zebra`. The spec says "contains query"; a literal reading would search with the spaces. Whitespace-only is treated as empty.
2. "Documents (N)" header shows the total, not the filtered count. Spec does not say.
3. Search is content-based via the main process, so each keystroke is one IPC call (no debounce). Fine for the sample size; not measured on large libraries.
4. Stale `content/<id>.txt` files of deleted docs are not deleted by `deleteDocument` (pre-existing), but search only scans listed docs, so they don't show up (unit test covers this).
5. The search input is not cleared when switching to a document view or on Refresh (only on Reset).
6. No UI import picker exists (pre-existing); e2e imports via `window.knowledgeBase.documents.import(path)`.

### Checker (round 1)

**Verdict: PASS**

**Defects:** none blocking.
**Observations (non-blocking):**
1. The query is trimmed: `search("attendees ")` -> `["meeting-summary"]`, but a literal "contains" check returns `[]`. `"   "` returns all docs.
2. The header count shows the total, not the filtered count.
3. A bridge import needs a Refresh before the list updates (this was already the case).

**What I ran:** `npm run check`, `npm test` (38/38), `check-architecture.sh` (PASS), `smoke-bridge.sh` (PASS), `npm run build`. The Maker's e2e scripts: document-search 10/10, answer-feedback 7/7, reset-all-data 6/6, conversation-history 13/13. My own `evaluation/checker-round1.mjs` (real CDP keystrokes, results checked against a brute-force oracle, plus ask/conversation/import regressions): 28/28 passed. Details are in `checker-verdict.md`.

## Round 2

### Maker (round 2)

No Maker changes this round. The application code is unchanged since 402c7ee.

### Checker (round 2)

**Verdict: PASS** (second PASS in a row)

**Defects:** none.
**Observations (non-blocking):** the same as round 1: the query is trimmed, the header shows the total count, and a bridge import or delete needs a Refresh. Out of scope and pre-existing: asking "What are the meeting attendees?" cites retrieval-plan and design-notes, not meeting-summary. This is retrieval quality; the search change doesn't touch Q&A or retrieval code.

**What I ran:** `npm run check`, `npm test` (38/38), `check-architecture.sh` (PASS), `smoke-bridge.sh` (PASS), `npm run build`. Regression: document-search 10/10, answer-feedback 7/7, reset-all-data 6/6, conversation-history 13/13, checker-round1 28/28. New `evaluation/checker-round2.mjs` checked results against an oracle: 35/35 passed. It covered non-ASCII case-insensitivity, a match at the end of a ~120 KB file, title-only matches, rejection of bad input, rapid and concurrent keystrokes and stale-response races, paste, select-all-clear, delete while filtered, a real restart, Reset with a filter active, re-import after Reset, and asking with a filter active. Details are in `checker-verdict.md`.

Under the loop rule (stop after 2 PASS in a row), the loop can stop here.
