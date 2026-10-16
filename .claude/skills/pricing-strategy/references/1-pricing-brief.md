# What a pricing recommendation must contain — `/pricing-strategy`

Read in Phase 3; give this file's checklist to `pricing-strategist` and use it
as the Phase 4 audit. Layout follows `pricing-strategist`'s output
(`.claude/agents/pricing-strategist.md` → Output).

## Sections

1. **Recommendation** — value metric, plans, headline price per currency, one paragraph. The value metric is justified in writing (what the customer sees as value, how it tracks our variable cost, how easy it is to measure and to manipulate) with **one rejected alternative and the reason**.
2. **Packaging** — plans, add-ons, hosted vs self-hosted editions, the buyer each plan is designed for (named by buyer, not by price tier) and the **upgrade trigger** between plans. Quotas are data, with soft/hard rules; the cheapest plan is not "unlimited everything".
3. **Price table** — `| Plan | Price + currency + period | VAT incl/excl | USD eq. (rate, source, date) | Source / rationale |`, local currency first (EGP, SAR, AED), USD last. One row per plan × currency × period. Prices for a market are set for that market, not converted from a USD list; the EGP row states a **review trigger** (rate move or date) because of currency volatility.
4. **Corridor** — dated competitor captures from `business/competitors/` with plan scope and billing period: at least three; with fewer, the count found plus `NOT SOURCEABLE` for the rest, labelled a sketch (P3 NOT MET) with no median. Show where we sit and why. Captures marked `NOT CAPTURED` or `STALE` are excluded and counted.
5. **Willingness to pay** — labelled by method and tier: competitor prices, interviews actually held (count), a price test result. With none, the price is a **labelled hypothesis to test**, not a conclusion.
6. **Annual vs monthly** — discount percentage, cash-flow effect, refund rule, with churn assumptions labelled.
7. **Margin by plan** — price net of VAT and payment fees, minus hosting, support, third-party (SMS/email) and infrastructure cost per customer. Inputs are sourced (`deploy/` Compose files, `docs/architecture/perf-budgets.md`, `slos.md`, provider fee pages dated) or labelled `ASSUMPTION`. State the **margin floor** (user's, set before research). Sensitivity ±20 % on churn, conversion and FX shown for margin and revenue.
8. **Payment methods and fees** — from each provider's own dated page (cards, Fawry, InstaPay, mada, Apple Pay, wallets, bank transfer). A method we cannot support is not priced around.
9. **VAT / e-invoicing display** — rule cited from the tax authority's own page (Egypt ETA, ZATCA, UAE FTA) with effective date; "confirm with a qualified advisor"; no conclusion.
10. **One-time licence** — price; included update window (months); maintenance as % of licence per year; what happens after expiry (keeps working, no updates); transfer rule; and the **3-year revenue and margin comparison** against the subscription equivalent.
11. **Self-hosted enterprise** — pricing basis (per instance / user band / year), support tier included, SLA, POC/trial licence terms, and the support and update-channel cost the margin must cover. **Never priced like hosted**: separate cost, margin and sales cycle.
12. **Offers** — any discount/coupon follows `/offer-design`'s guardrail fields; here only the headline policy and the floor price.
13. **Price test** — see `references/3-price-test.md`.
14. **Existing customers** — grandfathering period or immediate; a change ships as a **new catalogue version**, never an in-place edit.
15. **Assumptions and gaps** — each with how to close it; **decisions for `product-director`** (value metric, plans of record).
16. **Hand-off** — see `references/2-handoff.md`.

## Audit checklist (Phase 4 counts these; each is MET / NOT MET / NOT ASSESSED)

| # | Check | NOT ASSESSED when |
|---|---|---|
| P1 | Value metric justified, one alternative rejected | — |
| P2 | Every price row has value + currency + period + VAT status, local currency first, USD with rate/source/date | — |
| P3 | MET: ≥ 3 dated captures. NOT MET (sketch): 1–2 captures plus `NOT SOURCEABLE` for the rest, flagged as a sketch with no median | `business/competitors/` ABSENT and none fetched (zero captures) |
| P4 | Willingness-to-pay method labelled; hypothesis labelled as such | — |
| P5 | Margin per plan computed from sourced or labelled inputs; floor stated | cost inputs ABSENT and the user declined labelled assumptions |
| P6 | Sensitivity ±20 % on churn, conversion, FX shown, with holds/flips stated | margin NOT ASSESSED |
| P7 | Payment fees/methods from provider pages, dated | provider pages unreachable (listed) |
| P8 | VAT/e-invoicing rule cited with date and advisor caveat | tax authority page unreachable |
| P9 | One-time licence rows complete incl. 3-year comparison | licence not in scope (state it) |
| P10 | Self-hosted rows complete, separate economics | self-hosted not in scope (state it) |
| P11 | Price test designed with computed sample size and stop rule | — |
| P12 | Migration rule and catalogue-version hand-off | — |

## Verdict mapping (Phase 4)

| Check outcome | Effect on the verdict |
|---|---|
| P3 or P5 NOT ASSESSED; P2 NOT MET after one send-back | `INSUFFICIENT DATA` (price levels cannot be set) |
| P1, P11 or P12 NOT MET after one send-back; P3 NOT MET (sketch) | `RECOMMEND WITH CONDITIONS` — the condition is closing the item |
| P4 hypothesis; P6–P10 NOT ASSESSED or NOT MET with a stated reason | `RECOMMEND WITH CONDITIONS` |
| Base-case margin below the user's floor; dominated plan or loophole | `DO NOT RECOMMEND` (outranks the rows above) |
| Every check MET, drivers tier 1–3, holds under ±20 % | `RECOMMEND` |
