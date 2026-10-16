> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other six — one gate applies per invocation.


# Gate: Discovery → Product Design


**Required Artifacts:**
- [ ] `design/product-brief.md` exists and every REQUIRED field is filled: one-sentence pitch, problem, ICP, jobs-to-be-done, positioning, pricing model, distribution (hosted / self-hosted / hybrid), MVP list, out of scope, success metric, build order, decision log (template: `.claude/docs/templates/product-brief.md`)
- [ ] The brief states the **edition and pricing model once** (subscription, one-time licence, hybrid, self-hosted annual licence) — specs will link to it, not restate it
- [ ] Product principles and anti-principles are defined (in the brief, or `design/product-principles.md`; template `.claude/docs/templates/product-principles.md`), with PD-PRODUCT-PRINCIPLES recorded
- [ ] Visual identity anchor exists: `PRODUCT.md` at the repository root (impeccable), or the brief's "Brand & tone" line, with DD-CONCEPT-VISUAL recorded

**Recommended (not blocking):**
- [ ] Market and competitor evidence in `business/market/` and `business/competitors/` — sourced and dated (`.claude/docs/business-research-protocol.md`); an undated number is not evidence
- [ ] CTO-FEASIBILITY recorded for the core journey on the candidate stack and distribution model
- [ ] PR-SCOPE recorded for the MVP list against timeline and team size
- [ ] A throwaway spike in `prototypes/` with a REPORT.md showing PROCEED, when the core bet is technical (`/prototype`) — skipping it means specs may be written for an idea whose riskiest part has not been tried. Acceptable when the bet is proven by other means
- [ ] Market, competitor and pricing hypotheses written as the fuller sections the brief template lists for `standard` and `full`

**Quality Checks:**
- [ ] The ICP is narrow and named (segment, size, region, buyer vs user, trigger event) — "SMBs" is not an ICP
- [ ] Every MVP item traces to a job-to-be-done; the MVP list is short (about seven or fewer) and each security-sensitive item (auth, billing, uploads, PII, licensing) is marked — they will need a threat model
- [ ] The success metric has a number and a date (one activation metric, one revenue or retention metric)
- [ ] The build order puts the riskiest item (integration, tenancy, billing, performance) first
- [ ] Foundation decisions already taken (tenancy model, identity, data store, API style, deployment topology, licensing) appear in the decision log, with rejected alternatives; undecided ones are listed as open
- [ ] `distribution.model` is chosen (or explicitly listed as undecided, with who decides and by when). Hosted vs self-hosted changes the licence rules for the whole architecture (`.claude/rules/deploy.md`)
- [ ] No `[...]` template placeholder or `TBD` remains in a REQUIRED field — a brief that is still the template is **present but empty**: NOT ASSESSED, not PASS

## Floors at every tier

The brief with its REQUIRED fields filled is the floor of the whole studio
(`.claude/docs/workflow-modes.md` "minimal floor"). No tier drops it.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — brief (REQUIRED fields) + principles with PD-PRODUCT-PRINCIPLES + visual identity anchor with DD-CONCEPT-VISUAL + the fuller brief sections (market, competitors, personas, pricing hypotheses, risks, success metrics, roadmap) all required
- **`standard`** — brief (REQUIRED fields) required; principles + visual identity anchor + the fuller brief sections → recommended
- **`minimal`** — gate target is the **one-page `design/product-brief.md`** with its REQUIRED fields filled; the principles, visual-anchor, fuller-section and recommended items **drop** (a brief with real content = PASS). `/brainstorm` writes the one-page brief at this tier; the fuller concept sections belong to `standard`/`full`.

## Director gates at this transition

The PHASE-GATE panel (Section 4b) runs at the width `workflow` sets. The
per-skill gates PD-PRODUCT-PRINCIPLES, DD-CONCEPT-VISUAL, CTO-FEASIBILITY and
PR-SCOPE are **recorded**, not re-spawned (Section 3, "Recorded director
verdicts"). In `solo`/`lean` their absence is recorded as "skipped — [mode]"
and satisfies the item; with no record at all it is a CONCERNS finding.
