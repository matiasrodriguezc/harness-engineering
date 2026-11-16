VERDICT: PASS
LAYER: none

# verify-functional: conversation Markdown export (round 1)

Commit checked: 05b15a9 (implementation in 1c69c13). No application code was modified. Verified 2026-11-16 in a separate worktree.

## Defects

None. In the running app, every acceptance criterion in spec.md (1–11) held.

## Evidence

### Static and runtime (criterion 11)
- `npm run check`: no errors.
- `npm test`: `Test Files 6 passed (6)`, `Tests 50 passed (50)`.
- `bash scripts/check-architecture.sh`: `PASS: All architecture boundary checks passed`.
- `env -u NODE_OPTIONS npm run build`: `✓ built`.
- `bash scripts/smoke-bridge.sh`: `"keys": "documents,indexing,qa,feedback,conversation,app"`, `PASS: the running app exposes window.knowledgeBase`.

### End to end (my own script, independent of the implementer's e2e)
Script: `vf2.mjs` in the session scratchpad. It launches the built app with `electron . --remote-debugging-port=948x --user-data-dir=<fresh temp dir>` through `scripts/e2e/app-session.mjs`, and imports and indexes `data/sample-documents/`. To ask a question it clicks the "Ask a question" input with a real CDP mouse event, types with `Input.insertText` and presses Enter with `Input.dispatchKeyEvent`. It clicks the Export button with real CDP mouse events (`Input.dispatchMouseEvent`). It compares each export with an oracle, a Markdown string built independently from `qa.history()` using the format in spec.md. The script runs 4 app sessions:
1. Save to a non-ASCII path (`export – ünïcode.md`).
2. Restart on the same profile with `KB_EXPORT_SAVE_PATH=cancel`.
3. Save into a nonexistent directory.
4. Save to a path that is a directory.

Result: `vf2: all 36 checks passed`.

| # | Result | Observed |
|---|---|---|
| 1 | PASS | `typeof conversation.export === 'function'`. The keys are exactly `documents,indexing,qa,feedback,conversation,app`. |
| 2 | PASS | A fresh profile gives `# Conversation export` plus `No questions yet.` with no `## Question`. `app.reset()` gives the same result. After `qa.clearHistory()` the output is exactly `"# Conversation export\n\nNo questions yet.\n"`. |
| 3 | PASS | I asked 3 questions in the UI: "What are the main architecture decisions?", "Who attended the meeting and what was decided?" and "qqqzzz xyzzy plugh". `qa.history()` keeps that order. The export has headings `## Question 1..3`, and each heading is followed by its question's exact text. At least one answer had citations, including a multi-line excerpt. |
| 4 | PASS | Each `response.answer` appears inside its own section, after its question. |
| 5 | PASS | Titles and every `> ` excerpt line appear after the answer, in the stored order. The answer with no citations ("qqqzzz…") shows `No citations.` The whole export string equals the independent oracle exactly, with 3 questions and with 4. |
| 6 | PASS | A 4th question in the UI (with `ñandú “quotes” & <tags>`) adds `## Question 4` and no 5, and still matches the oracle. Two `export()` calls in a row return the same string, and `qa.history()` is unchanged by them. `clearHistory` produces the empty document. |
| 7 | PASS | There is exactly one `BUTTON` with `aria-label="Export conversation"` inside the Ask form. Its type is `button`. It is enabled and visible with an empty conversation, with a full one, and after a failed export. A mouse click does not add a history entry: 0 stays 0 and 3 stays 3. |
| 8 | PASS | A click on an empty conversation wrote a file equal to `export()`. A click after 3 questions wrote a file whose bytes equal `Buffer.from(export(), 'utf8')`. With `cancel`, no status or alert appears and the output directory is unchanged (same file list, same mtime). The native dialog cannot be driven over CDP. In code, `ipc-handlers.ts:29` gives the default name `conversation-YYYY-MM-DD.md`, and `main.ts` `chooseExportPath` adds a `md` filter. |
| 9 | PASS | On success, a `role=status` message is shown and it includes the full saved path. When the target directory doesn't exist, or the path is a directory, a `role=alert` message is shown, no status, and nothing is created. A later question asked in the UI is still answered (history n → n+1). |
| 10 | PASS | After a relaunch on the same `--user-data-dir`, `export()` returns the same string as before the restart, byte for byte. |
| 11 | PASS | See "Static and runtime" above. |

## Observations (not defects)
1. On my first run, the test itself removed the React-managed status node from the DOM, and the next click's message never appeared. That was a bug in my test, not in the app. With the DOM left alone the app works.
2. The answers are mock answers and can include raw document headings (`#`, `##`) inside the answer sections. spec.md puts escaping out of scope, and the `## Question N` headings stay correct and unique.
3. The preload also exposes `conversation.saveExport(markdown)`. The UI flow needs it.
