# Decision matrix, waves and files — `/team-business`

Read in Phase 1 and again before each wave if the conversation was compacted.

## Which specialists a decision needs

| Decision | `market-researcher` | `pricing-strategist` | `marketing-lead` | `sales-lead` |
|---|---|---|---|---|
| Enter country X (or X vs Y) with a product | yes, **one per country** | yes | yes | if an enterprise/self-hosted motion is in scope |
| Set or change prices / packaging | yes (corridor, willingness-to-pay evidence) | yes | no | only if enterprise discounts are affected |
| Launch offer or promotion | yes (competitor offers) | yes | yes (timing, copy) | no |
| Go-to-market for a product in a market | yes | yes | yes | if enterprise/self-hosted |
| Add a self-hosted / enterprise edition | yes | yes | no | yes |
| Is this product worth building / continuing (viability) | yes | yes | yes | yes |
| Pure market-size or competitor question | yes | no | no | no — use `/market-research` or `/competitor-analysis` |
| Brand architecture, product naming or trademark screening | no | no | `marketing-lead` owns | no — use `/brand-architecture` |

A specialist marked "no" is **not spawned and the plan says so with the reason**.
A decision that fits one row only needs less than a team: say "this is a
`/<skill>` question" and offer it.

## Waves (the order is the dependency order)

| Wave | Who | Why this order | Parallel? |
|---|---|---|---|
| 1 | `market-researcher` | counts, corridors, buyer behaviour, payment and tax facts feed everyone | one agent per country, **in one parallel block** |
| 2 | `pricing-strategist` | prices, floor and ACV feed CAC ceilings and discount authority; needs the corridor from wave 1 | single agent (may take several countries in one run, tables kept separate) |
| 3 | `marketing-lead` and `sales-lead` | each needs prices and the ICP; neither needs the other | **in one parallel block** |
| 4 | `business-director` | consolidates: one answer, options on one table, conflicts side by side, sensitivity, cheapest disproving test | single agent; runs the unit-economics model (`.claude/skills/business-case/references/model.py`) when the decision turns on payback, LTV:CAC or margin |

If an agent cannot be spawned, the skill says why and which part this session
did itself (shown in the final "Specialists" line).

## Working files (new files under `production/` named by this skill)

`production/business/<decision-slug>/` — `<decision-slug>` is the decision as a slug
(lowercase, spaces to hyphens, ASCII).

| Wave / agent | Writes to |
|---|---|
| 1 market-researcher, per country | `production/business/<slug>/01-market-<country>.md` |
| 2 pricing-strategist | `production/business/<slug>/02-pricing.md` |
| 3 marketing-lead | `production/business/<slug>/03-marketing.md` |
| 3 sales-lead | `production/business/<slug>/03-sales.md` |
| 4 business-director | `production/business/<slug>/04-decision.md` |

These are working drafts. The deliverables under `business/` are compiled from
them after the user approves (Phase 6). The files carry the same four-field
number rows as any business output.

## What each specialist is asked for

| Agent | Return |
|---|---|
| `market-researcher` | findings table, bottom-up sizing for its country (low/base/high), buyer/channel/payment/regulatory rows, competitor captures needed for pricing (dated, marked), NOT SOURCEABLE entries, gaps |
| `pricing-strategist` | recommendation, price table per currency (VAT status, USD with rate/source/date), corridor, margin by plan with ±20 % sensitivity, floor price, licence / self-hosted terms if in scope, price-test design |
| `marketing-lead` | ICP per country, positioning proposal, channel rows with sourced benchmarks or `ASSUMPTION`, CAC ceiling derived from the pricing file, budget table, launch sequence |
| `sales-lead` | motion by the selling-cost rule, qualification, pipeline and forecast (`ILLUSTRATIVE`), enterprise terms with status, payment terms, discount authority from the floor, objections with provenance |
| `business-director` | verdict, recommendation, numbers table with tally, options table, conflicts side by side, sensitivity, assumptions and gaps, next steps, specialists consulted / not run / unreachable |

## Final deliverables (each a new file, only after "May I write")

| File | Compiled from |
|---|---|
| `business/cases/<slug>-decision-<date>.md` | `04-decision.md` — the one consolidated answer |
| `business/market/<slug>-<country>.md` | `01-market-<country>.md` |
| `business/pricing/<slug>-pricing.md` | `02-pricing.md` |
| `business/marketing/<slug>-marketing.md` | `03-marketing.md` |
| `business/sales/<slug>-sales.md` | `03-sales.md` |

Specialist files that were not produced are not created, and the decision file
lists them as "not run".
