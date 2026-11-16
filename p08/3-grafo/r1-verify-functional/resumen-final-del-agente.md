The functional verification **passes**. I checked all 11 acceptance criteria in spec.md in the running app, found no defects, and changed no application code.

I wrote `verdict-functional.md` starting with `VERDICT: PASS` and `LAYER: none`. A verdict file from an earlier run was already there, and I replaced it with this run's evidence. I haven't committed it, since earlier verdict files were committed by the graph itself.

- **Standard checks:** `npm run check`, `npm test` (50 of 50 tests), `bash scripts/check-architecture.sh`, `npm run build` and `bash scripts/smoke-bridge.sh` all pass. The smoke test lists the new `conversation` key.
- **In the running app:** I wrote my own end-to-end script rather than reusing the implementer's. It asks questions and clicks the Export button with real keyboard and mouse events over Chrome DevTools. It compares each export against Markdown rebuilt independently from the conversation history, using the format in spec.md. All 36 checks passed. They cover:
  - an empty conversation, including after `qa.clearHistory()` and `app.reset()`;
  - question order and the `## Question N` headings;
  - citations, including multi-line excerpts and the `No citations.` case;
  - adding a fourth question;
  - clicking the button: it asks no question, and the saved file matches `export()` byte for byte in UTF-8;
  - a cancelled save: no file and no message;
  - failed saves (a missing folder, or a path that is a folder): an error message appears and later questions still get answered;
  - the export staying identical after the app restarts.
- **Not tested live:** the real save dialog, because it can't be driven over Chrome DevTools. I confirmed from the code that it offers a default name of `conversation-YYYY-MM-DD.md`.

My first run failed, but the cause was my script: it removed the confirmation message from the page itself, which broke the page's rendering. Once I stopped doing that, everything passed.

The script is at `/private/tmp/claude-501/-Users-matiasrodriguezc-harness-runs-p08-wt-func/d324ff65-0bf5-4691-a405-eb357ea56b50/scratchpad/vf2.mjs`.