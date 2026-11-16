The question panel now shows the whole Q&A history as a conversation: every question and answer, in order, each answer with its citations. I tested it in the running Electron app, and an automated check there passes 23 of 23 steps. Everything is committed and the working tree is clean.

**I had to fix two existing problems first** (committed separately):
1. **`npm run check` was failing** on the starter: wrong import paths, unused imports, and an unused import component that can't work on this Electron version. Fixed in `452cc75`.
2. **The UI couldn't reach the backend at all.** Electron 33 blocks the bridge script between the UI and the app from loading other files, so it failed at startup and no button did anything, including asking a question. The build now bundles that script into a single file with esbuild; Electron's sandbox stays on. Fixed in `93d865e`.

**What the feature does** (`8c65398`):
- **Conversation view:** your questions and the assistant's answers are shown as separate bubbles, each with a readable timestamp ("Today, 10:21 PM", or the date and year for older entries) and a confidence score.
- **Citations:** each answer lists its sources with document name, chunk number and excerpt. Clicking a source opens that document. Answers with no sources say so. Excerpts now end on a whole word with "…" instead of stopping mid-word.
- **Follow-up questions:** "Follow up" links a new question to an earlier one, and the earlier question is used when searching the documents. In the tests, a bare "Why?" found nothing on its own but found 2 sources as a follow-up.
- **Other controls:**
  - copy an answer
  - expand long answers
  - collapse sources
  - clear the conversation, with a confirmation step
  - see a "searching" message while waiting
  - retry if a question fails, with the error shown in the conversation
  - jump to any past question from the History tab
- **Saved history:** history survives restarts, and history saved before this change still loads.
- **Accessibility:** the conversation is announced to screen readers, the input has a label, and everything works from the keyboard with visible focus.

**How I checked it:**
- `npm run check` and `bash scripts/check-architecture.sh` both pass.
- `npm test`: 11 new tests of the Q&A logic pass.
- `scripts/verify-conversation.mjs` drives the real app using a temporary data folder, so your own app data isn't touched. It covers the empty state, several questions in a row, an error and retry, a long answer, restart, and clearing. Results and screenshots are in `docs/verification/README.md`.
- I looked at the screenshots and fixed what they showed was wrong: excerpts cut off mid-word, and the History tab not scrolling to the chosen question.

**Problems I found but left alone, because they're outside this feature:**
1. **"+ Import" does nothing.** You can't import documents from the UI, so the verification script loads the sample documents directly.
2. **"Index Document" doesn't feed Q&A.** Indexing a single document saves its chunks, but Q&A never uses them; only "index all" does.
3. **The status bar is blank** ("Index:" and "Documents:" have no values) because the status call returns the wrong data shape.
4. **The sample answers read oddly** (e.g. "follows a layered .") because the starter's placeholder answer generator splices in a cut-off piece of the excerpt.

**About your setup:** your `~/.zshrc` sets `NODE_OPTIONS=--openssl-legacy-provider`, and Electron won't start with that, including `npm run dev`. Run the app with `NODE_OPTIONS= npm run dev`. The verification script clears it for you, and I didn't change your shell config.