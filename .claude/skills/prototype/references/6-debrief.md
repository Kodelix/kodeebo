# /prototype — Phase 6: Usage Debrief

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Usage Debrief

The prototype is built. Now capture what was actually observed. Do NOT skip to
report generation — the report is only as good as the observations collected here.

**Click-through mock:** say exactly this:
> "The prototype is ready. Open `prototypes/[name]/prototype.html` in a browser and
> put it in front of people from the ICP — watch silently, then ask one question:
> 'What was confusing?' Come back with what you saw: how many people, what they did,
> where they hesitated, what they said."

**Code spike:** the iteration loop already captured errors and output. Now ask for
the measurement or behaviour that answers the question, with its conditions (data
volume, hardware, command, warm/cold).

**Concierge / manual:** ask for the `log.md` entries — deliveries done, time spent
each, user reactions, and whether any user would pay or pre-order.

**Paper:** say exactly this:
> "Read `prototypes/[name]/rules.md` and walk through `walkthrough.md` as if for
> the first time. If you can, run the rules with 5 people and note every point of
> confusion. Come back with what happened."

**If nobody has used it this session**, do not ask for a verdict and do not infer
one from how the build looks: the recommendation is **NOT ASSESSED — built, not
used**. Write the report with that verdict (Phase 7, asking first) and name the next
step — put it in front of the ICP, then re-run this debrief.

Once the user returns, ask these questions **one at a time** — wait for each answer
before asking the next:

1. **Hypothesis check:**
   > "The hypothesis was: [restate the hypothesis from Phase 1]. Did it hold up —
   > CONFIRMED, PARTIALLY CONFIRMED, or REFUTED? Tell me what you saw — numbers
   > first (how many people / what measurement)."

2. **Best moment:**
   > "What was the moment — if any — where it clearly worked (a user finished
   > unaided, a number came in under budget, someone asked to pay)? Be specific."

3. **Worst moment:**
   > "What was the most frustrating, confusing or broken moment? Be specific — not
   > 'it was slow' but 'the import of 100k rows took 14 s and the UI froze'."

4. **Surprise:**
   > "Did anything happen that you didn't expect — good or bad? Anything that
   > changes the security, tenancy or compliance picture (data you did not expect to
   > hold, a permission case nobody had thought of, a provider limit)?"

5. **Verdict:**
   > "PROCEED, PIVOT, or KILL — and one sentence why."

Collect all answers before report generation. If any answer is vague ("it felt
fine", "pretty good"), ask a follow-up: "Can you be more specific? What exactly
felt fine about it?" Precise observations make the report useful; vague ones make
it useless. A feasibility result without its measurement conditions is `indicative
only` (SKILL.md constraints).

---
