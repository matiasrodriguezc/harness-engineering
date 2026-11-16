I finished the `document-detail` feature and marked it `pass` in `feature_list.json`. `npm run check` is clean, all 19 unit tests pass, and I ran an end-to-end check in Electron 33 against a temporary data folder with the file picker stubbed. Nothing is committed yet.

**What changed**
- **Content view:** the detail panel now shows the document's full text, plus a word count. It has loading, missing, error and empty states. If you switch documents quickly, a late response from the previous one is ignored.
- **New IPC channel `documents:content`:** it goes through the preload as `documents.getContent(id)`. It only reads content for documents that exist, so a made-up ID like `../secret` returns nothing instead of reading outside the content folder.
- **Delete:** clicking Delete now asks for confirmation on the page, with Confirm and Cancel buttons. Before, delete only removed the document's entry and the stored copy of the file. Its text, chunks and search-index entry stayed on disk and were still counted in index status. Now `IndexingService.removeDocument()` cleans those up too.
- **Tests and docs:** new tests are in `src/services/document-detail.test.ts`, and `docs/ARCHITECTURE.md` is updated.

**End-to-end result:** after importing the 3 sample files, the shown text matched each source file exactly, and switching documents loaded the right one. Cancel kept the document; Confirm removed it from the sidebar (3 → 2) and left no files behind. I didn't test how the panel performs with a 10 MB file.

**Problems I noticed but didn't fix**
1. **Documents don't reappear after a restart.** `App.tsx` never loads the document list at startup, so the sidebar stays empty until you press Refresh, even though the data is saved. This is the first thing to fix for `basic-persistence`, the last feature not started.
2. **The "Index Document" button doesn't update the document.** Indexing one document writes its chunks but doesn't add it to the search index or change its status. The status stays `imported`, the button stays visible, and Q&A can't find it. Indexing all documents at once does work.

The next step is `basic-persistence`, which would cover the first problem; I can also fix the second while I'm there.