Round 1 is done and committed as `402c7ee`. Document search works through the bridge and in the UI, and everything I ran passed.

**What I built**
- **Search function:** `window.knowledgeBase.documents.search(query)` returns the documents whose title or saved text contains the query, ignoring case. The query is matched as plain text, not as a pattern. An empty query returns every document.
- **Search box:** the document list now has an input labelled 'Search documents' that filters the list as you type. Clearing it shows all documents again. If nothing matches, it says "No documents match …". Each keystroke runs a new search, and only the newest result is shown, so a slow older search can't replace a newer one.
- `docs/ARCHITECTURE.md` now covers the new search channel. I added `document-search` to `feature_list.json` as `active` rather than `passing`, because the Checker decides that.

**Verification**
- `bash init.sh` passed at the start and the end.
- `npm run check` and `bash scripts/check-architecture.sh` passed, and `bash scripts/smoke-bridge.sh` showed the app exposes `window.knowledgeBase`.
- `npm test`: 38/38 pass, including 16 new tests for search.
- New test that runs the real app, `scripts/e2e/document-search.mjs`: 10/10. It imports the 3 sample documents, then checks title, content, mixed-case, no-match and empty searches. It also types in the box one key at a time and clears it.
- Tests for the earlier features still pass when run in the real app: answer-feedback 7/7, reset-all-data 6/6, conversation-history 13/13.

The first run of the new app test failed because my test was wrong, not the app. I expected "design" to match only design-notes, but retrieval-plan's text also contains it. I changed the query to "Design-Notes", which appears only in a title.

**Choices I flagged in `loop-state.md` for the Checker**
- Spaces around a query are removed, and a query of only spaces counts as empty. Read literally, the spec might want the spaces kept.
- The "Documents (N)" header still shows the total, not how many match.
- The search box clears on Reset only, not on Refresh or when you switch views.