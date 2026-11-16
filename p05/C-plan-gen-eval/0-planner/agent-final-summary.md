I wrote and committed `sprint-contract.md` (commit `4ccd99b`). I didn't change any application code.

**The starting point is broken.** `npm run check` currently fails with 15 type errors in the renderer, mostly imports of `shared/types` that don't resolve. `npm run build` still passes, so the app runs anyway. `AGENTS.md` says not to build on a failing baseline, so the contract makes a small fix for this the first step (AC-0), committed separately.

**What's in the contract:**
- **In scope:** the conversation view replaces the single answer the question panel shows today. It covers:
  - every question and full answer, oldest first, plus timestamps and confidence
  - citations showing document, chunk number and excerpt; clicking or pressing Enter on one opens that document
  - history loaded from the saved `qa-history.json`, so it survives a restart
  - a waiting state that blocks a second submission, an inline error, an empty state, and a Clear button with an in-page confirm
  - automatic scrolling to the newest answer, and basic accessibility (screen-reader announcements, a labelled input, citations as real buttons or links)
  - a decision on the sidebar History tab: keep it consistent or remove it
- **Out of scope:** using earlier turns as context when generating an answer (this sprint is about display only), a real LLM, streaming, multiple conversations, fixing the Import button, new IPC channels or changes to the history file format, and a restyle.
- **Acceptance criteria:** 16 pass/fail checks, AC-0 to AC-15, each needing evidence.
- **Verification plan:** the reviewer runs everything in the app started with `npm run dev`; reading the code doesn't count. Steps:
  - Back up the app's data folder and start with none.
  - Load the three sample documents from the DevTools console, since the Import button only logs to the console.
  - Add a test exchange with an answer over 1,500 characters to check long answers wrap.
  - Run a scripted session of about 10 steps: a question with citations, a question with no matches (`xyzzy plugh`), a double-submit check against the log, and a keyboard-only run.
  - Break the history file on purpose so asking fails, check the error shows, then restore it.
  - Quit with Cmd+Q and relaunch to check history survives.
  - Test Clear: cancelling keeps everything; confirming empties the screen and the file and stays empty after a restart.
  - Check the logs. All evidence goes in `docs/evidence/conversation-history/`.

**Left behind:** running `npm install` created an untracked `package-lock.json`. I didn't commit it; whoever implements the feature can decide whether to keep it.