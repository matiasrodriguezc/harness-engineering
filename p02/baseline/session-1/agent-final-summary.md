Document import works now. You can import `.txt` and `.md` files with a native file picker or by dragging them onto the panel. `npm run check` is clean, the 15 new unit tests pass, and an end-to-end run in Electron 33 passed all 13 checks. That run replaced the native file dialog with a stub, and I didn't try a real drag-and-drop from Finder.

**Three existing bugs had to be fixed first, because import couldn't work without them:**
- **The preload never loaded.** Electron runs the preload in a sandbox, and the sandbox can't load the local file `../shared/types`. So `window.knowledgeBase` was never set up, and every IPC call failed, including the question panel that's marked "pass" in `feature_list.json`. Instead of turning the sandbox off, I bundle the preload into one file with esbuild (new `npm run build:preload` step, used by both `build` and `dev`).
- **`File.path` no longer exists.** Electron 32 removed it, and the old `ImportPanel` relied on it. Drag-and-drop now gets file paths with `webUtils.getPathForFile` in the preload.
- **The type check failed before any changes.** The renderer imported `shared/types` from the wrong path, and two `Window` declarations conflicted. There is now one typed bridge, in `src/renderer/types.d.ts`.

**How import works:**
- **Picker:** the "Choose Files…" button opens the native dialog from the main process, limited to `.txt`/`.md`, and lets you select several files at once.
- **Checks on each file:** `src/services/document-service.ts` checks the extension, that it's a regular file, the 10 MB limit from `docs/PRODUCT.md`, and that it's valid UTF-8 text. Binary files are rejected and a leading byte-order mark is stripped.
- **One bad file doesn't stop the rest.** The panel lists which files were imported and why the others failed. If anything was written before a failure, it's removed.
- **Same-name files no longer overwrite each other.** Each stored copy is named `documents/<id><ext>`. Before, two files called `notes.txt` from different folders replaced each other, and deleting one removed the other's stored copy.
- **In the UI:** if every file imports, the panel closes and the first new document is selected. If any fail, the panel stays open so the errors stay visible. The status bar now shows the real document count.

**Other changes:** I added a `.gitignore` for `node_modules/` and `dist/`, made Vitest find tests under `src/`, kept test files out of the Electron build, updated `docs/ARCHITECTURE.md`, and marked `document-import` as passing in `feature_list.json`. Nothing is committed.

**For the next session (detail view and saving data):**
- The app doesn't load the document list on startup; it only appears after an import or Refresh.
- `writeJson` is described as atomic but isn't.
- Deleting a document leaves its saved text in `content/<id>.txt` and its chunks on disk.
- `DocumentDetail` still doesn't load the document's text.