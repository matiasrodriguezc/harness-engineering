I finished the last tracked feature, `grounded-qa`. All features in `feature_list.json` are now marked `pass`, but the project isn't complete yet: the clean-state checklist found a missing "Show Chunks" button.

**What I did for grounded-qa**
- The question-answering service already worked: it returns citations and the 0.85 / 0.30 confidence scores, and it saves the question history. The only missing piece was showing the user how reliable an answer is.
- In `src/renderer/App.tsx`, answers that have citations now get a green "Well-grounded · confidence 85%" badge and border. Answers without citations get an amber "Speculative · confidence 30%" badge, and the answer text is shown in italics.
- **Checks:** `npm run check` passes. In a test run against the services directly, a question about chunking got 0.85 with 2 citations from ARCHITECTURE.md. A nonsense question got 0.30 with no citations. The saved history held both questions when read back by a new service instance. I haven't tried the badge in the running app.
- Committed as `b69ee5c`, along with the updates to `feature_list.json` and `session-handoff.md`.

**Clean-state checklist (partial pass)**
- **Passing:** `npm run check` and `npm run build` both succeed and produce `dist/`. There are no `any` types, no default exports, and no Node.js imports in the renderer.
- **Gap:** the checklist expects a "Show Chunks" button in the document detail view, and there isn't one. It isn't listed in `feature_list.json`, so under the one-feature-at-a-time rule I didn't build it. It should be added as a new feature entry first. I recorded this in `session-handoff.md` (commit `68cc821`).
- **Not checked:** the items that need the app running by hand, such as the window opening, the file picker and data surviving a restart.

**Optional extra:** the app saves question history and the API can return it, but the UI never displays it. No tracked feature requires it.