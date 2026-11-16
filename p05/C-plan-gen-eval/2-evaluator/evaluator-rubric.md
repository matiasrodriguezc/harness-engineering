# Evaluator rubric: multi-turn Q&A conversation history

- **Evaluator:** independent evaluator (did not write or modify application code or `sprint-contract.md`)
- **Date:** 2026-11-15
- **Commit evaluated:** `f53fa54` (feature), on top of `b17561e` (Step 0) and `96007e7` (preload fix, D-1)
- **Inputs:** `rubric-template.md`, `sprint-contract.md`
- **Evidence:** `docs/evidence/conversation-history/evaluator/` (screenshots `01`–`21`, raw results `p1.json`–`p3.json`, app logs `run1.log`–`run5.log`, driver scripts in `scripts/`)

## How it was verified

I did not reuse the Generator's scripts or results. I wrote my own Chrome DevTools Protocol driver (`evaluator/scripts/cdp.mjs`, `p1.mjs`–`p5.mjs`) and ran it against the built app (`tsc` + `vite build`, then `npx electron .`). The driver uses real `Input.dispatchKeyEvent`/`dispatchMouseEvent` events, takes screenshots, and records `Runtime.exceptionThrown` and every `console.*` call.

**Deviations from §6 of the contract:**

- **Data directory.** I used an isolated `--user-data-dir` in a scratch folder, so the user's real `~/Library/Application Support/knowledge-base` was never touched. The data landed in `<ud>/knowledge-base-data/`.
- **Restarts.** I stopped the app with SIGTERM instead of Cmd+Q. The service writes `qa-history.json` synchronously on every ask, so nothing is lost that Cmd+Q would have saved.
- **Screenshots.** I took them with `Page.captureScreenshot`, not `screencapture`.
- **Screen reader.** I did not test with VoiceOver, so live-region announcements were checked only through the DOM.

The §6.3 fixture script was run verbatim.

## Acceptance criteria (sprint-contract.md §4)

| AC | Result | Evidence |
|---|---|---|
| AC-0 | PASS | `npm run check` exit 0. `bash scripts/check-architecture.sh` printed `PASS: All architecture boundary checks passed`. `npm run build` OK. `npx vitest run`: 7/7 passed. |
| AC-1 | PASS | Fixture + 9 asks gave 10 exchanges, oldest first. After ask #2, the earlier exchanges' `innerText` was byte-identical to before (`p2.json` `s4_firstUnchanged: true`). |
| AC-2 | PASS | "YOU" bubble right-aligned in `#0f3460`; "ASSISTANT" card in `#1a1a3e`. The text labels mean colour isn't needed to tell them apart (`04-first-answer.png`). |
| AC-3 | PASS | Fixture answer rendered at 1,750/1,750 chars with no ellipsis. Scroller 920/920 and document 1200/1200 (`scrollWidth`/`clientWidth`). A 400-char unbroken question also wraps with no overflow (`12-long-unbroken-question.png`). At a 700 px viewport the document is 700/700 (`11-narrow-700px.png`). |
| AC-4 | PASS | Each citation shows title · chunk N · excerpt. `xyzzy plugh` shows "No sources cited." and no "Sources" header (`06-no-citations.png`). |
| AC-5 | PASS with defect | Click, Enter and Space each open `DocumentDetail` with the cited title (`s7`, `s8_enterOpened`, `s8_spaceOpened`). No exceptions and no console errors. However, a citation to a deleted document opens a stale "ghost" detail until the list is refreshed (see defect 2). |
| AC-6 | PASS | `<time datetime=ISO>` shows `Nov 15, 2026, 10:59 PM`. All 9 `datetime` values match `qa-history.json`, and the text matches their local (UTC-3) rendering (`p2.json` `s10_times`). |
| AC-7 | PASS | Restart: 11 exchanges before = 11 after = 11 in the file. Question, timestamp and citation titles match exactly (`sameAsBefore: true`, `sameAsFile: true`, `17-after-restart.png`). |
| AC-8 | PASS | Immediately after Enter, the pending turn shows the question + "Answering…". While it was pending: Enter, a click on Ask, and Enter again gave an `ASK_QUESTION` delta of **1**. The question appears only once, and the second draft stays in the input. |
| AC-9 | PASS with defect | With a corrupted history file: an inline "NOT ANSWERED" turn appears, all 10 earlier exchanges stay, and `Q&A failed` is logged. After restoring the file, Retry succeeds and the error turn is removed (`13-error.png`, `14-after-retry.png`). However, a second failure silently drops the first failed question (see defect 1). |
| AC-10 | PASS | Empty state on a fresh data dir (`01-empty.png`), after Clear (`19`), and after a restart (`20`). |
| AC-11 | PASS | In-page "Delete all 11 exchanges? This cannot be undone." with Cancel / Clear conversation. Focus moves to Cancel. Cancel keeps all 11. Confirm empties the view and the file (`[]`), and the empty state persists after restart. |
| AC-12 | PASS | scrollHeight 4112 > clientHeight 592. After the new answer the panel was at the bottom and the whole last exchange was visible (`07-autoscroll.png`). |
| AC-13 | PASS | `div[role=log][aria-live=polite]` > `ol` > `li` > `article[aria-label="Exchange 1 of 9"]`. The input has `<label for=question-input>`. Citations are `<button>`s; the only clickable divs are the pre-existing `DocumentList` rows, outside the conversation. Keyboard-only flow works. The focused citation shows `outline: solid 2px rgb(136,136,187)` and matches `:focus-visible`. |
| AC-14 | PASS | A single `interface Window` (`src/renderer/types.d.ts:5`). The renderer uses only `window.knowledgeBase`. No service or main changes in `f53fa54`. |
| AC-15 | PASS | `ConversationHistory.tsx` deleted, `lastResponse` gone, build passes, `git status` was clean at the start. |
| §6.8 logs | PASS | 8 startup init lines. `run2.log`: 12 `ASK_QUESTION` = 10 `Q&A response` + 2 `Q&A failed`. The `citationCount` values (2,2,0,2,…) match the citations on screen. |

## Scores

| Criterion | Score | Evidence |
|---|---|---|
| Functional completeness | **5** | AC-1, 3, 7, 8 and 12 all passed in the running app: 10 exchanges accumulated, nothing changed or truncated (1,750/1,750 chars), the restart round-trip matched the file exactly, and there was no double submit. |
| Visual design | **4** | Clear You/Assistant distinction, the existing palette, and inline styles (`04`, `08`). The confidence bar and the "· open" marker are nice touches. One deduction: with a document open at small window sizes, the 40% detail strip leaves the conversation only ~230 px (`11-narrow-700px.png`). The error red `#d9534f` is outside the listed palette, but it's reasonable for errors. |
| Timestamps | **5** | Readable local time in a `<time datetime>` element, verified against the file for all 9 entries. Invalid dates fall back to "Unknown time" (unit test). Minor: the resolution is minutes only, so rapid asks all show "10:59 PM". The contract's own example format accepts this. |
| Citation display | **4** | Title, chunk and full excerpt shown; usable with mouse, Enter and Space; selected-state marker; zero-citation wording. Deduction for defect 2: a stale document list opens a deleted document's detail panel instead of the "no longer available" notice (`15-stale-citation-before-refresh.png`). |
| Interactivity | **4** | Citation → document, Retry, Dismiss, Clear with confirmation, and a Close button on the detail strip all work. Deductions: Escape does not cancel the Clear confirmation (`escClosed: false`), and there is no copy action. Asking a new question after a failure discards the failed one (defect 1). |
| Edge cases | **4** | Empty, loading, load-error (`21-startup-corrupt-history.png`), long answer, long unbroken question, no citations, ask failure, and a deleted cited document after refresh are all handled with no exceptions. Deductions: defect 1 (a failed question is lost on the next failure or ask), defect 2 (ghost document), and defect 4 (in the load-error state Clear is disabled, so there is no in-app recovery). |
| Accessibility | **4** | role=log + aria-live, `ol`/`li`/`article`, a real `<label>`, button citations, `:focus-visible` outline, `role=alert` on errors, and focus moves to Cancel and back on Cancel. Deductions: after confirming Clear, focus falls to `<body>` (`afterClear.focus: BODY`). Escape doesn't close the confirmation. From the input, forward Tab needs 18 presses to reach the newest citation, because the input comes after every citation in DOM order (Shift+Tab takes 1). Announcements were not verified with a screen reader. |
| Code quality | **4** | check, build, architecture and vitest all pass. Display helpers are pure and tested. No new IPC. The duplicate `Window` typing was removed and there's no dead code. Deductions: deviation D-1 was recorded only in `generator-report.md`, not in the contract's "Contract deviations" section as the contract requires. `ConversationView.tsx` is 454 lines with all the sub-components inline. |

**Overall: 4.3** (34 / 8 = 4.25)

## Defects the Generator must fix (most important first)

1. **A failed question is silently lost** (AC-9 / in-scope item 7, "question text not silently lost").
   - **Cause:** `App.tsx:66` calls `setAskError(null)` at the start of every ask, and `askError` holds only one entry (`ConversationView.tsx:415`).
   - **Repro:** corrupt the history, ask "How does retrieval work?", then ask "Second failing question". Only the second question remains (`p3.json` `err2`). The first was never answered, and it isn't in the input, the view, or the file.
   - The same thing happens when you simply ask a new question after a failure: the failed one disappears without being retried.
   - **Fix:** keep the failed question until it is retried or dismissed (or restore it to the input), and don't overwrite one error with another.
2. **A citation to a deleted document opens a ghost `DocumentDetail`** (AC-5).
   - **Cause:** `handleOpenCitation` (`App.tsx:95-98`) trusts the cached `documents` list. After `documents.delete(id)` without a Refresh, clicking the citation shows the deleted document's metadata and actions (`15-stale-citation-before-refresh.png`). The "This document is no longer available." notice appears only after a manual Refresh (`16`).
   - **Fix:** confirm through `documents.get(id)`, or refresh the list before selecting.
3. **Focus is lost after confirming Clear** (accessibility). `confirmClear` (`ConversationView.tsx:286-290`) unmounts the focused button and doesn't move focus, so it lands on `<body>`. Move it to the question input or to the conversation heading.
4. **There's no recovery from a corrupted or unreadable history at startup.** The panel shows "Could not load the conversation history. Try again", but Try again can never succeed, and Clear is disabled because `history.length === 0` (`ConversationView.tsx:334`) (`21-startup-corrupt-history.png`). Allow Clear in the `error` load state.
5. **Escape does not cancel the in-page Clear confirmation** (`ConversationView.tsx:315-328`). Add an Escape handler on the confirm group that calls `cancelClear`.
6. **Keyboard reach to the newest answer's citations is poor going forward.** From the input, 18 forward Tabs are needed (`s8_forwardTabsToNewestCitation`), because Tab walks through every citation in history first. Shift+Tab works in 1 press. At minimum, document this. Better: add a skip link or a shortcut that focuses the newest exchange.
7. **Record the contract deviation in the right place.** D-1 (the preload sandbox fix) belongs under "Contract deviations" in `sprint-contract.md`, as the contract requires, not only in `generator-report.md`. Do this if the user permits that edit; otherwise get the user's sign-off on recording it elsewhere.
8. **The error turn shows raw technical text** ("Details: SyntaxError: Expected property name or '}' in JSON at position 1…", `13-error.png`). Keep the details behind a disclosure, or use plain wording.

**Not counted against this sprint (pre-existing, out of scope):** the status bar shows an empty "Index:" and "Documents:". `DocumentList` rows are clickable `<div>`s that can't be reached by keyboard. The CSP dev warning. The mock answer text doesn't match the question (for example, the indexing question gets an answer about importing). The IPC table in `docs/ARCHITECTURE.md` is missing `qa:clear-history` and `conversation:get`.
