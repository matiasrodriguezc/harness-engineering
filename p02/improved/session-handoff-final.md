# Session Handoff

## Verified Now

- What is currently working:
  - **document-import** (`pass`, session 1): pick a .txt/.md file in ImportPanel -> validated -> stored -> appears in DocumentList and is selected. Unsupported types and files over 10 MB show an inline error.
  - **document-detail** (`pass`, session 2): selecting a document loads its full text through `documents:get-content` into a scrollable pre-wrap viewer (with View/Hide toggle and loading/missing/error states). Delete has an inline Confirm/Cancel step and removes the original copy, `content/<id>.txt`, `chunks/<id>.json` and the document's `index-meta.json` entry.
  - **basic-persistence** (`pass`, session 2): App calls `refreshDocuments()` on mount, so persisted docs and the status bar load on startup.
- What verification actually ran:
  - `npm run check` and `npm run build`, both clean.
  - Launched Electron with `--remote-debugging-port=9333 --user-data-dir=<scratch>` and drove the UI over CDP: imported 2 files through the real file input, selected each one and compared the rendered text to the source (byte-identical), toggled the viewer, indexed one doc, then went through delete -> cancel -> delete -> confirm. Checked the data dir on disk afterwards. Also called `getContent`/`delete` with path-traversal ids: they return null/false.
  - Persistence: quit Electron, relaunched with the same user-data-dir. The list and status bar were populated without clicking, and the content was viewable.
  - Not run: `npm test` (the repo has no tests).

## Changed This Session

- Code or behavior added:
  - `IPC_CHANNELS.GET_DOCUMENT_CONTENT = 'documents:get-content'`, its handler, preload `documents.getContent(id)`, and the `types.d.ts` entry.
  - `DocumentService`: `getDocumentContent` and `deleteDocument` reject ids that aren't UUIDs (guards against path traversal from the renderer). `deleteDocument` now also removes the content file, the chunks file and the index-meta entry.
  - `PersistenceService.deleteFile(relativePath)`.
  - `App.tsx`: mount `useEffect` -> `refreshDocuments()`.
  - `DocumentDetail`: loads content and chunks on `document.id` change, ignores stale responses, View/Hide Content toggle, inline delete confirmation (resets when the selection changes).
- Docs:
  - ARCHITECTURE.md: rewrote Content Retrieval Flow, added Delete Flow, and fixed Data Storage. `index-meta.json` actually lives at the data root, not in `index/`; the docs now match the code.
  - PRODUCT.md: content loads on selection, delete cleanup and confirmation, and the UI diagram.

## Broken Or Unverified

- Known defect:
  - `IndexingService.startIndexing(id)` (single document, the "Index Document" button) writes `chunks/<id>.json` but does NOT add the doc to `index-meta.json` and does not update `Document.status`/`chunks`. So the status bar's indexed count only changes after a full `startIndexing()`, and the button never disappears. Not fixed (out of scope).
  - `selectedDoc` in App is a snapshot: metadata shown in DocumentDetail goes stale after indexing until the user re-selects the doc.
  - `PersistenceService.writeJson` is not actually atomic despite its doc comment.
  - Imported files are read as UTF-8 without encoding detection.
  - `getStatus().lastIndexed` always returns "now", not a real timestamp.
- Unverified path: the 'missing' and 'error' content states in DocumentDetail were not exercised in the UI (a content file is always created on import).
- Risk for the next session: new preload imports must stay bundle-able; don't switch the preload back to plain tsc output.

## Next Best Step

- All features in feature_list.json are now `pass`.
- Suggested next work, by value:
  1. Make single-document indexing (`startIndexing(id)`) update `index-meta.json` and the document's `status`/`chunks`, and refresh `selectedDoc` in App after indexing.
  2. Make `PersistenceService.writeJson` actually atomic (write to a temp file, then `renameSync`).
  3. Add vitest unit tests for DocumentService and IndexingService (`npm test` currently has nothing to run).
- What must not change: preload bundling, the `<id>-<filename>` storage naming, the import validation constants, and the UUID id guard in DocumentService.

## Commands

- Startup: `npm install && npm run dev`
- Verification: `npm run check && npm run build`
- Focused debug command: `npm run build && env -u NODE_OPTIONS npx electron . --remote-debugging-port=9333 --user-data-dir=<scratch dir>`. NODE_OPTIONS in this shell contains `--openssl-legacy-provider`, which Electron rejects. Then attach via `curl localhost:9333/json/list`. Node 20 needs `node --experimental-websocket` for a CDP client script that uses the global `WebSocket`.
