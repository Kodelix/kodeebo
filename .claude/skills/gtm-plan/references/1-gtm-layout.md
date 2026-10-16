# GTM plan layout and audit — `/gtm-plan`

Read in Phase 3; give to `marketing-lead` and use as the Phase 4 audit. Output:
`business/marketing/gtm-<product>-<market>.md` — one file per market or one
sequenced file when the user wants Egypt then GCC in one plan (each market keeps
its own sections; nothing is blended).

## Sections

1. **Header** — date, author agents, product, edition (hosted / self-hosted, separate), market(s), verdict, source list, stale-after date.
2. **Recommendation** — segment first, positioning, channel focus, launch window, in one paragraph.
3. **Segment choice** — the product brief's ICP restated in one sentence, then per country: company size, buyer role, trigger event, current alternative, languages, payment preferences. Evidence missing → labelled **hypothesis** with the interview count or test that would settle it. Segment size from `business/market/` (SAM/SOM with its verdict) — if absent, `NOT ASSESSED`.
4. **Positioning** — for whom / the problem / our category / the difference / the proof. Alternatives and competitors come from dated captures (`business/competitors/`). The positioning **of record** belongs to `product-director`; this section is a proposal marked as such.
5. **Messaging (Arabic and English)** — table:

   | Audience | Primary claim (AR) | Primary claim (EN) | Proof | Evidence for the claim (measurement or source) | CTA | Register |

   Written natively, not translated word for word; Modern Standard Arabic and, where tested, Egyptian or Gulf register. Every claim has evidence in the product or a source; **no testimonial, customer logo, case study, review score or statistic that does not exist**. RTL layout, mixed-direction text and numerals/date format reviewed with `localization-lead`.
6. **Channels** — per channel: role in the funnel, audience size or search volume (source, date) or `ASSUMPTION`, cost model, first test that would validate it. Platform choices justified by sourced usage data per country; unsourced → assumption. Detailed budgets and calendars belong to `/marketing-plan`; the GTM names the channels and their sequence.
7. **Pricing and offer reference** — links to `business/pricing/` rows; the GTM restates no price (a price in two places drifts).
8. **Launch sequence** — pre-launch / launch / post-launch, per market, with dated milestones, assets needed (site pages, demo, docs, onboarding emails), owner role, go/no-go checklist coordinated with `release-manager`, and a fixed post-launch review date. Later markets start after an explicit exit criterion from the earlier one, not on a date alone.
9. **Targets** — leads, trials, paid customers, revenue per period for low / base / high, each target derived from SOM, price and conversion assumptions (formula shown). A target above the SOM base case is flagged; a flagged stretch gives `PLAN READY WITH CONDITIONS`, an unflagged one `PLAN NOT READY`. Conversion rates are `ASSUMPTION` until measured, with the number of observations after which they are replaced.
10. **Owners** — a column of **roles or names the user supplies** (founder, sales lead, content owner…). The agents `marketing-lead` and `sales-lead` author plans; they do not own real-world actions. A row with no owner is `UNASSIGNED` and counts against the verdict.
11. **Risks and dependencies** — regulatory (VAT/e-invoicing, data-residency, consent), payment-method availability, Arabic/RTL readiness, competitor reactions, support readiness (`customer-success`), each with a trigger and a response.
12. **Measurement** — funnel table (visits → signup → activation → paid) with the events from the tracking plan, the attribution method and its blind spots (dark social, WhatsApp referrals, offline); consent rules.
13. **Assumptions and gaps** — each with how to close it (an interview count, a landing-page test, a pilot).
14. **Next steps** — action — owner — date.

## Audit checklist (Phase 4: MET / NOT MET / NOT ASSESSED)

| # | Check | NOT ASSESSED when |
|---|---|---|
| G1 | ICP restated; per-country differences present or labelled hypothesis | brief ABSENT |
| G2 | Segment size from `business/market/` with its verdict cited | market note ABSENT |
| G3 | Positioning marked as proposal; competitors cited with capture dates | competitor files ABSENT |
| G4 | AR and EN messages native; each claim has evidence; no invented proof | — |
| G5 | Channel rows have audience/volume source or `ASSUMPTION`, and a first test | — |
| G6 | Launch sequence dated, with go/no-go and review date; exit criterion between markets | — |
| G7 | Targets derived by formula, low/base/high, ≤ SOM base or flagged | SOM ABSENT |
| G8 | Every row has an owner (user-supplied) | owners not yet given → UNASSIGNED, counts as NOT MET |
| G9 | Consent and privacy rules present; self-hosted telemetry off by default | — |
| G10 | Hosted and self-hosted kept separate | — |
| G11 | Number rows: E (defective) = 0 | — |
