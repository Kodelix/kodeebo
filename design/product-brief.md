# Product Brief: Kodeebo — by Kodelix

<!--
Written by /brainstorm on 2026-10-16 at workflow: standard, docs.density: balanced,
review: lean (PD-PRODUCT-PRINCIPLES, DD-CONCEPT-VISUAL, CTO-FEASIBILITY, PR-SCOPE
skipped — none of them is an approval). Labels: **evidence** = the founder observed or
customers said/paid it; **assumption** = belief not yet tested; **NOT SOURCEABLE** =
not checked yet, carried into Risks. Competitor facts: § Market & competitors,
from /competitor-analysis captures dated 2026-10-16 (business/competitors/).
-->

**One-sentence pitch:** Kodeebo helps owners of PlayStation lounges and cafés in Egypt stop money leaking from the drawer and unbilled station time, with a counter app that never waits for the internet and an owner view that works from anywhere.

## Problem
- Lounges run the floor on paper, Excel or one of a few dominant systems that owners call "slow, freezing, not online, very basic, no flexibility" (**evidence**: founder's conversations).
- Money leaks: cash leaves the drawer recorded only on paper or not at all; station time goes unbilled; staff attendance is not tracked; there is no detailed daily report (**evidence** of the leak; amounts **assumption** — unknown).
- The owner can only trust the money by standing at the counter.

## ICP — ideal customer profile
- **Primary:** owner-operator of a PlayStation or cyber gaming lounge in Egypt, ~5–20 stations (**assumption**), with a café counter; one branch, sometimes 2+; hires cashiers and is not at the counter every shift. The buyer is the owner (sometimes a team lead at a multi-branch operator); the daily user is the cashier.
- **Trigger events:** cash found missing; the current system freezes or loses a running session; opening a new branch.
- **Also in scope:** standalone cafés — takeaway and a simple table tab (**assumption**, no customer evidence yet); PC gaming — PCs as a timed station type.
- **Not for:** restaurants needing floor plans, kitchen display or delivery (Later module); retail (Later module); PC centres that need automatic PC lock — supported in Tier 2; venues unwilling to pay for software.

## Jobs-to-be-done
1. **(core)** When the floor is busy, I want every station minute and every café item to land on the right bill by itself, so I collect every pound without arguing with customers.
2. When the internet drops or crawls, I want the counter to keep working at full speed, so no session or sale is lost.
3. When I am not at the venue, I want to see every action, every cash paid-out and who was on shift, so I can stop leakage and trust my staff.
4. When the business day ends, I want a detailed report that reconciles the drawer, so I know what I earned and what is missing.
5. When a customer wants a drink to go or sits at a café table, I want to ring it up in seconds or keep a simple tab, so the counter never queues.

## Positioning
*Revised 2026-10-16 (product-director recommendation, Option A, founder-approved) after the competitor captures showed the "not online" contrast no longer holds.*
- For owners of gaming lounges and cafés in Egypt who lose money they cannot see, Kodeebo is a lounge and café POS with an owner control room that **stops money leaking** — every pound, every station minute and every shift leaves a record the owner sees from anywhere.
- Unlike paper and Excel (free, but no trail) and lounge apps you install and learn on your own, Kodeebo is installed at the venue, the cashiers are trained on site, and support comes to the counter; the counter works from its own data and keeps selling with or without internet — **the trail is the headline; on-site service and the local-first counter are the proof.** Exception, stated wherever offline is claimed: after [N] days offline the cashier app must connect once for the subscription check (N5; N set by `/license-design`, no number in copy until then). "Never stops" is not used.
- Proof in a 3-minute demo: network cable pulled → start a session → void a drink with a reason → the owner's phone shows the void, the cashier, the reason and the open shift.
- Customer copy names no competitor: competitor capabilities are untested vendor claims (`business/competitors/`, captured 2026-10-16) and the "dominant systems" customers named are still unidentified.
- One-liner — EN: "Kodeebo stops money leaking from your lounge: every pound, every minute of play and every shift is on record, and you see it from your phone. We install it at your place, train your cashiers on site, and the counter keeps working even when the internet is down."
- One-liner — AR (Egyptian; draft, needs a native copywriter's review): «كوديبو بيوقف الفلوس اللي بتضيع من محلك: كل جنيه وكل دقيقة لعب وكل شيفت متسجّلين، وانت شايفهم من موبايلك. بنركّبه لك في المحل، ونعلّم الكاشير عندك، والكاشير شغّال حتى لو النت فاصل.»
- Switching cost to beat: retraining cashiers, leaving history behind, fear of downtime during the switch — answered by on-site install and training; history is moved by hand by the founder.
- **Open before any of this is published:** N5 grace length (`/license-design`; should be clearly longer than Waqtak's published 5 days); what "ongoing on-site support" includes (visits per year, response time, cities, cost per visit); whether referral partners can install, train and support; the dominant-systems gap; trial accounts on HSYS and Waqtak to check audit-log scope and offline limits; PDPL check of the "who was on shift" claim (`privacy-compliance-specialist`); native review of the Arabic line; on-site cost data for `/pricing-strategy` and `/business-case`.

## Pricing model
- **Model:** subscription, annual or monthly.
- **Plans / price points (hypothesis):** anchor 10,000 EGP/year per venue (**evidence**: each of the 3 current customers pays this today, via referral). Value metric (per branch / per station / tiers), monthly price and plan names → `/pricing-strategy`.
- **Trial / free tier:** none self-serve. A guided demo and installation by Kodelix or a referral partner; the customer pays to start.
- **Billing:** EGP. Provider, invoicing and VAT handling → `/pricing-strategy` + `/research` (**NOT SOURCEABLE** yet).
- **Subscription control (N5):** each tenant is active or suspended; the cashier app has a bounded, known offline grace period, after which it must reach the server to keep selling. Design → `/license-design` + `/research`.

## Distribution
- **Delivery:** hosted multi-tenant (Kodelix runs the server and owner dashboard). The cashier app is installed on the venue's Windows PC.
- **Channels:** Windows cashier app (installed during onboarding) · owner web dashboard · owner Android app (Google Play; iOS later) · direct sales via demo · marketing site later.
- **Acquisition:** the 3 existing lounges move from Glitch first; then referral partners (friends and contacts paid a commission per sale). Wide marketing only after Kodeebo is built.

## Stack (profile)
Not set — `/setup-stack`, after the desktop-client `/research` and the Windows 10/11 spike. Delivery is hosted multi-tenant; three client surfaces in Tier 1 (Windows cashier app, owner web dashboard, owner Android app), build approach of each by `/research` + ADR.

## MVP — scope tiers

**Scope rule (founder, 2026-10-16):** Glitch's gaming and café feature set is the **baseline**. All of it is in Kodeebo's scope, rebuilt from scratch with a clean design — never copied. An item leaves scope only when the founder drops it explicitly. Tiers are **ordering only — nothing is cut.** Item IDs refer to `design/glitch-idea-pool.md`. The Tier 1/Tier 2 line is **provisional** until the founder's aggregate operation-count test on the Glitch server (counts per feature type, no customer data) runs before `/map-domains`; anything with real daily use moves to Tier 1.

**Tier 1 — what the 3 customers need to switch from Glitch.** 🔒 = security-sensitive (threat model required).
1. **Stations and sessions** — station categories → types → units, incl. PlayStation and **PCs as a timed station type** (G1); hourly price per type with named price tiers (G2); **change the price tier during a running session, billed per period** (N4); minimum billable minutes (G5); prices frozen at session start (G12); start/end (S1); move to another station (S3); cancel by permission 🔒 (S4); one open session per station (S5); timer and planned-end alert (S6); live floor view (S12).
2. **Selling and tabs** — quick takeaway sale (O1); open tab (O2); café items on the session tab (S10); simple café table tab (N3); **open item** — free name and price, by permission, logged with a reason, owner-set maximum price 🔒 (N1); manual discount/surcharge by permission with a reason 🔒 (G10); void with reason 🔒 (O6); daily order numbers per branch (O7).
3. **Payments and receipts** — several methods on one bill, the method **recorded only** (O3); tax inclusive/exclusive, service charge, minimum charge, rounding (G11 — Egyptian VAT and e-receipt rules via `/research`); receipt printer and cash drawer (D1); **tips (gratuity)** — the owner enables them per branch, a tip is recorded per bill and per payment method, is never counted as sales revenue, and is shown in the shift close and the Z report (new, founder 2026-10-20).
4. **Shifts, cash and the ledger** — shift open/close with cash count (W1); paid-outs from the drawer against reasons 🔒 (W2); X and Z reports (W3); business day past midnight and end-of-day close (W4); one ledger of every money movement 🔒 (O8).
5. **Staff** — employees, roles (owner, manager, cashier), permissions, branch assignment 🔒 (W5); passcode sign-in on the device 🔒 (W8); clock in/out (W6 — staff attendance is personal data under PDPL).
6. **Stock** — café product catalogue; stock per branch deducted by sales, adjustments, transfers between branches (I1).
7. **Activity log and platform** — one audit record for every change 🔒 (P6); customer-defined reason lists (P5); store → branch → device, one cashier device per branch in the MVP (P3); Arabic first, English complete, RTL first, Egyptian Arabic copy (P4); **the minimum of P1: which modules and limits a tenant has, so a vertical is enabled per tenant by entitlement from the start** (plan tiers and per-tenant overrides, P2, stay Tier 2); **owner alerts by email and in the dashboard** (the in-app part of D3, moved from Tier 2: the sync and salvage decisions already require an owner alert).
8. **Local-first operation** 🔒 — the cashier app always works from its own encrypted local data and business logic; online it sends its changes to the server; offline it keeps working and queues changes (encrypted) until the connection returns; server changes (prices, settings, dashboard edits) are pushed down (F1 changed to local-first); applied on the server in device order, never twice (F2); a day closed offline whose server totals differ is flagged for review (F3); clear offline/syncing/failed/conflict states (F4).
9. **Owner web dashboard** (N2) — reports, activity log, live floor, configuration.
10. **Owner Android app** (D6, changed: Android only, iOS later) — same capabilities as the owner web dashboard (N2). Every current customer asked for it; it carries the positioning.
11. **Subscription control** 🔒 (N5) — tenant active/suspended; bounded offline grace period.

**Tier 2 — the rest of the baseline.**
- Pricing: fixed one-time session price (G4); first N minutes free (G6); special price for one unit (G7); automatic time-of-day/day-of-week discounts and surcharges (G9).
- Sessions: backdated start with an approver 🔒 (S7); extras with charging modes and lost/damaged tracking (S9); station power/network control (S11); **automatic PC lock/unlock when time ends** — a client agent on every PC that resists customer bypass 🔒, own `/research` + `/threat-model`.
- Selling: move, split and merge orders or lines (O4); partial refund against a payment 🔒 (O5).
- Customers: customer records and walk-ins 🔒 PII (C1); loyalty points with expiry (C3); customer price groups (C4).
- Staff: work contracts, attendance summaries, payroll 🔒 (W7).
- Stock: low-stock alerts (I2); recipes (I3); suppliers, purchase invoices, receiving, supplier payments (I4); expenses against approved reasons (I5).
- Devices and other: kitchen and bar printers, displays per workstation (D1); coupons and promotions (D2); push notifications (the rest of D3; owner alerts by email and in the dashboard are Tier 1); webhooks 🔒 (D4); support tickets and complaints (D5).
- Platform: plan tiers switching capabilities with per-tenant overrides (P2); the full plan model for verticals enabled per tenant by plan (P1 — its minimum, modules and limits per tenant, is Tier 1).

## Out of scope — not building this
- **Later:** per-player pricing and player join/leave (G3, G8, S8 — pricing is by tier; single → multi is N4); prepaid hours / customer wallet (C2); restaurant module (V1); retail module (V2); customer app (D7 — Glitch never built it); owner iOS app; **card-terminal and e-wallet API integration** (not in Glitch: its hardware covered printers, displays and cash drawers only, and its "wallet" was an internal customer balance — O3 records the method only); device-to-device sync over the local network; multiple cashier devices per branch (the MVP must not block it); a CSV/Excel **onboarding import** of catalogue, staff and customers for new venues coming from another system or a spreadsheet (`data-import`; it handles personal data and an untrusted file upload; not Tier 1); **Android cashier mode** (selling from an Android device — no customer asked for it; decided 2026-10-16).
- **Not offered:** self-hosted delivery (hosted multi-tenant only).
- **Not built:** a Glitch → Kodeebo data import — the founder moves the 3 customers' data by hand. (The generic onboarding import above is a separate, Later item; this rule is unchanged.)
- **Dropped:** pause and resume (S2); pricing preview simulator (G13).
- **Never:** Glitch's design, data model, business rules or code carried over.

## Success metric — what "working" looks like
*Confirmed by the founder on 2026-10-16. Dates are relative to the Tier 1 release until a target date is set.*
- **Activation:** all 3 founding lounges run Kodeebo as their only system for 14 consecutive business days, within 30 days of the Tier 1 release.
- **Revenue / retention:** 10 paying venues at ≥ 10,000 EGP/year within 6 months of the Tier 1 release, and all 3 founding lounges renew.

## Build order
1. **Spikes first:** desktop client technology (`/research` + spike on real Windows 10/11 machines) and local-first sync with fault injection (`/research` + `/prototype`) — risks 1 and 2.
2. Tenancy, identity, roles and passcodes, subscription control (N5).
3. **Vertical slice:** start a session → add a café item → close and pay → sync → see it on the owner dashboard.
4. Stations, sessions and pricing core (incl. N4, G12).
5. Selling, payments, receipts, the ledger.
6. Shifts, paid-outs, X/Z reports, business day.
7. Stock.
8. Owner web dashboard, then the owner Android app.
9. Tier 1 private beta with the 3 lounges → Tier 1 release → Tier 2.

## Decision log
| Date | Decision | Why | Rejected alternatives |
|------|----------|-----|----------------------|
| 2026-10-14 | Clean-room rebuild: never read or reuse Glitch's code; Glitch informs only as an idea pool | Founder instruction | Port or adapt Glitch |
| 2026-10-14 | Desktop client technology decided only after its own `/research` + a spike on real Windows 10/11 and Windows 7 x64 VMs, before `/setup-stack` | Windows 7 support is uncertain; the leads in the idea pool are unverified | Pick in `/setup-stack` or here |
| 2026-10-16 | Concept: lounge-first POS (stations + café on one bill) with owner control features **in** the MVP; Kodeebo as one platform with future venue modules as the long-term vision | Customers praise control (activity log, reports); the losses are leakage | Owner's-Eye-only product; platform-first MVP |
| 2026-10-16 | Module room in the architecture decided by ADR in `/create-architecture` | An architecture decision, not a product one | Decide here |
| 2026-10-16 | Scope rule: Glitch's gaming + café feature set is the baseline; Tier 1/Tier 2 are ordering only | The 3 customers move from Glitch and must lose nothing | Lean MVP from praised features only |
| 2026-10-16 | Local-first, not offline fallback: the cashier app always runs on local encrypted data and logic; sync mechanics by `/research` + ADR | Speed regardless of the internet; principle 2 | Online-first with an offline fallback |
| 2026-10-16 | One cashier device per branch in the MVP; devices never talk on the LAN; the MVP must not block multi-device | Every current customer has one device per branch | LAN peer sync; multi-device in the MVP |
| 2026-10-16 | Delivery: hosted multi-tenant only | Founder choice | Self-hosted; hybrid |
| 2026-10-16 | Pricing: annual/monthly subscription, anchor 10,000 EGP/year; guided demo, no self-serve trial | Current customers pay this; sales run through referral partners | One-time licence; free trial; paid pilot |
| 2026-10-16 | Owner Android app in Tier 1 (iOS later), same capabilities as the web dashboard; build approach by `/research` + ADR | Every customer asked for it; carries the positioning | Web-only owner view; iOS at launch |
| 2026-10-16 | Principle 2's one named exception: subscription control may require the server after a long, known offline grace period | Revenue protection without breaking the counter's daily speed | No grace (always online); unlimited offline |
| 2026-10-16 | PC gaming: PC as a timed station type in Tier 1; automatic PC lock agent in Tier 2 | Same model as G1; the lock agent is a separate security-heavy component | Exclude PC centres |
| 2026-10-16 | Data migration from Glitch done by hand by the founder | Only 3 customers | Build an import tool |
| 2026-10-16 | No card-terminal / e-wallet integration (Later); payment method recorded only | Not in the Glitch baseline | Integrate in Tier 1 |
| 2026-10-16 | Positioning leads with money leakage; speed and local-first are the proof | It is the loss owners name | Lead with speed or offline |
| 2026-10-16 | Positioning revised (product-director recommendation, founder-approved, Option A): lead stays money leakage — the money trail (P6, O8, W2, reasons/permissions; attendance shown as "who was on shift"); proof = on-site install + training + support and a local-first counter that keeps selling offline, with the N5 subscription check stated wherever offline is claimed; "never stops" not used; no competitor named in customer copy. Reversal: revisit if < 3 of 5–8 non-referral owners (risk 5) value on-site service enough to pay above a software-only price, or the on-site cost per venue makes the package unprofitable at the `/pricing-strategy` price, or the identified "dominant systems" publish on-site service; review by 2027-01-14 (competitor refresh) | 2026-10-16 captures: all three named competitors publish offline/hybrid and a remote owner view, so "not online" no longer holds; none publishes on-site service; Waqtak publishes no audit log, PlayMasr only claims one (HSYS publishes one, and attendance) — vendor claims, untested | Option B: product-only contrast (trail depth + offline limit), service kept out of positioning — thin against HSYS, does not explain the price; lead with local-first / "never stops" — false under N5 and table stakes; lead with on-site service — a delivery method, not the loss owners name; keep "not online"; name competitors in copy |
| 2026-10-16 | Android cashier mode is Later. Tier 1 client surfaces stay three: Windows cashier app, owner web dashboard, owner Android app (full dashboard + control from home, no selling). One cashier device per branch in Tier 1, unchanged | No customer asked for it; it would lengthen Tier 1 and pull multi-device (a second selling device per branch, risk 9) into it | Android cashier mode in Tier 1; owner Android app doubling as a cashier |
| 2026-10-16 | Supported cashier OS in Tier 1: **Windows 10 and 11, 64-bit; Windows 7 is not supported.** The one venue (of 3) on Windows 7 has its PC or Windows upgraded by Kodelix during the on-site install. Windows 10 PCs move to Windows 11 at install when the hardware meets Microsoft's requirements; otherwise they are enrolled in consumer ESU. Windows 11 is never forced. Reversal: revisit Windows 10 support before consumer ESU ends on **2027-10-12**; revisit Windows 7 only if a paying customer needs it | Every current runtime on the spike shortlist still supports Windows 10, so the app keeps getting security patches there. On Windows 7 the only routes are engines without security fixes (Electron 22, Chromium 109, Tauri ≤ 2.11), and SHA-2 and TLS 1.2 need manual patches (`docs/research/desktop-client-technology.md` M7) | Windows 7 as a best-effort legacy build; forcing Windows 11 at install (many venue PCs lack a TPM 2.0); dropping Windows 10 now |
| 2026-10-20 | `/map-domains` founder decisions: tips are Tier 1; the minimum of P1 (modules and limits per tenant) and owner alerts by email and in the dashboard (in-app D3) move from Tier 2 into Tier 1; a generic CSV/Excel onboarding import for new venues is Later, and the "no Glitch import" rule is unchanged. Coupons and promotions (D2) stay Tier 2 and now have a spec key. The full map is `design/specs/domain-map.md` | Layer 3 means a vertical needs an entitlement to be enabled; the sync and salvage decisions need an owner alert; tips are a money fact that must reach the shift close and Z report | Tips in Beta with a reserved ledger design; all of P1 in Tier 2 |

---
**Who it's for / what they feel:** lounge and café owners who want to stop wondering where tonight's money went — in control from anywhere, without standing at the counter.

**Brand & tone:** Kodeebo, endorsed "by Kodelix"; mascot Kiko the wolf. Branded-house architecture — one master brand, each vertical differs by design theme. Egyptian Arabic first. Visual quality matters: current customers praise the look of what they use today.

**Reference product:** the founder's previous system (Glitch) — as a capability baseline only, never as a design or code source.

**Compliance / data:** Egypt PDPL (Law 151/2020) — staff data (attendance, passcodes) in Tier 1, customer PII in Tier 2. Egyptian VAT and e-receipt obligations — **NOT SOURCEABLE** yet, `/research`. Hosted data residency — open, `/research`. No card data handled.

---

## Market & competitors
- **Market size:** NOT SOURCEABLE yet — `/market-research`.
- **Alternatives:** paper and Excel; a few dominant lounge systems (names unknown to the founder; complaints: slow, freezing, not online, very basic, no flexibility — **evidence**: founder's conversations); Glitch (the founder's previous system, used by the 3 founding customers).
- **Dominant systems still unidentified (gap):** it is unknown whether the three competitors below are the systems customers complained about. If not, the dominant systems are neither named nor captured. Close it: ask the 3 founding customers and the non-referral owners in risk 5 which system they use or left, then `/competitor-analysis` on those names.
- **Competitors captured 2026-10-16** (`/competitor-analysis`, Egypt, verdict COMPLETE WITH GAPS, horizon 90 days → refresh by 2027-01-14). Files: `business/competitors/waqtak.md`, `playmasr.md`, `hsys.md`; matrix `business/competitors/comparison-matrix.md`. Prices in EGP as published, VAT status not stated by any; capabilities are vendor claims (VERIFIED-ON-SITE = read on their site, not tested).

  | | Waqtak (waqtak.app) | PlayMasr (playmasr.com) | HSYS (hsys.io) |
  |---|---|---|---|
  | Price | 200/month · 500/quarter · 1,500/year · 3,000/3 years, per shop, unlimited devices | 150/month · 1,500/year (2 screens vs "unlimited" — page contradicts itself) | PS shop per month: 199 online · 299 offline · 399 online+offline; +99/month per extra branch; annual "save 15%", no figure |
  | Trial | 14 days, no card | 7 days, no card | 3-hour demo + 7-day trial |
  | Offline | local DB, up to 5 days, then one connection to check the subscription | "works fully offline", while its own disclaimer says cloud-dependent | offline-only or online+offline plan |
  | Owner remote view | web dashboard + Android app (Google Play) | PWA on any device | browser; mobile on the hybrid plan; no native app |
  | Activity log / attendance | not published / not named | claims only / none | audit log of sensitive actions / from login |
  | Cashier OS | Windows (version not stated); PC-lock client on Windows 10/11 | browser/PWA, OS not stated | desktop program or browser, OS not stated |
  | ETA e-invoicing | not mentioned | not mentioned | claimed (automatic, QR on receipt) |
  | Onboarding | self-install, remote help, no fee | self-serve, "no technician needed" | remote same-day setup; affiliates paid 5–25% recurring |

- **Price corridor** (one venue, plan with offline + remote owner view, cheapest commitment ≤ 1 year; n = 3): **EGP 1,500 – 4,788 per year, median 1,500**; billed monthly 1,800 – 4,788, median 2,400. **Kodeebo's 10,000 EGP/year is not like for like:** it covers software + on-site installation + training + ongoing on-site support (**evidence**: founder, 2026-10-16), while all three publish a software subscription with self-serve or remote onboarding. Raw ratio 2.1× the highest, 6.7× the median; the on-site share of the 10,000 is not recorded (NOT SOURCEABLE → `/pricing-strategy`, `/business-case`).
- **What the captures mean** (evidence for decisions, not decisions):
  1. **Price pressure on risk 5** — published software prices are far below the anchor; the on-site service is the only published difference. → `/pricing-strategy`.
  2. **Offline and a remote owner view are table stakes** — all three publish both. The positioning line "unlike the dominant lounge systems (… not online …)" does not hold against these three. **Resolved 2026-10-16:** positioning revised (§ Positioning, Option A — trail leads; on-site service and the local-first counter are the proof).
  3. **Where Kodeebo can stand apart** (on their published claims): the money trail (Waqtak publishes no audit log, PlayMasr only claims), attendance, on-site install/training/support (none publishes it), and a counter that never stops (Waqtak stops after 5 offline days for a subscription check — the same pattern as N5, now with a published comparison point).
  4. **Where Kodeebo is behind on paper:** no trial versus 7–14-day trials; HSYS claims ETA e-invoicing (raises risk 7); Waqtak ships a PC-lock client today (Kodeebo: Tier 2).
  5. **Channel:** HSYS also grows through paid referrers (5–25% recurring).
- **Gaps:** no reviews or store ratings found for any; VAT status, Windows versions, printer/drawer hardware and hosting region unpublished by all; HSYS annual price, PlayMasr subscription page and screen limit not captured; no USD conversion (CBE rate page blocked). Most close with a 7–14-day trial account per vendor — the founder's action. Full list: matrix § Tally and gaps.

## Personas
- **Owner (buyer):** runs one or more lounges or a café; not always on site; Android phone; Egyptian Arabic. Wants: trust in the money, staff accountability, a daily report. Uses: owner Android app, owner web dashboard.
- **Cashier (daily user):** works long shifts, often past midnight, on the venue's Windows PC; Egyptian Arabic; often new to the job. Wants: speed, no freezes, no disputes with customers. Uses: the cashier app.
- **Manager:** runs a shift or branch for the owner; approves exceptions within the owner's permissions.
- **Referral partner:** sells and introduces Kodeebo for a commission; needs a demo they can give.
- **Kodelix support:** onboards, installs, supports; manages subscriptions.

## Pricing hypotheses & unit economics
- **Willingness to pay (evidence):** 3 lounges × 10,000 EGP/year, all reached through referral.
- **Unknown:** what cold buyers and café-only buyers pay; the value metric; monthly price.
- **Cost per tenant (infra + support):** NOT SOURCEABLE yet — `/business-case` after `/setup-stack`.
- **Channel cost:** referral commission per sale (rate not recorded here).
- Detail → `/pricing-strategy`, then `design/` pricing model by `pricing-billing-designer`.

## Risks & assumptions
Ranked by impact if wrong × uncertainty. Top three have their cheapest test in the build order.

| # | Assumption | Type | Impact if wrong | Evidence today | Cheapest test | Pass signal |
|---|---|---|---|---|---|---|
| 1 | Local-first sync never loses or double-counts money or time | feasibility | Critical — breaks principle 1 and the pitch | Glitch ran offline at 3 sites (different design; not proof) | `docs/research/local-first-sync.md` (Draft, 2026-10-16) + one `/prototype` sync spike with fault injection (network cut mid-close, resend, duplicate replay, crash and restore cases): the 1-day prototype cap is waived in writing by the founder (2026-10-16) for this risk; phases 0–5, each with a pass/fail gate, stopping at the first failed gate; PowerSync spikes run in parallel for the adopt-vs-build ADR | Zero lost or duplicated money/time events: 3,000 clean randomized runs at each of the phase 2 and phase 3 gates (per-run defect rate below 0.1% at 95% confidence; 30,000 as a stretch campaign) |
| 2 | A desktop technology runs well, prints and opens the drawer on Windows 10/11 (Windows 7 not supported in Tier 1 — decision 2026-10-16) | feasibility | High — blocks `/setup-stack` | `docs/research/desktop-client-technology.md` (Draft, 2026-10-16): Windows 7 leads checked against vendor sources; nothing yet run on Windows | Spike on the 4 GB Windows 10/11 reference PC (slowest CPU, HDD if available) with the U.POS AI-330 and Xprinter XP-80C; shortlist Compose Multiplatform Desktop, Electron, Tauri 2 | Starts, prints Arabic receipts, opens the drawer and the encrypted store works on Windows 10 and 11 within the budgets set for the reference PC |
| 3 | The 3 customers switch without losing anything | desirability | High — first revenue and references | Praise only | Op-count test on Glitch + a parity checklist each customer signs off | Zero missing-feature blockers in UAT |
| 4 | Tier 1 (3 clients + backend + sync) fits 2 engineers in acceptable time | viability | High | None; rough estimate ~10–14 months | `/estimate` after `/map-domains` | Tier 1 fits the founder's target date |
| 5 | Cold, non-referral lounges pay ~10,000 EGP/year | viability | High | 3 referral sales (price includes on-site install, training and support); published competitor software prices EGP 1,500–4,788/yr, median 1,500 (n = 3, captured 2026-10-16, `business/competitors/comparison-matrix.md`) | `/competitor-analysis` prices + 5–8 non-referral owner interviews with a pre-sale ask | ≥ 3 of 8 commit at the hypothesis price |
| 6 | Standalone cafés want it | desirability | Medium | None — assumption | 5 café-owner interviews | ≥ 3 describe the leakage pain and a gap in their tool |
| 7 | ETA e-receipt rules can be met by an integration built after Tier 1 (the earlier "do not force an integration into Tier 1" wording is **contradicted for cafés**: ETA Phase 6 names restaurants and cafés outside commercial centres, mandatory from 15 Nov 2024 in Greater Cairo and Alexandria and 15 Jan 2025 elsewhere, for taxpayers on ETA's lists; PlayStation lounges are not named) | compliance | High — legal blocker | `docs/research/eta-e-receipt-e-invoice.md` (Draft, BLOCKED, 2026-10-16): mandates bind by published list, not size; no software-vendor certification found; offline issuing allowed with sending within 24 h; all legal points need counsel | Founder decision 2026-10-16: Tier 1 is ETA-ready (numbering, immutability, receipt fields), integration is the first post-Tier-1 increment. **Trigger:** if ETA's per-venue inquiry shows any of the 3 venues or a signed prospect on an e-receipt list, the integration moves into Tier 1. Counsel on Art. 37 serial, lounge classification, software-POS registration, signing custody | Inquiry result for the 3 venues + counsel's written answers |
| 8 | The subscription grace period (N5) resists clock tampering | security | Medium — revenue leakage | None | `/license-design` + `/threat-model` | A tampered clock cannot extend grace in tests |
| 9 | Multi-device branches can be added later without a redesign | feasibility | Medium — restaurants and cafés may need several devices | None | Settle in `/design-spec` + `/research`: two offline devices starting the same station; duplicate bill numbers; drawer and shift per device or per branch; two devices selling the last stock item | A chosen design (e.g. station owned by one device at a time, or server-side resolution) recorded in an ADR |

**Open questions (local-first):** what happens when the same thing changes on the server and on an offline device; with 2+ cashier devices in one branch, must they see each other's work while the internet is down.

## Success metrics & targets
See *Success metric* above (confirmed 2026-10-16). Add after `/setup-stack`: sync health (queued changes age, conflict rate), counter action latency against `docs/architecture/perf-budgets.md`, support tickets per venue per month. Tracking plan → `product-analytics-engineer`.

## Roadmap
- **M0 — Spikes:** desktop client technology; local-first sync. Usage op-count test on Glitch (founder).
- **M1 — Vertical slice:** session → café item → close and pay → sync → owner dashboard.
- **M2 — Tier 1 private beta** with the 3 founding lounges; parity checklist signed.
- **M3 — Tier 1 release**, then referral-partner launch.
- **M4+ — Tier 2**, then future modules (restaurant, retail) per ADR.

Scope estimate: **Large — Tier 1 ≈ 10–14 months, full baseline ≈ 18–24 months, team of 2** (unvalidated; PR-SCOPE skipped in Lean mode; replaced by `/estimate` after `/map-domains`).

## Visual Identity Anchor
None yet — DD-CONCEPT-VISUAL skipped (Lean mode) and no direction supplied; set by `/impeccable`. Inputs: Kodeebo master brand endorsed by Kodelix, Kiko the wolf, one theme per vertical, Arabic-first RTL, visual quality is a stated customer value.

## Product principles
See `design/product-principles.md`: (1) Every pound leaves a trail · (2) The counter never waits · (3) Fast for a tired cashier at 2 a.m. · (4) The owner sets the rules; the counter follows them · (5) Built in Arabic, not translated into it.
