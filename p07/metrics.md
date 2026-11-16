# P07 · Loops: goal, timer and maker-checker

Project question: what happens when the agent runs on its own, in a loop, with nobody guiding it between rounds?

**Base:** the final repo of my P06 harness (app with rating, reset and history; 22 tests; `init.sh` that opens the app).

**Difference from the course:** the course suggests `/goal` and `/loop` interactively inside Claude Code. Here the loops are external scripts (`scripts/p07-*.sh`) that launch new `claude -p` sessions and decide when to stop with deterministic checks. That way every round is measured and has a transcript.

## Experiment 1 · Goal loop (`p07-goal.sh`)

**Goal (`prompts/goal.md`), verified by `prompts/check-goal.sh`:** tests green, `src/services/` coverage ≥ 95% of lines and of functions overall, and every file ≥ 90% of lines; types and architecture green. Starting point: 83.13% of lines, 74.07% of functions, four files below 90%.

| | Single pass | Goal loop |
|---|---|---|
| Sessions | 1 | 4 rounds (3 with an agent; round 2 failed due to infrastructure) |
| Cost | US$0.70 | US$0.74 (0.22 + 0 + 0.27 + 0.25) |
| Agent time | 2:23 | 2:41 |
| Final coverage (lines / functions) | **100% / 100%** | 99.01% / met |
| Tests at the end | 75 | 45 |
| Result | `GOAL: PASS` | `GOAL: PASS` in round 4 |
| Progress per round | — | 83.13 → 89.8 → 89.8 (failed) → 96.47 → 99.01 |

**What happened along the way (and is documented in the evidence):**
- The first goal (≥ 80% of lines) **was already met** by the P06 tests: the loop had nothing to do. I stopped the run and raised the bar to 95/95/90.
- Round 2 did not run: `claude: command not found` (Claude Code updated itself at that moment). The loop counted it as a round with no progress and kept going; nothing broke.
- My check marked the single pass as failed: the coverage tool was installed with `--no-save` and the `npm install` in `init.sh` removed it. Once reinstalled, the agent's result was confirmed: 100/100. The script was fixed (`--save-dev`).

## Experiment 2 · Timer loop (`p07-timer.sh`)

Each tick runs `init.sh` (deterministic and free); only if it fails is the agent woken up with the error output. In ticks 2 and 4 the script itself injects a failure with a "teammate" commit. 5 ticks every 4 minutes (about 22 minutes; the course suggests 2 hours, it was shortened to fit in the session).

| Tick | Injected failure | `init.sh` | Agent | After | Cost |
|---|---|---|---|---|---|
| 1 | — | ✅ | No | — | US$0 |
| 2 | Type error in `qa-service.ts` | ❌ | Yes: `git revert` of the broken commit | ✅ | US$0.12 |
| 3 | — | ✅ | No | — | US$0 |
| 4 | `fs` import in the renderer (violates the architecture) | ❌ | Yes: `git revert` of the broken commit | ✅ | US$0.11 |
| 5 | — | ✅ | No | — | US$0 |

**Summary:** 2 failures injected, 2 detected, 2 fixed, 0 false positives, 0 escalations (`ALERT.md` was not needed). To see whether "fixing" broke something else, I ran the hidden P06 suite on the final repo: **12/12**. Total monitoring cost: **US$0.23**, because the agent is not called on healthy ticks.

## Experiment 3 · Maker-checker (`p07-maker-checker.sh`)

New feature: document search (`documents.search(query)` and a "Search documents" field that filters the list). The maker implements; the checker, independent and without touching code, tests it in the real app and writes `checker-verdict.md`. It stops at 2 PASS in a row or 6 rounds.

| Round | Maker | Checker | Blocking defects | Cost |
|---|---|---|---|---|
| 1 | Implemented, 38 tests green | PASS | 0 (3 non-blocking observations: it trims spaces from the search, the counter shows the total, the list does not refresh on its own when importing through the API) | US$1.06 + US$0.50 |
| 2 | No (confirmation) | PASS | 0 | US$0.58 |

**Independent check** (`scripts/p07-search-accept.mjs`, hidden from the agents): **7/7**, including that asking questions still works. On the first run my script gave 6/7 because it asked without indexing first; the bug was mine and was fixed.

## Failures by layer

| Experiment | Failure | Layer |
|---|---|---|
| Goal | The initial target was already met: the loop started out finished | Task (goal poorly calibrated against the real state) |
| Goal | Coverage tool removed by `npm install` | Environment (my setup) |
| Goal | Round 2 without an agent (`claude: command not found`) | Environment (infrastructure) |
| Maker-checker | My check asked without indexing | Verification (my script) |

## Conclusion

**The loops worked, but with this model the task fit in a single pass.** The goal loop reached the target in 4 rounds for the same cost as a single pass, which also went further (100% and 75 tests). Its real value lay elsewhere: a stopping condition that does not depend on what the agent says, and resilience to a round that failed due to infrastructure without breaking anything. **The timer loop was the clearest:** deterministic check first and the agent only when needed; it detected and reverted both failures for US$0.23 and made nothing worse. The maker-checker approved in the first round, and an independent check of my own confirmed it was right.

What taught the most in P07 were its stumbles, and all of them came from the harness, not the agent: a goal that was already met, a tool that `init.sh` itself removed, and a badly written check of mine. This is lecture 13 in practice: **the loop is only as good as its stopping condition and its checks**, and those need to be verified too.
