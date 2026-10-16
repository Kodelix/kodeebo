# /sales-playbook — Handoff Contract

## Role in Pipeline
Turns the price table, the CAC ceiling and engineering-confirmed enterprise terms
into a sales playbook and a fill-in proposal template: which motion for which deal
size, how a lead is qualified, how a deal moves, what can and cannot be promised,
who sells through partners, the real objections. Work is done by `sales-lead`; the
people who can confirm an enterprise term are asked first. Reached from `/business`
(class `sales`) and `/team-business`; follows `/pricing-strategy`, `/business-case`
and `/gtm-plan`. Feeds `customer-success` (close hand-off fields) and the user's own
proposals.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| `design/product-brief.md` | ICP | no brief and no ICP from the user → `INSUFFICIENT DATA — no ICP` |
| `docs/ROADMAP.md` | hosted and self-hosted plan, licence decisions | stated ABSENT |
| `business/pricing/*` | prices, **floor price**, licence terms | with a user-supplied price basis (labelled `ASSUMPTION`): ACV and discount-authority floor `NOT ASSESSED` (S1, S6), no ACV invented, no motion chosen from a remembered threshold; with no price basis anywhere: `INSUFFICIENT DATA — no price basis` |
| `business/cases/*` | CAC ceiling, margin, payback limit | S1 `NOT ASSESSED`; selling-cost rule cannot be applied |
| `business/market/*` | buyer roles, procurement, payment methods, tax facts | brief gets "none"; payment and VAT rows are sourced from the authority's page or labelled assumption (S5 `NOT ASSESSED` if the page is unreachable) |
| `business/competitors/*`, `business/marketing/*` | alternatives, segment and messages | stated ABSENT |
| licence-model artifact, `docs/architecture/slos.md`, backup/DR design | basis of self-hosted licence terms, SLA, RPO/RTO | the matching enterprise term is `NEEDS ENGINEERING APPROVAL`, never `OFFERED` |
| `business/sales/*` (existing) | recorded FOUND or ABSENT; the newest playbook/template is the `Supersedes:` target of a re-run and the source of `OFFERED` terms for `--scope proposal` | `--scope proposal` falls back to slots only |

### Preconditions
- A product is named; none → the skill asks and stops
- `--scope full|motion|terms|proposal` (default `full`) fixes the files, sections and active checks: `motion` = sections 1-5, 9, 10, 13, 14 (S1, S2, S3, S7, S8, S10-S12); `terms` = 1, 2, 6, 7, 8, 11, 13, 14 (S4, S5, S6, S10-S12); `proposal` = the template only (S9-S12); everything else is `N/A — out of scope (stated)` and counts as MET
- Hosted and self-hosted are separate in motion, cycle, win rate, support load and forecast
- Markets, conversation notes or counts, partners and owners come from the user; a skipped answer is re-asked in plain text. No conversations supplied → every objection is `HYPOTHESIS`; no partner named without the user's confirmation; no owner invented
- Enterprise or self-hosted in scope → `sre-lead`, `licensing-specialist`, `security-lead`, `privacy-compliance-specialist` are spawned in one parallel block before `sales-lead`; each returns `can promise today` + proof path / `needs work` / `not planned`, and no evidence is "not confirmed"

## Verdicts Emitted
`PLAN READY` / `PLAN READY WITH CONDITIONS` / `PLAN NOT READY` / `INSUFFICIENT DATA`.
Precedence, first match wins: `PLAN NOT READY`, `INSUFFICIENT DATA`,
`PLAN READY WITH CONDITIONS`, `PLAN READY`. Checks S1–S12: MET / NOT MET / NOT ASSESSED;
a check whose subject is out of scope (S4 with neither enterprise nor self-hosted in
scope) is `N/A — out of scope (stated)` and counts as MET.
The verdict is computed **after** the audit's fixes, demotions and removals (a term demoted to `NEEDS ENGINEERING APPROVAL` or a reference removed no longer counts).
- `PLAN NOT READY`: an unconfirmed term still presented as `OFFERED`; a motion's selling cost above the CAC ceiling in the base case; a discount path below the floor; invented references or pipeline still present.
- `INSUFFICIENT DATA`: no ICP (`INSUFFICIENT DATA — no ICP` when brief and user give none), or no price basis anywhere (`INSUFFICIENT DATA — no price basis`). A price file absent but a price basis given by the user is `NOT ASSESSED` for S1/S6 instead.
- `PLAN READY WITH CONDITIONS`: any check NOT ASSESSED or NOT MET for a stated reason, or continuing on labelled assumptions; each condition says how it closes.
- `PLAN READY`: S1–S12 MET (`N/A` counts as MET) and drivers tier 1–3 or measured; reachable for a hosted-only playbook.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `business/sales/<product>-playbook.md` (`--scope` full, motion or terms) | header (date, author agents, product, edition, markets, scope, verdict, sources, stale-after, `Supersedes:` on a re-run); recommendation; motion by ACV with the selling-cost-vs-CAC-ceiling rule; qualification (SMB and MEDDICC); pipeline with forecast formula and low/base/high; enterprise terms with status and source; payment terms; discount authority; partners and resellers; objection handling with provenance; questionnaire/RFP library pointer; hand-off to `customer-success`; assumptions and gaps; next steps |
| `business/sales/<product>-proposal-template.md` (`--scope` full or proposal) | the nine proposal sections (stated problem; proposal; price; term and renewal; service levels; data, security and residency; implementation; assumptions; acceptance) with deliberate `{slot}` markers |

The S1–S12 table, motion table, terms table and conditions are presented in the
conversation; the layout does not make the S1–S12 table a section of the file.

### Output Guarantees
- Every enterprise term has exactly one status: `OFFERED` (cited path: pricing file, ADR, SLO, licence model, test), `NEEDS ENGINEERING APPROVAL` (named confirmer) or `REFUSED` (reason). No source → `NEEDS ENGINEERING APPROVAL`
- Prices appear only from the pricing file; the floor is never invented; missing floor → `NOT ASSESSED`
- Motion is chosen by `fully loaded selling cost <= CAC ceiling`, not by a remembered ACV cut-off; cycle days and selling cost are `ASSUMPTION` until measured, with the closed-deal count that replaces them
- Forecast is computed with `calc.py`, shown low/base/high, example deals marked `ILLUSTRATIVE`
- Every objection is `OBSERVED`, `PUBLISHED` or `HYPOTHESIS`; an answer promising an unshipped capability is removed
- Money is local currency first with USD, rate, source and date; VAT/e-invoicing cited from the authority's page with effective date and the advisor caveat
- Hosted and self-hosted are never blended; a specialist or check that did not run is listed as not run, with dependent terms left unconfirmed; unspawned enterprise agents are named "enterprise terms: not in scope"
- Number rows A/B/C/D/E are counted as in `/business` Phase 4 and E = 0
- The header date comes from `date +%F`; leftover placeholders other than the template's `{slot}` markers are searched for

## Immutability Rules
- WRITES only the files above that the scope produces, under `business/sales/`, only after "May I write ...?" (autonomous mode: writes and records `log_decision`). A declined write writes nothing: the presented verdict stands and the report says "not saved" (accepted business-skill exception)
- No `Edit` tool is granted and nothing is overwritten: a re-run over an existing file writes a new dated file (`<product>-playbook-<date>.md`, `<product>-proposal-template-<date>.md`; same-day collision adds `-2`) whose header says `Supersedes: <previous path>`. The questionnaire library is only pointed to, never built here
- Never edits the pricing file, specs, the licence model or code; price, plan or edition changes go to `/pricing-strategy` or `product-director`

## Hard Constraints (Never Violate)
- Nothing is promised that engineering has not confirmed in writing: SLA, residency, certifications, features
- No fabricated customers, references, logos, quotes, win stories or pipeline numbers; no personal data of real prospects; no cold outreach from scraped data
- No legal, tax or accounting conclusion; contract text goes to the user's legal advisor; no legal wording drafted as binding
- Sending proposals, contacting prospects or partners, and signing are the user's actions

## Downstream Skill Expects
`customer-success` reads the close hand-off fields; the user takes `NEEDS ENGINEERING APPROVAL` terms to the named confirmers, fills the template per deal and sends it. Terms and numbers marked `ASSUMPTION` or `HYPOTHESIS` stay so.

## Known Fragile Points
- The four confirmers are spawned from this skill; nested spawning from a subagent may be unavailable, so an unreachable confirmer leaves its terms `NEEDS ENGINEERING APPROVAL` and is reported as not run
- Conversion rates, cycles and selling costs are assumptions until the first N closed deals; objections are hypotheses without user-supplied notes
