# P04 · Runtime feedback to correct the agent

Project question: do structured logs and an architecture check make the agent find the cause of a bug faster and fix it with a smaller change?

**The planted bug:** in `src/services/indexing-service.ts`, documents longer than 1,000 characters produce empty chunks (`content.length > 1000 ? '' : buffer.trim()`). All three samples exceed 1,000 characters, so answers come back with empty citations.

**Adjustment to the course starter:** the starter ships the bug **annotated with a comment** (`// BUG: For long documents...`). Those two comment lines were deleted in both runs, leaving only the code, so the agent has to find it.

**Prompt (same in both runs), phrased as a user report:** "Users report that when they ask questions about their imported documents, the answers come back with empty citation excerpts and no useful content. Find the root cause and fix it."

**Model and how it ran:** Claude Opus 5.5, non-interactive mode, `--permission-mode auto`, no skills or MCPs, a single session with no cap.

**What changes between runs:**

| | Run 1 · weak harness | Run 2 · strong harness |
|---|---|---|
| `AGENTS.md` | Starter: 5 lines (commands and two rules) | Solution: startup routine, observability, layer constraints, Definition of Done and wrap-up routine |
| Indexing logs | `console.log` with content length and chunk count | Structured logger (JSON) that also reports **the total characters across chunks** |
| `docs/ARCHITECTURE.md` | No | Yes |
| `scripts/check-architecture.sh` | No | Yes |
| `clean-state-checklist.md` | No | Yes, unchecked; includes "no empty chunks in indexed documents" (a hint toward the bug that is part of the course harness) |

## Results

| Metric | Run 1 | Run 2 |
|---|---|---|
| Duration | 59 s | 92 s |
| Turns | 7 | 15 |
| Cost | US$0.29 | US$0.49 |
| Actions until it saw the bug line | **2** (read the indexing code) | **8** (first followed the startup routine and fixed the broken typecheck) |
| Did it use the runtime logs to find it? | No (it didn't need to) | No: it found it by reading the code, same as the weak run |
| Did it find the correct root cause? | Yes | Yes |
| Bug fix | `indexing-service.ts` (+16 lines): returns the text and also **rebuilds already-broken indexes** | `indexing-service.ts` (6 lines): returns the text; already-broken indexes are left as "not fixed", documented |
| Other changes | None | Separate commit fixing the starter's 14 typecheck errors (5 renderer files), as the `AGENTS.md` asks |
| Did it verify with real data? | Yes, tests with the sample documents; did not open the app | Yes, a test with the sample documents; did not open the app |
| Regression test | 3 tests (fail without the fix) | 2 tests (fail without the fix) |
| `npm test` finds the tests | No (it flagged this and offered to fix it) | Yes (added `vitest.config.ts`) |
| `npm run check` at the end | 14 errors (the same as the starter, out of scope) | 0 errors |
| `check-architecture.sh` at the end | Passes (I ran it; the run did not have the script) | Passes |
| Commits | 1 (the one from the end-of-session script) | 2 by the agent: typecheck on one side, bug on the other |
| Change size (excluding `package-lock.json`) | 2 files, +73 / −5 | 9 files, +82 / −16 |
| My verification | Bug condition removed, 3/3 tests, guard OK | Bug condition removed, 0 type errors, 2/2 tests with `npm test`, guard and build OK |

## Failures by layer

| Run | Failure | Layer |
|---|---|---|
| 1 | Left the repo with the typecheck red (14 pre-existing errors) and `npm test` not finding tests: it fixed the bug but not the starting point | Environment / verification (no "fix what's broken first" rule) |
| 2 | Did not rebuild the indexes the bug had already broken: the user has to reindex manually | Task (the report asks to "fix it"; there is no criterion for what counts as fixed for existing data) |
| 1 and 2 | Neither opened the app to confirm the answers look right | Verification (same as in P03) |
| Experiment design | The bug is visible by reading the code: the runtime logs had no chance to contribute | — |

## Conclusion

The P04 hypothesis was that structured logs help find the cause faster. **This experiment could not test it:** the bug was visible by reading the code (a `content.length > 1000` condition in the chunking), and both runs found it that way, without looking at logs. The weak run even got there first (2 actions versus 8). Measuring the real value of runtime signals requires a bug that only shows up at execution time: one that depends on the data, the configuration, or a state the code does not show.

What the harness did change was **discipline**: the strong run followed the startup routine, detected that the typecheck was already broken and fixed it first in a separate commit, left `npm test` working, and finished with everything green (typecheck, tests, architecture guard, build). The weak run fixed only the bug and left the repo with 14 type errors and no way to run the tests with the standard command. That discipline cost 70% more (US$0.49 versus US$0.29). And the weak run did something the strong one did not: rebuild the indexes the bug had already damaged, a more complete fix for the user. A single run per condition: the numbers are indicative.
