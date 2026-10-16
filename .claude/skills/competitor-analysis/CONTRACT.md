# /competitor-analysis — Handoff Contract

## Role in Pipeline
Produces the dated competitor record and price corridor that `/pricing-strategy`,
`/offer-design`, `/gtm-plan`, `/sales-playbook`, `/business` and `/team-business`
consume.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md` | segment and named alternatives | candidates come from the user's list or from search, confirmed by the user |
| `business/competitors/*` (excluding `notes/`, which holds unverified `/business` notes) | refresh base | new files |
| `business/pricing/*` | "our product" column | matrix says `not priced` |

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `INSUFFICIENT DATA`, per competitor and
overall. Per competitor, `INSUFFICIENT DATA` (no `VERIFIED-ON-SITE` price
capture) outranks the other two values. Overall, the worst per-competitor value
applies, except that overall `INSUFFICIENT DATA` means **no** competitor has a
`VERIFIED-ON-SITE` price capture; if at least one does, the overall verdict is
`COMPLETE WITH GAPS` and the `INSUFFICIENT DATA` competitors are named.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/competitors/<slug>.md` | name, URL, segment; plans and prices with capture date, exact page, archive link or none; plan limits; billing options; local payment methods; Arabic/RTL; self-hosted offer; data-residency claims; reviews with site, count, date; mark on every field; change log; NOT SOURCEABLE/NOT CAPTURED table; sources |
| `business/competitors/comparison-matrix.md` | normalised price view with rule and FX source/date; capability matrix with mark and date per cell; corridor with n; tally of marks; re-capture list |

### Output Guarantees
- Every field has one of `VERIFIED-ON-SITE`, `THIRD-PARTY` (source, tier), `NOT CAPTURED` (reason), `NOT SOURCEABLE` (searched)
- Prices keep the published currency, period, unit and tax status; conversions add rate, source, date and never replace the original
- A refresh appends to the change log; older captures are never overwritten
- Corridor statistics are computed, show n, and are withheld below three verified captures

## Immutability Rules
- WRITES only under `business/competitors/` (new files with `Write`; a refresh appends with `Edit`); never edits product briefs, specs or the pricing model

## Hard Constraints (Never Violate)
- No price from memory, review sites or snippets marked as verified
- No login use, paywall/bot-check bypass or contact with a vendor
- No personal data, no fabricated reviews or testimonials; customer logos are claims

## Downstream Skill Expects
Consumers read price rows with their capture dates and treat `STALE` or
`NOT CAPTURED` cells as absent. `/pricing-strategy` needs ≥ 3 dated captures or
the count found plus `NOT SOURCEABLE` for the rest.

## Known Fragile Points
- Pricing pages that render in the browser only, or vary by visitor country, often return no price to a plain fetch: those are `NOT CAPTURED`, and the matrix says so rather than leaving a blank
- Plan-matching across vendors is a judgement; the rule used is written in the matrix
- Rates move: a matrix built on captures from different dates shows the rate date per row
