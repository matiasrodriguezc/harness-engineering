I fixed and verified 7 of the 8 defects. Defect 7 needs your decision. Everything is committed as `33b3ff4`, and the working tree is clean.

| # | Defect | Fix |
|---|---|---|
| 1 | Failed question lost | Every failed question now stays on screen until you retry or dismiss that specific one. Neither a new question nor a second failure removes it. |
| 2 | Clicking a citation to a deleted document opened it anyway | The app now checks with the backend that the document still exists, instead of trusting the possibly outdated document list. A deleted one shows "This document is no longer available.", the list refreshes on its own, and a detail panel that was open for it closes. |
| 3 | Focus lost after Clear | Focus moves to the "Conversation" heading. If clearing fails, it goes back to the Clear button. |
| 4 | No way out of a corrupted history at startup | Clear now works in that error state. Confirming replaces the unreadable file with an empty history. |
| 5 | Escape didn't cancel the Clear confirmation | Escape now cancels it and returns focus to Clear. |
| 6 | 18 Tab presses to reach the newest answer's sources | A "Jump to latest answer" button appears right after Ask when you Tab to it, and Alt+↑ in the question box does the same. The newest source is now 4 key presses away. |
| 8 | Raw technical error text | The error now uses plain wording, with the technical message folded under a "Technical details" toggle. |

I also moved the message components out of `ConversationView.tsx` (454 → 237 lines) into a new `ConversationTurns.tsx`. Nothing outside the renderer changed.

**Verification:**
- `npm run check`, `npm run build` and `bash scripts/check-architecture.sh` all pass.
- Unit tests: 9/9 pass, including 2 new ones for the failed-question list.
- I ran a new script against the built app, with its own data folder and real key presses and clicks. All 18 checks passed: 14 starting from empty data, 4 starting from a corrupted history file. Neither run showed errors or exceptions; the only console message was Electron's usual development security warning.
- One run failed at first because the script typed before focus had finished moving to the heading. That was a timing problem in the script, not the app, and the script now waits for it.
- The report, screenshots, logs and scripts are in `docs/evidence/conversation-history/generator/fixes/`; start with `fixes-report.md`.

**Decision for you — defect 7:** in the earlier session you told me to leave `sprint-contract.md` unedited, and the rubric only allows this change with your permission. So the note on the earlier preload fix is still only in `generator-report.md`. Should I add it to the "Contract deviations" section of `sprint-contract.md`, or are you fine with it staying where it is?

**Remaining risks:**
- Failed questions are kept only while the app is open and are gone after a restart. That's deliberate, so the saved history file's format doesn't change.
- An existing issue I didn't fix: after a document is deleted, new answers can still cite it as "Unknown Document", because deleting doesn't remove it from the search index.
- Nobody has tested with a real screen reader yet.