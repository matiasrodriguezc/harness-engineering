I found the bug and fixed it. Any document longer than 1000 characters was being indexed with empty chunks.

**Root cause:** in `src/services/indexing-service.ts`, the chunking code did this for every chunk:

```ts
const chunkContent = content.length > 1000 ? '' : buffer.trim();
```

Once a document went over 1000 characters, every chunk was saved with empty text. That broke Q&A in two ways:
- Keyword matching scores chunk text, so empty chunks rarely matched and few or no citations came back.
- Any citation that did come back had an empty excerpt, and the answer text was built from that empty excerpt, so it said nothing useful.

**Fix:**
1. **Chunks keep their text:** `chunkDocument` now stores the real paragraph text for every chunk, whatever the document's length.
2. **Existing indexes get rebuilt:** indexing used to skip any document already recorded as indexed, so users' broken indexes would never have been fixed. It now re-indexes a document if its saved chunks are missing or empty. Users only need to run indexing again; they don't have to re-import anything.

**Verification:** I added `tests/indexing-service.test.ts` with three tests: chunks of a long document keep their text, Q&A returns citations with non-empty excerpts, and an index broken by the old bug gets rebuilt. All three fail on the old code and pass with the fix.

**Things you should know:**
- **`npm run test` doesn't find any tests.** `vite.config.ts` sets the test root to `src/renderer`, so vitest only looks there. I ran the new tests with `npx vitest run --root . tests`. A small vitest config would make `npm run test` pick them up; I can add one.
- **`npm run check` fails with 14 type errors.** The same 14 errors appear with or without my change, so they were already there. They're in the renderer components and an unused import in `qa-service.ts`, and none involve the files I changed. Because of the rule to run `check` before committing, I haven't committed.
- **New `package-lock.json`:** dependencies weren't installed, so I ran `npm install` (without downloading the Electron app itself), which created this file. Keep it or delete it as you prefer.
- **Separate bug I didn't fix:** indexing a single document writes its chunks but doesn't record the document in `index-meta.json`. Q&A builds its list of chunks from that file, so a document indexed on its own isn't searchable until a full re-index runs.