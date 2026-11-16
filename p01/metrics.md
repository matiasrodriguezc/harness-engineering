# P01 · Prompt only versus minimal harness

Same task, same agent, same model. The only thing that changes is the harness.

**Task (same in both runs):** "Build an Electron app that can show documents and answer questions."

**How the agent was launched:** non-interactive mode, `claude -p "<task>" --disable-slash-commands --strict-mcp-config --permission-mode auto --output-format stream-json --verbose`. No skills or MCPs, so no other harness sneaks in. In non-interactive mode nobody answers its questions, so human interventions are 0 by design in both runs.

**Model:** Claude Opus 5.5 (`claude-opus-5-5`), Claude Code 2.1.278.

**Difference from the course protocol:** the course assumes an interactive run; here non-interactive mode was used to measure both runs the same way and save the full transcript.

## Results

| Metric | Run 1 · weak harness | Run 2 · strong harness |
|---|---|---|
| Start time | 20:16:14 | 20:29:49 |
| Time the agent said "done" | 20:27:54 (11 min 40 s) | 20:39:02 (9 min 13 s) |
| Agent turns | 54 | 31 |
| Cost | US$3.28 | US$2.30 |
| Result (complete / partial / failed) | Complete (4 of 4), and went far beyond what was asked | Complete (4 of 4) + 8 extra features, all recorded in `feature_list.json` with evidence |
| First successful launch (minutes from start) | ~12 (right after finishing), but only by removing `NODE_OPTIONS` from the environment | ~9 (right after finishing), with plain `npm run dev`: it fixed the launch script |
| Human interventions | 0 (non-interactive mode) | 0 (non-interactive mode) |
| Declared victory without the app launching? (yes / no) | No: it warned that Electron does not start with my `NODE_OPTIONS` and gave the command | No: it verified with an end-to-end test on the real app |
| Independent verification (mine) | `npm run check` clean, 34/34 tests, build OK, the app opens | `init.sh` OK, 17/17 tests, end-to-end smoke test PASS, the app opens |
| Change size (excluding `package-lock.json`) | 25 files, +1,917 / −788 lines | 26 files, +1,524 / −590 lines |
| Left state for the next session | No (only a README) | Yes: `feature_list.json` with evidence and `claude-progress.md` with the log |
| `init.sh` at the end (run 2 only) | — | ✅ passes |

## The 4 expected features

Mark ✅ if it works when you test it, ⚠️ if it is half done, ❌ if it is missing.

| Feature | Run 1 | Run 2 |
|---|---|---|
| The app window opens | ✅ (with `env -u NODE_OPTIONS`) | ✅ (plain `npm run dev`) |
| Document list on the left | ✅ (layout verified in the code; no screenshot) | ✅ (verified by the smoke test) |
| Q&A panel on the right | ✅ (same) | ✅ (same) |
| The local data directory is created | ✅ `~/Library/Application Support/knowledge-base/knowledge-base-data` | ✅ (same directory) |

## Failures by layer (lecture 01)

For each failure you see, note which layer it falls in: task, context, environment, verification or state.

| Run | Failure | Layer |
|---|---|---|
| 1 | `NODE_OPTIONS=--openssl-legacy-provider` in my shell prevents Electron from starting (the agent detected it and flagged it) | Environment |
| 1 | On its own, it added an optional mode that sends passages to the Anthropic API if `ANTHROPIC_API_KEY` is set; it was not requested and it did not test it | Task (undefined scope → the agent expands) |
| 1 | It deleted and replaced three starter components (`DocumentDetail`, `ImportPanel`, `QuestionPanel`) with its own design | Task / context (with no written spec or conventions, it decides alone) |
| 2 | It disabled Electron's sandbox (`sandbox: false`) because the preload imports the constants from `src/shared/types.ts`, as `AGENTS.md` requires; run 1 had solved the same thing while keeping the sandbox. It declared this and offered to revert it | Context (the harness has a convention that clashes with the sandbox and does not say which to prioritize) |
| 2 | It replaced the "mock" answers required by `docs/PRODUCT.md` with answers extracted from the documents. It declared this as a deviation from the spec | Task (vague prompt versus written spec) |
| 2 | It added 8 features beyond the 4 requested | Task, but visible: all of them were recorded in `feature_list.json` with evidence |

## Notes during the run

- **Run 1:** with a current model, the weak harness did not produce the failure the course anticipates. The agent explored the starter, found and fixed real bugs (fake Q&A, import that did nothing, preload blocked by the sandbox, incomplete indexing), wrote 34 tests and drove the app with a script. What it did show is the other side of the weak harness: **without written limits, it decides the scope on its own** (it redesigned components and added an integration with an external API that nobody asked for).
- **Run 2:** it followed the `AGENTS.md` protocol (ran `init.sh`), respected the starter's component structure instead of replacing it, stayed 100% local as the spec says, wrote an end-to-end test on the real app and left the state ready for the next session.

## Conclusion

With Claude Opus 5.5, both runs finished with all 4 features working, so the minimal harness **did not change whether the agent finishes, but how it works**. With the harness, the run was 21% faster (9:13 versus 11:40), used 43% fewer turns (31 versus 54) and cost 30% less (US$2.30 versus US$3.28), with a smaller change (+1,524 versus +1,917 lines). In addition, the `AGENTS.md` definition of "done" pushed toward stronger verification (an end-to-end test on the real app, versus service tests and a script), and run 2 left `feature_list.json` and `claude-progress.md` with evidence, so the next session does not start from scratch. Without the harness, the agent decided the scope on its own: it redesigned components and added an integration with an external API that nobody asked for.

The harness also showed a limit: an `AGENTS.md` convention (shared IPC constants) clashed with Electron's sandbox and the agent chose to disable it, something the run without the harness did not do. An incomplete harness still guides, sometimes toward a worse decision; the fix is to add an explicit rule ("keep `sandbox: true`; if the preload needs shared code, bundle it"). It is a single run per condition, so the differences in time and cost are indicative, not conclusive.
