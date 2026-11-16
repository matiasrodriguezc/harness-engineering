# P03 · Continuity across restarts, one feature at a time

Project question: when the session is cut off midway, does the agent scatter across several features or lose the state? Does it mark features as `pass` without evidence?

**Features to implement (4):** splitting documents into fragments (chunking), metadata extraction, indexing status in the status bar, and Q&A with citations.

**How restarts are simulated:** each session has a spending cap (`--max-budget-usd`). When it hits the cap, the session is cut off mid-work, as when the context runs out, and a fresh session starts that knows only what was left in the files. Sessions are chained until all 4 features are in `pass` or up to 5 sessions. Script: `scripts/run-multi.sh`.

**Design adjustment:** the first attempt used a US$1.20 cap and the weak run finished all 4 features in a single US$0.91 session, without reaching the cap: there was no restart. That attempt was saved in `baseline-no-cutoff/`, and the two compared runs use a cap of **US$0.50** per session.

**Prompts (same in both runs):** session 1, "Implement the remaining features of this project."; subsequent ones, "Continue working on this project."

**Model:** Claude Opus 5.5, non-interactive mode, `--permission-mode auto`, no skills or MCPs.

**What changes between runs:**

| | Run 1 · weak harness | Run 2 · strong harness |
|---|---|---|
| `AGENTS.md` | Starter: commands, layers, feature list, a short definition of "done" | Solution: startup rules, **one-feature-at-a-time policy** (implement, verify, mark with evidence, commit), dependencies between features |
| `feature_list.json` | Yes (4 features `not-started`) | Yes (4 features `not-started`) |
| `init.sh` | No | Yes |
| `session-handoff.md` | No (`AGENTS.md` says it may be missing) | The course's blank template |
| `claude-progress.md` | No | Empty (title only) |
| `clean-state-checklist.md` | No | Yes, all unchecked |

**Difference from the course:** the P03 doc includes no protocol or metrics; using the spending cap to simulate a restart is my own.

## Results by session

| Session | Run 1 · weak | Run 2 · strong |
|---|---|---|
| 1 | US$0.49 · 1:43 · 11 turns · implemented **all 4 features at once** without testing them; marked them as `implemented` (a status it invented), not `pass` | **Cut off by the cap** (US$0.52 · 2:10) · fixed the typecheck and did metadata and chunking, **one commit per feature**: the cutoff lost nothing |
| 2 | US$0.29 · 1:17 · 10 turns · wrote 3 service tests, marked all 4 as `pass`, committed and created a brief `session-handoff.md` | US$0.36 · 1:09 · 11 turns · resumed from the handoff, did **only** the indexing status and committed |
| 3 | — | US$0.39 · 1:06 · 14 turns · did Q&A, ran the wrap-up checklist, found that a button ("Show Chunks") is missing and wrote it down; stated that the project is **not** complete |
| **Total** | **2 sessions · 3:00 · 21 turns · US$0.78** | **3 sessions · 4:25 · 35 turns · US$1.27** |
| Actions before the first edit | 4 and 4 | 3, 4 and 3 |

## Final result

| | Run 1 · weak | Run 2 · strong |
|---|---|---|
| Features in `pass` according to `feature_list.json` | 4/4 | 4/4 |
| One feature at a time? | No: all 4 at once in session 1 | Yes: one commit per feature (`git-log.txt`) |
| Was work lost when a session was cut off? | There was no actual cutoff | No: the cut-off session had already committed what it did |
| `npm run check` / build | ✅ / ✅ | ✅ / ✅ (`init.sh` also passes) |
| Automated tests | 3 (services) | None |
| **Can the UI use the app?** (verified by me with `scripts/check-bridge.mjs`) | ❌ `window.knowledgeBase` is `undefined`: the window shows but cannot import or ask questions | ❌ same |
| State for the next session | 12-line `session-handoff.md` (it created it on its own) | `session-handoff.md`, `claude-progress.md` and checklist findings |
| Change size (excluding `package-lock.json`) | 14 files, +206 / −103 | 15 files, +205 / −109 |

**The attempt without a cutoff** (`baseline-no-cutoff/`, weak harness, US$1.20 cap): 1 session, US$0.91, all 4 features at once, no tests. It disabled Electron's sandbox, which in P01 made the UI work; I did not verify it with `check-bridge.mjs` before deleting the folder.

## Failures by layer

| Run | Failure | Layer |
|---|---|---|
| 1 and 2 | All 4 features ended in `pass` with the UI disconnected: the preload imports `../shared/types` with the sandbox enabled and does not load. Neither run detected it | Verification: neither the Definition of Done nor the checklist requires testing the app from the UI; "the app opens" is not "the app works" |
| 1 | It implemented all 4 features at once | Task / scope (no one-feature-at-a-time policy) |
| 2 | It wrote no tests | Verification (the Definition of Done does not require them) |
| 2 | It checked "the app opens" in the wrap-up checklist, but did not try importing or asking questions from the window | Verification (the checklist is filled in by reading code, not by using the app) |

## Conclusion

The **one-feature-at-a-time policy with a commit per feature** did what it promises against restarts: the strong run was the only one with a real cutoff mid-work (session 1 hit the cap) and it **lost nothing**, because it had already committed each finished feature; each following session resumed from the handoff and took exactly one feature. The weak run, by contrast, put all 4 features in at once in a single session. With this model that turned out fast and cheap (US$0.78 versus US$1.27), but if that session had been cut off before committing, everything would have been lost.

The most important finding is a different one: **both runs marked all 4 features as `pass` with the UI disconnected.** The UI bridge between the window and the app does not load (a problem that the agents in P01 and P02 did find and solve), and no harness detected it, because the evidence they asked for was the typecheck, the build, service tests or "the app opens". The "do not mark `pass` without evidence" policy was followed in form, not in substance: **the evidence was the wrong kind.** This is exactly the topic of lectures 09 and 10: declaring victory too early, and why only an end-to-end test truly verifies. The concrete improvement for the next harness is a check that uses the app like a user (for example, `check-bridge.mjs` inside `init.sh`, or a smoke test like the one the P01 strong run wrote). A single run per condition: indicative numbers.
