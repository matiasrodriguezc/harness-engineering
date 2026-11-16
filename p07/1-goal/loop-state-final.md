# Loop state

## Round 1

- Added `tests/services/document-service.test.ts` (8 tests): list on empty store, import (title/filename/size/status/content), missing file throws, unknown id lookups, update + persistence across a new service instance, update unknown, delete keeps others, delete unknown.
- No changes to `src/`.
- Coverage before: lines 83.13% / functions 74.07%; below 90%: document-service 63.23, indexing-service 87.61, logger 70.11, persistence-service 77.33.
- Coverage after: lines 89.8% / functions 85.18%; below 90%: indexing-service 87.61, logger 74.71, persistence-service 84. document-service no longer below the bar.
- tests, types and architecture checks all pass (`check-goal.sh` exit fields = 0).

### Next (superseded by Round 2)

## Round 2

- Added `tests/services/logger.test.ts` (4 tests): JSON entry shape + per-level console stream, `data` only when non-empty, `LOG_LEVEL=WARN` filtering (module re-imported with `vi.resetModules`), `forService` ServiceLogger at all levels.
- Added `tests/services/persistence-service.test.ts` (6 tests): directory creation + path getters, readJson/readText missing -> null and round-trips in nested dirs, copy/delete in documents (missing delete is a no-op), listFiles/exists on missing paths, resetAll.
- No changes to `src/`.
- Coverage before: lines 89.8% / functions 85.18%; below 90%: indexing-service 87.61, logger 74.71, persistence-service 84.
- Coverage after: lines 96.47% / functions 98.3%; below 90%: indexing-service 87.61 only.
- `check-goal.sh`: tests_exit=0 types_exit=0 arch_exit=0; GOAL: FAIL only because of indexing-service.

### Next
1. `indexing-service.ts` (87.61%) — the only remaining blocker. Run coverage with a text/json reporter (only `coverage-summary.json` is written to `.coverage-goal/`) to find the uncovered lines, then add `tests/services/indexing-service.test.ts` for those branches.

## Round 3

- Added `tests/services/indexing-service.test.ts` (5 tests): empty status/chunk lookups, single-document indexing with missing content -> `error` status, single-document indexing writes chunks (content + metadata) but does not update `index-meta.json` (current behavior, documented as-is), ~500-char chunking at paragraph boundaries, batch indexing (skips missing content and already-indexed docs, idle -> indexing -> ready).
- No changes to `src/`.
- Coverage before: lines 96.47% / functions 98.3%; below 90%: indexing-service 87.61.
- Coverage after: lines 99.01% / functions 98.3%; below 90%: none.
- `check-goal.sh`: tests_exit=0 types_exit=0 arch_exit=0 — **GOAL: PASS**.

### Next
- Goal met; nothing required. Possible observation (not a test task): single-document `startIndexing(id)` never records the doc in `index-meta.json`, so `getAllChunks()`/status ignore it until a batch run.
