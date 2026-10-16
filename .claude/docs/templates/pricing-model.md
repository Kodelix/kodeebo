# Pricing Model: [Product Name]

*Created: [Date]*
*Owner: pricing-billing-designer*
*Status: [Draft / Validated / Live]*
*Source of truth for values*: [plan data store / config file — values live there, never in code; this document explains and justifies them]

---

## Overview

[What is sold, to whom, and how is it charged? Which behaviours does the model
encourage (adoption, seat growth, annual commitment)? One short paragraph.]

**Models in use**: [subscription (flat / per seat / usage) · one-time licence · licence + maintenance · self-hosted annual licence · add-ons]

---

## Plans

| Plan | Audience | Price (per period) | Billing periods | Currency | Trial | Notes |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| [Free] | [Evaluation] | [0] | — | — | — | [Limits below; abuse controls] |
| [Starter] | [Solo / small team] | [X] | [monthly / annual (−Y%)] | [EGP / USD] | [14 days, no card] | |
| [Team] | | | | | | |
| [Enterprise / Self-hosted] | | [custom / per-year licence] | [annual] | | [POC licence] | [Contract terms, DPA, SLA] |

### Plan Rules
- [Rule — e.g. "Prices are stored as integer minor units per currency; no floats"]
- [Rule — e.g. "Annual is 10x monthly"]
- [Rule — e.g. "Grandfathering: existing subscribers keep their price for N months after a change"]

---

## Entitlements (data, not code)

<!-- Entitlements are data keyed by plan; code asks `can(tenant, "feature.key")`
     and never checks plan names. Changing a plan's entitlements is a data
     change with an audit-log entry, not a deploy. -->

| Entitlement key | Type | Free | Starter | Team | Enterprise | Enforced where | Source spec |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| `feature.export` | boolean | no | yes | yes | yes | use case + UI gate | `design/specs/...` |
| `max_seats` | integer | 1 | 5 | 25 | custom | invitation use case | |
| `api_access` | boolean | no | no | yes | yes | API policy | |

**Evaluation order**: [plan defaults -> add-ons -> per-tenant overrides -> licence claims (self-hosted)]
**Cache**: [entitlement cache decision, TTL, invalidation on plan change — see `cache-design.md`]

---

## Limits & Quotas

| Quota | Unit | Period | Free | Starter | Team | Enterprise | Hard / soft | On exceed |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| [API requests] | requests | month | | | | | [soft] | [429 + `Retry-After`, banner at 80%] |
| [Storage] | GB | total | | | | | [hard] | [block uploads, keep reads] |
| [Projects] | count | total | | | | | [hard] | [422 `plan_limit_reached`] |

**Overage policy**: [block / allow and bill / grace of N% — per quota]
**Rate limits (abuse control, separate from quotas)**: [per tenant/actor/route — see `perf-budgets.md` / security baseline]

---

## Metering (usage-based components)

| Meter | Event source | Unit | Aggregation | Idempotency key | Late-event window | Visible to customer |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| [active_seats] | [membership table, daily snapshot] | seat | max per period | `tenant:date` | [48 h] | dashboard + invoice |

- **Accuracy rule**: [events are deduplicated by key; reconciliation job compares meter vs. source daily]
- **Customer disputes**: [how a customer sees usage detail and how corrections are issued as credits]

---

## Trials, Coupons & Promotions

| Item | Rule | Abuse control |
| ---- | ---- | ---- |
| Trial | [length, plan features, card required?, conversion behaviour, what happens at expiry (downgrade to Free / read-only / suspend)] | [one per email domain / payment fingerprint; disposable-email block; rate limit] |
| Coupon | [percent/fixed, duration (once / N months / forever), stackable? max redemptions, expiry, applicable plans] | [no stacking by default; redemption limits; audit] |
| Referral / credit | | |

---

## Billing Mechanics

### Proration
- **Upgrade mid-period**: [charge difference prorated by remaining days immediately / at next invoice]
- **Downgrade mid-period**: [effective at period end / credit]
- **Seat change**: [prorated add, no refund on removal until renewal]
- **Rounding**: [half-even to minor units; applied to the line, not the total]

*Formula*: `proration = (new_price - old_price) * remaining_days / period_days`

### Invoicing & Payment
- **Provider**: [name; hosted checkout / tokenised only — card data never touches our servers]
- **Invoice numbering and retention**: [format; legal retention period]
- **Payment methods**: [cards · local wallets · bank transfer for annual/enterprise]
- **Refunds & credits**: [policy; who may issue; audit trail]

### Dunning (failed payments)
| Day after failure | Action | Customer communication | Access state |
| ---- | ---- | ---- | ---- |
| 0 | Retry | In-app banner + email | Full access |
| 3 | Retry | Email | Full access |
| 7 | Retry | Email + admin notice | Limited / read-only |
| 14 | Cancel or suspend | Final notice | Suspended; data retained N days |

### Tax / VAT
- **Jurisdictions and rates**: [Egypt VAT, EU VAT/OSS, other — who is the merchant of record]
- **Tax-inclusive vs exclusive display**: [per region]
- **Tax IDs and invoices**: [collect, validate, show on invoice]
- **Provider tax tooling**: [yes/no; reconciliation owner]

---

## Licence Terms for Self-Hosted

<!-- Mechanics live in licence-model.md; commercial terms here. -->

| Term | Value |
| ---- | ---- |
| Licence types | [annual subscription · perpetual + maintenance · per-instance · per-seat] |
| Unit of licensing | [instance / node / seat / tenant count] |
| Update eligibility | [updates released before the licence expiry date remain usable] |
| Grace period after expiry | [N days of full function, then read-only] |
| Offline activation | [supported; process] |
| Renewal & reinstatement | [process; price] |
| Support & SLA | [tiers] |

---

## Price Targets & Unit Economics

| Metric | Target | Rationale |
| ---- | ---- | ---- |
| Gross margin per plan | [>= X%] | [infra + support + provider fees per tenant] |
| Free-to-paid conversion | [X%] | |
| Trial-to-paid conversion | [X%] | |
| Annual-plan share | [X%] | |
| Involuntary churn (failed payments) | [< X%] | [dunning effectiveness] |
| ARPA / expansion revenue | [X] | |

---

## Pricing Health Checks (`/pricing-check`)

| Check | Healthy | Warning | Action |
| ---- | ---- | ---- | ---- |
| Every plan reachable and differentiated (no dominated plan) | yes | a plan is never chosen | Rework tiers |
| Loophole: downgrade/upgrade cycling to avoid charges | none | found | Fix proration/trial rules |
| Quota with no enforcement point | none | found | Add enforcement + test |
| Customer exceeding quota without any notice | 0 | >0 | Add 80%/100% notices |
| Margin negative for any plan at P90 usage | none | found | Raise price or lower quota |

---

## Ethical Guardrails

- [No dark patterns: cancellation as easy as sign-up; no hidden auto-renew; clear renewal reminders]
- [Prices and limits shown before purchase; taxes shown in checkout]
- [Price changes announced with notice period; existing customers grandfathered per policy]
- [Data export available on every plan, including after cancellation for N days]

---

## Dependencies

- Depends on: [billing provider integration (`integration-spec.md`), tenancy, identity, notifications]
- Affects: [entitlement checks in every feature spec, onboarding, tracking plan (plan/trial events), licence-model]
- Must coordinate with: `product-manager`, `growth-lifecycle`, `product-analytics-engineer`, `security-lead` (billing threat model)
