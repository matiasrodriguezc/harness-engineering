The health check passes again. The fix is committed as `fc81108`.

**What broke:** The latest commit, `d29cb1e` ("tweak qa service", by "compañero"), added a single line at the end of `src/services/qa-service.ts`:
```ts
export const brokenCount: number = 'not a number';
```
That puts text into a variable declared as a number, so the type check failed with error TS2322. That was the only change in the commit, and nothing in the codebase uses `brokenCount`.

**Fix:** I reverted that commit, which removes the two lines it added and changes nothing else. There was no correct value to guess for it, so I didn't write an `ALERT.md`.

**Verification:** I re-ran `bash init.sh` and all 6 steps passed: environment, dependencies, types, build, architecture checks, and the real app exposing `window.knowledgeBase`. It ended with `init.sh OK`. The working tree is clean.

The NODE_OPTIONS warning in step 1 has nothing to do with this failure, and the scripts already work around it.

You may want to ask whoever made `d29cb1e` what that change was for, in case they meant to add something real.