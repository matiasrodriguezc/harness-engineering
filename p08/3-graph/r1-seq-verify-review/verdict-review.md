VERDICT: PASS
LAYER: none

# verify-review, round 1

Reviewed: `git diff 1d8a496 HEAD` (the commit that added spec.md to HEAD 3e0bddf), against spec.md, feature.md and docs/ARCHITECTURE.md.

## Commands run

- `npm run check` -> `tsc --noEmit -p tsconfig.node.json && tsc --noEmit -p tsconfig.json`, no errors.
- `npm test` -> `Test Files 6 passed (6)`, `Tests 50 passed (50)`.
- `bash scripts/check-architecture.sh` -> `PASS: preload has no local runtime requires`, `PASS: All architecture boundary checks passed`.
- `grep -c "ipcMain.handle(" src/main/ipc-handlers.ts` -> `17`, which matches the "17 channels" count and table in docs/ARCHITECTURE.md.

## Correctness against spec.md / feature.md

- Markdown format (`src/services/conversation-export-service.ts:11-36`) matches the spec: `# Conversation export`, `## Question N` from 1 in history order, full question, `### Answer`, answer, `### Citations` with `N. **title**` and every excerpt line prefixed `> ` (CRLF handled), `No citations.` when there are none, `No questions yet.` with no `## Question` when the history is empty. Nothing is escaped.
- `exportMarkdown()` (`conversation-export-service.ts:43-47`) reads the history on every call and only reads it, so criteria 6 and 10 hold.
- Save path (`src/main/ipc-handlers.ts:109-123`, `src/main/main.ts:47-61`): `.md` default name, native dialog with an `md` filter, `KB_EXPORT_SAVE_PATH` override with `cancel` as the spec requires, `{saved:false}` and no write on cancel, and a write error is passed back to the renderer.
- UI (`src/renderer/components/ExportConversationButton.tsx`): `type="button"`, `aria-label="Export conversation"`, never disabled. Clicking it writes exactly the `export()` string, shows `role=status` with the path, shows `role=alert` on error and shows nothing on cancel. It sits inside the QuestionPanel `<form>` (`src/renderer/components/QuestionPanel.tsx:66`).
- The spec reads feature.md correctly. Adding `conversation.saveExport` is a reasonable way to reach the file-save requirement through the bridge, and the other namespaces are unchanged.

## Layer boundaries

- The renderer only uses `window.knowledgeBase.conversation.*`. The dialog and `fs` calls run in main and services. The preload only adds two `ipcRenderer.invoke` calls (`src/preload/preload.ts:27-30`). The sandbox is untouched, and the bundle check passes.
- The docs are updated: the preload API, the channel table and count, the QuestionPanel entry, the services list and an export data-flow section.

## Findings (none blocking)

1. `tests/conversation-export.test.tsx:168-179`: the button's click behavior has no unit test. Only its static markup is checked. Criteria 8 and 9 (status message with the path, alert on a failed write, nothing on cancel) are covered only by the e2e script `scripts/e2e/conversation-export.mjs`, which `npm test` does not run. Suggestion: add a jsdom/RTL test with a mocked `window.knowledgeBase.conversation`.
2. `src/renderer/components/ExportConversationButton.tsx:52-66`: the `Conversation exported to <path>` status stays on screen indefinitely, even after the history is cleared or more questions are asked. It can mislead a little, but it is cosmetic and allowed by the spec.
3. `src/main/main.ts:48-52`: `KB_EXPORT_SAVE_PATH` is honored in production builds too, not just test runs. The spec asks for this. It is noted only because anyone who can set the app's environment can redirect where exports are saved without a dialog.
4. `src/shared/types.ts:95`: `GET_CONVERSATION: 'conversation:get'` has no handler. It predates this diff and is not dead code added by this feature. It is mentioned because it now shares the `conversation:` prefix with the new channels.
5. No dead code was added by the diff. `defaultExportFileName`, `ExportSaveResult` and the `withApp` `env` option are all used.
