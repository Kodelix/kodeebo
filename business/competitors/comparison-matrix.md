# Competitor comparison: POS / management software for PlayStation and gaming lounges and cafés — Egypt

Date: 2026-10-16   Built from: waqtak.md (last captured 2026-10-16), playmasr.md (2026-10-16), hsys.md (2026-10-16)
Our product: Kodeebo — not priced (no price file; the brief's hypothesis is in § Corridor)   Horizon: 90 days (studio convention) — refresh by 2027-01-14   Stale cells flagged: 0
Verdict (/competitor-analysis): **COMPLETE WITH GAPS** — every competitor has a VERIFIED-ON-SITE price capture; each file has NOT CAPTURED / NOT SOURCEABLE fields (listed under § Tally and gaps).
Spot re-check: one price page per competitor re-fetched by /competitor-analysis on 2026-10-16 — all three matched.

## Prices (normalised view; originals live in the files)
Normalised unit: EGP per venue (one branch) per year, tax status as published ("not stated" for all)   Currency shown: EGP only
FX: none — no sourced, dated USD rate (the Central Bank of Egypt rate page blocked the fetch on 2026-10-16); USD column omitted rather than filled
Normalisation rule: published annual price where one exists; otherwise monthly × 12 (computed with calc.py). Multi-year plans shown per year for reference, not used in the corridor.

| Competitor | Plan | Original price as published | Normalised (EGP / venue / year) | Capture date | Mark |
|---|---|---|---|---|---|
| Waqtak | شهري | EGP 200 / month, per shop | 2,400 (×12) | 2026-10-16 | V |
| Waqtak | ربع سنوي | EGP 500 / 3 months | 2,000 (×4) | 2026-10-16 | V |
| Waqtak | سنوي | EGP 1,500 / year | 1,500 | 2026-10-16 | V |
| Waqtak | 3 سنوات | EGP 3,000 / 3 years | 1,000 (÷3; reference only) | 2026-10-16 | V |
| PlayMasr | الاشتراك الشهري | EGP 150 / month ("instead of 400") | 1,800 (×12) | 2026-10-16 | V |
| PlayMasr | الاشتراك السنوي | EGP 1,500 / year ("original value 4,800") | 1,500 | 2026-10-16 | V |
| HSYS — PS shop | أونلاين فقط | 199 ج.م / month | 2,388 (×12) | 2026-10-16 | V |
| HSYS — PS shop | أوفلاين فقط | 299 ج.م / month | 3,588 (×12) | 2026-10-16 | V |
| HSYS — PS shop | أونلاين + أوفلاين | 399 ج.م / month | 4,788 (×12) | 2026-10-16 | V |
| HSYS — PS café | أونلاين + أوفلاين | 449 ج.م / month | 5,388 (×12) | 2026-10-16 | V |
| HSYS — cyber | أونلاين + أوفلاين | 379 ج.م / month | 4,548 (×12) | 2026-10-16 | V |
| HSYS — any | annual ("وفر 15%") | no figure published | NOT CAPTURED | 2026-10-16 | NC |
| HSYS — any | extra branch | 99 ج.م / month each | 1,188 per extra branch (×12) | 2026-10-16 | V |

## Capability and market fit
Cells: value + mark (V = VERIFIED-ON-SITE, T = THIRD-PARTY, NC = NOT CAPTURED, NS = NOT SOURCEABLE), all captured 2026-10-16. Competitor capabilities are vendor claims; no product was run.

| Field | Waqtak | PlayMasr | HSYS | Kodeebo (brief) |
|---|---|---|---|---|
| Billing options | monthly, quarterly, annual, 3-year; auto-renew (V) | monthly, annual (V) | monthly; annual "save 15%" without a figure (V / NC); no auto-renew (V) | annual or monthly (hypothesis) |
| Free tier / trial | no free tier; 14-day trial, no card (V) | 7-day trial, no card (V); "100% free" lead only (T, tier 5) | 3-hour demo + 7-day trial (V) | none; guided demo, pay to start |
| Local payment methods (own subscription) | e-wallet, wallets not named (V / NC); Google Play (V) | NC (/subscription/ unreadable) | Vodafone Cash, InstaPay, bank transfer (V) | NS — /pricing-strategy |
| Arabic / RTL | Arabic-native UI claimed, Arabic + English site (V) | Arabic site + English toggle (V); product UI NC | Arabic (V); English NC; product RTL NC | Arabic first, RTL first, English complete |
| Self-hosted offer | none (V) | none, cloud-based (V) | none; per-device offline desktop serial (V) | not offered |
| Data-residency claims | region not named (V); Cairo is the company address only | Firebase/Google Cloud named, region not stated (V) | not stated (V) | open — /research |
| Offline (claim) | local DB, up to 5 days, then a subscription check (V) | "works fully offline" (V), while /disclaimer/ says cloud-dependent; limits NS | offline-only or online + offline plans (V); limits NS | local-first always; bounded grace for subscription only (N5) |
| Owner remote view | web dashboard + Android app on Google Play (V) | PWA on any device (V) | browser; hybrid plan on mobile (V); no native app described | web dashboard + Android app (Tier 1) |
| Activity / audit log | not published (NS) | claims only (V) | audit log of sensitive operations (V) | every change, every money movement (Tier 1) |
| Attendance | not named (NS) | none (V) | from login (V) | clock in/out (Tier 1) |
| PC stations | PC lock client, Windows 10/11 (V) | "supports PCs"; mechanism NS | per-hour/minute PC billing (V); lock mechanism NC | PC as timed station (Tier 1); lock agent Tier 2 |
| Cashier OS | Windows, version NS | browser/PWA; OS NS | desktop program or browser; OS NS | Windows 10/11 (Win 7 by spike) |
| Egyptian e-invoicing (ETA) | not mentioned (NS) | not mentioned (NS) | claimed, automatic with QR (V, claim) | NOT SOURCEABLE — /research (risk 7) |
| Onboarding | self-install + remote help, no fee (V) | self-serve, "no technician needed" (V) | remote same-day setup (V); on-site NS | on-site install + training + on-site support by Kodelix or partner |
| Referral channel | none published (NS) | none published (NS) | affiliates 5–25% recurring (V) | referral partners on commission |
| Reviews | NC (stores script-rendered) / NS | NS | NS | — |

## Corridor
Comparable-plan rule (judgement call): for each competitor, the plan closest to Kodeebo's Tier 1 — the counter keeps working offline **and** the owner sees the venue remotely — for one venue, at the cheapest published commitment of one year or less.
- Waqtak سنوي (all plans include offline + Android app) ≈ Kodeebo — judgement call.
- PlayMasr السنوي (offline claim + PWA) ≈ Kodeebo — judgement call.
- HSYS PS shop أونلاين + أوفلاين (the only HSYS plan with both offline and mobile access); no annual figure, so monthly × 12 — judgement call.

| Measure (EGP / venue / year) | Value | Computed |
|---|---|---|
| Lowest | 1,500 | Waqtak and PlayMasr annual |
| Median | 1,500 | calc.py `median(1500,1500,4788)` |
| Highest | 4,788 | HSYS 399 × 12 |

n = 3 of 3 competitors in scope (1 capture each in the corridor); NC cells (HSYS annual) excluded and counted, not filled. If HSYS applies its "save 15%" to the list price, its annual figure would be about 4,070 — a derivation, not a capture, and excluded.
Sensitivity — the same plans billed monthly: 1,800 / 2,400 / 4,788 (median 2,400, calc.py).

**Kodeebo comparison (not a corridor point).** The brief's anchor is 10,000 EGP/year per venue (evidence: the 3 founding lounges pay it, all through referral). Per the founder (2026-10-16), that price covers **software + on-site installation + training + ongoing on-site support**. The competitors publish a software subscription with self-serve or remote onboarding (Waqtak remote help during the trial, no installation fee; PlayMasr "no technician needed"; HSYS remote same-day setup; none publishes on-site visits). So the corridor is a software-only price and the comparison is not like for like. Raw ratios, for orientation only: 10,000 is 2.1× the highest (4,788), 6.7× the median (1,500), 4.2× the monthly-billed median (2,400) — calc.py. The on-site service share of the 10,000 is not recorded anywhere (NOT SOURCEABLE — needs the founder's cost per visit and visit count → /pricing-strategy, /business-case).

## Reading the gaps
- **Price.** On published software prices Kodeebo's anchor sits well above all three (Corridor; ratios above). The gap is only partly explained by on-site service, which the competitors do not publish. Risk 5 in the brief (cold lounges pay ~10,000/yr) faces this directly. → /pricing-strategy.
- **Offline and remote view are table stakes, not differentiators.** All three publish an offline or hybrid mode and a remote owner view (rows "Offline", "Owner remote view"). The brief's "unlike the dominant lounge systems (… not online …)" does not hold against these three. Positioning is not changed here — sent to `product-director` for approval.
- **Where Kodeebo could stand apart (all on published claims, not tested):** the money trail — Waqtak publishes no audit log and PlayMasr only claims (row "Activity / audit log"); attendance — absent or unnamed at Waqtak and PlayMasr; on-site service and training — none publishes it (row "Onboarding"); offline that never stops the counter — Waqtak stops after 5 days for a subscription check, and PlayMasr's own disclaimer contradicts its offline claim.
- **Where Kodeebo is behind on paper:** no trial versus 7–14-day trials at all three (row "Free tier / trial"); HSYS claims ETA e-invoicing (row "ETA"), which Kodeebo has not researched (risk 7); Waqtak ships a PC-lock client today, Kodeebo's is Tier 2.
- **Unidentified competition.** It is unknown whether these three are the "dominant lounge systems" the founder's customers complained about (slow, freezing, not online). If they are not, the dominant systems remain unidentified and uncaptured — the most important gap in this matrix.
- No statement above relies on a THIRD-PARTY tier 4–5 cell.

## Tally and gaps
Fields (researcher counts, approximate — the files carry the exact lines): Waqtak 52 — V 41, T 1, NC 4, NS 6; PlayMasr 38 — V ~30, rest T/NC/NS; HSYS 40 — V ~28, rest NC/NS.

What to re-capture and how:
| Gap | Competitor | How to close |
|---|---|---|
| Who the "dominant lounge systems" are | all / unknown | ask the 3 founding customers and 5–8 non-referral owners which system they use or left; run /competitor-analysis on those names |
| VAT status of every price | all | trial account or written quote (user's action) |
| Annual price | HSYS | trial / quote; or a human read of the page toggle |
| Screen limit 2 vs unlimited; what the price is per | PlayMasr | 7-day trial (user's action) |
| Subscription payment methods | PlayMasr (NC), Waqtak (wallet names) | trial / checkout page read by a person |
| Windows version, printer and drawer hardware | all | trial install on a test PC |
| Offline limits and conflict handling | all | trial: cut the network mid-session |
| Reviews / store ratings | all | a person reading Google Play / Microsoft Store listings; Facebook groups |
| USD equivalents | all | retry CBE rate page or another tier-1 source |
| Bowling / kids-area tables, FAQ answers | HSYS | re-fetch or human read |
| On-site service share of Kodeebo's 10,000 | Kodeebo | founder's visit count and cost → /business-case |
