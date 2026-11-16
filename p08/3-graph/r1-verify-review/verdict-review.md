VERDICT: PASS
LAYER: none

# verify-review, round 1 (re-run at HEAD 05b15a9)

Reviewed: `git diff 1d8a496 HEAD`. 1d8a496 is the commit that added spec.md. Between 3e0bddf and HEAD, the only changes are the verdict files, so the application diff is the one in 1c69c13. It was checked against spec.md, feature.md and docs/ARCHITECTURE.md. No application code was modified.

## Commands run

- `npm run check`: `tsc --noEmit -p tsconfig.node.json && tsc --noEmit -p tsconfig.json`, no errors.
- `npm test`: `Test Files 6 passed (6)`, `Tests 50 passed (50)`.
- `bash scripts/check-architecture.sh`: `PASS: All architecture boundary checks passed`. This was run before and after `env -u NODE_OPTIONS npm run build`, so the preload rule was checked against a real bundle and did not pass vacuously because nothing was built. `grep require( dist/preload/*.js` shows only `require("electron")`.

## Correctness against spec.md / feature.md

- `buildConversationMarkdown` (`src/services/conversation-export-service.ts:11-36`) matches the spec format exactly:
  - `# Conversation export`, then `## Question N` numbered from 1 in history order.
  - Full question, `### Answer`, full answer, `### Citations`, then `N. **title**` with every excerpt line prefixed `   > ` (CRLF split).
  - `No citations.` when an answer has none, and `No questions yet.` with no `## Question` when the history is empty.
  - No escaping.
- History order: `exportMarkdown` uses `qaService.getHistory()`, the same source as the `qa:history` IPC (`src/main/ipc-handlers.ts:83-85`). `ask` appends (`qa-service.ts:174-176`), so the order is oldest first, as criterion 3 requires.
- The file is saved through main (`src/main/main.ts:47-61`, `src/main/ipc-handlers.ts:109-123`):
  - The default name is `conversation-YYYY-MM-DD.md`, with an `md` filter.
  - `KB_EXPORT_SAVE_PATH` works as the spec describes, including `cancel`.
  - Cancelling returns `{saved:false}` and writes nothing.
  - A write error rejects, and the renderer turns it into `role=alert`.
- UI (`src/renderer/components/ExportConversationButton.tsx`):
  - The button has `type="button"` and `aria-label="Export conversation"`, is never disabled, and sits inside the QuestionPanel `<form>` (`QuestionPanel.tsx:66`).
  - Success shows `role=status` with the path, a cancel shows nothing, and an error shows `role=alert`.
- The spec does not misread feature.md. "The conversation" maps to the persisted Q&A history, which is what the conversation view shows. Citations are title plus excerpt, the empty case is covered, and the button is in the question panel with the required aria-label. The testability hook and `saveExport` are additions the feature needs, not changes to its meaning.

## Layer boundaries

- The renderer only calls `window.knowledgeBase.conversation.*`. `dialog` runs in main and `fs` runs in services, and services have no Electron IPC or React. The preload adds only two `ipcRenderer.invoke` calls (`src/preload/preload.ts:27-30`). The sandbox setting is untouched.
- The docs are updated: the preload API, the channel count (17) and table, the QuestionPanel entry, the services list, an export data-flow section, and PRODUCT.md.

## Findings (none blocking)

1. `tests/conversation-export.test.tsx:169-179`: the button is only tested as static markup (`renderToStaticMarkup`). Its click behavior has no automated test in `npm test`: it should write exactly the `export()` string, show status with the path, show an alert on error, and show nothing on cancel. That behavior is covered only by `scripts/e2e/conversation-export.mjs` and by verify-functional. Suggestion: add a jsdom test with a mocked `window.knowledgeBase.conversation`.
2. `src/preload/preload.ts:29` / `src/main/ipc-handlers.ts:109-123`: `saveExport(markdown)` writes whatever string the renderer passes. It does not regenerate the export in main. This is correct for the current UI, which passes the `export()` result straight through. However, the guarantee that the file equals `export()` (criterion 8) relies on the renderer, not on main. A `saveExport()` with no argument that builds the Markdown in main would make it structural. This is a design note, not a defect.
3. `src/renderer/components/ExportConversationButton.tsx:12,21`: the `Conversation exported to <path>` status stays on screen after later questions or a cleared history. It is cosmetic and allowed by the spec.
4. `src/main/main.ts:48`: `KB_EXPORT_SAVE_PATH` is honored in every build, not only in tests. spec.md asks for this, but anyone who controls the app's environment can redirect exports with no dialog.
5. `src/services/qa-service.ts:126-139`: `getHistory()` can write, because it backfills missing answer ids, so `conversation.export()` is not strictly read-only on legacy history files. This behavior predates the feature and `qa.history()` does the same. It does not break criterion 6, which compares `qa.history()` before and after.
6. `src/shared/types.ts:95`: `GET_CONVERSATION: 'conversation:get'` has no handler. It predates this diff and is not dead code the feature added. No dead code was added: `defaultExportFileName`, `ExportSaveResult` and the `withApp` `env` option are all used.
