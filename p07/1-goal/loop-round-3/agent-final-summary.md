Round 2 is done and committed as `15bec9b`. The goal still isn't met: one file, `indexing-service.ts`, is below the 90% line bar at 87.61%.

**What I added** (tests only, nothing in `src/` changed):
- `tests/services/logger.test.ts` (4 tests): checks the format of each log entry, which console method each level uses, that extra data is only included when it isn't empty, that `LOG_LEVEL=WARN` drops debug and info messages, and that `forService` tags every level with the service name.
- `tests/services/persistence-service.test.ts` (6 tests): checks the startup directories and their path getters, that reading a missing file returns null, that JSON and text written into nested folders read back the same, copying and deleting documents (deleting a missing one does nothing), and that `resetAll` wipes the data and recreates empty folders.

**Coverage from `bash scripts/check-goal.sh`:**

| | Before | After |
|---|---|---|
| Lines | 89.8% | 96.47% |
| Functions | 85.18% | 98.3% |
| Files below 90% | indexing-service 87.61, logger 74.71, persistence-service 84 | indexing-service 87.61 |

Tests, type check and architecture check all pass.

**Next round:** add tests for `indexing-service.ts`. The coverage output only includes the summary file, so the next round first needs to rerun coverage in a format that shows which lines are missed. I put this in `loop-state.md`, which now has a Round 2 entry. The old Round 1 "Next" list there is replaced by this one, since its first two items are now done.