Round 3 is done and the goal is now met: `bash scripts/check-goal.sh` prints **GOAL: PASS**.

- **What I added:** `tests/services/indexing-service.test.ts`, with 5 tests. Earlier rounds left this file as the only one below 90% (at 87.61%). The new tests cover:
  - the empty state;
  - indexing one document whose content is missing, which returns `error`;
  - indexing one document whose content exists;
  - how text is split into roughly 500-character pieces at paragraph breaks;
  - indexing everything at once, which skips documents with no content and ones already indexed, and moves through idle → indexing → ready.
- **Coverage:** lines went from 96.47% to 99.01%. Functions stayed at 98.3%. No file is below 90% any more. Tests, the type check and the architecture check all pass.
- No changes to `src/`. I updated `loop-state.md` and committed both files as `9bc28c7`.

One behaviour you might not expect: indexing a single document with `startIndexing(id)` saves its chunks but doesn't add it to `index-meta.json`. Until a full indexing run, the status and `getAllChunks()` don't count that document. The tests describe this as it works today, as the goal requires, and I noted it in `loop-state.md` in case it's a bug.