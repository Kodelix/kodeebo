# /business — Handoff Contract

## Role in Pipeline
Front door for every business question. Classifies it, runs the owning business
specialists, has `business-director` consolidate, and returns one answer in the
`business-research-protocol.md` shape. Callable from `/studio` and
`studio-orchestrator` whenever a flow hits a market, price, offer, go-to-market,
sales or unit-economics question.

## Inputs Consumed

### Files That Must Exist
None are mandatory — absence is reported, not papered over.

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md` | ICP, positioning, decision log | question about "the product" → `INSUFFICIENT DATA` unless the user supplies it |
| `docs/ROADMAP.md` | business model (subscription, one-time licence, hosted + self-hosted) | stated as ABSENT in the answer |
| `design/specs/pricing-model.md` (canonical; else `Glob design/**/pricing-model*.md`, non-canonical location named) | implemented prices | implementation status of pricing unknown, said so |
| `business/**`, `docs/research/**` | reuse of dated, sourced facts | no reuse; everything is researched fresh |

### Preconditions
- A question in Arabic or English. No argument → the skill asks and stops
- Thresholds (margin floor, payback limit, budget cap) are set by the user before research, or recorded as "none stated"

## Verdicts Emitted
`RECOMMEND` / `RECOMMEND WITH CONDITIONS` / `DO NOT RECOMMEND` / `INSUFFICIENT DATA`;
outcome `ROUTED` (no verdict) when the whole question is out of scope.
Precedence: `DO NOT RECOMMEND`, then `INSUFFICIENT DATA`, then
`RECOMMEND WITH CONDITIONS`, then `RECOMMEND`. `INSUFFICIENT DATA` outranks both
recommendations and does not outrank a known failure.

## Outputs Produced

| File | Guaranteed sections | Notes |
|---|---|---|
| `business/<market\|pricing\|marketing\|sales\|cases>/<slug>-<date>.md` | header (date, author agents, question, language, sources); verdict + recommendation; numbers table with the A/B/C/D/E tally; assumptions and gaps with closing actions; dated next steps; specialists consulted / not run / unreachable | new file, only after the user's yes |
| `business/competitors/notes/<topic>-<date>.md` | same sections as above, plus the header lines `Type: /business note - not a competitor capture` and `Verification: NOT VERIFIED-ON-SITE`; closes with the recommendation to run `/competitor-analysis` for a full verified capture | competitor-dominant answers only; new file after the user's yes; never `business/competitors/<slug>.md` or `comparison-matrix.md`; ignored as a capture by `/competitor-analysis`, `/pricing-strategy`, `/gtm-plan` |

### Output Guarantees
- Every number row has value + unit + currency, source + tier, date and scope, or is labelled `ASSUMPTION` / `NOT SOURCEABLE`; the E count is 0
- Money is local currency first with USD, rate, rate source and rate date; VAT status stated
- A verdict is derived from the drivers' status, never from tone
- Hosted and self-hosted are separate columns/sections, never summed

## Immutability Rules
- READS: `design/`, `docs/ROADMAP.md`, `business/**`, `docs/research/**`
- WRITES: only new files under `business/` (a competitor-dominant answer goes only to `business/competitors/notes/`, never into the verified-capture files)
- Never edits product code, specs, contracts, infra or the pricing model

## Hard Constraints (Never Violate)
- No market figure, price, fee, tax rate or FX rate from memory
- No fabricated quote, testimonial, survey or interview result; no named individuals as competitors
- No legal, tax or accounting conclusion
- Never contacts anyone, publishes, or commits spend

## Downstream Skill Expects
`/pricing-strategy`, `/gtm-plan`, `/business-case` and `/team-business` read the
saved answer's numbers table and assumptions list as dated, sourced inputs; an
`ASSUMPTION` row stays an assumption downstream. A `business/competitors/notes/` file
is a lead, never a `VERIFIED-ON-SITE` capture, and is not counted toward any corridor.

## Known Fragile Points
- Nested spawning from a subagent may be unavailable; the skill spawns the specialists itself for that reason
- Facts older than the user's stated horizon are re-verified; with no horizon stated the skill asks rather than assuming
