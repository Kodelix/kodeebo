# /team-business — Handoff Contract

## Role in Pipeline
Runs the business team end to end for one decision and returns a single
consolidated, sourced recommendation. Callable from `/studio` and
`studio-orchestrator` when a flow needs a market-entry, pricing, launch,
edition or viability decision.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md` | ICP, positioning | `INSUFFICIENT DATA — no ICP / product to evaluate` unless the user supplies it |
| `docs/ROADMAP.md` | business model, editions | stated ABSENT |
| `business/**`, `docs/research/**` | reuse of dated, sourced rows | everything is researched fresh |

### Preconditions
- At least one decision stated; options compared when a choice is asked
- Thresholds (margin floor, payback limit, budget cap, minimum SOM) set by the user before wave 1, or recorded as "none stated"

## Verdicts Emitted
`RECOMMEND` / `RECOMMEND WITH CONDITIONS` / `DO NOT RECOMMEND` / `INSUFFICIENT DATA`;
wave outcomes `DONE` / `BLOCKED` / `NOT RUN`. Precedence: `DO NOT RECOMMEND`,
`INSUFFICIENT DATA`, `RECOMMEND WITH CONDITIONS`, `RECOMMEND`. A needed wave that is
`BLOCKED` or `NOT RUN` makes the verdict at best `INSUFFICIENT DATA`.

## Outputs Produced

| File | Guaranteed sections | Notes |
|---|---|---|
| `production/business/<slug>/NN-<agent>[-country].md` | the specialist's draft in protocol shape | working drafts, written by the agents under the bounded exception |
| `business/cases/<slug>-decision-<date>.md` | verdict; recommendation; numbers table with A/B/C/D/E tally; options table; conflicts side by side; ±20 % sensitivity; assumptions and gaps; cheapest disproving test and threshold; next steps; specialists consulted / not run / unreachable | new file after the user's yes |
| `business/market|pricing|marketing|sales/<slug>-*.md` | the matching specialist's note | only for specialists that ran |

### Output Guarantees
- Which specialists ran and which did not is stated before the run and in the output
- Countries and editions are separate; money is local currency first with USD, rate, source, date; VAT status stated
- Arithmetic shown in drafts was re-run by the skill

## Immutability Rules
- WRITES only new files under `production/business/<slug>/` and `business/`
- Never edits `design/**`, specs, code, the pricing model or the catalogue

## Hard Constraints (Never Violate)
- No number from memory; no fabricated quote, testimonial, survey, interview or pipeline figure
- No legal, tax or accounting conclusion; no investment advice
- Never contacts anyone, publishes, buys or commits spend; never decides product scope or implements pricing

## Downstream Skill Expects
`product-director` reads the decisions list for sign-off; `pricing-billing-designer`
reads the pricing note after sign-off; `/gtm-plan`, `/marketing-plan`,
`/sales-playbook` start from the specialist files rather than researching again.

## Known Fragile Points
- Nested spawning from a subagent may be unavailable, so the skill (not the director) spawns every specialist
- Parallel wave 1 agents may report different definitions of the unit of count; the director shows the definitions side by side and does not sum
- Working drafts under `production/business/` can go stale; the decision file carries the stale-after date
