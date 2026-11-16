# Evaluator rubric: multi-turn Q&A conversation history (re-review, round 2)

- **Evaluator:** independent evaluator (did not write or modify application code or `sprint-contract.md`)
- **Date:** 2026-11-15
- **Commit evaluated:** `33b3ff4` ("Fix evaluator defects 1-6 and 8"), on top of `f53fa54` (feature), `96007e7` (preload fix, D-1) and `b17561e` (Step 0)
- **Inputs:** `rubric-template.md`, `sprint-contract.md`, the round-1 defect list
- **Evidence (this round):** `docs/evidence/conversation-history/evaluator/round2/`: screenshots `01`–`13`, raw results `p2.json`, `r2a.json`, `r2b.json`, `r2c.json`, app logs `run1.log`–`run5.log`, driver scripts in `scripts/`. Round-1 evidence in `evaluator/` is kept for comparison.

## How it was verified

I did not use the Generator's `fixes.mjs` or its results. I reused my own round-1 CDP driver (`cdp.mjs`, `p1`/`p2`/`p4`/`p5`) as a full regression pass, and wrote new drivers aimed at the revised behaviour (`r2a.mjs`, `r2b.mjs`, `r2c.mjs`). All runs used the built app (`npm run build`, then `npx electron .`) with real `Input.dispatchKeyEvent`/`dispatchMouseEvent` events, and with a fresh isolated `--user-data-dir` in the scratchpad, so the user's real data directory was never touched. Documents were seeded through the preload API (§6.2), and the §6.3 long-answer fixture script was run verbatim.

These deviations from §6 are the same as in round 1: SIGTERM instead of Cmd+Q (history is written synchronously), `Page.captureScreenshot` instead of `screencapture`, and no VoiceOver test (live regions were checked in the DOM only).

## Status of the round-1 defects

| # | Round-1 defect | Status | Evidence |
|---|---|---|---|
| 1 | A failed question is silently lost | **Fixed** (but see new defect 1) | Two failures in a row are both kept (`r2a.json` `d1_twoFailures`, `03-two-failures.png`). The input is empty after a failure, but the question stays in its turn. Retry turns it into an answered exchange (`d1_afterRetry`); Dismiss removes only that entry. |
| 2 | Ghost `DocumentDetail` for a deleted cited document | **Fixed** | With `design-notes` open, I deleted it through the API without a Refresh, then clicked its citation. The detail closed (`detail: null`), the citation shows "This document is no longer available.", the list refreshed itself to "Documents (2)", and there were no exceptions or console errors (`d2_*`, `06-deleted-citation.png`). Citations to live documents still open them. |
| 3 | Focus falls to `<body>` after confirming Clear | **Fixed** | Focus goes to `H2: Conversation (0 exchanges)` (`p4` output, and again in `r2c.json`). |
| 4 | No recovery from an unreadable history at startup | **Fixed** | Started with `{not json`. The error panel points to Clear, Clear is enabled, and the confirmation says "Replace the unreadable conversation history with an empty one?". Confirming writes `[]`, shows the empty state, and the next ask persists (`r2c.json`, `12-startup-corrupt.png`, `13-recovered.png`). |
| 5 | Escape doesn't cancel the Clear confirmation | **Fixed** | `escClosed: true` (`p4` output). |
| 6 | Poor forward keyboard reach to the newest citations | **Fixed** | Input → Tab (Ask) → Tab ("Jump to latest answer", visible with a focus ring when focused, `01-jump-button-focused.png`) → Enter (focus on `#latest-exchange`, `:focus-visible`) → Tab reaches the newest citation (`r2b.json` `kb_path`). That's 4 presses, down from 19. Alt+ArrowUp from the input also works (`d6_altArrowUp`). |
| 7 | D-1 not recorded in the contract's "Contract deviations" section | **Open, needs the user's decision** | The Generator held off because the user told it not to edit `sprint-contract.md`. That is a reasonable call. It's listed below for the user, not counted against code quality. |
| 8 | Raw technical text in the error turn | **Fixed** | Plain wording, with the raw message inside a closed `<details>` "Technical details" (`d1_detailsOpenByDefault: [false,false]`). |

## Acceptance criteria (sprint-contract.md §4), regression pass

| AC | Result | Evidence |
|---|---|---|
| AC-0 | PASS | `npm run check` exit 0. `npm run build` OK. `bash scripts/check-architecture.sh` printed `PASS: All architecture boundary checks passed`. `npx vitest run`: 9/9 passed. |
| AC-1 | PASS | The fixture plus 9 asks gave 10 exchanges, oldest first. Earlier exchanges were byte-identical after later asks (`p2.json` `s4_firstUnchanged: true`). |
| AC-2 | PASS | "YOU" / "ASSISTANT" text labels, plus alignment and background. |
| AC-3 | PASS | Fixture answer 1,750/1,750 chars, no ellipsis. Scroller 920/920, document 1200/1200. At 700 px: 700/700. A 400-char unbroken question wraps. |
| AC-4 | PASS | Title · chunk N · excerpt. `xyzzy plugh` shows "No sources cited." and no Sources header. |
| AC-5 | PASS | Click, Enter and Space open the cited document (`s7`, `s8_enterOpened`, `s8_spaceOpened`). A deleted document gives no ghost and no errors (round-1 defect 2 fixed). |
| AC-6 | PASS | `<time datetime>` shows `Nov 15, 2026, 11:10 PM`. All `datetime` values equal the `timestamp` values in the file. |
| AC-7 | PASS | Restart: 16 on screen before = 16 after = 16 in the file. Question, timestamp and citation titles match exactly (`sameAsBefore: true`, `sameAsFile: true`, `08-after-restart.png`). |
| AC-8 | PASS | Pending turn + "Answering…" shown immediately. Enter, a click on Ask, then Enter while pending gave an `ASK_QUESTION` delta of 1, and no duplicate question turn. |
| AC-9 | PASS | Inline "NOT ANSWERED" turn, earlier exchanges kept, `Q&A failed` logged, later asks succeed. Failed questions are no longer lost. |
| AC-10 | PASS | Empty state on a fresh data dir, after Clear (`10`), and after a restart (`11`). |
| AC-11 | PASS | In-page confirmation, focus on Cancel; Cancel keeps 16; Escape closes it; Confirm empties the view and the file (`[]`); the empty state persists after restart. |
| AC-12 | **PASS on the main path, FAILS after a failure** | Normal path: scrollHeight 4112 > clientHeight 592, and the last exchange is fully visible (`s6`). However, when a failed turn exists and a new question is then answered, the new answer is pushed out of view (new defect 1). |
| AC-13 | PASS | `div[role=log][aria-live=polite]` > `ol` > `li` > `article`; `<label for=question-input>`; citations are `<button>`s; keyboard-only flow works; `:focus-visible` outline on citations. |
| AC-14 | PASS | A single `interface Window` (`src/renderer/types.d.ts:5`). No service, main, preload or IPC changes in `33b3ff4`. |
| AC-15 | PASS | Build passes. No dead code found. `git status` was clean at the start. |
| §6.8 logs | PASS | 8 startup init lines (`run1.log`). `run2.log`: 19 `ASK_QUESTION` = 15 `Q&A response` + 4 `Q&A failed`. |

## Scores

| Criterion | Score | Evidence |
|---|---|---|
| Functional completeness | **5** | AC-1, 3, 7 and 8 pass in the running app: exchanges accumulate, nothing is truncated (1,750/1,750), restart round-trips 16/16 against the file, and there is no double submit. Failed questions are no longer lost. The ordering problem after a failure is scored under Edge cases. |
| Visual design | **4** | Clear You/Assistant distinction, the existing palette, and inline styles. Plain error wording with a disclosure for details. Deductions: the 40% detail strip still leaves the conversation cramped at small window sizes (round 1), and the "Jump to latest answer" button appears inline when focused, which makes the input shrink (`01-jump-button-focused.png`). This is minor. |
| Timestamps | **5** | Readable local time in `<time datetime>`, matching the file. Unchanged from round 1. |
| Citation display | **5** | Title, chunk and excerpt shown; works with mouse, Enter and Space; selected-state marker; zero-citation wording. A deleted document now shows the "no longer available" notice with no ghost detail and no errors (`06`). New answers citing "Unknown Document" after a delete come from the service index, which is pre-existing and out of scope. |
| Interactivity | **4** | Retry, Dismiss, Escape-cancel, Clear (including recovery from a corrupted history), Jump to latest, Alt+ArrowUp, and citation → document all work. Deductions: failed turns are not in chronological order, and retrying a failed question while the fault persists moves it to the end of the failure list (`d1_retryStillBroken`). There is still no copy action. |
| Edge cases | **4** | These are all handled with no exceptions: two failures in a row, retry while still broken, a deleted cited document with the cached list stale, an unreadable history at startup (now recoverable), long answers, long unbroken questions, and no citations. Deduction for new defect 1: after a failure, the next successful answer renders above the stale failed turns, and auto-scroll lands on the failures. With 2 failed turns the new answer was entirely out of view (`04-order-after-new-success.png`); with 1 failed turn, its top 108 px were clipped (`r2b.json` `vis_newAnswerAfterFailure`). |
| Accessibility | **4** | role=log + aria-live, `ol`/`li`/`article`, a real label, button citations, `:focus-visible`, focus management for Clear (Cancel ↔ Clear, heading after confirm), Escape, skip control and `aria-keyshortcuts`. Deduction for new defect 2: activating Retry or Dismiss unmounts the focused button and focus falls to `<body>` (`d1_focusAfterDismiss`, `focusAfterRetry`). This is the same class of bug as round-1 defect 3, now in the failed turn. Screen-reader announcements were not verified. |
| Code quality | **5** | check, build, architecture and vitest (9/9) all pass. `ConversationView.tsx` went from 454 to 237 lines, with the turns split into `ConversationTurns.tsx`. The failure-list helpers are pure and tested. There are no service, IPC or schema changes, no duplicate `Window` typing, and no dead code. Defect 7 is a process question awaiting the user, so it is not counted here. |

**Overall: 4.5** (36 / 8). Round 1 was 4.3.

## Defects the Generator must fix (most important first)

1. **After a failure, a newly answered question is hidden and out of order** (AC-12, edge cases).
   - **Cause:** `ConversationView.tsx` renders all `history` items first and all `askErrors` after them, and the auto-scroll effect sets `scrollTop = scrollHeight`. Failed turns therefore stay pinned to the bottom, below answers that came later, and the scroll lands on them.
   - **Repro:** corrupt `qa-history.json`, ask twice (both fail), restore the file, ask "What design pattern is used?". The answer is placed above the two failed turns and is completely out of view (`round2/04-order-after-new-success.png`). With one failed turn, the new answer's top is clipped (`r2b.json`: latestTop −12 vs viewTop 96).
   - **Fix:** either interleave the turns chronologically (record where each failure happened relative to `history.length`), or, at minimum, scroll the newest *answered* exchange (`#latest-exchange`) into view when an answer arrives, instead of jumping to the bottom of the list.
2. **Focus is lost after Retry and Dismiss** (accessibility).
   - **Cause:** `FailedTurn` (`ConversationTurns.tsx`) unmounts with its focused button, and nothing moves focus, so it lands on `<body>` (`r2a.json` `d1_focusAfterDismiss`, `r2b.json` `focusAfterRetry`).
   - **Fix:** after Dismiss, move focus to the next failed turn's Retry button, or to the question input if there is none. After Retry, move focus to the question input (or the pending turn), as was done for Clear.
3. **Contract deviation D-1 is still recorded only in `generator-report.md`** (carried over from round-1 defect 7).
   - This needs the **user's** decision. Either permit the Generator to add D-1 under "Contract deviations" in `sprint-contract.md`, or explicitly accept `generator-report.md` as the record.
4. *(Minor)* **Clear is disabled when the only turns are failed ones.** With an empty history and one or more failed turns, Clear is disabled (`canClear` needs `history.length > 0`), so the user must dismiss each failure one by one. Consider enabling Clear when `askErrors.length > 0`.
5. *(Minor, cosmetic)* **Focusing "Jump to latest answer" makes the input shrink.** The button changes from visually hidden to an inline button inside the form row, which reflows the input. Consider positioning it absolutely (as typical skip links are) so the input doesn't move.

**Not counted against this sprint (pre-existing, out of scope):** the status bar shows an empty "Index:" and "Documents:". `DocumentList` rows are clickable `<div>`s (4 found) that can't be reached by keyboard. The Electron CSP dev warning. The mock answer text doesn't match the question. After a document is deleted, new answers can still cite its chunks as "Unknown Document", because the index is not purged on delete. The IPC table in `docs/ARCHITECTURE.md` is missing `qa:clear-history` and `conversation:get`.
