I finished the two remaining features, so all 7 in `feature_list.json` are now `pass`. I tested both by running the real app. Nothing is committed yet.

**Document detail (view and delete)**
- Selecting a document now loads its full text into a scrollable viewer, with a View/Hide Content button and messages for loading, missing content and errors. If you switch documents while one is loading, the old result is ignored.
- Delete asks for an inline Confirm/Cancel first. It now removes everything stored for the document: the original copy, the extracted text, the chunks and its index entry. Before, it left the text and chunks behind.
- `getContent` and `delete` now reject any id that isn't a UUID, so the UI can't pass a path like `../x` that reaches files outside the data folder.
- To test it, I launched the app and drove it over Chrome DevTools: imported two files through the real file picker, checked the displayed text matched the source files exactly, indexed one, then tried delete with Cancel and with Confirm. Afterwards the deleted document's files were all gone from disk and the other document's files were untouched.

**Saved documents load on startup**
- `App.tsx` now loads the document list and status bar when the app starts. I tested it by quitting and relaunching with the same data folder: the list and status bar filled in without clicking Refresh, and the content was viewable.

**Docs:** I updated `docs/ARCHITECTURE.md` and `docs/PRODUCT.md`. I also corrected the docs' location for `index-meta.json`: the code stores it in the root of the data folder, not in `index/`.

**Known problems I didn't fix** (all listed in `session-handoff.md`):
- The "Index Document" button for a single document creates the chunks but doesn't update `index-meta.json` or the document's status. The status bar count doesn't change and the button never goes away.
- After indexing, the document details on screen stay out of date until you select the document again.
- `writeJson` is described as atomic in the code comments but isn't: a crash mid-write could corrupt the file.
- The project has no automated tests (`npm test` has nothing to run). The "missing content" and "error" messages in the viewer were never triggered during testing.

Do you want me to commit this, as the previous session did at the end of its run?