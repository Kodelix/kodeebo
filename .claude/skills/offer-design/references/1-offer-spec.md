# Offer spec, abuse cases, impact, measurement — `/offer-design`

Read in Phase 2. Give in Phase 3 to `pricing-strategist` (and `marketing-lead` for launch
deals). Layout of the saved file is at the end.

## Guardrail fields (every offer, every row filled)

| Field | Content |
|---|---|
| Purpose | the one behaviour the offer is meant to change (first purchase, annual commitment, upgrade, referral, reactivation) |
| Eligibility | who qualifies and how it is checked (new account only, first paid period, segment, country, invited partners) |
| Depth | maximum discount in % **and** the resulting price in each currency, VAT status stated |
| Duration | how long the customer keeps the discount (first period only / N months / the term) and how long the offer is open |
| Stacking | with coupons, partner discounts, volume discounts, annual discount: **no stacking unless stated**; show the lowest price reachable by any stack |
| Floor price | the price below which the offer can never go, per plan and currency, from `business/pricing/` (the margin floor). Absent → the offer is `INSUFFICIENT DATA`; no floor is invented |
| Budget cap / redemption limit | maximum redemptions and the maximum total discount value, in local currency |
| Start and end date | calendar dates; end date mandatory |
| Abuse controls | one per abuse case below |
| Renewal behaviour | price at the first renewal; the notice given to the customer; no hidden auto-renew; cancellation as easy as sign-up |
| Existing customers | excluded, or offered the same terms — stated, with the grandfathering rule from the pricing file |
| Editions | hosted / self-hosted; the offer for each is separate (POC licence terms for self-hosted) |

## Abuse cases to walk (each gets a control or is declared an accepted risk by the user)

1. Trial farming: repeat sign-ups with new emails; disposable emails; one per email domain / payment fingerprint
2. Coupon leakage: code posted to coupon sites; single-use codes vs capped shared codes
3. Stacking: coupon + annual + partner + volume reaching below the floor
4. Downgrade-after-discount and plan cycling to keep a promotional price
5. Refund arbitrage: annual prepay, use, refund; the refund window and what counts as use
6. Cross-currency arbitrage: buying at the cheaper EGP/regional price from a country where the list is higher; billing-country and payment-method checks
7. Reseller/partner arbitrage: partner discount plus public coupon
8. Referral self-dealing: self-referral, referral rings, rewards paid before the referred customer pays and the refund window passes
9. Bundle unbundling: buying a bundle for one item and cancelling the rest
10. Self-hosted POC licence reuse: repeated POC licences for one organisation; expiry enforcement via the licence mechanics (`licensing-specialist`)
11. Account-sharing under per-seat discounts

An offer whose abuse case has no control and whose worst case breaches the floor
is `DO NOT RECOMMEND`.

## Expected impact (a scenario, not a forecast)

Every rate is `ASSUMPTION` unless a measured or sourced figure exists; the
formula is written out and run with `calc.py`.

```
Redemptions R         = eligible reach E x conversion c_o                     (c_o: ASSUMPTION or measured baseline)
Incremental share i   = share of R who would NOT have paid at full price       (ASSUMPTION; the rest is cannibalised)
p = full net price per period   p_d = discounted net price per period   v = variable cost per customer per period
Incremental margin M  = R x i x (p_d - v)  -  R x (1 - i) x (p - p_d)           (per period the discount applies)
Offer payback         = offer cost (media, reward, setup) / monthly (p_d - v) of incremental customers
```

Show low / base / high by varying `c_o`, `i` and the discount depth; show the
break-even `i` (the incremental share below which M is zero):
`i* = (p - p_d) / ((p_d - v) + (p - p_d))` = `(p - p_d) / (p - v)`. If the
base case is below zero margin the offer fails. "Comfortably inside" (the `RECOMMEND` bar) means `i*` ≤ 0.8 × the low-scenario `i`.

## Measurement plan (with `product-analytics-engineer`)

| Item | Content |
|---|---|
| Events | names and properties added to the tracking plan (`.claude/docs/templates/tracking-plan.md`): offer shown, code applied, redeemed, renewed at full price, refunded, churned within N days |
| Holdout | a control group with no offer, or a staggered start, so incremental share is measured, not assumed |
| Metrics | primary (incremental paid conversions or incremental gross margin), guards (refund rate, renewal at full price, support contacts, downgrade rate) |
| Sample and duration | computed with the two-proportion method in `/pricing-strategy` (price-test design); fixed before launch |
| Stop rule | pre-written: kill the offer if redemptions exceed the cap or a guard breaches its limit |
| Consent | email/analytics under the consent rules in `marketing-lead`'s brief and `privacy-compliance-specialist`'s facts; self-hosted telemetry stays off by default |
| Review | date of the read-out and who decides |

## Legal and tax

Promotional pricing, advertised discounts, auto-renewal and consumer-protection
rules differ by country. State the question, cite the authority's page if one was
found, and say "confirm with a qualified advisor". No conclusion.

## Layout of `business/pricing/offer-<slug>.md`

```
# Offer: <name>
Date - Author: pricing-strategist (via /offer-design) - Verdict - Sources
## Recommendation (one paragraph)
## Offer terms: | Field | Value (per currency, VAT status) | Source / rationale |   (all guardrail fields)
## Floor check: lowest reachable price per plan/currency vs floor
## Abuse cases: | # | Case | Control | Residual risk (accepted by user: yes/no) |
## Expected impact: formula, inputs table (Value | Source tier / ASSUMPTION | Date | Scope), low/base/high, break-even i
## Measurement plan
## Assumptions and gaps (how to close each)
## Hand-off: pricing-billing-designer (catalogue rows), marketing-lead (copy), product-analytics-engineer (events)
## Next steps (action - owner - date)
```
