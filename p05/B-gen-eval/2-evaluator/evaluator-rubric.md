# Evaluator rubric: multi-turn Q&A conversation history

- Evaluated commit: `8c65398 Add multi-turn Q&A conversation history`
- Date: 2026-11-15. Electron 33 on macOS (darwin).
- Rubric: `rubric-template.md`. There is no `sprint-contract.md` in the repo, so only the rubric was used.
- Evaluator role: independent reviewer. No application code was changed. The only files added are this one and `evaluation/`, which holds my probe script and screenshots.

## What I ran

| Step | Result |
|---|---|
| `npm run check` | exit 0 |
| `bash scripts/check-architecture.sh` | all 3 boundary checks PASS |
| `npm test` | 11/11 pass (`tests/qa-conversation.test.ts`) |
| `npm run build` | succeeds |
| The generator's `scripts/verify-conversation.mjs`, run against the real Electron app. I pointed screenshots at my scratchpad so the generator's evidence was not overwritten. | **23/23 PASS.** This reproduces `docs/verification/README.md` |
| My own probes: `evaluation/probe-conversation.mjs`. Same CDP harness, throwaway user-data dir, real Electron app | **7/13 pass.** Failures listed below |

Rerun the probes with: `npm run build && node --experimental-websocket evaluation/probe-conversation.mjs`. The script writes screenshots to `evaluation/`.

Independent probe results:

```
PASS  P1 Enter submit works, focus stays in input
PASS  P2 long unbroken question does not overflow — [920,920,1200,1200]
PASS  P3 follow-up of follow-up still grounded — [2,2]   (see note in Interactivity)
FAIL  P4 focus after cancelling clear returns to a sensible control — BODY
FAIL  P5 thread keeps list semantics (ol not overridden by role=log) — role="log"
FAIL  P6 opening a citation reveals/highlights the cited chunk
FAIL  P8 clearing while a question is pending leaves an empty conversation — exchanges after=1
PASS  P9 300 exchanges render — 105ms
FAIL  P9b thread scrolled to newest after load — distance=11.5px  (false positive: this is the 12px container padding; not a defect)
PASS* P10 one malformed entry …  (my assertion was wrong; it passed only because stale data stayed on screen; this is a real defect, see #1)
PASS  P11 corrupt history shows an error — raw "SyntaxError: Expected property name…"
FAIL  P11b asking with corrupt history gives actionable error — raw SyntaxError text
PASS  P11c corrupt file untouched (no silent data loss)
```

After correcting the two mis-scored probes (P9b, P10), the result is **6 real defects out of 13 probes**.

## Scores

| # | Criterion | Score |
|---|---|---|
| 1 | Functional completeness | 4 |
| 2 | Visual design | 4 |
| 3 | Timestamps | 5 |
| 4 | Citation display | 3 |
| 5 | Interactivity | 4 |
| 6 | Edge cases | 3 |
| 7 | Accessibility | 4 |
| 8 | Code quality | 4 |
| | **Overall (31 / 8)** | **3.9** |

### 1. Functional completeness: 4

What works:
- I asked 3 questions in a row in the running app. All 3 appear in order as question and answer pairs (E2E check "all questions shown in order").
- The rendered answer text equals the persisted text exactly ("answers shown in full").
- The conversation survives an app restart ("conversation persists across app restart").
- 300 exchanges render in about 105 ms (P9).
- The service persists `id`, `askedAt` and `followUpOf` (`src/services/qa-service.ts:144`). It also normalizes older entries (`qa-service.ts:160-168`), and the E2E test confirms a legacy entry is displayed.

Why it is not a 5:
- If the history fails to load, the UI keeps showing the **previous, stale conversation** as if it were current. Example: "300 exchanges" and "History (300)" stayed on screen after the file was corrupted (`evaluation/p11-corrupt.png`). The cause is in `src/renderer/App.tsx:48-55`, which sets `historyError` but never resets `conversation`.
- A question asked while a Clear is confirmed comes back after the clear (P8, `evaluation/p8-clear-pending.png`).

### 2. Visual design: 4

What works:
- Questions and answers are clearly distinct (`docs/verification/02-conversation.png` and my own run's screenshot). User questions are right-aligned purple bubbles with a "You" label. Answers are left-aligned dark bubbles with an "Assistant" label.
- The palette (`#16213e` / `#0f3460` / `#533483`) matches the existing sidebar, header and buttons.
- Low confidence is shown in amber.

Why it is not a 5:
- Citation excerpts render with `white-space: pre-wrap` and include raw markdown/newlines. Their blank lines make the Sources block taller than the answer (screenshot 02: a two-citation block fills most of the viewport).
- A collapsed long answer is cut at exactly 1200 characters, which can be mid-word (`ExchangeItem.tsx:153`). Excerpts, by contrast, cut on a word boundary.

### 3. Timestamps: 5

- Every exchange shows two timestamps: the question time (`askedAt`) and the answer time.
- Both use `<time datetime>` (`ExchangeItem.tsx:103,133`). The format is readable: "Today, 10:23 PM", "Yesterday, …", and "Mar 4, 2025, 07:00 AM" for older years (seen in the running app, E2E check).
- Hovering shows the full date in a tooltip (`formatFullTimestamp`).
- The sidebar History also shows timestamps.
- Minor issue: "Today" is computed at render time and is never refreshed, so it goes stale after midnight. The 2-digit hour gives "07:00 AM". Neither affects the score.

### 4. Citation display: 3

What works:
- Each answer lists numbered sources showing the document title, the chunk, and an excerpt in a `<blockquote>` (E2E "answer citations show document and excerpt").
- The sources list can be collapsed.
- A deleted document is marked "(document no longer available)".
- Answers without citations are clearly labelled.

Why it is only a 3 ("usable" is weak):
- Clicking a citation only opens the document header. The cited chunk is not shown, scrolled to or highlighted (P6, `evaluation/p6-citation.png`). Chunks stay hidden until the user clicks "Show Chunks" and then searches the list for "Chunk N" by hand.
- Chunk numbers are 0-based ("chunk 0"), which is an internal index exposed to the user.
- Excerpts show raw markdown (`# Software Design Notes\n\n## Architecture…`).

### 5. Interactivity: 4

These all work in the running app:
- Copy answer, with "Copied" feedback.
- Follow up: a context chip appears, focus moves to the input, Esc cancels, and the follow-up is linked to its parent with a "jump to" link.
- Expand and collapse long answers.
- Collapse sources.
- The sidebar History jumps to an exchange, focuses it and highlights it.
- Retry and Dismiss on errors.
- Clear with an inline confirmation.
- Enter submits the question (P1).

Issues:
- Clearing while a question is pending: the cleared conversation immediately regains that exchange (P8). The confirmation text "Delete all N exchanges?" is therefore not true.
- Follow-up context covers only one level. `qa-service.ts:80` adds only the immediate parent's *question*. It does not add the parent's answer or any earlier turns. In a chain A → "and then?" → "why?", the third turn is retrieved with "and then? why?". P3 still found citations only because short words like "and" and "then" match almost any chunk, so that probe does not prove the context is real.
- Esc does not cancel the Clear confirmation.

### 6. Edge cases: 3

Handled and verified in the app:
- Empty history.
- Long answer (collapsed, then expanded to the full 3190 characters).
- A very long unbroken question (no overflow, P2).
- An answer without citations.
- An IPC write failure, with Retry.
- A legacy entry without id or timestamp.

Not handled:
- **One malformed history entry hides the whole conversation.** An entry without `response` makes `getConversation` throw at `qa-service.ts:164` (`entry.response.timestamp`), so none of the valid entries can be shown (P10, `evaluation/p10-malformed.png`).
- **Corrupt `qa-history.json` produces raw developer errors.** The user sees "TypeError: Cannot read properties of undefined (reading 'timestamp')" and "SyntaxError: Expected property name or '}' in JSON at position 1". These are shown both as the load error and as the reason a new question "could not be answered" (P11/P11b). The UI gives no guidance on recovery. On the positive side, the corrupt file is not overwritten (P11c).
- The load-error banner sits at the top of the scroll area, above the stale exchanges. After scrolling to the bottom, the user does not see it (`p11-corrupt.png` shows only the per-question error).
- The clear-while-pending race (see #5).

### 7. Accessibility: 4

What works:
- The input is labelled with a visually hidden `<label>` (`QuestionPanel.tsx:228`).
- Each exchange is an `<article>` labelled by its question, which is an `<h3>` under the "Conversation" `<h2>`.
- `<time>` elements are used.
- Toggles carry `aria-expanded` / `aria-controls`.
- Errors use `role="alert"` and copy feedback uses `role="status"`.
- The sidebar has `aria-current`, and `:focus-visible` outlines are styled.
- All controls are native `<button>`s.
- Selecting from History moves focus to the exchange.

Issues:
- `role="log"` on the `<ol>` (`QuestionPanel.tsx:155`) overrides its list role. The `<li>` children are then list items with no list, which is an axe "listitem" violation, and screen readers lose the count of exchanges (P5).
- After Cancel in the Clear confirmation, focus falls back to `<body>` (P4). The Cancel button that had focus via `autoFocus` is unmounted and focus is not restored to "Clear conversation".
- The Documents/History tabs use `aria-pressed` toggle buttons instead of a `tablist` (`App.tsx:146-161`). This is acceptable but not idiomatic.
- I did not measure contrast with a tool. Colors checked by eye (#9a9ac0 on #1a1a2e) look adequate.

### 8. Code quality: 4

What works:
- `npm run check` passes, `check-architecture.sh` passes, there are 11 unit tests, and the build succeeds.
- Layer boundaries are respected. Normalization lives in the service (`getConversation`). The renderer only formats for display (`src/renderer/format.ts`). Preload only forwards `ipcRenderer.invoke`.
- `docs/ARCHITECTURE.md` and `AGENTS.md` were updated, and the E2E script is reproducible.

Issues:
- **Dead API surface.** The renderer no longer uses the `qa:history` channel, the preload `qa.history` or its type in `src/renderer/types.d.ts`. Only `conversation:get` is consumed (`grep` shows no renderer caller).
- `formatIpcError` (`format.ts:34`) strips only Electron's wrapper. Raw `TypeError`/`SyntaxError` messages from the service still reach the user, because the service has no error translation.
- `QuestionPanel` imports style constants (`userBubble`, `smallButton`, `metaText`) from the `ExchangeItem` component module. This is minor coupling, and a shared styles module would be cleaner.
- No unit test covers malformed history entries, which is the case that breaks.

## Defects the generator must fix (most important first)

1. **Stale conversation shown after a load failure.** When `conversation.get()` fails, `App.tsx:48-55` keeps the previous `conversation` state. Counts ("300 exchanges", "History (300)") and old exchanges stay on screen as though they were current. Clear or visibly mark the stale state, and keep the error visible near the composer, not only at the top of the scroll area. (Evidence: P11, `evaluation/p11-corrupt.png`)
2. **One malformed history entry breaks the whole conversation.** `getConversation()` (`qa-service.ts:160-168`) throws on an entry without `response` (or `question`). Skip invalid entries or normalize them per entry, log a WARN, and add a unit test for it. (Evidence: P10, `evaluation/p10-malformed.png`)
3. **Raw developer errors shown to users.** Messages like "TypeError: Cannot read properties of undefined…" and "SyntaxError: Expected property name… position 1" appear both as the load error and as the reason a question failed. Translate persistence/parse failures into a user-facing message, e.g. "Conversation history file is unreadable", ideally with the file location. (P11/P11b)
4. **Citations do not lead to the cited text.** Clicking a citation opens only the document header. Chunks stay collapsed, and the cited chunk is neither shown nor scrolled to nor highlighted. Pass the chunk index along so `DocumentDetail` reveals and highlights it. Also consider showing 1-based chunk numbers to users. (P6, `evaluation/p6-citation.png`)
5. **Clear while a question is pending brings the exchange back.** The confirmation says "Delete all N exchanges?", yet the in-flight question is saved after the clear and reappears. Either disable Clear while a question is pending, or discard the late result. (P8, `evaluation/p8-clear-pending.png`)
6. **`role="log"` on `<ol>` breaks list semantics** (`QuestionPanel.tsx:154-159`). Put `role="log"` on a wrapping `<div>` and keep the `<ol>`/`<li>` structure. (P5)
7. **Focus is lost after cancelling the Clear confirmation.** Focus lands on `<body>`. Return it to the "Clear conversation" button. Make Esc cancel the confirmation too. (P4)
8. **Follow-up context is too thin for multi-turn use.** `qa-service.ts:80` concatenates only the immediate parent's question. A chain of follow-ups loses the original topic, and retrieval is carried by stop-word matches. At minimum, include the ancestor chain or the parent's answer/citations, and add a test with a chain longer than 2.
9. **Citation excerpts dominate the layout.** `pre-wrap` keeps raw markdown and blank lines, so the Sources block is often taller than the answer. Collapse whitespace or clamp the excerpt height.
10. **Dead `qa:history` API.** The channel, the preload `qa.history` and its renderer type are unused now that `conversation:get` exists. Remove them, or document why they stay.
11. **The long-answer cut is mid-word** (`ExchangeItem.tsx:153`). Reuse the word-boundary logic used for excerpts.
12. **"Today/Yesterday" labels never refresh** while the app stays open across midnight. This is low priority.

Out of scope for this feature, but visible in the conversation (pre-existing in the starter and already listed in `docs/verification/README.md`):
- The no-match fallback answer says "No relevant documents have been indexed yet" even when 3 documents are indexed (`qa-service.ts` `generateAnswer`). Users will see this in the conversation and be misled.
- "+ Import" is a no-op.
- The status bar shows empty `Index:` and `Documents:` values.
