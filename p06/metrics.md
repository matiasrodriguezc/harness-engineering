# P06 · Full harness, benchmark and ablation

The final project: build the best harness using what was learned in P01–P05, measure it against a weak harness, and remove one component at a time to see which ones matter.

## The fixed task (same in all five runs)

Three features on the P06 app, with API names and `aria-label`s fixed so they can be verified:

1. **Rate answers:** each `qa.ask` answer has an `id`; `feedback.submit(answerId, 'up'|'down')` and `feedback.list()`; persists across restarts; "Mark answer helpful" / "Mark answer not helpful" buttons.
2. **Reset everything:** `app.reset()` deletes documents, chunks, history and ratings; the empty state persists; "Reset all data" button with confirmation.
3. **Conversation history:** the panel shows the full history with expandable citations and a confidence indicator.

"The features must work in the running app."

## Verification: my own acceptance suite, hidden from the agents

`scripts/p06-acceptance.mjs` opens the real app with a temporary data folder and, through the preload bridge, runs 12 checks: bridge, import, ask with citations, id, rating, history, UI buttons, persistence across restarts (two restarts), reset, and that the reset persists. It does not depend on what the agent says it did.

Suite validation: the untouched starter scores **0/12** (the bridge does not load). The course solution also fails check 1 because of the same preload bug (`require("../shared/types")` with the sandbox enabled); with the sandbox manually disabled, it passes the checks that do not depend on this task's API names.

## My harness (`my-harness/`)

| Component | Source lesson |
|---|---|
| Short `AGENTS.md` with entry and exit routine, one feature at a time, one commit per feature | Lectures 03–05 and 07; P02, P03 |
| Definition of done in 3 layers: static → tests + bridge → end-to-end in the real app | Lectures 09–10; P03 (false `pass`es) |
| `feature_list.json` with behavior + verification command + status | Lecture 08 (the course lists were missing the command) |
| `init.sh`: environment (`NODE_OPTIONS`), types, build, guard and **the real app** with `smoke-bridge.sh` | Lecture 06; P01–P04 |
| `check-architecture.sh` with a new preload rule and a what/why/how message | Lecture 10; the bug that appeared in every project |
| Handoff, progress log and wrap-up checklist | P02, P03 |

Before using it, its tools were tested against the starter: the preload rule and the bridge check detect the bug.

## Results

| | Weak (starter) | **Mine** | No end-to-end | No feature list | No instructions |
|---|---|---|---|---|---|
| **Acceptance suite** | **12/12** | **12/12** | **12/12** | **12/12** | **12/12** |
| Cost | **US$1.19** | US$2.74 (+US$0.47 cleanup) | US$2.86 | US$2.27 | US$1.51 |
| Duration | 4:36 | 8:56 (+1:25) | 11:03 | 9:01 | 8:29 |
| Turns | 21 | 41 (+13) | 53 | 38 | 31 |
| Automated tests | **0** | 22 | 22 | 18 | 7 |
| How it fixed the bridge | **Disabled the Electron sandbox** | Bundled the preload | Bundled the preload | Bundled the preload | Bundled the preload |
| Agent commits | 0 | 6 (one per feature + base + cleanup) | 6 | 5 | **0** |
| State for the next session | None | Feature list with evidence, handoff, log | Feature list with evidence, handoff, log | Handoff and log | Feature list, handoff and log |
| `npm run check` | ✅ | ✅ | ✅ | ✅ | ✅ |
| Change size (excluding lock) | 16 files, +702 | 39 files, +1,469 | 35 files, +1,392 | 32 files, +1,320 | 24 files, +942 |

**Cleanup and re-run ("mine" only):** the suite scored 12/12 before and after the cleanup pass; the cleanup added `.gitignore`, marked in the docs the scripts that do not exist, and re-verified the features (US$0.47).

## Ablation: what each component contributes

| Removed | Measured effect |
|---|---|
| **End-to-end verification** (`smoke-bridge.sh`, preload rule, layer 3) | None visible: same result, same tests, sandbox intact. The task already said "must work in the running app" and the agent wrote its own test against the app. |
| **Feature list** | Slight: 18 tests instead of 22, 5 commits instead of 6; the state ended up in the handoff and log. |
| **Instructions** (custom `AGENTS.md` and `CLAUDE.md`) | The largest: **0 commits** and **7 tests** instead of 22. Even so, it found and used `init.sh`, the feature list and the handoff because they were in the repo, and it bundled the preload. |
| **Everything** (weak harness) | Same suite, less than half the cost, but **no tests, no commits, no state** and with the **sandbox disabled**. |

## Failures by layer

| Run | Failure | Layer |
|---|---|---|
| Weak | Disabled the Electron sandbox so the preload would load: the app works, but with a security regression that no behavior check detects | Verification (no executable security rule) |
| Mine | "Don't disable the sandbox" exists only as an instruction in `AGENTS.md`: the preload rule exempts `sandbox: false`, so a run that disables it passes the guard | Verification (a rule that should be executable) |
| No instructions | Committed nothing | Instructions |
| Acceptance suite | With such a well-specified task it did not discriminate: 12/12 across the board | Experiment design |

## Conclusion

**With a well-specified task, the model delivered working software with any harness**: the acceptance suite scored 12/12 in all five variants, and the weak harness was the cheapest (US$1.19 versus US$2.74 for mine). The task specification (API names, `aria-label`s and "it has to work in the real app") did much of the work that nobody did in P03. That is layer 1 from lecture 01.

The harness did not change **whether it works**, but **what state the repo is left in**: with my harness there were 22 tests, one commit per feature, the feature list with evidence, the handoff for the next session and the sandbox intact; with the weak one, zero tests, zero commits, no state and the sandbox disabled. The ablation says that **what matters most today is the instructions** (without them: 0 commits and a third of the tests), while end-to-end verification contributed nothing measurable **on this task**, because the prompt itself already required it. And it leaves one concrete improvement: turn "don't disable the sandbox" into an executable rule. A single run per variant: the numbers are indicative.

## Repeated with a smaller model

The same benchmark (weak and mine) was repeated with **Claude Haiku 5.5**; see [`haiku/metrics.md`](haiku/metrics.md). Both passed 12/12 again, and the harness changed the same things as with Opus (sandbox kept, tests, commits, state), at about an eighth of the cost: US$0.37 against US$3.21 for my harness with its cleanup pass.
