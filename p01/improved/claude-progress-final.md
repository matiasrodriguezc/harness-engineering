# claude-progress.md -- Session Log

## 2026-11-15 -- Session 1: make the app show documents and answer questions

Starting state: `npm run check` failed (wrong relative imports in renderer, removed `File.path`
API), import button was a no-op, single-document indexing never reached the index, `app:status`
was unregistered, delete left orphaned data, and Q&A returned canned text.

Done:
- Services: validated import (.txt/.md, <=10 MB), id-based storage (no name collisions), full
  cleanup on delete, atomic + path-safe persistence, chunker splits oversized paragraphs,
  IndexingService tracks real status and updates document status/chunk counts.
- Q&A: IDF-weighted keyword retrieval with stemming/prefix matching; answers are extractive
  (quoted sentences/list items from cited chunks; headings boost the text beneath them).
- IPC: added `documents:content`, `documents:pick-and-import`, registered `app:status`,
  input validation on all handlers.
- Renderer: rewritten UI — native picker + drag-drop import, document Content/Chunks tabs,
  clickable citations that highlight the chunk, Q&A history, error banners, status bar.
- Tests: `npm test` (17 service tests), `npm run smoke` (real Electron end-to-end).

Notes:
- `sandbox: false` in BrowserWindow: the compiled preload requires `../shared/types`.
  Bundling the preload would allow re-enabling the sandbox.
- `scripts/dev.js` strips NODE_OPTIONS before launching Electron (the user's shell sets
  `--openssl-legacy-provider`, which Electron rejects).
