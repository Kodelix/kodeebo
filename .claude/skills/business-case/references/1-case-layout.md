# Business case layout, formulas, audit — `/business-case`

Read in Phase 2; give to `business-director`; use as the Phase 5 audit. Output:
`business/cases/<product>-<slug>.md` and `business/cases/<product>-<slug>-inputs.json`.

## Formulas (written in the file, with variables and a worked base-case example)

```
ARPA                = net revenue per account per month, excl. VAT, in local currency
Variable cost       = hosting + support + third-party (SMS, email, maps...) per account per month
Gross margin / mo   = ARPA x (1 - payment_fee_pct - other_cost_pct) - Variable cost
Gross margin %      = Gross margin / mo / ARPA
CAC                 = fully loaded acquisition spend / new paying customers in the SAME period
Churn (monthly)     = share of accounts lost per month  (annual contracts: 1 - (1 - annual)^(1/12))
LTV (horizon H)     = Gross margin / mo x (1 - (1 - churn)^H) / churn          (capped at H months)
LTV:CAC             = LTV(H) / CAC
Payback months      = CAC / Gross margin / mo
Break-even customers= fixed monthly cost / Gross margin / mo
Contribution/customer over H = LTV(H) - CAC
Licence (per deal, H years) = licence price - delivery cost - CAC
                              + sum over years of [maintenance revenue - support cost] x active share
```

`model.py` implements exactly these; the file shows the worked example with the
base inputs and the script's output verbatim. LTV is capped at a horizon (the
user chooses H; if none, propose 36 months and label it a studio convention) so
a low churn assumption cannot create an unbounded LTV. Expansion revenue is not
modelled: say so, and treat it as upside.

## Inputs table (every input, every scenario)

`| Input | Low | Base | High | Unit + currency | Source (link) + tier, or ASSUMPTION | Date | Scope |`

"Low" is the **pessimistic** case for every input (lower price, higher churn, higher
CAC), "high" the optimistic. Where an input is the output of another skill it
cites the file and row (`business/pricing/...`, `business/market/...`,
`business/marketing/...`). Cost inputs come from `deploy/` Compose files,
`docs/architecture/perf-budgets.md`, `slos.md`, provider fee pages (dated) or are
labelled `ASSUMPTION`. Gross margin includes hosting, support, payment fees,
irrecoverable VAT on costs where it applies (rule from the authority page, not
from memory), and for self-hosted the support and update-channel cost.

| Input family | Where a sourced value can come from |
|---|---|
| ARPA / licence price | `business/pricing/` price table (net of VAT) |
| Hosting, support, third-party | infrastructure files and cost notes; provider price pages dated |
| Payment fees | the provider's own current page, dated |
| Churn | the user's own measured data; a published analogue with tier, date, scope and a stated difference; else a range labelled `ASSUMPTION` — "measure in pilot" |
| CAC | `/marketing-plan` channel rows, measured campaign results the user supplies, else a range from the CAC ceiling (ARPA × margin × payback) labelled `ASSUMPTION` |
| Fixed costs, new customers per month | the user's plan (headcount, budget); `ASSUMPTION` until committed |
| FX | central-bank or authority page, dated; EGP figures note before/after a major rate move |

## Decision criteria (set **before** running the model)

The user states: maximum payback months, minimum LTV:CAC, minimum gross margin %,
and the horizon. If the user asks for starting points, offer payback ≤ 12 months
and LTV:CAC ≥ 3 as **unsourced studio conventions to be replaced by the user's
own numbers**, never as findings. Without criteria the case reports numbers and
the verdict is `INSUFFICIENT DATA — no decision criteria`.

## Sections

1. Header — date, author agents, product, **edition** (hosted and self-hosted are **separate cases**, never blended), market, horizon, verdict, sources, stale-after
2. Decision and criteria
3. Recommendation (one paragraph) and the cheapest test that would prove it wrong, with the decision threshold set before the test
4. Inputs table and gross-margin build
5. Formulas and worked example (base)
6. Scenario results (script output, low / base / high) with USD equivalents (rate, source, date) and the PASS/FAIL observations against the user's criteria
7. Sensitivity: the script's top three inputs, ±20 % each, with "recommendation holds / flips" stated for each
8. One-time licence vs subscription over the same horizon (when both are in scope), each from its own run
9. Break-even: customers and month, peak cash need (if new-customer ramp was supplied)
10. Assumptions and gaps with how to close each (a pilot of N customers, N interviews, a 2-week test)
11. Next steps — action — owner (user-supplied) — date
12. Reproduction: the exact command and the inputs file path

## Audit checklist (MET / NOT MET / NOT ASSESSED)

| # | Check | NOT ASSESSED when |
|---|---|---|
| C1 | Decision criteria set by the user before the run | user declines → verdict `INSUFFICIENT DATA` |
| C2 | Every input has source+tier+date+scope or `ASSUMPTION`; E rows = 0 | — |
| C3 | Low/base/high defined as pessimistic/central/optimistic for every input | — |
| C4 | Margin build includes all cost components or states which are `NOT ASSESSED` | cost inputs ABSENT and no assumption approved |
| C5 | Model run with `model.py`; output pasted verbatim; inputs file saved | model could not run (reason) |
| C6 | Worked example reproduces the script's base numbers | — |
| C7 | Sensitivity: top three varied ±20 %, holds/flips stated | — |
| C8 | Hosted and self-hosted separate | one edition only (state it) |
| C9 | FX source and date; VAT status; EGP rate-move note | rate page unreachable |
| C10 | Cheapest disproving test and its threshold written | — |
