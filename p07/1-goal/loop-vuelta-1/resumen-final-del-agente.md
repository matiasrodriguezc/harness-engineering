Round 1 is done and committed (`9785c22`). The goal isn't met yet: `check-goal.sh` still reports **FAIL**.

**What I added:** `tests/services/document-service.test.ts`, with 8 unit tests for `document-service.ts`, the least-covered module. They test what the code does today when you list, import, look up, update and delete documents, including:
- a file that doesn't exist
- IDs it doesn't know
- saved changes still being there when the service is created again

I didn't change anything in `src/`.

**Coverage from `check-goal.sh`:**

| | Before | After |
|---|---|---|
| Lines | 83.13% | 89.8% |
| Functions | 74.07% | 85.18% |
| Files below 90% | 4 | 3 |

`document-service.ts` is now above the 90% bar. `npm test`, the type check and the architecture check all pass.

**Still below 90%**, in the order I'll take them next (also noted in `loop-state.md`):
1. `logger.ts` at 74.71%
2. `persistence-service.ts` at 84%
3. `indexing-service.ts` at 87.61%