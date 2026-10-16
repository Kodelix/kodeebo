# /market-research — Handoff Contract

## Role in Pipeline
Produces the sourced market numbers (counts, sizing, buyer behaviour, payment and
regulatory facts) that `/pricing-strategy`, `/gtm-plan`, `/marketing-plan`,
`/sales-playbook`, `/business-case`, `/business` and `/team-business` consume.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md` | segment, ICP, jurisdiction | segment must come from the user; else `INSUFFICIENT DATA — no segment defined` |
| `business/pricing/*`, `business/competitors/*` | price basis `P` | `P` is `ASSUMPTION` or `NOT SOURCEABLE`; country stays below `SIZED` |
| `business/market/*` | reuse of dated rows | researched fresh |

## Verdicts Emitted
`SIZED` / `SIZED WITH ASSUMPTIONS` / `INSUFFICIENT DATA`, per country and overall
(worst wins). `INSUFFICIENT DATA` outranks both pass values.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/market/<topic>.md` | header (date, author, countries, edition, horizon, stale-after, verdict per country); findings table; per-country sizing with formula and low/base/high; buyer, channel, payment and regulatory tables; NOT SOURCEABLE table; assumptions and gaps with closing actions; row tally (A/B/C/D/E, E = 0); next steps; not researched / unreachable |

### Output Guarantees
- Countries and editions are sized separately; any sum is labelled `ILLUSTRATIVE SUM` with overlap and definitions stated
- Unit of count is defined in words from the source; top-down figures appear only as labelled cross-checks
- Arithmetic was re-run by the skill with `calc.py`, not accepted from prose
- Money is local currency first with USD, rate, rate source and rate date; VAT status stated

## Immutability Rules
- WRITES only new files under `business/market/`; never edits existing notes (a refresh is a new dated file or an appended, dated section the user approves)
- Never edits briefs, specs or the pricing model

## Hard Constraints (Never Violate)
- No number from memory; no fabricated survey, interview or quote; no personal data of real people
- No legal, tax or accounting conclusion
- A country with no sourced count is never given a number without a `NOT SOURCEABLE` entry and a labelled range

## Downstream Skill Expects
Consumers read the findings table rows by their scope and date, treat `C`/`D`
rows as assumptions, and re-verify rows older than the file's `Stale after` date.

## Known Fragile Points
- Registries define SMEs differently per country; comparing counts without the definition lines is the usual error
- EGP figures before and after a major rate move are not comparable; the note says which side of such a move each figure sits
- Many official statistical pages are JavaScript-rendered or paywalled; those rows are `not run — unreachable`, not "no data"
