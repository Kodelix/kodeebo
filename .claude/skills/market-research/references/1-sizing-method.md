# Bottom-up sizing method — `/market-research`

Read in Phase 3. Re-read if the conversation was compacted.

## The unit of count comes first

Before any count, write the definition the source uses, in words:
registered companies vs active vs employing at least N staff vs tax-registered vs
a trade-licence holder. Registries and surveys define SMEs differently by
country; two countries' counts are comparable only after the definitions are put
side by side. Quote the source's definition in your own words and link the page.
A count whose definition cannot be read is tier 4 at best.

## Formula (written out, per country, per edition)

```
Target organisations      N   = count of units in the segment        (source, definition)
Share with the problem    p   = share that has the pain/need         (source, or ASSUMPTION)
Share reachable           r   = share reachable with our channel     (source, or ASSUMPTION)
Annual price              P   = price per unit per year, local ccy   (our price file or competitor capture)

TAM = N × p × P                    everyone who could buy
SAM = N × p × r × P                the part our product, language and channel can serve
SOM = SAM × s                      s = share we can win in the horizon (ASSUMPTION unless a measured analogue exists)
```

Each of `N, p, r, P, s` is a table row with the four protocol fields. Compute
low / base / high by varying **the inputs** (low N and p, high P and so on), not
by multiplying the result. Run the arithmetic with `Bash` (`calc.py`) and
print the working; do not do multi-factor arithmetic in prose.

Hosted and self-hosted are sized separately (different price, different buyer,
different reach). Never one blended row.

## Countries are separate

Egypt, Saudi Arabia, UAE, and any other country each get their own table and
their own verdict. They are **not summed** unless the user asks; if asked, show
the per-country rows first, then a sum labelled `ILLUSTRATIVE SUM`, and state the
overlap (firms operating in several countries) and the definition mismatch.
MENA-wide or GCC-wide figures are never used in place of a country figure; if
only a regional figure exists the country row is `NOT SOURCEABLE` and the
regional figure sits in a separate "comparison" row marked as such.

## Top-down is a cross-check only

A "market will reach USD X billion" statement from a vendor blog or research
teaser is tier 5. It may appear in a "Cross-check (labelled comparison)" row with
its tier, never as TAM, and never to rescue a gap in the bottom-up. When the
bottom-up and the top-down differ by more than a factor of two, say so and give
the likeliest reason (definition, currency, scope).

## Buyer behaviour (what to find, per country)

| Item | Where the fact comes from |
|---|---|
| Segment structure, headcount bands, sector counts | tier 1: national statistics office / ministry / regulator pages |
| Internet, smartphone, e-commerce, digital-payment penetration | tier 1: ITU, World Bank, central bank, telecom regulator |
| Buying roles, procurement path, trigger events | tier 2–3: public tenders, association reports, published surveys with sample; interviews only if they took place (count and role mix) |
| Where buyers search and which platforms they use | tier 2–3: platform's own published audience data, regulator or industry reports; otherwise `NOT SOURCEABLE` |
| Payment methods in use and their fees | the provider's own current page, dated |
| VAT and e-invoicing rules | the tax authority's own page (Egypt ETA, ZATCA, UAE FTA) with effective date — "not legal advice, confirm with a qualified advisor" |
| Data-residency and personal-data law | the authority's or legislature's own text; routed to `privacy-compliance-specialist` for interpretation |
| Willingness to pay | competitor captures (`/competitor-analysis`), published surveys, price tests actually run — else a labelled hypothesis |

## When the data does not exist

Write `NOT SOURCEABLE — searched: <terms>, <sites/registries tried>, <date>`,
then the range estimate with formula and every assumption labelled. Then name the
**cheapest primary research** that would close it: for example "N structured
interviews with <role> at <segment> in <country>", "a 2-week landing-page test
with N visitors per arm", "ask three distributors for their customer counts".
Counts of interviews or tests are proposals, not results.

## Verdict inputs (what `INSUFFICIENT DATA` means here)

A country is `INSUFFICIENT DATA` when **N** (the count) has no sourced figure and
no defensible range, or when its unit definition cannot be established. It is
`SIZED WITH ASSUMPTIONS` when N is sourced but `p`, `r`, `P` or `s` are
assumptions or ranges. It is `SIZED` only when N, p, r and P are all tier 1–3
rows (`s` stays an assumption by nature; the SOM is always presented as a
scenario, and says so).
