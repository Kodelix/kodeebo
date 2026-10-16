# Hand-off to `pricing-billing-designer` — `business/pricing/<product>-handoff-<date>.md`

`pricing-strategist` recommends; `product-director` signs off the value metric
and plans of record; `pricing-billing-designer` implements into
`.claude/docs/templates/pricing-model.md` (its own artifact) as a **new catalogue
version**. This file is **data in the order of that template**, with no price
appearing in any spec or in code (`.claude/rules/specs.md` — specs link to the
model, they do not restate prices). It never edits the pricing model, specs or
code; it is the input those owners read.

## Header

```
Product: <name>   Date: <YYYY-MM-DD>   Author: pricing-strategist (via /pricing-strategy)
Status: PROPOSED - not signed off. Sign-off: product-director <pending | date + decision, filled by the user>
Catalogue version proposed: <vN+1>   Supersedes: <vN | none>
Verdict: <RECOMMEND | RECOMMEND WITH CONDITIONS | DO NOT RECOMMEND | INSUFFICIENT DATA>
Source analysis: business/pricing/<product>-<topic>.md
```

## Data, in pricing-model.md order

| Section of `pricing-model.md` | What this hand-off lists |
|---|---|
| Plans | plan key, audience, price per currency per interval in **integer minor units** (EGP piastres, SAR halalas, AED fils, USD cents — money in minor units, server-side catalogue, `.claude/rules/integrations.md`), interval, annual discount %, trial terms |
| Entitlements | key, type, value per plan (data, not code) — only keys that exist in specs; a proposed key not in a spec is listed as "new key - needs a spec" |
| Limits & quotas | quota, unit, period, value per plan, hard/soft, on-exceed behaviour |
| Metering | usage meters if the value metric is usage-based |
| Trials, coupons & promotions | the headline policy and floor price; detailed rules come from `/offer-design` |
| Billing mechanics | tax display (incl./excl. VAT per market), payment methods **from provider pages** with fees and their dates |
| Licence terms for self-hosted | licence type, unit, update window months, maintenance %, grace after expiry, offline activation, renewal/reinstatement price, support and SLA tier |
| Price targets & unit economics | margin target per plan, conversion/churn **assumptions labelled**, annual-plan share assumption |
| Grandfathering | rule for existing customers and notice period |
| Review triggers | FX move / date at which EGP prices are reviewed |

## After this file

1. The user takes the decisions list to `product-director` (an approval request, not a gate).
2. `pricing-billing-designer` writes the new catalogue version and updates the pricing model.
3. `/pricing-check` runs on the result (loopholes, dominated plans, margin vs infrastructure cost, enforcement).
4. Anything unresolved here stays in the file's "Open questions" list; nothing is "TBD" inside a data row — an unknown is `NOT SOURCEABLE` or `ASSUMPTION`.
