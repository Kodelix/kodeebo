# /pricing-strategy — Handoff Contract

## Role in Pipeline
Turns market, competitor and cost evidence into a priced, margin-checked,
testable model, and hands it as data to `product-director` (sign-off) →
`pricing-billing-designer` (implementation) → `/pricing-check`. Feeds
`/offer-design`, `/sales-playbook`, `/marketing-plan` and `/business-case` with
prices and the floor.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md` | ICP, positioning, pricing hypotheses | `INSUFFICIENT DATA — no ICP / value to price` unless supplied |
| `business/competitors/*` (≥ 3 `VERIFIED-ON-SITE`, within horizon; `notes/` excluded) | corridor (P3) | P3 `NOT ASSESSED`; verdict `INSUFFICIENT DATA` for price levels |
| `deploy/`, `docs/architecture/perf-budgets.md`, `slos.md`, hosting notes | cost per customer (P5) | P5/P6 `NOT ASSESSED` unless the user approves labelled assumptions (then `RECOMMEND` is unreachable) |
| `design/specs/pricing-model.md` (canonical; else `Glob design/**/pricing-model*.md`, non-canonical location named) | existing catalogue, to version | treated as first version |
| licence-model artifact | licence mechanics | `licensing-specialist` asked; unanswered = "not decided", a condition |

### Preconditions
- The margin floor and VAT display rule are the user's and set before research

## Verdicts Emitted
`RECOMMEND` / `RECOMMEND WITH CONDITIONS` / `DO NOT RECOMMEND` / `INSUFFICIENT DATA`.
Precedence: `DO NOT RECOMMEND`, `INSUFFICIENT DATA`, `RECOMMEND WITH CONDITIONS`,
`RECOMMEND`. Checks P1–P12: MET / NOT MET / NOT ASSESSED; any NOT ASSESSED makes
`RECOMMEND` unreachable. Every P1–P12 outcome maps to a verdict (table in
`references/1-pricing-brief.md`).

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/pricing/<product>-<topic>.md` | verdict; value metric with one rejected alternative; packaging with upgrade triggers; price table (local currency first, USD with rate/source/date, VAT status); corridor with n; margin by plan with sensitivity ±20 %; licence and self-hosted terms; offers headline and floor; price-test design with computed sample size; check table P1–P12; assumptions and gaps; decisions for `product-director` |
| `business/pricing/<product>-handoff-<date>.md` | header (status PROPOSED, catalogue version, verdict); data in `pricing-model.md` order, prices in integer minor units; grandfathering; EGP review trigger; open questions |

### Output Guarantees
- No price appears without currency, period and VAT status; no spec or code receives a price from this skill
- Self-hosted and hosted rows have separate cost, margin and sales-cycle lines
- Sample size is computed (`calc.py`), not stated
- The hand-off never says "signed off" — sign-off is the user's and `product-director`'s

## Immutability Rules
- WRITES only new files under `business/pricing/`; reads the rest
- Never edits `design/specs/**`, the pricing model, the catalogue, code or contracts

## Hard Constraints (Never Violate)
- No fee, rate, tax rule or competitor price from memory; no fabricated willingness-to-pay data
- No legal, tax or accounting conclusion
- No publishing or running of a price test; no contact with customers or competitors

## Downstream Skill Expects
`pricing-billing-designer` reads the hand-off as data in template order and
creates a new catalogue version; `/pricing-check` reads the resulting model,
not this file; `/offer-design` and `/business-case` read the price table and the
margin floor.

## Known Fragile Points
- Currency volatility makes an EGP price list age fast; the review trigger is part of the output and is not optional
- A corridor from fewer than three captures is a sketch; the file says so
- Payment-provider pages are often script-rendered; fees that could not be fetched are `NOT ASSESSED`, not assumed
