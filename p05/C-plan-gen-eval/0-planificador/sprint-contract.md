# Sprint Contract: Multi-turn Q&A Conversation History

- **Role split:** Planner wrote this contract. The Generator implements it. The Evaluator verifies it against this file and `rubric-template.md`.
- **Date:** 2026-11-15
- **Base commit:** `4e63815` (starter P05 + rubric)
- **Changes to this contract:** The Generator must not edit the acceptance criteria or the verification plan. If a criterion turns out to be impossible or wrong, record that under "Contract deviations" at the end of this file with the reason, and leave the original text unchanged.

---

## 1. Goal

Today the right-hand panel shows only the latest answer (`lastResponse` in `src/renderer/App.tsx`). Each new question overwrites the previous answer. The sidebar "History" tab (`src/renderer/components/ConversationHistory.tsx`) is a placeholder that cuts answers off at 80 characters and leaves out citations.

After this sprint, the question panel area shows the whole Q&A session as a conversation:

- every previous question and its answer, in order
- each answer's citations
- the history survives an app restart, because it is loaded from the persisted `qa-history.json`

## 2. Starting state (observed by the Planner)

| Check | Result |
|---|---|
| `npm install` | OK (it creates an untracked `package-lock.json`) |
| `npm run check` | **FAILS**: 15 errors in the renderer. Imports of `../../shared/types` and `../../../shared/types` don't resolve, `React` is imported but unused, there are implicit `any`s, and `File.path` doesn't type-check in `ImportPanel.tsx` |
| `npm run build` | Passes. Vite erases the type-only imports, so the app runs anyway |
| `bash scripts/check-architecture.sh` | Passes |

`AGENTS.md` forbids stacking feature work on a broken baseline. **Step 0 of this sprint is therefore a narrow baseline fix** (see AC-0). It is the only work allowed outside the feature scope.

Other facts the Generator and Evaluator need:

- **Import button does nothing.** The "+ Import" button in `App.tsx` (`handleImport`) only calls `console.log`. Documents have to be seeded through the preload API from DevTools (see §6.2). Fixing import is **out of scope**.
- **Data directory.** It is `~/Library/Application Support/knowledge-base/knowledge-base-data/` (Electron `userData` for the package name `knowledge-base`). History lives in `qa-history.json` as `QAHistory[]` (`{ question, response: { answer, citations[], confidence, timestamp } }`).
- **The Q&A service is a mock.** `QaService.ask` matches keywords against indexed chunks, returns at most 2 citations, waits 100–500 ms at random, and saves to history **before** returning.
- **IPC already exists.** `qa:ask`, `qa:history`, `qa:clear-history` and `conversation:get` are already wired through main, preload and the renderer typings. **No new IPC channel should be needed.**
- **Closing the window doesn't quit on macOS.** Closing the window does not quit the app (`window-all-closed`). A "restart" means **Cmd+Q** followed by `npm run dev`.

## 3. Scope

### In scope

1. **Baseline fix (Step 0).** Make `npm run check` pass with the smallest possible change: correct the shared-types import paths (or use the existing `@shared/*` alias), remove unused `React` imports, and fix the implicit `any`s and the `File.path` typing. Don't change behaviour.
2. **Conversation view in the question panel area.** It replaces the single `lastResponse` block. All exchanges are listed oldest-first above the question input, and the newest exchange is scrolled into view.
3. **Per-exchange content.** Each exchange shows:
   - the question (user turn)
   - the full answer (assistant turn), never truncated
   - a readable timestamp
   - the confidence indicator
   - the citations: document title, chunk index and excerpt
4. **Citation interaction.** Activating a citation selects the cited document, so `DocumentDetail` shows it. This works with the mouse and the keyboard.
5. **Loading persisted history** on startup, and after each ask, through the existing `conversation.get()` / `qa.history()` API.
6. **Pending state.** The submitted question appears at once with an "Answering…" indicator. A second submission is blocked until the first one settles.
7. **Error state.** If `qa.ask` rejects, an inline error is shown in the conversation, the earlier exchanges stay visible, and the question text is not silently lost (it is either restored to the input or shown in the error turn).
8. **Empty state** when there is no history.
9. **Clear conversation.** A control that uses the existing `qa.clearHistory()`, with an in-page confirmation step. `window.confirm` must not be used.
10. **Sidebar "History" tab.** Either make it consistent with the new view (the count matches, and it is not a lossy duplicate) or remove it, together with its now-dead code. Either choice is acceptable. Record which one in the summary.
11. **Accessibility basics:**
    - semantic list/article structure for the conversation
    - a polite live region (for example `role="log"` or `aria-live="polite"`) so that new answers are announced
    - a labelled question input (a `<label>` or `aria-label`)
    - visible focus on the interactive elements

### Out of scope (do not do these)

- Using earlier turns as **context** for answer generation (follow-up resolution, pronoun carry-over). "Multi-turn" in this sprint means multi-turn **display** only. `QaService.ask(question)` keeps its signature and its behaviour.
- Swapping the mock Q&A for a real LLM or retrieval engine, and streaming answers.
- Multiple named conversations or threads, search inside history, editing or deleting individual turns, and export.
- Fixing the "+ Import" button or `ImportPanel`, beyond the type fix in Step 0.
- New IPC channels, new persistence files, or changes to the `qa-history.json` schema. If one turns out to be unavoidable, record it as a contract deviation with the reason.
- A visual restyle of the app. The new UI must reuse the existing palette (`#16213e`, `#1a1a3e`, `#0f3460`, `#533483`, `#e0e0e0`, `#8888bb`) and the inline-style approach.
- Changing `scripts/check-architecture.sh`, `AGENTS.md`, or the verification rules.

## 4. Acceptance criteria

Each criterion is pass/fail. The Evaluator must cite evidence for every one of them (a command and its output, a screenshot, or `file:line`).

**AC-0 (baseline).** `npm run check` exits 0 and `bash scripts/check-architecture.sh` prints `PASS: All architecture boundary checks passed`. Both outputs are recorded.

**AC-1 (accumulation).** After asking 3 questions in a row in the running app, all 3 questions and all 3 answers are visible in the question panel area, oldest at the top and newest at the bottom. Asking a 4th question does not remove or change any of the first 3.

**AC-2 (role distinction).** User questions and assistant answers are visually distinct (for example alignment, background, or a "You" / "Assistant" label). They can also be told apart without colour: a text label or the structure is enough.

**AC-3 (full answers).** Answers are rendered in full. No `substring` or ellipsis truncation is applied to answer text in the conversation view. A long answer (≥ 1,500 characters, from the fixture in §6.3) wraps inside the panel with no horizontal scrolling of the window.

**AC-4 (citations).** For every answer that has citations, each citation shows the document title, the chunk index, and the excerpt. For an answer with zero citations, the view says so in plain words (for example "No sources cited") rather than rendering an empty "Citations:" header.

**AC-5 (citation is usable).** Clicking a citation, or focusing it with Tab and pressing Enter or Space, selects that document: `DocumentDetail` shows the cited document's title. If the cited document no longer exists, the citation stays visible and activating it does not throw. A console error or an uncaught rejection counts as a failure.

**AC-6 (timestamps).** Each exchange shows a human-readable local time taken from `response.timestamp`, for example `Nov 15, 2026, 10:42 PM`. A raw ISO string does not count. The times shown match the `timestamp` values in `qa-history.json`.

**AC-7 (persistence across restart).** After Cmd+Q and `npm run dev`, the conversation view shows the same exchanges, in the same order, with the same citations as before the restart. The number of exchanges equals the length of the array in `qa-history.json`.

**AC-8 (pending state, no double submit).** While an answer is pending:

- the submitted question is already visible
- an "Answering…" (or equivalent) indicator is visible
- pressing Enter or clicking Ask again does not send a second `ASK_QUESTION`, which the log can show

Once the answer arrives, the indicator is replaced by the answer and no duplicate question turn remains.

**AC-9 (error handling).** When `qa:ask` rejects (trigger described in §6.4):

- an inline error message appears in the conversation
- all earlier exchanges stay on screen
- the app stays usable: a later ask succeeds once the fault is removed
- the failed question is not shown as answered

**AC-10 (empty state).** With no history (a fresh data directory, or after Clear), the panel shows an explanatory empty state instead of a blank area.

**AC-11 (clear).** The Clear control asks for confirmation inside the page. Cancelling keeps everything. Confirming empties the view **and** `qa-history.json` (the file contains `[]`), and the empty state still holds after a restart.

**AC-12 (auto-scroll).** After a new answer arrives in a conversation longer than the panel height, the newest exchange is scrolled into view without any manual scrolling.

**AC-13 (accessibility).** In the DOM, checked in DevTools Elements:

- the conversation container has `role="log"` or `aria-live="polite"`
- exchanges use list or article semantics
- the question input has an accessible name
- citations are `<button>` or `<a>` elements, not clickable `<div>`s
- the full flow (type the question, submit, Tab to a citation, activate it) can be done with the keyboard only

**AC-14 (layer boundaries).** The renderer still talks to main only through `window.knowledgeBase`. There are no new Node or Electron imports in the renderer, and no React in services or main. No business logic moves into the renderer: formatting dates and finding a document by ID count as display logic and are fine. There is a single `Window.knowledgeBase` typing; the duplicate global declaration in `App.tsx` and the one in `types.d.ts` must not contradict each other. Removing the duplicate is preferred.

**AC-15 (no dead code / clean repo).**

- The placeholder `TODO` in `ConversationHistory.tsx` is resolved, either by implementing it or by removing the component.
- The `lastResponse` state is removed if it is no longer used.
- `npm run build` passes.
- `git status` shows only intended files.

## 5. Constraints for the Generator

- Work order: Step 0 (baseline), commit, then the feature, then commit. Use separate commits so the baseline fix can be reviewed on its own.
- Keep the service and IPC layers unchanged unless a criterion cannot be met otherwise. If one can't, record it as a deviation.
- Don't add dependencies. Playwright and testing libraries are **not** required, and a test framework (vitest) is already present if a pure helper needs a unit test.
- `npm run check`, `npm run build` and `bash scripts/check-architecture.sh` must all pass before handing over.

## 6. Verification plan (end to end, in the running app)

The Evaluator runs every step against the built app started with `npm run dev`. Code reading alone does not count as verification of AC-1 to AC-13.

Save the evidence under `docs/evidence/conversation-history/`:

- screenshots, taken with `screencapture -x <file>.png` or `screencapture -w`
- log excerpts
- `verification-report.md`, which records the result of each step together with the AC ids it covers

### 6.1 Static gates (AC-0, AC-14, AC-15)

```bash
pwd
git log --oneline -5
npm install
npm run check                         # must exit 0
npm run build                         # must exit 0
bash scripts/check-architecture.sh    # must print PASS
grep -rn "substring\|\.\.\." src/renderer/components   # inspect: no answer truncation in the conversation view
grep -rn "interface Window" src/renderer               # single source of truth for the API typing
git status --short
```

### 6.2 Clean data directory and document seeding

1. Quit the app if it is running (Cmd+Q). Back up the existing data and start fresh:
   ```bash
   KB="$HOME/Library/Application Support/knowledge-base/knowledge-base-data"
   [ -d "$KB" ] && mv "$KB" "$KB.bak-$(date +%s)"
   ```
2. Run `npm run dev 2>&1 | tee docs/evidence/conversation-history/run1.log`.
3. **AC-10:** before asking anything, take a screenshot of the empty state (`01-empty.png`).
4. Open DevTools with View → Toggle Developer Tools (Alt+Cmd+I). In the Console, run the following, replacing `<repo>` with the absolute output of `pwd`:
   ```js
   for (const f of ['design-notes.md','meeting-summary.txt','retrieval-plan.md'])
     await window.knowledgeBase.documents.import(`<repo>/data/sample-documents/${f}`);
   await window.knowledgeBase.indexing.start();
   ```
   Then click **Refresh** in the header. Confirm that 3 documents are listed.

### 6.3 Long-answer fixture (AC-3)

With the app quit (Cmd+Q), append one synthetic exchange whose answer is longer than 1,500 characters, and whose citation points at a real document ID:

```bash
KB="$HOME/Library/Application Support/knowledge-base/knowledge-base-data"
node -e '
const fs=require("fs"),p=process.argv[1];
const h=fs.existsSync(p+"/qa-history.json")?JSON.parse(fs.readFileSync(p+"/qa-history.json")):[];
const d=JSON.parse(fs.readFileSync(p+"/documents-meta.json"))[0];
h.push({question:"FIXTURE: long answer",response:{answer:"Long answer sentence for wrapping. ".repeat(50),citations:[{documentId:d.id,documentTitle:d.title,chunkIndex:0,excerpt:"fixture excerpt"}],confidence:0.85,timestamp:new Date().toISOString()}});
fs.writeFileSync(p+"/qa-history.json",JSON.stringify(h,null,2));' "$KB"
```

Run this **after** §6.2, so that `documents-meta.json` exists. Afterwards, relaunch with `npm run dev`.

### 6.4 Scripted session

Type each step in the question input. Record a screenshot per step.

| # | Action | Expected | ACs |
|---|---|---|---|
| 1 | Relaunch. Observe the fixture exchange. | The long answer is shown in full and wraps. There is no horizontal scrollbar on the window. | AC-3, AC-7 |
| 2 | Ask `How does the indexing pipeline chunk documents?` | The question appears immediately with "Answering…", then the answer appears with ≥ 1 citation (title, chunk #, excerpt) and a readable timestamp. | AC-1, AC-4, AC-6, AC-8 |
| 3 | Ask `What did the meeting decide about retrieval?` and immediately press Enter or click Ask again while "Answering…" is visible. | Only one `ASK_QUESTION` line is added to the log (`grep -c ASK_QUESTION` on the run log before and after). There is no duplicate turn. | AC-8 |
| 4 | Observe the result of step 3. | A second exchange is added below. The first is unchanged. | AC-1, AC-2 |
| 5 | Ask `xyzzy plugh` | The answer says no relevant documents, and the view states that no sources were cited. There is no empty citations header. | AC-4 |
| 6 | Ask 3 or more further questions until the conversation is taller than the panel. | The newest exchange is scrolled into view automatically. | AC-12 |
| 7 | Click a citation from step 2. | `DocumentDetail` shows the cited document. | AC-5 |
| 8 | Keyboard only: Tab to the input, type `What design pattern is used?`, press Enter, Tab to one of its citations, press Enter. | The whole flow works without a mouse, and focus is visible at each step. | AC-5, AC-13 |
| 9 | DevTools Elements: inspect the conversation container, an exchange, the input, and a citation. | `role="log"`/`aria-live`, list or article semantics, an accessible name on the input, and citations that are buttons or links. | AC-13 |
| 10 | Compare the on-screen timestamps with `qa-history.json` (`cat "$KB/qa-history.json"`). | They match, after converting to local time. | AC-6 |

### 6.5 Error path (AC-9)

1. With the app running and the conversation non-empty, corrupt the history file:
   ```bash
   cp "$KB/qa-history.json" /tmp/qa-history.good.json
   echo '{not json' > "$KB/qa-history.json"
   ```
   `QaService.saveToHistory` will now throw, so `qa:ask` rejects.
2. Ask `How does retrieval work?` Expected:
   - an inline error is shown
   - earlier exchanges stay visible
   - the app does not crash
   - the log shows `Q&A failed`
3. Restore the file: `cp /tmp/qa-history.good.json "$KB/qa-history.json"`. Ask again. Expected: the answer appears normally.

### 6.6 Restart persistence (AC-7)

1. Count the exchanges on screen and run `node -e 'console.log(require(process.argv[1]).length)' "$KB/qa-history.json"`.
2. Quit with Cmd+Q, then run `npm run dev` again.
3. Expected: the same count, order, citations and timestamps as before. Take screenshots before and after.

### 6.7 Clear (AC-11, AC-10)

1. Click Clear, then Cancel. Nothing changes.
2. Click Clear, then Confirm. The view shows the empty state, and `cat "$KB/qa-history.json"` prints `[]`.
3. Restart. The empty state persists. Also check the sidebar History tab: its count is 0, or the tab has been removed, matching whichever choice was made for in-scope item 10.

### 6.8 Log checks

From the run logs, confirm:

- service initialization lines appear at startup
- each successful ask produced exactly one `ASK_QUESTION` and one `Q&A response` with `citationCount` matching the citations shown on screen
- the error step produced `Q&A failed`

### 6.9 Teardown

Quit the app. Optionally restore the backed-up data directory. Confirm that `git status` contains only intended changes, plus the evidence directory if it is being committed. Then score `rubric-template.md` and attach the evidence paths.

## 7. Definition of done

- All of AC-0 to AC-15 pass, with evidence in `docs/evidence/conversation-history/verification-report.md`.
- `npm run check`, `npm run build` and `bash scripts/check-architecture.sh` pass on the final commit.
- The repo restarts cleanly through the `AGENTS.md` startup workflow.
- Unresolved risks are listed in the final summary.

## 8. Known risks

- **Pending turn vs persisted history.** The renderer shows a pending question before the service has saved it. The Generator must reconcile the optimistic turn with the refreshed history, or the question will appear twice (covered by AC-8).
- **Stale citations.** Citations can point at documents that have since been deleted (covered by AC-5).
- **Seeding is manual.** Documents can only be seeded through the DevTools console, because the Import button is broken and out of scope.
- **Mock answers repeat.** The mock produces repetitive answers. Distinguish exchanges by their question text and timestamp, not by their answer text.

## Contract deviations

_(The Generator records any deviation here, with the reason. Empty at signing.)_
