# /prototype — Phase 4: Plan the Prototype

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Plan the Prototype

Define in 3–5 bullet points the minimum viable prototype:

- What is the falsifiable hypothesis, and the measurable signal that settles it?
- What is the riskiest assumption — and how does this prototype test it first?
- What is the absolute minimum needed to answer the question?
- What is explicitly cut? (auth, tenancy, billing, error handling, tests, polish, architecture — all of it) — these become the report's **Shortcuts taken** list.
- Who or what will produce the observation (named ICP testers and how many; a benchmark with its data volume and hardware) — and when. **If no one will use it, the verdict will be NOT ASSESSED; say so now.**
- Safety: sandbox credentials only, `127.0.0.1` binds, no real customer data, nothing deployed.

**Scope constraint:** A concept prototype tests ONE question — not the whole
product. If scope covers more than one, cut it down. When in doubt, cut more.

Present this plan to the user before building. Get confirmation before proceeding.
Name the checkpoint file in that confirmation: "May I record this plan in
`production/session-state/active.md`?"
If the user declines the plan, build nothing and stop with
`NOT ASSESSED — prototype plan not approved`.

Once confirmed, write a session checkpoint to `production/session-state/active.md`
(create `production/session-state/` if it does not exist) in the `<!-- CHECKPOINT -->`
format of `.claude/docs/templates/session-state.md` — **overwrite the block, never
append**. Include: concept name, hypothesis, path chosen, scope bullet points, and
the next step ("Phase 5 — Implement"). This lets the next session resume without
starting over if the session ends mid-build.

---
