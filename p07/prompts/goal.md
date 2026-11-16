# Goal

Every service module in `src/services/` has meaningful unit tests: overall line and function coverage of `src/services/` is at least 95%, and every file in `src/services/` has at least 90% line coverage.

## Acceptance criteria (all machine-checked by `bash scripts/check-goal.sh`)

- [ ] `npm test` passes
- [ ] Overall line and function coverage of `src/services/**` are at least 95%, and every file has at least 90% line coverage (`scripts/check-goal.sh` prints the numbers and the files below the bar)
- [ ] `npm run check` passes
- [ ] `bash scripts/check-architecture.sh` passes

## Scope

Fair game:
- Test files under `tests/`
- Small, behavior-preserving changes in `src/services/` only if a module is impossible to test otherwise (explain why in `loop-state.md`)

Hands off:
- `src/renderer/`, `src/preload/`, `src/main/`
- Application behavior: tests must describe what the code does today; do not change features to make tests pass
- `package.json` dependency versions

## How to work

1. Read `loop-state.md` (if it exists) to see what earlier rounds did.
2. Run `bash scripts/check-goal.sh` to see the current coverage.
3. Add tests for the least-covered modules first.
4. Run `bash scripts/check-goal.sh` again.
5. Update `loop-state.md`: the round number, what you added, the coverage before and after, what is next. Commit.

## Stop conditions (enforced by the loop, not by you)

- `scripts/check-goal.sh` passes
- 6 rounds
- No coverage progress for 2 rounds in a row
