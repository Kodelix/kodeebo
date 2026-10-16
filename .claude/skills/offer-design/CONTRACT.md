# /offer-design — Handoff Contract

## Role in Pipeline
Designs a launch deal, discount, coupon, bundle, trial, referral reward or
partner/POC term as a price with a purpose, an end date and a control for every
abuse case. Work is done by `pricing-strategist` (with `marketing-lead` for
launch-deal copy and timing). Follows `/pricing-strategy` and `/business-case`;
reached from `/business` (class `offer`) and `/team-business`. Feeds
`pricing-billing-designer` (catalogue rows, then `/pricing-check`), `/marketing-plan`,
`/gtm-plan` and `product-analytics-engineer`. It designs; it does not publish, apply a
coupon in billing or send a campaign.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `business/pricing/*` | price table, **margin floor**, grandfathering rule | no floor to guard, none invented: `INSUFFICIENT DATA — no floor price` naming `/pricing-strategy` |
| `design/specs/pricing-model.md` (canonical; else `Glob design/**/pricing-model*.md`, non-canonical location named) | live plans, existing trials and coupons | stated ABSENT |
| `business/cases/*` | CAC, payback, churn, variable cost per customer | impact `NOT ASSESSED` unless the user approves labelled assumptions (then `RECOMMEND` is unreachable); assumptions declined → `INSUFFICIENT DATA — no unit-cost / CAC input` naming `/business-case`; the guardrail table is still presented |
| `business/market/*`, `business/competitors/*` (dated public offers) | audience size, competing offers | stated ABSENT; rates are `ASSUMPTION` |
| `design/product-brief.md` | product and edition context | stated ABSENT |

### Preconditions
- An offer idea or goal is given; none → the skill asks what the offer should achieve and stops
- Type (launch / discount / bundle / trial / referral / partner / POC) and edition are classified; hosted and self-hosted are separate offers
- The user supplies the single behaviour to change, the budget cap in local currency, earliest and latest dates, and whether existing customers may take it; a skipped answer is re-asked in plain text
- The user confirms `<slug>`, the kebab-case offer name, in Phase 1
- `pricing-strategist` is spawned; for a launch deal `marketing-lead` is spawned in the same parallel block; then `product-analytics-engineer` is spawned with the strategist's terms, impact and draft measurement plan to agree the plan

## Verdicts Emitted
`RECOMMEND` / `RECOMMEND WITH CONDITIONS` / `DO NOT RECOMMEND` / `INSUFFICIENT DATA`.
Precedence, first match wins: `DO NOT RECOMMEND`, `INSUFFICIENT DATA`,
`RECOMMEND WITH CONDITIONS`, `RECOMMEND`.
- `DO NOT RECOMMEND`: any stack reaches below the floor; base case has negative incremental margin; no cap or end date; an abuse case that breaches the floor has no control.
- `INSUFFICIENT DATA`: no floor price; or economics cannot be computed (no unit-cost / CAC input and assumptions declined, or still not computable with approved ones).
- `RECOMMEND WITH CONDITIONS`: any rate is an assumption; any abuse case is an accepted risk; the measurement plan is not yet agreed with `product-analytics-engineer` (it ran and asked for changes), or that agreement is `NOT ASSESSED` because it did not run (then `RECOMMEND` is unreachable).
- `RECOMMEND`: floor, cap, dates and controls complete, impact inputs tier 1-3 or measured, and break-even `i*` at most 80 % of the **low**-scenario `i` (a studio convention, unsourced, stated as such in the file).
A check that did not run is `NOT ASSESSED` and keeps `RECOMMEND` out of reach, including the `product-analytics-engineer` agreement.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/pricing/offer-<slug>.md` | header (date, author `pricing-strategist` via `/offer-design`, verdict, sources); recommendation; offer terms table covering all twelve guardrail fields (purpose, eligibility, depth, duration, stacking, floor price, budget cap / redemption limit, start and end date, abuse controls, renewal behaviour, existing customers, editions) with source or rationale per row; floor check; abuse cases table (all eleven, control and residual-risk acceptance); expected impact (formula, inputs table, low/base/high, break-even `i`); measurement plan; assumptions and gaps; hand-off; next steps |

### Output Guarantees
- No floor price is invented; the lowest price reachable by any stack is shown against the floor per plan and currency
- Every offer has an end date, a cap and a control per abuse case, or the case is marked "accepted risk - needs the user's decision"; this skill never accepts a risk
- Impact is a labelled scenario: `M = R x i x (p_d - v) - R x (1 - i) x (p - p_d)`, cannibalisation explicit, low/base/high, `i* = (p - p_d) / (p - v)`; all arithmetic run with `calc.py`; a past-campaign result only if the user supplies the data
- Measurement plan names events for the tracking plan, a holdout or staggered start, primary metric and guards, sample size computed with `calc.py`, a pre-written stop rule, consent rules, and the read-out date and decider
- Money is local currency first with USD, rate, source and date; VAT status stated
- Number rows A/B/C/D/E counted as in `/business` Phase 4; E = 0
- No dark patterns: no hidden auto-renew, cancellation as easy as sign-up, renewal terms shown before purchase; no unprovable claim in copy; self-hosted telemetry stays off by default
- The header date comes from `date +%F`; leftover placeholders are searched for

## Immutability Rules
- WRITES only the one file above under `business/pricing/`, only after "May I write ...?" (autonomous mode: writes and records `log_decision`). A declined write writes nothing: the presented verdict stands and the report says "not saved" (accepted business-skill exception)
- Never edits the price table, the pricing model, billing catalogue or code; offers that change plans or entitlements of record go to `product-director` as an approval request

## Hard Constraints (Never Violate)
- No fabricated testimonials or results; no legal, tax or accounting conclusion (promotional pricing, auto-renewal and consumer-protection questions are stated, the authority's page cited, "confirm with a qualified advisor")
- Nothing is published, applied in billing or sent; the user launches and ends the offer

## Downstream Skill Expects
`pricing-billing-designer` reads the terms table for catalogue rows, then `/pricing-check`; `/marketing-plan` and `/gtm-plan` take copy and timing; `product-analytics-engineer` takes events and holdout; `privacy-compliance-specialist` takes consent facts; `licensing-specialist` takes POC licence enforcement. `ASSUMPTION` rates stay assumptions.

## Known Fragile Points
- `product-analytics-engineer` can be unreachable (nested spawning); the verdict is then capped below `RECOMMEND` and the file says the agreement was not run
- The eighty-percent break-even rule is a studio convention, not a sourced figure
- Abuse-control quality (trial farming, coupon leakage, cross-currency arbitrage) is judgement and needs the user's review
- `<slug>` is the kebab-case offer name the user confirmed; a change of name after confirmation needs a re-ask before the write
