# Vertical Slice Report: [Product Name]

> **Date**: [YYYY-MM-DD]
> **Slice Duration**: [N days]
> **Target Scope**: one core journey working end to end, deployed: DB -> API -> web/mobile -> deploy
> **Source**: design/product-brief.md

---

## Validation Question

[The architecture-and-experience question this build was proving:
"Can a new tenant admin, starting from nothing, complete [core journey] within
[N] minutes, unguided — and does the architecture (tenancy, auth, billing hook,
deploy) hold at representative quality, buildable in [X] days?"]

---

## Scope Built

[Layers and contexts implemented, quality level, what was intentionally omitted.]

**Layers included:**
- [DB schema + migration + tenancy enforcement]
- [API endpoints + contract]
- [Web / mobile screens]
- [Auth / entitlement check / observability]
- [Deploy: compose up on the target topology]

**Quality level:** [Placeholder / Representative / Near-shipping]
**Shortcuts taken deliberately:** [List]
**What was cut from original scope:** [List]

---

## Build Velocity Log

[Day-by-day record of what was completed. Real production-rate data — use it in
sprint planning.]

| Day | Completed |
|-----|-----------|
| Day 1 | [What was built] |
| Day 2 | [What was built] |
| Day 3 | [What was built] |

**Total elapsed:** [N days] for [scope summary]
**Velocity estimate:** [e.g. "1 day per CRUD endpoint with tests and evidence, 0.5 days per web screen"]

---

## Architecture Validation

| Concern | Result | Evidence |
|---------|--------|----------|
| Tenant isolation holds (cross-tenant negative test) | [PASS / FAIL] | `[file]` |
| Auth / session flow works across web + mobile | | |
| Observability: one trace spans client -> API -> DB/cache | | |
| Performance vs `perf-budgets.md` on the slice | | |
| Clean-architecture rules respected (no inward violations) | | |
| Deploy: fresh `docker compose up` to working journey | | |
| Self-hosted topology still viable (if in scope) | | |

---

## Usability Results

| Attribute | Value |
|-----------|-------|
| Total sessions | [N] |
| Internal testers | [N] |
| External testers | [N — people from the ICP who had not seen the product] |
| Avg time to complete core journey | [N minutes (target: [N] minutes)] |
| Time to first value | [N seconds (target: [N] seconds)] |

---

## Observations

[Specific, non-opinion observations from sessions. Quote testers where useful.]

**Where testers succeeded without guidance:**
- [...]

**Where testers were confused or stuck:**
- [...]

**Reactions observed:**
- [...]

---

## Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Time to first value | [N sec] | [N sec] |
| Core journey completion time | [N min] | [N min] |
| Critical usability blockers found | 0 | [N] |
| Pipeline / CI / deploy blockers found | 0 | [N] |
| Architecture surprises | 0 | [N] |

**Experience assessment:** [Specific — "confirmation step unclear; users re-submitted the form" not "felt rough"]

---

## Recommendation: [PROCEED / PIVOT / KILL / NOT ASSESSED — the slice was built but nobody has used it]

[One paragraph with evidence — reference the validation question directly. Did a
target user complete the core journey unguided within the target time? Does the
architecture hold? Can the team build at this quality on the projected schedule?]

**product-director review (PD-USABILITY):** [APPROVE / CONCERNS / REJECT / NOT ASSESSED — the director's reason; or "not run — [review mode]"]

---

## If Proceeding

**Production requirements** (what must change from slice to production):
- [e.g. "Replace seeded data and fake billing with the provider sandbox integration"]
- [e.g. "Add rate limits and audit log"]

**Architecture adjustments needed:**
- [ADR to update or create]

**Sprint velocity estimate based on slice data:**
- [e.g. "1 day per endpoint with full DoD evidence"]

**Scope adjustments from the original plan:**
- [What the slice revealed about true production scope]

**Performance targets:** [Confirmed / Revised — list changes if revised]

**Usability note:** run `/usability-report` to structure additional session data
before running `/gate-check production`.

**Next steps:**
1. `/create-epics layer:foundation` — plan Foundation layer epics
2. `/create-epics layer:core` — plan Core layer epics
3. `/create-stories [epic-slug]` — break each epic into stories
4. `/sprint-plan` — use velocity data from this report in the estimate
5. `/gate-check production` — formally advance to Production

---

## If Not Assessed

[The slice was built but nobody from the ICP has used it unguided, so there is no
evidence for PROCEED, PIVOT or KILL yet.]

**Next step:** run at least one documented, unguided session, then re-run
`/vertical-slice` — it resumes from the checkpoint in
`production/session-state/active.md`.

---

## If Pivoting

[Which specs or ADRs need revision and why — be specific about the failure mode observed.]

**Features requiring spec revision:** [List]
**Architecture decisions to revisit:** [List — use `/architecture-decision` to update]
**Core journey change needed:** [What specifically to change]

**Next steps:**
1. `/design-spec [feature]` — revise affected specs
2. `/architecture-decision [decision]` — address architecture issues
3. `/vertical-slice` — re-validate after revisions

---

## If Killing

[Why the core journey does not work at this quality, or why the architecture
cannot support it. What to do instead.]

**Next step:** `/brainstorm` to explore a new direction, or `/prototype [new-concept]`
to test a different concept cheaply before investing in another vertical slice.

---

## Lessons Learned

- **What assumptions were broken by building to near-production quality?**
  [...]

- **What surprised us about the pipeline or architecture?**
  [...]

- **What would we change about the slice scope if we ran this again?**
  [...]

---

> *Vertical slice code location: `prototypes/[product-name]-vertical-slice/`*
> *This code is reference material only. Production implementation is written from scratch.*
> *Never import or refactor this code into a code root.*
