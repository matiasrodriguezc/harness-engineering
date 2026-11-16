# Rubric: multi-turn Q&A conversation history

Score each criterion from 1 (missing or broken) to 5 (complete and polished). For every score give concrete evidence: what you ran or clicked, what you saw, or the file and line you inspected. If you could not verify a criterion, say so and score it no higher than 2.

| Criterion | What a 5 looks like |
|---|---|
| Functional completeness | Asking several questions in a row shows all previous questions and answers as a conversation; nothing is lost or truncated; it works in the running app, not only in code |
| Visual design | Clear distinction between user questions and assistant answers; consistent with the rest of the app |
| Timestamps | Each exchange shows when it happened, in a readable format |
| Citation display | Each answer's citations are visible (document and excerpt) and usable |
| Interactivity | Sensible interactions (e.g. select, expand, copy, follow-up) that work |
| Edge cases | Empty history, long answers, answers without citations and errors are handled |
| Accessibility | Semantic elements, keyboard use, labels |
| Code quality | Respects the layer boundaries in `docs/ARCHITECTURE.md`, `npm run check` and `scripts/check-architecture.sh` pass, no dead code |

**Overall:** the average of the eight scores, to one decimal.

Then list the defects that remain, numbered, most important first.
