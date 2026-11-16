# Harness Engineering · Portfolio

Eight measured experiments with Claude Code on the [Learn Harness Engineering](https://github.com/walkinglabs/learn-harness-engineering) course (WalkingLabs, MIT license): how the environment around an AI agent (instructions, tools, environment, state and verification) changes what the same model delivers.

**Live demo:** https://harness-engineering-matias.vercel.app (the page's code is [`index.html`](index.html); Vercel publishes only that file, see `.vercelignore`).

- **48 agent sessions** (Claude Opus 5.5, non-interactive mode), all with saved transcripts · **US$53.86** in total, plus 3 Claude Haiku 5.5 sessions (US$0.55) that repeat P06
- In each project, the same task with the same model, changing only the harness
- Every result verified outside the agent: typecheck, tests, build, the real app and my own checks that the agents could not see

## Key findings

1. **With a current model, the harness changes how the work gets done more than whether it gets finished.** In almost every project both versions delivered the task; the harness shifted the cost, the verification, the tests, the commits and what gets written down for the next session.
2. **The wrong kind of evidence produces false "done".** In P03, two agents marked 4 features as done with the UI disconnected. Only a test in the real app catches it.
3. **The course solutions repeat a bug:** the preload imports a local file with Electron's sandbox enabled, and the UI is left without access to the app (also in the final project's solution, graded 5/5 by its own rubric). It was turned into an executable rule.
4. **A well-specified task does much of the work.** In P06, with fixed API names and "it has to work in the real app", all five variants passed the hidden suite, including the weak harness.
5. **An independent evaluator adds value; a planner, not always** (P05: judge 3.9 → 4.5 with an evaluator; 4.0 with a planner).
6. **In the ablation, instructions matter most** (P06: without `AGENTS.md`, zero commits and a third of the tests).
7. **The pattern holds with a smaller model.** P06 repeated with Claude Haiku 5.5: 12/12 with both harnesses, and the harness changed the same things as with Opus (sandbox kept, tests, commits, state) at about an eighth of the cost.

## Results by project

| Project | What was tested | Weak run | Strong run |
|---|---|---|---|
| [P01](p01/metrics.md) | `AGENTS.md`, `init.sh`, `feature_list.json` | 4/4 features · 11:40 · 54 turns · US$3.28 · no state for the next session · scope decided by the agent | 4/4 features · 9:13 · 31 turns · US$2.30 · end-to-end test · state recorded with evidence |
| [P02](p02/metrics.md) | `session-handoff.md` + `AGENTS.md` with startup and wrap-up rules (two sessions) | 2/3 features · 8:49 · US$1.85 · session 2 left what it learned only in the chat | 3/3 features · 7:52 · US$2.04 · session 2 resumed from the handoff and updated it · no tests |
| [P03](p03/metrics.md) | One feature at a time with a commit per feature, `init.sh`, wrap-up checklist (sessions cut off by a spending cap) | 4/4 in `pass` · 2 sessions · US$0.78 · all 4 features at once · **UI disconnected** | 4/4 in `pass` · 3 sessions · US$1.27 · one commit per feature, the cutoff lost nothing · **UI disconnected** |
| [P04](p04/metrics.md) | Structured logger, architecture guard, startup and wrap-up routine (seeded bug) | Bug fixed in 59 s · US$0.29 · repo left with 14 type errors | Bug fixed in 92 s · US$0.49 · fixed the broken typecheck first, everything green · the logs were not needed |
| [P05](p05/metrics.md) | Separate roles: generator + evaluator (B) and also a planner (C), against a single role (A) | A: judge 3.9 · US$2.54 | B: judge **4.5** · US$7.05 · C: judge 4.0 · US$8.60 |
| [P06](p06/metrics.md) | My full harness (3 verification layers, feature list with commands, `init.sh` that opens the app, preload rule) + ablation | Hidden suite 12/12 · US$1.19 · 0 tests · sandbox disabled · no state | Hidden suite 12/12 · US$2.74 · 22 tests · commit per feature · full state · the ablation shows that instructions matter most |
| [P07](p07/metrics.md) | External loops: goal with deterministic stop, timer with a check before the agent, maker-checker | Single pass: 100% coverage · US$0.70 | Goal loop: 99% in 4 rounds · US$0.74 · timer: 2/2 failures reverted for US$0.23 · maker-checker: PASS in round 1, confirmed 7/7 |
| [P08](p08/metrics.md) | Explicit graph: functional verification ∥ review in worktrees, rollback by layer, human approval with timeout | P07 loop: 4 implicit edges found when drawing it | Parallel verification 34% faster · features 6/6 · regression 12/12 · stopped waiting for human approval |

## Structure

| Folder | Contents |
|---|---|
| `p01/` … `p04/` | Weak-harness run (`baseline/`) and strong-harness run (`improved/`): transcript, diff, agent summary, harness used, `metrics.md` |
| `p05/` | The three role configurations, their evaluations and the independent judge's report |
| `p06/` | My harness (`my-harness/`), the ablation variants and the runs with their hidden acceptance suite results; `haiku/` repeats the benchmark with Claude Haiku 5.5 |
| `p07/` | The three loops with their prompts, the timer log and `loop-state.md` |
| `p08/` | `graph.md` (the P07 loop as a graph) and the run log of the executable graph, with its approval request |
| `scripts/` | Everything needed to repeat the experiments |
| `index.html` | The demo page |

Transcripts (`transcript.jsonl`) and diffs (`changes.patch`) are kept exactly as recorded, since they are the evidence. The experiments originally ran with harness files partly written in Spanish, so some notes the agents wrote during the runs (progress logs inside those files) are in Spanish. Everything else in the repo is in English.

## Tools

| Script | What it does |
|---|---|
| `run-session.sh` | Runs a non-interactive Claude Code session in an isolated folder and saves the transcript, diff and timings |
| `run-multi.sh` | Chains fresh sessions with a spending cap (simulates restarts) until `feature_list.json` is complete |
| `analyze-transcript.py` | Turns, cost and actions before the first edit (rediscovery cost) |
| `check-bridge.mjs` | Connects to the open app via Chrome DevTools and checks that the UI has access to the API |
| `run-p05.sh` | The three role configurations and the independent judge |
| `run-p06.sh`, `run-p06-all.sh` | The P06 variants with the acceptance suite at the end |
| `run-p06-haiku.sh` | The P06 benchmark (weak and mine) on another model, Claude Haiku 5.5 by default |
| `p06-acceptance.mjs` | Hidden end-to-end suite: 12 checks with two app restarts |
| `p07-goal.sh`, `p07-timer.sh`, `p07-maker-checker.sh` | The three P07 loops |
| `p07-search-accept.mjs`, `p08-export-accept.mjs` | Independent checks of the P07 and P08 features |
| `p08-graph.sh` | The graph: plan, implement, parallel verification in worktrees, routing, human approval and timeout |

## Pending: P08 human approval

The P08 graph is stopped at its approval node, waiting for a person's decision (on purpose; it was not simulated). To complete it: read `p08/3-graph/approval-request.md`, write `approval: approved` or `approval: rejected` in `~/harness-runs/p08-graph/state.md` and run `scripts/p08-graph.sh resume`.

## Limitations

- One run per condition: differences in time and cost are indicative, not statistical.
- Mostly a single model (Claude Opus 5.5). Only P06 was repeated with a smaller one (Claude Haiku 5.5); with other models or harder tasks, several conclusions may change.
- The sessions ran in non-interactive mode, not by hand as the course suggests, so they could be measured the same way; human interventions are zero by design.
- I designed several protocols myself because the course does not define them (P02, P03, P05–P08). Every adjustment and every stumble is documented in the project's `metrics.md`.
