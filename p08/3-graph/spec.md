# spec.md: export the conversation as Markdown

Source: `feature.md`. Round 1, no earlier verdicts.

## Scope

"The conversation" is the persisted Q&A history: what `window.knowledgeBase.qa.history()` returns, in that order
(oldest first, the same order the conversation view shows). Two parts are added:

1. **Bridge:** `window.knowledgeBase.conversation.export()` returns `Promise<string>`, a Markdown document built
   from the current history. It reads the history every time it runs and changes no data.
2. **UI:** the question panel gets a button with `aria-label="Export conversation"`. Clicking it gets the Markdown
   from `conversation.export()` and writes it to a file the user chooses in a native save dialog.

The code follows `docs/ARCHITECTURE.md`. The renderer only uses `window.knowledgeBase`. File writing and the
save dialog run in the main process and are reached through new IPC channels exposed by the preload. The preload
bundle stays sandbox-safe. The docs (preload API, channel count and table, QuestionPanel) are updated.

## Markdown format

```
# Conversation export

## Question 1

<question text>

### Answer

<answer text>

### Citations

1. **<documentTitle>**
   > <excerpt line 1>
   > <excerpt line 2>

## Question 2
...
```

- Each history entry produces one `## Question N` section, with N starting at 1 and following history order.
  The question text appears in full, then `### Answer` and the full answer text.
- Every answer is followed by its citations, in the order stored on the answer. Each citation shows the
  document title and the excerpt. Every line of the excerpt is prefixed with `> `, so a multi-line excerpt
  stays inside its citation.
- When an answer has no citations, the `### Citations` heading is followed by the line `No citations.`
- When the conversation is empty, the document is `# Conversation export` followed by a line saying
  `No questions yet.`, with no `## Question` sections.
- Question, answer, title and excerpt text are copied as stored. This feature does not escape Markdown.

## Acceptance criteria

These are checked in the running app, using `window.knowledgeBase` and the UI over Chrome DevTools, with a
fresh `--user-data-dir` and `data/sample-documents/` imported and indexed.

1. `typeof window.knowledgeBase.conversation.export === 'function'`. The other preload namespaces (`documents`,
   `indexing`, `qa`, `feedback`, `app`) are unchanged.
2. With an empty history (a fresh profile, or after `qa.clearHistory()` or `app.reset()`), `export()` resolves
   to a string that contains `# Conversation export` and `No questions yet.` and does not contain
   `## Question`.
3. After asking 3 different questions (at least one answer has citations), `export()` contains exactly 3
   `## Question N` headings (1, 2, 3). Each heading is followed by that question's exact text, in the order
   the questions were asked, matching `qa.history()` order.
4. For each history entry, the answer text `response.answer` appears after its question and before the next
   `## Question` heading.
5. For each citation of each answer, the citation's `documentTitle` and every line of its `excerpt` (with the
   `> ` prefix) appear inside that answer's section, after the answer text, in the order the citations are
   stored. An answer without citations shows `No citations.` in its section.
6. `export()` reflects the current state: asking another question adds `## Question 4`, and after
   `qa.clearHistory()` the result is the empty document from criterion 2. Calling `export()` does not change
   `qa.history()`.
7. The question panel (the `<form>` that holds the "Ask a question" input) contains a `<button>` with
   `aria-label="Export conversation"`. Its `type` is not `submit`, so clicking it does not ask a question. It
   is shown and enabled both when the conversation is empty and when it is not.
8. Clicking the button opens a save dialog with a `.md` default file name. When the user picks a path, the file
   at that path contains exactly the string `conversation.export()` returns at that moment, in UTF-8. When the
   user cancels, no file is written and no error is shown.
   - **Testability:** a native dialog cannot be driven over CDP. When the environment variable
     `KB_EXPORT_SAVE_PATH` is set, the main process skips the dialog and uses that path as the chosen file,
     and the special value `cancel` simulates a cancelled dialog. Without the variable, the real dialog is
     used.
9. After a successful save, the UI shows a visible confirmation that includes the saved file path, for example
   `role="status"` text like `Conversation exported to <path>`. If writing fails (for example an unwritable
   or nonexistent directory), the UI shows a visible error message (`role="alert"`) and the app keeps working.
   A later question can still be asked.
10. The export (bridge and file) survives a restart: after the app is relaunched with the same
    `--user-data-dir`, `export()` returns the same questions, answers and citations.
11. Static and runtime checks pass: `npm run check`, `npm test` (with new tests for the Markdown builder,
    covering the empty case, ordering, citations and multi-line excerpts, plus the IPC/preload wiring and the
    button), `bash scripts/check-architecture.sh` and `bash scripts/smoke-bridge.sh`, which must list the
    `conversation` key.

## Out of scope

- Other formats (PDF, HTML, JSON) and import of an exported file.
- Including feedback ratings, confidence, timestamps or document ids in the export. These may be added only if
  they do not break the criteria above, and they are not required.
- Escaping Markdown special characters in user or document text.
- Exporting a subset of the conversation, or a single answer.
- Changes to Q&A, retrieval, citation quality, or the conversation history view.
- An export button outside the question panel.
