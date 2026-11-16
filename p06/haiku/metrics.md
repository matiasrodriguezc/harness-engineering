# P06 with a smaller model: Claude Haiku 5.5

Does the harness still cover you when the model is much smaller? This repeats the P06 benchmark with **Claude Haiku 5.5** instead of Claude Opus 5.5. Only the model changes:

- **Same task:** the same three features, with the same fixed API names and `aria-label`s (`scripts/run-p06.sh`).
- **Same hidden suite:** the 12 end-to-end checks in `scripts/p06-acceptance.mjs`, with two app restarts.
- **Same two harnesses:**
  - *weak:* the untouched course starter;
  - *mine:* my full harness, restored from git exactly as the Opus run used it (the commit before the repo was translated), followed by the same cleanup pass.

How to repeat it: `scripts/run-p06-haiku.sh <folder-with-the-original-harness> [model-id]`. It sets `CLAUDE_MODEL`, which `run-session.sh` passes as `--model`. The transcripts confirm `"model":"claude-haiku-5-5"` in every session.

## Results

| | Opus · weak | Opus · mine | **Haiku · weak** | **Haiku · mine** |
|---|---|---|---|---|
| **Acceptance suite** | 12/12 | 12/12 | **12/12** | **12/12** (12/12 before the cleanup too) |
| Cost | US$1.19 | US$2.74 (+US$0.47 cleanup) | **US$0.18** | **US$0.35** (+US$0.02 cleanup) |
| Duration | 4:36 | 8:56 (+1:25) | 5:46 | 8:06 (+1:35) |
| Turns | 21 | 41 (+13) | 44 | 42 (+17) |
| Automated tests | 0 | 22 | **0** | 14 |
| How it fixed the bridge | Disabled the Electron sandbox | Bundled the preload | **Disabled the Electron sandbox** | Bundled the preload |
| Agent commits | 0 | 6 | **0** | 6 (base fix + one per feature + wrap-up + cleanup) |
| State for the next session | None | Feature list with evidence, handoff, log | **None** | Feature list (3 `passing`), handoff, log |
| `npm run check` | ✅ | ✅ | ✅ | ✅ |
| Change size (excluding lock) | 16 files, +702 | 39 files, +1,469 | 14 files, +614 | 28 files, +1,117 |

Haiku with my harness also found and fixed a real bug outside the task: `IndexingService.startIndexing(documentId)` did not record chunks in `index-meta.json`, so documents indexed one at a time were never cited. It wrote this down in the handoff.

## What it shows

1. **On this task, the smaller model delivered the same working software.** All four runs passed the hidden suite 12/12. As with Opus, the well-specified task (fixed names and "it has to work in the real app") did most of the work.
2. **The harness changed the same things with both models.** Without it, both models disabled the Electron sandbox to make the preload load, wrote no tests, made no commits and left no state. With it, both bundled the preload, committed one feature at a time and left the feature list, handoff and progress log ready for the next session. The pattern does not depend on the model.
3. **Haiku with the harness cost about an eighth of Opus with the harness** (US$0.37 against US$3.21 including the cleanup) for the same suite result and the same repo discipline. It wrote fewer tests (14 against 22).
4. **The weak harness's security regression repeats with the smaller model.** The sandbox rule should be executable, not just an instruction (see the main P06 conclusion).

## Limits

- One run per condition, as in the rest of the portfolio: the numbers are indicative.
- This task is well specified and medium-sized, and the suite did not discriminate between harnesses with either model. It does not show that a small model with a good harness covers harder tasks (large codebases, ambiguous requirements, design decisions). Where the model cannot solve the problem, the harness detects it but does not fix it.
- Opus and Haiku ran a few hours apart (2026-11-15 and 2026-11-16) on the same Claude Code version, 2.1.325.
