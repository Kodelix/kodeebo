# /gtm-plan — Handoff Contract

## Role in Pipeline
Turns the product brief, the sized market, dated competitor captures and the
price table into a launch plan the user can run. Feeds `/marketing-plan`
(channels, CAC ceiling), `/sales-playbook` (motion), `/business-case` (targets)
and `/launch-checklist` (go/no-go and dates).

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md` | ICP, positioning, decision log | G1 `NOT ASSESSED`; with no description from the user either, `INSUFFICIENT DATA — no ICP` |
| `PRODUCT.md` | brand and tone | tone stated as ABSENT |
| `business/market/*` | SAM/SOM and verdict, buyer, channel, payment, regulatory facts | G2, G7 `NOT ASSESSED`; targets `NOT ASSESSED` with no SOM |
| `business/competitors/*` (excluding `notes/`) | dated alternatives | G3 `NOT ASSESSED` |
| `business/pricing/*` | price table, linked and never restated | pricing reference says ABSENT |
| `business/cases/*` | CAC and payback targets | CAC target is an `ASSUMPTION` |

### Preconditions
- Launch window, budget ceiling (if any) and owners come from the user; an owner is never invented

## Verdicts Emitted
`PLAN READY` / `PLAN READY WITH CONDITIONS` / `PLAN NOT READY` / `INSUFFICIENT DATA`.
Precedence, first match wins: `PLAN NOT READY`, `INSUFFICIENT DATA`,
`PLAN READY WITH CONDITIONS`, `PLAN READY`. Checks G1–G11: MET / NOT MET /
NOT ASSESSED. An unflagged target above the SOM base case is `PLAN NOT READY`; a
flagged one is `PLAN READY WITH CONDITIONS`.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/marketing/gtm-<product>-<market>.md` | header (date, authors, edition, market, verdict, sources, stale-after); recommendation; segment choice; positioning (marked proposal); AR/EN messaging table with evidence per claim; channels; pricing reference (links only); launch sequence with go/no-go and review date; targets low/base/high with formula; owners (`UNASSIGNED` where not supplied); risks; measurement; assumptions and gaps; next steps; check table G1–G11 |

### Output Guarantees
- No price is restated; no testimonial, logo, case study, review score or statistic without a row behind it
- Targets derive from SOM by a shown formula (`calc.py`), or are `NOT ASSESSED`
- Hosted and self-hosted plans, and markets, are never blended
- Money is local currency first with USD, rate, rate source and date; VAT status stated
- A specialist or check that did not run is listed as not run

## Immutability Rules
- WRITES only new files under `business/marketing/`
- Never edits the product brief, specs, the pricing model or code; the positioning of record stays `product-director`'s

## Hard Constraints (Never Violate)
- No fabricated proof; no legal, tax or accounting conclusion
- Nothing is published, sent or spent by this skill

## Downstream Skill Expects
`/marketing-plan` and `/sales-playbook` read the segment, positioning proposal,
channel sequence and targets; they treat `ASSUMPTION` rows as assumptions and
`UNASSIGNED` owners as open.

## Known Fragile Points
- Arabic register quality is only checked when `localization-lead` ran; otherwise the file says "Arabic review: not run"
- A launch plan for several markets in one file keeps separate sections per market; blending is the usual error
