# P05 · Separating the doer from the reviewer

Project question: how much does separating roles improve the result? Three configurations on the same feature, with the same rubric.

**Feature (same in all three):** "Add multi-turn Q&A conversation history to this knowledge base app: the question panel should show the previous questions and answers as a conversation, with each answer's citations."

**Common rubric:** `rubric-template.md`, 8 criteria scored 1 to 5. It requires evidence of having used the app; an unverified criterion cannot score above 2.

**Configurations** (each session is fresh and only knows what is in the files; script `scripts/run-p05.sh`):

| | Sessions |
|---|---|
| **A · single role** | 1: plans, implements and self-evaluates with the rubric |
| **B · generator + evaluator** | generator → skeptical evaluator (tests the app, does not touch code) → generator fixes → evaluator re-evaluates |
| **C · planner + generator + evaluator** | planner writes `sprint-contract.md` without touching code → generator → evaluator → fix → re-evaluation |

**Final judge:** to avoid relying on each configuration's own score (its evaluator is part of the treatment), **the same independent judge** (same prompt, ignores prior evaluations, tests the app) scored all three. I also verified: typecheck, architecture guard, tests, build, and the UI bridge with `scripts/check-bridge.mjs`.

## Results

| | A · single role | B · gen + eval | C · plan + gen + eval |
|---|---|---|---|
| Sessions | 1 | 4 | 5 |
| Duration | 10 min | 23 min | 33 min |
| Cost (excluding the judge) | US$2.54 | US$7.05 | US$8.60 |
| Own score | 4.0 (self-evaluation) | 3.9 → **4.5** (evaluator, round 1 → 2) | 4.3 → **4.5** (evaluator, round 1 → 2) |
| **Independent judge score** | **3.9** | **4.5** | **4.0** |
| Defects the evaluator found | — | 6 real (out of 13 tests) | 8 (fixed 1–6 and 8) |
| Tests | 13 | 20 | 9 |
| UI bridge (my verification) | ✅ | ✅ | ✅ |
| typecheck / guard / build | ✅ / ✅ / ✅ | ✅ / ✅ / ✅ | ✅ / ✅ / ✅ |
| Code change size (excluding lock, screenshots and evaluation files) | 24 files, +1,372 | 26 files, +1,895 | 68 files, +4,688 |

**Judge score by criterion:**

| Criterion | A | B | C |
|---|---|---|---|
| Functional completeness | 4 | 5 | 5 |
| Visual design | 4 | 4 | 4 |
| Timestamps | 5 | 5 | 4 |
| Citations | 4 | 4 | 4 |
| Interactivity | 3 | 5 | 3 |
| Edge cases | 3 | 4 | 4 |
| Accessibility | 4 | 4 | 4 |
| Code quality | 4 | 5 | 4 |

**Comparison with the course solution:** the course rubrics say 1.6 / 3.3 / 4.9 for A / B / C. Those are illustrative numbers from the repo itself; here, measured with an independent judge, they came out 3.9 / 4.5 / 4.0.

## Failures by layer

| Config | Failure | Layer |
|---|---|---|
| C | C's evaluator gave it 4.5 and the judge 4.0: the judge's first defect ("follow-up questions don't receive the conversation as context") was not flagged by C's evaluator | Verification (the planner's contract set the criteria and the evaluator checked them; whatever fell outside the contract was not looked at) |
| C | The largest change of the three (68 files) with no better score | Task / scope (the contract expanded the work) |
| A | Weaker interactivity and edge cases (3 and 3) | Verification (without an outside look, gaps remained that B did fix) |

## Conclusion

**Separating the reviewer helped; adding a planner did not.** With a current model, a single agent already does good work and self-evaluates quite accurately (it gave itself 4.0 and the judge 3.9): the strong "leniency" the course anticipates did not show up. Adding an independent evaluator that uses the app raised the judge's score from 3.9 to 4.5: it found 6 real defects and the fix pass closed them, especially in interactivity and edge cases. Adding a planner on top did **not** improve things: the judge gave it 4.0, below B, with the largest code change and the highest cost. The contract made C's evaluator review against criteria fixed in advance, and it missed a defect the judge flagged first.

Cost: B costs 2.8 times as much as A for +0.6 points; C costs 3.4 times as much for +0.1. This matches Anthropic's idea that the evaluator is worth it when the task is beyond what the model does well on its own; here the feature was medium-sized and A was already close to 4. A single run per configuration and a single judge: the numbers are indicative.
