# Concept Prototype Report: [Concept Name]

> **Date**: [YYYY-MM-DD]
> **Prototype Path**: [Click-through mock / Code spike / Concierge-manual / Paper]
> **Brief File**: design/product-brief.md (if it exists)

---

## Hypothesis

[The falsifiable hypothesis this prototype set out to test:
"If the [ICP role] [does X], they will [Y] — evidenced by [measurable signal Z]."]

---

## Riskiest Assumption Tested

[The biggest risk in the product idea (desirability, feasibility, willingness to
pay, integration viability, performance at scale) and whether it proved out.]

---

## Approach

[What was built, how long it took, what shortcuts were taken deliberately.]

**Path chosen:** [Click-through mock / Code spike / Concierge-manual / Paper]
**Reason for path:** [Why this path was appropriate for this hypothesis]

**Shortcuts taken (intentional):**
- [e.g. hardcoded tenant, fake billing, no auth, seeded data, no tests]

---

## Result

[What actually happened — specific observations, not opinions. Quote testers
directly where possible.]

---

## Metrics

| Metric | Value |
|--------|-------|
| Path used | [Mock / Spike / Concierge / Paper] |
| Prototype duration | [e.g. 4 hours] |
| Testers | [N internal / N external, ICP match?] |
| Task success / time-on-task | [Specific — "3 of 5 finished import in under 2 min"] |
| Technical measurement (if feasibility) | [e.g. "p95 340 ms at 100k rows without an index"] |
| Willingness-to-pay signal | [quote, pre-order, or none] |
| Hypothesis verdict | [CONFIRMED / PARTIALLY CONFIRMED / REFUTED] |

---

## Recommendation: [PROCEED / PIVOT / KILL / NOT ASSESSED — built but nobody has used it]

[One paragraph explaining the recommendation with evidence from the result above.]

---

## If Proceeding

[What the prototype revealed that should directly inform the feature specs:]

- **Values discovered (limits, thresholds, timeouts):** [e.g. "batch size 500 kept p95 under budget"]
- **Assumptions confirmed:** [What the brief assumed that proved true]
- **Assumptions disproved:** [What the brief assumed that proved wrong]
- **Emerging requirements:** [Behaviours seen in testing worth specifying]
- **Security / tenancy surprises:** [Anything that changes the threat model]

**Next steps:**
1. `/spec-review design/product-brief.md`
2. `/gate-check`
3. `/map-domains`
4. `/design-spec [feature]` (use learnings in Detailed Behaviour and Non-Functional Requirements)

---

## If Pivoting

[What alternative direction the results suggest — what felt almost right and what
to adjust. Be specific about what to change.]

**Pivot direction:** [What to try differently]
**What to keep:** [What worked and should be preserved]
**Next step:** `/prototype [revised-concept]`

---

## If Killing

[Why this does not work — the specific signal that led to the verdict. This
report is the deliverable; no further action is needed on this concept.]

**Next step:** `/brainstorm [new-direction]`

---

## Lessons Learned

- **What assumptions were broken by actually building this?**
  [...]

- **What surprised us that did not show up in the brainstorm?**
  [...]

- **What would we test differently next time?**
  [...]

---

> *Prototype code location: `prototypes/[concept-name]-concept/`*
> *This code is throwaway. Never refactor it into a code root.*
