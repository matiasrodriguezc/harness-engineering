I've implemented the conversation Markdown export from `spec.md`, and all four required checks pass. It's committed as `1c69c13`. `state.md` had no feedback to address, and I didn't edit `spec.md`, `state.md` or any verdict files.

**What was added**
- **`window.knowledgeBase.conversation.export()`** returns the Markdown described in `spec.md`. The builder is in `src/services/conversation-export-service.ts`.
- **Saving to a file:** a second call, `conversation.saveExport(markdown)`, opens a save dialog with a default name like `conversation-2026-11-16.md` and writes the file. It returns `{saved:false}` if the user cancels, and fails with an error if the write fails.
- **`KB_EXPORT_SAVE_PATH`:** when this environment variable is set, the save dialog is skipped and its value is used as the file path; `cancel` acts as a cancelled dialog. This is the test hook the spec asks for, because the native dialog can't be driven from scripts.
- **The button:** "Export conversation" sits in the question panel and is `type="button"`, so it never submits a question. After a save it shows "Conversation exported to <path>"; if the write fails it shows an error; on cancel it shows nothing.
- **Tests and docs:** `tests/conversation-export.test.tsx` (12 tests) and a real-app script, `scripts/e2e/conversation-export.mjs`. The architecture and product docs now list the new calls, and the channel count went from 15 to 17.

**Results**
- `npm run check` and `bash scripts/check-architecture.sh` pass.
- `npm test`: 50 of 50 pass.
- `bash scripts/smoke-bridge.sh` passes and lists the `conversation` key.
- The real-app script passes 18 of 18 checks, covering all 11 acceptance criteria, including a restart, a cancelled save, and a failed write after which questions still work.
- The four earlier real-app scripts still pass (7/7, 6/6, 13/13, 10/10), and `bash init.sh` is OK.

The native save dialog itself has not been tested, since the automated runs always skip it via `KB_EXPORT_SAVE_PATH`. Someone should click the button once with the variable unset to confirm the dialog opens.

I added `conversation-export` to `feature_list.json` as `active`, with this evidence; it should become `passing` only after the two verify nodes pass it. I also updated `session-handoff.md` and `claude-progress.md`.