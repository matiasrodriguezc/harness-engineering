I wrote `spec.md` and committed it as `1d8a496`. Following the plan node's rules, I touched nothing else: no application code, and I left `state.md` alone. There were no verdict files, so nothing from an earlier round needed folding in.

**Scope:** "the conversation" means the saved Q&A history, oldest first. That's what `qa.history()` returns and the order the conversation view shows.
- **Bridge:** `window.knowledgeBase.conversation.export()` returns the Markdown and changes no data.
- **UI:** a button labelled "Export conversation" in the question panel opens a save dialog. The dialog and the file writing run in the app's main process, reached through new channels exposed by the preload (the bridge script behind `window.knowledgeBase`).

**Format:** a `# Conversation export` heading, then one `## Question N` section per question with `### Answer` and `### Citations`. Each citation is a numbered entry: the document title in bold, then the excerpt quoted with every line prefixed by `> `. An answer without citations says `No citations.`, and an empty conversation says `No questions yet.`

**Acceptance criteria (11):**
- **Bridge:** the empty case; order and exact question text; answers and citations in the right section; the export updates after a new question or a cleared history; the export changes nothing.
- **Button:** where it sits, and that it doesn't trigger a question.
- **Saving:** the file contents match `export()` exactly; cancelling writes nothing.
- **Feedback:** a success message with the file path, and an error message if the write fails.
- **Other:** the export is the same after a restart, and the static and runtime checks plus new tests pass.

**One addition beyond `feature.md`:** the verify node can't click through a native save dialog over Chrome DevTools. So the spec requires a test hook: when the `KB_EXPORT_SAVE_PATH` environment variable is set, the app skips the dialog and saves to that path, and the value `cancel` acts as a cancelled dialog. If verify-review treats this as reading too much into the feature, this is the point it will flag.

**Out of scope:** other formats, exporting feedback, confidence or timestamps, escaping Markdown characters, partial exports, and any change to Q&A or retrieval.