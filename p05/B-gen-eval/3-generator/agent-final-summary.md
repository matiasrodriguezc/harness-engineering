I fixed all 12 defects listed in `evaluator-rubric.md` and verified them in the running app. The work is committed as `cbe074c` and the working tree is clean. I did not edit `evaluator-rubric.md`, `rubric-template.md` or anything in `evaluation/`.

**Verification**
- `npm run check` and `bash scripts/check-architecture.sh` both pass.
- `npm test`: 20/20 pass, up from 11. The new tests cover malformed entries, a corrupt or non-list history file, write errors, a 4-turn follow-up chain, clearing while a question is pending, and the excerpt helpers.
- `scripts/verify-conversation.mjs` in the real Electron app: 34/34 pass, up from 23. Each defect now has its own check, and screenshots 07–09 are new.
- The evaluator's probe: 12/13 pass, up from 7. I ran it from a scratchpad copy where only the selector changed (`ol[role=log]` → `[role=log] ol`), because fix #6 moved that role. The one failure is P9b, which the evaluator had already called a false positive (it measures the thread's 12px padding).

**Fixes, in rubric order**
1. **Stale conversation after a load failure:** the conversation and the counts now reset to 0. The error shows just above the question box, so it stays visible after scrolling.
2. **One bad entry hid everything:** entries are now checked one at a time. Invalid ones are skipped with a WARN log but stay in the file, so nothing is lost when the file is next saved.
3. **Raw developer errors:** they now read "The conversation history file is unreadable (<path>). It was left unchanged. Repair or move that file, then press Refresh." Save failures get a similar message, such as "permission denied".
4. **Citations:** clicking one now opens the chunk list, scrolls to the cited chunk, focuses it and highlights it as "cited in the answer". Chunk numbers start at 1.
5. **Clear while a question is pending:** the service no longer saves that answer, and the UI ignores it. The confirmation now says "…and discard the question still being answered?"
6. **List semantics:** `role="log"` is on a wrapping `<div>`, so the `<ol>`/`<li>` structure is intact.
7. **Focus after Cancel:** Cancel and Esc both close the confirmation and return focus to "Clear conversation".
8. **Follow-up context:** retrieval now uses the questions from up to 5 earlier turns in the chain. It also ignores punctuation and common words like "and" and "why", so matches on those no longer count.
9. **Long excerpts:** excerpts are plain one-line text with markdown stripped, limited to 3 lines.
10. **Dead `qa:history` API:** removed the channel, handler, preload method and renderer type.
11. **Mid-word cut:** long answers are cut at a word boundary, using a helper now shared with excerpts (`src/shared/text.ts`).
12. **"Today/Yesterday" labels:** they refresh just after midnight. Hours now show as "7:00 AM" rather than "07:00 AM".

I also moved the shared styles into `src/renderer/styles.ts`, which removes the coupling the evaluator noted.

**Open risks**
- The fallback answer still says "No relevant documents have been indexed yet" even when documents are indexed. The rubric marked this out of scope, so I left it and listed it in `docs/verification/README.md`.
- The E2E check for clearing while a question is pending depends on timing. It clicks Clear while the app's simulated answer delay (100–500 ms) is still running. It passed here, but on a very slow machine the answer could arrive first.
- The error message shows the full path to the history file. That is intentional, so the user can find the file, but it does expose the local folder layout.