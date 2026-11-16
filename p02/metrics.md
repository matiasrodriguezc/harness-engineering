# P02 · Readable, resumable repo

Project question: can a fresh session resume the work by reading only the repo, without anyone explaining anything?

**Features to implement:** document import, detail view with content (and delete), and persistence across restarts. They are split across two sessions.

**Model and how it runs:** same as P01 (Claude Opus 5.5, non-interactive mode, `--permission-mode auto`, no skills or MCPs). Script: `scripts/run-session.sh`. Each session is fresh: it inherits nothing except what was left in the files.

**Prompts (same in both runs):**
- Session 1: "Implement document import for this knowledge base app. This session covers import only; the document detail view and persistence will be done in a later session."
- Session 2: "Continue working on this project."

**What changes between runs:**

| | Run 1 · weak harness | Run 2 · strong harness |
|---|---|---|
| `AGENTS.md` | Starter: 20 lines (commands, layers, conventions) | Solution: startup rules, Definition of Done and "when wrapping up, update `session-handoff.md`" |
| `docs/` | The starter's `ARCHITECTURE.md` and `PRODUCT.md` | The solution's (they change little from the starter) |
| `feature_list.json` | Yes (3 features `not-started`) | Yes (3 features `not-started`) |
| `session-handoff.md` | Does not exist | The course's blank template |

**Difference from the course:** the P02 doc includes no protocol or metrics; this design (two sessions with fixed prompts, the second deliberately vague) is my own.

## Results by session

| Metric | R1 · session 1 | R1 · session 2 | R2 · session 1 | R2 · session 2 |
|---|---|---|---|---|
| Duration | 6:27 | 2:22 | 5:05 | 2:47 |
| Turns | 24 | 12 | 28 | 15 |
| Cost | US$1.18 | US$0.67 | US$1.25 | US$0.79 |
| Actions before the first edit (rediscovery) | 5 | 3 | 5 | 3 |
| Did it respect session 1's scope? | Yes (import only) | — | Yes (import only) | — |
| Did it leave a record for the next session? | `feature_list.json` and a section of `ARCHITECTURE.md` | `feature_list.json`; the problems it found were left **only in its final message**, not in the repo | Complete `session-handoff.md`: verified, broken, next step, what not to touch | Updated `session-handoff.md` with the pending problems and the next work |
| Did session 2 correctly identify what was missing? | — | Yes, but it did **only one** of the two pending features | — | Yes, and it finished **both** |
| Did session 2 break or redo session 1's work? | — | No | — | No (it respected the handoff's "what not to touch" list) |
| **Run total** | | **8:49 · 36 turns · US$1.85** | | **7:52 · 43 turns · US$2.04** |

## Final result of each run

| Feature | Run 1 | Run 2 |
|---|---|---|
| Document import | ✅ | ✅ |
| Detail with content and delete | ✅ | ✅ |
| Persistence across restarts | ❌ the data is saved, but the list appears empty on restart (it is not loaded at startup) | ✅ loads at startup; the agent tested it by closing and reopening the app |
| `npm run check` / build | ✅ / ✅ | ✅ / ✅ |
| Tests | 19/19 (written by the agent) | Wrote no tests; verified by driving the real app via Chrome DevTools |
| The app opens | Only with `env -u NODE_OPTIONS` (it did not flag this) | Only with `env -u NODE_OPTIONS` (it documented this in the handoff) |
| Total change size (excluding `package-lock.json`) | 22 files, +720 / −175 | 19 files, +427 / −125 |

## Failures by layer

| Run | Failure | Layer |
|---|---|---|
| 1 | Session 2 found two bugs (the list does not load at startup, the button to index a document does not update the index) and left them only in its final answer: a session 3 would have to rediscover them | State |
| 1 | It ended with persistence not done: session 2 did one feature and stopped | State / task (no "next step" and no "done" criterion for the whole set) |
| 1 | `npm run dev` does not open because of `NODE_OPTIONS`, and it did not flag this | Environment |
| 2 | It wrote no automated tests; verification was left to manually driving the app | Verification (the `AGENTS.md` Definition of Done does not require tests) |
| 2 | `npm run dev` does not open because of `NODE_OPTIONS`; it documented this but did not fix it | Environment |

## Conclusion

The rediscovery cost was **the same** in both runs: session 2 took 3 actions to orient itself in both cases, because the "weak" starter already ships `feature_list.json`, and that is enough to know what is missing. What changed was **what session 2 did with that information**. Without a handoff, it completed one feature, found two bugs and left them only in its final message, outside the repo: the work ended at 2 of 3, and what it learned is lost to the next session. With a handoff, it read `session-handoff.md` first (what is verified, what is broken, the next step and what counts as done), finished both pending features, tested persistence by restarting the app and again wrote down what was pending. It cost only slightly more (US$2.04 versus US$1.85) for doing twice the work in the second session.

This is the idea of lectures 03 and 04 in practice: knowledge left in the chat does not exist for the next session. And a new cost appears: the strong harness's Definition of Done does not require tests, and this run wrote none, while the weak one wrote 19. The improvement for the next harness is to add "automated tests for each feature" to the definition of done. As in P01, it is a single run per condition: the numbers are indicative.

