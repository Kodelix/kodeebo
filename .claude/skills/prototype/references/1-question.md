# /prototype — Phase 1: Define the Question

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Define the Question

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Check for spike mode:** If `--spike` was passed, skip to the **Spike Mode** section.

**Check for a carry-forward note:** Glob `prototypes/*/PIVOT-NOTE.md`. If one
exists for this concept (or an earlier version of it), read it and start from its
revised hypothesis instead of forming one from scratch — say which note you used.

Then, unless `--spike` sent you to Spike Mode, use `AskUserQuestion` to confirm
intent before proceeding — with or without a carry-forward note:

- **Prompt**: "How would you like to use this prototype session?"
- **Options**:
  - `Prototype this concept` — build a throwaway to test the riskiest assumption before writing specs (up to 1 day)
  - `Skip — concept already proven` — I have enough evidence this works; log it and proceed directly to design
  - `Mid-build spike` — I'm already building and want to test a specific design or technical question quickly (~4 hours, no phase-gate implications)

**If "Skip — concept already proven":**
Ask (plain text, not a widget): "What evidence do you have that the concept works?"
Record the one-line answer, then stop. Note: "Concept prototype skipped — evidence:
[answer]." Suggest next step: `/map-domains` or `/design-spec [feature]`.

**If "Mid-build spike"**: skip to the **Spike Mode** section.

**If "Prototype this concept"**: continue below.

---

**A note on prototype strategy:** Building 2–3 concept variants and letting the
best one win is far more likely to succeed than iterating one concept until it
works. This is your first prototype, not necessarily your only one. If this one
produces a PIVOT verdict, consider whether to refine the concept OR start fresh
with a different angle on the same idea.

Read the concept description from the argument. Before building anything, define
the **falsifiable hypothesis** this prototype must answer:

> *"If the [ICP role] [does X], they will [Y] — we will know this is true if [measurable signal Z]."*

Good: "If a clinic receptionist imports a patient list, they will finish within
2 minutes without help — we'll know if 4 of 5 testers do."
Good (feasibility): "A single Postgres instance serves the tenant dashboard query
under 150 ms p95 with 100k rows per tenant — we'll know from `EXPLAIN ANALYZE`
and a 5-minute k6 run."

Bad: "Is this a good product?" ← not testable, not falsifiable.

**If the concept is too vague to form a hypothesis, stop here.** Ask the user to
narrow the question before proceeding. A prototype without a clear question
wastes time.

Also ask: **"What is the riskiest assumption in this concept?"** Name its kind —
*desirability* (will the ICP want/use it), *willingness to pay*, *feasibility*
(can we build/operate it), *integration viability* (does the provider/API do what
we need), *performance at scale*, or *compliance/privacy* — and test that first,
not the easiest part.

---
