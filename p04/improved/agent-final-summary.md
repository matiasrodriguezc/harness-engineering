I found and fixed the bug. When a document was longer than 1000 characters, the indexing step threw away the text of every chunk it made from it.

**Root cause:** `chunkDocument` in `src/services/indexing-service.ts` had this line in two places:

```ts
const chunkContent = content.length > 1000 ? '' : buffer.trim();
```

So any document over 1000 characters was stored as chunks with empty content. That covers all three sample documents, which are 1160–1940 characters. Q&A picks chunks by matching keywords against their content, so these documents almost never matched. Users got the generic fallback answer, and any citation that did come back had an empty excerpt. The fix keeps `buffer.trim()` in both places.

**Verification:**
- I added a test in `tests/qa-citations.test.ts` that imports the sample documents, indexes them and asks a question. It checks that no chunk is empty and that citations come back with real excerpts. It fails without the fix ("expected 0 to be greater than 0") and passes with it (2/2).
- I added `vitest.config.ts`, because `npm test` couldn't find any tests before: it was using the Vite config, which points at `src/renderer`.
- `npm run check`, `npm run build` and `bash scripts/check-architecture.sh` all pass.
- I did not launch the Electron app by hand.

**Separate fix, committed first:** `npm run check` was already failing before I touched anything, with 14 type errors. Most were import paths with one `../` too many and unused `React` imports; one was Electron's `File.path` missing from the browser `File` type. AGENTS.md says to fix a broken baseline before new work, so these are in their own commit (`5883db4`), and the bug fix is `6034f67`.

**Not fixed:**
1. **Already-indexed documents stay broken until they're reindexed.** Indexing everything skips documents already listed in `index-meta.json`, so their empty chunk files stay. Users need to delete those index entries, or re-import the files, to get the fix.
2. **Indexing a single document doesn't make it searchable.** `startIndexing(documentId)` writes the chunks but never adds the document to `index-meta.json`, and Q&A only reads chunks for documents listed there. I left this alone because it's a different bug from the one reported; it's worth its own fix.