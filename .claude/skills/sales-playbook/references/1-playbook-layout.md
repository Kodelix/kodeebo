# Sales playbook layout and audit — `/sales-playbook`

Read in Phase 2; give to `sales-lead`; use as the Phase 4 audit. Output:
`business/sales/<product>-playbook.md` and
`business/sales/<product>-proposal-template.md` (layout in
`references/2-proposal-template.md`).

## Sections

1. **Header** — date, author agents, product, edition (hosted / self-hosted **separate**, never blended), markets, scope (`full|motion|terms|proposal`), verdict, sources, stale-after, and `Supersedes: <path>` on a re-run.
2. **Recommendation** — motion per edition and market, headline terms, in one paragraph.
3. **Motion by ACV** — table per edition and country:

   | Edition / country | ACV (local currency; USD eq. with rate, source, date) | Source (price file row) | Expected sales cycle (days) | Fully loaded selling cost per deal | Motion |

   Rule, written in the file: a motion is acceptable only if its **fully loaded selling cost ≤ CAC ceiling** (`ACV × gross margin × payback months allowed`, from `business/cases/` or `/marketing-plan`); below that, a cheaper motion applies. Self-serve / inside sales / enterprise-field / partner-led are chosen **by this rule and the buyer behaviour in each country**, not by a remembered ACV cut-off. Cycle days and selling costs are `ASSUMPTION` until measured, with the number of closed deals after which they are replaced. Missing ACV or ceiling → `NOT ASSESSED`.
4. **Qualification** — SMB: budget range and owner, decision maker and process, need and trigger event, timeline. Enterprise (MEDDICC): metrics, economic buyer, decision criteria, decision process, identified pain, champion, competition. Each element: **the question to ask, the evidence required to tick it, the disqualify rule**. ICP fit from the brief.
5. **Pipeline** — stages with entry criteria, exit criteria, owner role, maximum age before review, and conversion assumption (`ASSUMPTION` or sourced); stage names match the CRM fields listed. **Forecast formula** written out (`leads × stage conversions × ACV`, by country and edition), low/base/high vs the revenue target, computed with `calc.py`. Any example deal is marked `ILLUSTRATIVE`; no pipeline actuals are invented.
6. **Enterprise terms** — one row per term; the **status** is exactly one of:

   | Status | Meaning | Needs |
   |---|---|---|
   | `OFFERED` | can be promised today | a source: pricing file, ADR, SLO, licence model, test evidence — path cited |
   | `NEEDS ENGINEERING APPROVAL` | not yet confirmed | a named confirmer in writing: `sre-lead` (SLA/RPO/RTO), `licensing-specialist` (licence terms), `security-lead`, `privacy-compliance-specialist` (residency, subprocessors) |
   | `REFUSED` | not offered | the reason; used for source-escrow and audit requests unless decided otherwise |

   Terms: SLA percentage (tied to `docs/architecture/slos.md`), response times by severity, support hours across Egypt and Gulf time zones, RPO/RTO from the backup design, data-residency options actually supported, subprocessors, exit and data-export rights, security-review support, self-hosted licence term, instance/user bounds, offline grace, update window, expiry behaviour, support entitlement, POC/trial licence. **A term with no source defaults to `NEEDS ENGINEERING APPROVAL`, never `OFFERED`.** Prices only from the pricing file.
7. **Payment terms** — per market: bank transfer and invoicing cycles, purchase orders, advance vs net terms, accepted methods, VAT/e-invoicing presentation cited from the authority's own page (Egypt ETA, ZATCA, UAE FTA) with effective date — "confirm with a qualified advisor". Sourced or labelled assumption.
8. **Discount authority** — table: depth band, who may approve (role), floor price per plan (from `business/pricing/`), required give-gets (annual prepay; a case-study permission only if the customer agrees), quote expiry. No floor price → `NOT ASSESSED`; none is invented.
9. **Partners and resellers** — categories (resellers, integrators, distributors, accountants' networks), the offer, margin or referral fee (a proposal, labelled), who owns the customer, support split, enablement material, territory, exit. Names only where the user confirms a real conversation.
10. **Objection handling** — each objection carries its provenance: `OBSERVED` (the user supplied notes from real conversations, count stated), `PUBLISHED` (a dated source such as review sites or competitor pages), or `HYPOTHESIS` (to validate on the first N calls). Each has the factual answer, its source and the proof asset. Candidate topics: price, data location, Arabic/RTL support, trust in a new vendor, on-prem need, local accounting/e-invoicing integration. An answer that promises an unshipped capability is removed.
11. **Questionnaire and RFP library** — a pointer to `business/sales/questionnaire-library.md` and its rule (every answer cites the standard, ADR or test evidence; unanswerable → "not currently provided"). Building the library is a separate task; the playbook states whether it exists.
12. **Hand-off to `customer-success`** — fields recorded at close: contract terms, promised timelines, success criteria the customer stated, stakeholders by role, risks, licence or tenant provisioning request.
13. **Assumptions and gaps** — each with how to close it (first N deals, an interview count, an engineering confirmation).
14. **Next steps** — action — owner (user-supplied) — date.

## Audit checklist (MET / NOT MET / NOT ASSESSED)

`--scope` limits both sections and checks (table in SKILL.md Phase 1): a check outside the scope is `N/A — out of scope (stated)` and counts as MET.

| # | Check | NOT ASSESSED when |
|---|---|---|
| S1 | Motion table: ACV, cycle, selling cost, rule vs CAC ceiling, per edition/country | price file or CAC ceiling ABSENT (with a user-supplied price basis; with none anywhere the verdict is `INSUFFICIENT DATA — no price basis`) |
| S2 | Qualification: question + evidence + disqualify rule for every element | — |
| S3 | Pipeline: entry/exit/owner/max age/conversion labelled; forecast formula, low/base/high, ILLUSTRATIVE | — |
| S4 | Every enterprise term has a status and a source or confirmer; none `OFFERED` without a path | — (`N/A — out of scope`, stated, when neither enterprise nor self-hosted is in scope; counts as MET) |
| S5 | Payment terms sourced; VAT/e-invoicing from authority page with date and caveat | authority page unreachable |
| S6 | Discount authority table with floor price from the pricing file | floor ABSENT |
| S7 | Partner terms labelled proposals; no unconfirmed names | — |
| S8 | Objections have provenance; no unshipped promise | — |
| S9 | Proposal template complete (see 2-proposal-template.md) | — |
| S10 | Hosted and self-hosted separate throughout | — |
| S11 | No fabricated references, customers, logos, quotes, pipeline numbers | — |
| S12 | Number rows: E (defective) = 0 | — |
