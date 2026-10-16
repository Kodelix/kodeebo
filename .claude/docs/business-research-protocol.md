# Business Research Protocol

Business agents (`business-director`, `market-researcher`, `pricing-strategist`,
`marketing-lead`, `sales-lead`) answer business questions with **real, sourced
numbers**. A confident invented number is worse than "unknown": it gets copied
into a pricing page or a budget. This protocol is the business counterpart of
`research-protocol.md`.

**Markets in scope:** Egypt; GCC and wider MENA (Saudi Arabia, UAE, Kuwait,
Qatar, Bahrain, Oman, Jordan, Morocco…). Global data is used only as a labelled
comparison, never as a stand-in for a regional figure.

## Every number carries four things

| Field | Example |
|---|---|
| **Value + unit + currency** | EGP 1,450 / user / year, excl. VAT |
| **Source** (link) and **tier** | competitor pricing page — tier 2 |
| **Date** observed or published | 2026-10-12 |
| **Scope** | Egypt, SMB plan, annual billing |

A number missing any of the four is not stated as fact.

## Source tiers

1. **Official statistics and regulators** — CAPMAS (Egypt), Central Bank of Egypt, ITIDA/MCIT, Saudi GASTAT, SAMA, ZATCA, UAE FCSC, central banks and ministries; World Bank, IMF, ITU; official tax authority pages for VAT/e-invoicing rules.
2. **Primary market evidence** — competitors' public pricing pages and plan limits (captured with date; archive link if possible), public filings and investor reports, marketplace listings, job posts as hiring signals, app-store listings.
3. **Reputable industry research** — published reports with methodology (consultancies, industry associations, payment providers' published reports), reputable business press citing a named source.
4. **Practitioner sources** — founder posts, communities, review sites (G2, Capterra), surveys with stated sample. Corroborate before relying on them.
5. **Everything else** — leads only, never the basis of a recommendation.

Paywalled or unreachable sources are named as such; their figures are not
quoted from memory or from snippets without the full context.

## When the data does not exist

Say so, then estimate transparently:

- `NOT SOURCEABLE — <what was searched>`, followed by
- an **estimate as a range** (low / base / high), the **formula**, and every **assumption** with its own source or a clear "assumption" label.

Example: SAM = (number of target companies, source) × (share with the problem, source or assumption) × (price, source). Bottom-up sizing is preferred over top-down percentages of a global market.

## Currency, tax and price facts

- Show local currency first (EGP, SAR, AED…) and the USD equivalent with the exchange rate, its source and date. EGP figures note whether they precede or follow major rate moves.
- State whether prices include VAT, and the VAT/e-invoicing rule with its official source (Egypt ETA, ZATCA, UAE FTA).
- Payment-method availability and fees (cards, Fawry, InstaPay, mada, Apple Pay, wallets, bank transfer) come from the provider's own pages, dated.

## Competitor analysis

For each competitor: name, URL, segment, plans and prices (dated capture),
plan limits, billing options, local payment methods, Arabic/RTL support,
self-hosted/on-prem offer, data-residency claims, notable reviews (source).
Mark which items were verified on their site and which came from third parties.

## What business agents deliver

Every answer ends with:

1. **The recommendation** in one paragraph.
2. **The numbers table** (value, source, date, scope) behind it.
3. **Assumptions and gaps**, each with how to close it (a survey, a pilot, an interview count, a price test).
4. **What to do next** — concrete, owned, dated: e.g. "run a 2-week price test on the landing page at EGP X vs Y with N visitors per arm".

## Boundaries

- No legal, tax or accounting conclusions — cite the official rule and recommend a qualified advisor for anything binding.
- No personal data of real people in research notes; competitors are companies, not individuals.
- No fabricated customer quotes, testimonials or survey results — ever.
- Business outputs live in `business/` (see `directory-structure.md`); decisions that change the product go to `product-director`, and pricing decisions reach the product through `pricing-billing-designer`.
