The health check passes again. I fixed it and committed the fix as `df3b5b9`.

**What broke it:** commit `d7d9208` ("add fs helper for renderer") added `src/renderer/fs-helper.ts`. That file imports Node's `fs` module into the renderer. The project's rule (`docs/ARCHITECTURE.md`, AGENTS.md) is that the renderer reaches the app only through `window.knowledgeBase`, so the architecture check flagged it. The file only exported `leaked = typeof fs`, and nothing in `src`, `tests` or `scripts` uses it.

**Fix:** I reverted `d7d9208`, which deletes that file. Nothing used it, so removing it doesn't change how the app behaves.

**Check:** I ran `bash init.sh` again and it ended with `init.sh OK`. The architecture check found no violations, and the real-app step confirmed the running app exposes `window.knowledgeBase` (keys: documents, indexing, qa, feedback, app). The working tree is clean.

I didn't write an ALERT.md, since the fix was clear. If the author really needs file access from the renderer, it has to go through the preload and `window.knowledgeBase`, not a direct `fs` import.