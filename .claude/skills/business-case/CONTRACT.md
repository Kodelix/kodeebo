# /business-case — Handoff Contract

## Role in Pipeline
Produces the unit economics and scenario model that `/offer-design` (margin and
CAC limits), `/marketing-plan` (CAC ceiling), `/sales-playbook` (selling-cost
ceiling), `/gtm-plan` (targets) and `/business` consume, and that the user uses
to decide launch, price or market entry.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `business/pricing/*` | ARPA, licence price, margin floor | driver absent: ask; unapproved → `INSUFFICIENT DATA` |
| `deploy/`, `docs/architecture/perf-budgets.md`, `slos.md` | variable cost | cost rows are `ASSUMPTION` (user-approved) or `NOT ASSESSED` |
| `business/marketing/*`, `business/sales/*` | CAC, selling cost | CAC from user actuals or labelled range |
| user-supplied actuals | churn, CAC, conversion | churn is an assumption range |

### Preconditions
- Decision criteria (max payback, min LTV:CAC, min margin, horizon) are given by the user before the run

## Verdicts Emitted
`RECOMMEND` / `RECOMMEND WITH CONDITIONS` / `DO NOT RECOMMEND` / `INSUFFICIENT DATA`.
Precedence: `DO NOT RECOMMEND`, `INSUFFICIENT DATA`, `RECOMMEND WITH CONDITIONS`,
`RECOMMEND`. `RECOMMEND` requires drivers that are tier 1–3 rows or the user's
measured data.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/cases/<product>-<slug>.md` | header with edition and verdict; criteria; recommendation with the cheapest disproving test; inputs table (provenance on every row); formulas and worked example; verbatim model output; sensitivity with holds/flips; assumptions and gaps; reproduction command |
| `business/cases/<product>-<slug>-inputs.json` | the exact inputs for `references/model.py`, scenario low = pessimistic |

### Output Guarantees
- Re-running `python3 -I .claude/skills/business-case/references/model.py business/cases/<product>-<slug>-inputs.json` reproduces the pasted tables
- Hosted, self-hosted and licence cases are separate runs and sections
- Money is net of VAT, local currency first, USD with rate source and date

## Immutability Rules
- WRITES only new files under `business/cases/`; a refresh is a new dated file
- Never edits pricing, specs or code; `model.py` is read-only for the skill's runs

## Hard Constraints (Never Violate)
- No input without provenance or an `ASSUMPTION` label; no fabricated benchmark or result
- No thresholds chosen after seeing results
- No legal, tax, accounting or investment advice

## Downstream Skill Expects
Consumers read the inputs table and the criteria; they treat `ASSUMPTION` rows as
assumptions and take CAC and margin ceilings from the stated base values.

## Known Fragile Points
- Pre-launch churn and CAC are always assumptions; the verdict says so instead of hiding it
- Expansion revenue is not modelled; a case that depends on it states it as upside
- Annual contracts: monthly churn derived from annual churn smooths renewal cliffs; the file notes it when it applies
