Document import works. I checked it by launching the real app and choosing files through the actual file picker (driven remotely). A `.pdf` and an 11 MB file were each rejected with an error shown in the import panel, and nothing was saved. Two sample documents imported, showed up in the sidebar and were selected. Importing the same file again created a separate third document. The saved files on disk match the originals byte for byte. `npm run check` and `npm run build` are both clean; there are no automated tests in the repo, so none ran.

Import could not have worked before this session, for three reasons:

- **The bridge to the main process never loaded.** Electron sandboxes this script by default, and in that mode it can't load our shared types file. So `window.knowledgeBase` was undefined and every call failed, not just import. I now bundle that script into a single file with esbuild (`npm run build:preload`, run by `build` and `dev`). I did this instead of turning the sandbox off, which would have weakened security.
- **`file.path` no longer exists** in this Electron version (removed in 32). The selected file's path is now looked up with Electron's `webUtils` instead.
- **The project didn't type-check at all.** The interface code had wrong import paths and some unused imports.

What I added for import:
- **Validation** in `DocumentService.importDocument`: the file must exist, be `.txt` or `.md`, and be at most 10 MB. These limits are defined once in `src/shared/types.ts`, and the import panel checks them too.
- **No overwrites:** the original copy is saved as `documents/<id>-<filename>`, so two files with the same name both survive.
- **Import panel:** shows errors in the panel, an "Importing…" state and a Cancel button. After a successful import it closes and selects the new document.
- **Status bar fix:** it went blank as soon as any document existed, because the status data had a different shape than the screen expected. I fixed that.

Left for the next session (all recorded in `session-handoff.md`):
- Showing document content isn't built yet (the `documents:get-content` channel).
- Delete doesn't remove the saved text or chunks.
- The document list doesn't load on startup.
- The JSON writes aren't actually atomic, even though the code comment says they are.

I updated `docs/ARCHITECTURE.md`, `docs/PRODUCT.md` and `session-handoff.md`, and marked import as `pass` in `feature_list.json` with this evidence. I added esbuild as a dev dependency, pinned to the version Vite already installs.

Nothing is committed. There is no `.gitignore`, so `dist/`, `node_modules/` and `package-lock.json` show up as untracked files. You'll probably want to ignore the first two before committing.