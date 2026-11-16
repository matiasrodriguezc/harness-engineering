# Evaluator rubric: multi-turn Q&A conversation history (re-review)

- Evaluated commit: `cbe074c Fix evaluator defects in conversation history`. The previous review covered `8c65398`.
- Date: 2026-11-15. Electron 33 on macOS (darwin).
- Rubric: `rubric-template.md`. The repo still has no `sprint-contract.md`, so only the rubric was used.
- Evaluator role: independent reviewer. I did not change any application code. I changed only this file and files under `evaluation/`:
  - `probe-conversation.mjs`: selectors updated for the new `role="log"` wrapper. The P9b threshold now allows the 12px container padding, which round 1 had already marked as a false positive.
  - `probe-round2.mjs`: new adversarial probes.
  - Screenshots in `evaluation/` and `evaluation/round2/`.

## What I ran

| Step | Result |
|---|---|
| `npm run check` | exit 0 |
| `bash scripts/check-architecture.sh` | all boundary checks PASS |
| `npm test` | 20/20 pass |
| `npm run build` | succeeds |
| Generator's `scripts/verify-conversation.mjs` against the real Electron app. Screenshots went to my scratchpad, so `docs/verification/` was not overwritten. | **34/34 PASS**, matching `docs/verification/README.md` |
| Round-1 probes (`evaluation/probe-conversation.mjs`) | **13/13 PASS** after the P9b threshold change (12/13 before it; the only failure was the 11.5px container padding). Every defect round 1 found is fixed. |
| Round-2 probes (`evaluation/probe-round2.mjs`) | **4/8.** Details below |

To rerun: `npm run build && node --experimental-websocket evaluation/probe-conversation.mjs` and `node --experimental-websocket evaluation/probe-round2.mjs`.

Round-2 results:

```
PASS  R1 double Enter (two real CDP key events) creates one exchange — n=1
FAIL  R2 failed clear is reported to the user — {"n":2,"alerts":[]}
FAIL  R3 failed clear does not silently drop the pending question — {"n":2,"alerts":[],"pending":false,"onDisk":2}
PASS  R4 citation to a missing chunk explains itself — "The cited chunk 100 is no longer in this document's index…"
FAIL  R5 stop-word question answer is not misleading — "why?" → "No relevant documents have been indexed yet…"
FAIL  R6 sidebar History does not claim "no history" when loading failed — "History (0) · No conversation history yet."
PASS  R7 repair + Refresh recovers — {"n":3,"alerts":[]}
PASS  R8 all thread controls are in the tab order
```

Note on R1: my first version called `requestSubmit()` twice in the same task and got 2 exchanges. A real user cannot do that, because separate keypresses are separate tasks. I redid the test with real CDP Enter key events and it passed, so this is **not** counted as a defect.

R2 and R3 make `qa-history.json` read-only (`chmod 444`) to force a write failure on Clear.

## Scores

| # | Criterion | Score (round 1 → now) |
|---|---|---|
| 1 | Functional completeness | 4 → **5** |
| 2 | Visual design | 4 → **5** |
| 3 | Timestamps | 5 → **5** |
| 4 | Citation display | 3 → **5** |
| 5 | Interactivity | 4 → **4** |
| 6 | Edge cases | 3 → **4** |
| 7 | Accessibility | 4 → **4** |
| 8 | Code quality | 4 → **4** |
| | **Overall (36 / 8)** | **4.5** (was 3.9) |

### 1. Functional completeness: 5

- I asked several questions in a row in the running app. All appear in order, and the answers match the persisted text exactly (E2E checks).
- The conversation survives a restart.
- 300 exchanges render in 75 ms (P9).
- A load failure now clears the stale conversation and the counts: P11 shows `n:0`, "Conversation (0 exchanges)" and "History (0)". This was the main defect in round 1.
- A malformed entry no longer hides the valid ones (P10, and the E2E check "good one", "good two").
- Clearing while a question is pending now leaves the conversation empty, both in the UI and in the file (P8 and E2E).
- The remaining loss case only happens when Clear fails (see criterion 6), so I scored it under edge cases, not here.

### 2. Visual design: 5

- Questions are right-aligned purple bubbles labelled "You". Answers are left-aligned dark bubbles labelled "Assistant" (my run's `02-conversation.png`).
- Citation excerpts are now plain single paragraphs clamped to 3 lines, with markdown removed. The E2E check measured the sources block at about 122px against about 90px for the answer, which is comparable rather than dominant.
- Long answers are cut on a word boundary (`ExchangeItem.tsx` uses `truncateAtWord`).
- The palette matches the rest of the app.
- Small leftover issue, which comes from the starter: the mock answer text contains a raw 100-character slice ("Retrieval-Augmen."). It is listed under known issues and I did not count it.

### 3. Timestamps: 5

- Every exchange shows a `<time datetime>` for both the question and the answer, in formats like "Today, 10:32 PM", "Yesterday, …" and "Mar 4, 2025, 7:00 AM".
- Hovering shows the full date.
- Round 1 noted the 2-digit hour; it is now `hour: 'numeric'`.
- Round 1 noted that "Today/Yesterday" never refreshed; there is now a midnight timer in `App.tsx` (the `now` state). I checked this by reading the code; I did not wait past midnight.

### 4. Citation display: 5

- Each source shows the document, the 1-based chunk number ("chunk 1") and a clean excerpt.
- Clicking a source opens the document, expands its chunks, then scrolls to, focuses and highlights the cited chunk, which is labelled "· cited in the answer". Evidence: P6, the E2E check (`focused:true, visible:true, onlyOne:true`) and my `03-citation-opens-document.png`.
- A citation to a chunk that no longer exists shows a `role="status"` notice (R4).
- Citations to deleted documents are still marked "(document no longer available)".

### 5. Interactivity: 4

These all work:
- Copy, with feedback.
- Follow-up chip with Esc to cancel.
- Follow-up chains: retrieval now uses up to 5 ancestor questions, and a unit test covers a 4-turn chain. P3 still grounded.
- Expand and collapse long answers.
- Collapse sources.
- Selecting an exchange from History jumps to it.
- Retry and Dismiss on errors.
- Clear confirmation: Cancel and Esc both return focus to "Clear conversation" (P4 and E2E).
- A double Enter creates one exchange (R1).
- Repairing the file and pressing Refresh recovers the conversation (R7).

Why it is not a 5:
- **A failed Clear does nothing and says nothing** (R2, `evaluation/round2/r2-clear-failed.png`). Both exchanges stay on screen and no alert appears. Cause: `App.tsx:110` sets `historyError`, then `App.tsx:112` calls `refreshConversation()`. That read succeeds and resets `historyError` to null.
- **A failed Clear also silently throws away the pending question** (R3, `evaluation/round2/r3-clear-failed-pending.png`). The question "How are documents indexed into chunks?" disappears. It is not saved (`onDisk:2`), no error is shown, and the conversation was not cleared either. Cause: both `App.tsx:103` (`clearEpoch.current++`) and `qa-service.ts:267` (`clearGeneration++`) mark the pending answer for discard *before* the clear is known to have succeeded.

### 6. Edge cases: 4

Verified in the app:
- Empty history.
- Long answer (1200 characters collapsed, 3190 expanded).
- Long unbroken question (no overflow).
- Answer without citations.
- IPC failure with Retry.
- Legacy entry.
- Malformed entry skipped, with a WARN log; the entry is kept on disk (unit test).
- Corrupt or non-list file: a user-facing message with the file path, shown above the composer. The file is left untouched (P11, P11b, P11c).
- Write failure translated into a readable message (unit test).
- Missing cited chunk (R4).
- Recovery after repairing the file (R7).

Remaining gaps:
- The Clear write-failure path described under Interactivity (R2, R3).
- While loading has failed, the sidebar History tab says "No conversation history yet. Ask a question to get started." (`ConversationHistory.tsx:16`, R6, `evaluation/round2/r6-sidebar-corrupt.png`). That is wrong: history exists but cannot be read.
- The stop-word filter (`retrievalTerms`, new in this commit) means a standalone "why?" or "what is that?" now matches nothing. Such a question gets the starter's fallback "No relevant documents have been indexed yet. Please import and index documents…", even though 3 documents are indexed (R5). The fallback text is old, but this commit makes it reachable more often. The italic "No sources cited" note under it is accurate.

### 7. Accessibility: 4

Fixed since round 1:
- `role="log"` now sits on a wrapper, so the `<ol>`/`<li>` keep list semantics (P5: `{"role":null,"wrapper":"log"}`).
- After Cancel or Esc in the Clear confirmation, focus returns to "Clear conversation" (P4).
- The cited chunk receives focus.

Still good:
- The input has a label.
- Each exchange is an `<article>` labelled by its `<h3>` question.
- `aria-expanded` / `aria-controls` on toggles.
- `role="alert"` and `role="status"` where appropriate.
- All controls are in the tab order (R8).

Why it is not a 5:
- The Documents/History switch still uses `aria-pressed` buttons (`App.tsx:174,182`) instead of a `tablist`. This is unchanged from round 1.
- The live region (`QuestionPanel.tsx:189`, `aria-live="polite" aria-relevant="additions"`) wraps the whole thread. Loading or refreshing history inserts every exchange as an "addition", so a screen reader may read out the entire history. I did not test this with a real screen reader; it is inferred from the markup.

### 8. Code quality: 4

What works:
- `npm run check` and `check-architecture.sh` pass, there are 20 tests, and the build succeeds.
- The dead `qa:history` API is removed.
- Styles are now shared in `src/renderer/styles.ts`.
- `src/shared/text.ts` holds pure helpers used by both the service and the renderer, with no Node or DOM APIs, so the layer boundaries hold.
- Error translation lives in the service.
- `docs/ARCHITECTURE.md` and `docs/verification/README.md` are updated.

Why it is not a 5:
- `historyError` is overloaded. It is used both for load failures and for Clear failures. A Clear failure would be shown as "Could not load the conversation history. …" (`QuestionPanel.tsx:246`), which is the wrong message, and it is immediately overwritten anyway (defect 1).
- `clearHistory()` increments the generation before the write that can fail (`qa-service.ts:267-268`).
- There is no test, unit or E2E, for a failed Clear. That is why defects 1 and 2 slipped through.

## Defects the generator must fix (most important first)

1. **A failed Clear is silent.** When `qa.clearHistory()` rejects (for example, the file is read-only), `handleClearConversation` (`App.tsx:102-113`) sets `historyError` and then `refreshConversation()` resets it to null. The user sees nothing, and the conversation is not cleared. Keep a separate clear-error state with an accurate message such as "Could not clear the conversation: …", and make sure a successful reload does not erase it. (R2, `evaluation/round2/r2-clear-failed.png`)
2. **A failed Clear discards the in-flight question.** The renderer epoch (`App.tsx:103`) and the service generation (`qa-service.ts:267`) are both bumped before the clear succeeds. When the write fails, the pending answer is dropped in both layers with no error and no saved exchange. Bump the generation or epoch only after a successful write, or otherwise restore and report the pending question. Add a unit test and an E2E check for a failed Clear, with and without a pending question. (R3, `evaluation/round2/r3-clear-failed-pending.png`)
3. **The sidebar History says "No conversation history yet" while loading has failed** (`ConversationHistory.tsx:16`). Pass the load-error state through and show "History could not be loaded" instead. (R6)
4. **Stop-word-only questions now hit the misleading "No relevant documents have been indexed yet" fallback**, even with documents indexed. The fallback is from the starter, but the new stop-word filter makes it common for short standalone questions like "why?". Change the fallback wording to something true, such as "No indexed document matched this question", or route stop-word-only standalone questions to a hint to rephrase or use Follow up. (R5)
5. **The live region covers the whole thread**, so a history load or Refresh may announce every exchange (`QuestionPanel.tsx:189`). Limit the announcement to newly answered exchanges, for example with a small separate `role="status"` region saying "Answer received", or by applying `aria-live` only after the initial load. This is unverified with a screen reader and low priority.
6. **Documents/History are `aria-pressed` toggle buttons, not tabs** (`App.tsx:174,182`). Use `role="tablist"`/`tab`/`tabpanel` with arrow-key navigation. This is low priority and carried over from round 1.

All 12 defects from round 1 are verified fixed, by the round-1 probes, the E2E checks, or code inspection (the midnight refresh).

Out of scope, pre-existing in the starter and already listed in `docs/verification/README.md`: "+ Import" is a no-op; the status bar shows empty `Index:` and `Documents:`; mock answers contain a raw excerpt slice.
