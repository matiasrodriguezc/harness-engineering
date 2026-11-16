# Session Handoff

## Verified Now

- What is currently working:
  - **document-import** (feature_list status `pass`): pick a .txt/.md file in ImportPanel -> validated -> stored -> appears in DocumentList and is selected. Unsupported types and >10 MB files show an inline error.
  - The preload bridge actually loads now (it never did before; see Changed This Session).
  - Status bar shows the document count and index status after import.
- What verification actually ran:
  - `npm run check` and `npm run build`, both clean.
  - Launched Electron with `--remote-debugging-port=9333 --user-data-dir=<scratch>` and drove the real file input via CDP `DOM.setFileInputFiles`: bad extension, oversized file, two valid imports, and a duplicate filename. Inspected `knowledge-base-data/` on disk (meta, content, original copies match the source byte for byte).
  - Not run: `npm test` (no tests exist in the repo).

## Changed This Session

- Code or behavior added:
  - `DocumentService.importDocument` validates non-empty path, regular file, extension (`SUPPORTED_EXTENSIONS`), and size (`MAX_IMPORT_SIZE_BYTES`), all in `src/shared/types.ts`. It stores the original copy as `documents/<id>-<filename>` so same-named files don't overwrite each other. `deleteDocument` uses the same naming.
  - Preload exposes `documents.getFilePath(file)` (wraps `webUtils.getPathForFile`; `File.path` was removed in Electron 32).
  - ImportPanel: client-side pre-validation, importing state, inline error, Cancel button, and the input resets so the same file can be picked again.
  - App.handleImport selects the new doc, closes the panel, and rethrows a cleaned error message to the panel.
  - `IndexStatus` moved to shared types. App maps it to `AppStatus` (previously the status bar went blank once any document existed).
- Infrastructure or harness changes:
  - The baseline didn't type-check. Fixed the shared-type import paths in the renderer, unused imports, the duplicate `declare global` in App.tsx (types.d.ts is canonical), and the StatusBar index type.
  - **Preload is now bundled with esbuild** (`npm run build:preload`, added to `build` and `scripts/dev.js`). A sandboxed preload can't `require('../shared/types')`, so `window.knowledgeBase` was undefined. Added `esbuild@0.25.12` as an exact devDependency (same version vite already pulled in).

## Broken Or Unverified

- Known defect:
  - `documents:get-content` channel / preload `getContent` / handler do not exist yet (docs mark this as pending). DocumentDetail `content` state is a placeholder.
  - `deleteDocument` removes metadata and the original copy but not `content/<id>.txt` or chunks (PRODUCT.md says it should).
  - App does not load the document list on startup; it only refreshes after import or Refresh (basic-persistence feature).
  - `PersistenceService.writeJson` is not actually atomic despite its doc comment.
  - Imported files are read as UTF-8 without encoding detection.
- Unverified path: inline display of a *server-side* import error through the UI. Client pre-validation catches type and size first; the prefix-stripping regex was checked against the actual raw message format only.
- Risk for the next session: new preload imports must stay bundle-able; don't switch preload back to plain tsc output.

## Next Best Step

- Highest-priority unfinished feature: `document-detail` (add `GET_DOCUMENT_CONTENT: 'documents:get-content'` to IPC_CHANNELS, the handler, preload `getContent`, the types.d.ts entry, and load content in DocumentDetail).
- Why it is next: import now produces content files that nothing can display.
- What counts as passing: selecting an imported doc shows its full text. Delete removes it from the list and removes its content file.
- What must not change during that step: preload bundling, the `<id>-<filename>` storage naming, and the import validation constants.

## Commands

- Startup: `npm install && npm run dev`
- Verification: `npm run check && npm run build`
- Focused debug command: `npm run build && env -u NODE_OPTIONS npx electron . --remote-debugging-port=9333 --user-data-dir=/tmp/kb-test` (NODE_OPTIONS in this shell contains `--openssl-legacy-provider`, which Electron rejects), then attach via `curl localhost:9333/json/list`.
