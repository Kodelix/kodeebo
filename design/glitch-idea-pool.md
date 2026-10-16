# Glitch Idea Pool

> **Ideas, not requirements.** These capabilities were observed in the founder's
> previous system (Glitch) on 2026-10-14 through a read-only review of its docs,
> migrations and feature flags. Kodeebo is a **revamp built from scratch**:
>
> - Nothing here is a spec. Every item may be **kept** (with its logic
>   redesigned), **changed**, **dropped**, or joined by **new** ideas.
> - No design, data model, business rule or code from Glitch is carried over as
>   is. A kept item gets its logic from `/design-spec` and its implementation
>   from `/research` (primary sources, best practice), like any new feature.
> - "Exists in Glitch" is not market evidence. The evidence is what current
>   customers **use**, which the founder supplies.
>
> Used as input to `/brainstorm` (MVP scope) and `/competitor-analysis`.

> **Decisions filled by `/brainstorm` on 2026-10-16.** Tier 1 / Tier 2 are ordering only (nothing cut) and provisional until the aggregate operation-count test on the Glitch server; see `design/product-brief.md`.

## How to use this file

In `/brainstorm`, fill the **Decision** column for each row:

| Value | Meaning |
|---|---|
| `Keep` | The idea stays; its behaviour is redesigned in `/design-spec` |
| `Change` | The idea stays in a different form (note what changes) |
| `Drop` | Not in Kodeebo |
| `Later` | Not in the MVP; a later release or another vertical |
| `?` | Undecided; needs customer evidence or research |

**Used today** = do current customers actually use it (`daily` / `sometimes` /
`never` / `unknown`). This is the market signal; fill it from what you know.

New ideas go in [New ideas](#new-ideas) at the end.

---

## 1. Platform and commercial model

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| P1 | One platform, verticals (gaming, café/restaurant, retail) enabled per tenant by plan | unknown | Keep — Tier 2 | Packaging and plan names belong to `/pricing-strategy` |
| P2 | Plan tiers that switch individual capabilities on or off per tenant, with per-tenant overrides | unknown | Keep — Tier 2 | Entitlement model: `/design-spec` + `pricing-billing-designer` |
| P3 | Chains: store, then branches, then workstations (registered POS devices) | unknown | Change — Tier 1: one cashier device per branch in the MVP; the model must allow more | |
| P4 | Arabic first, English complete, RTL first; Egyptian Arabic copy | unknown | Keep — Tier 1 | |
| P5 | Customer-defined reason lists (void, refund, expense, complaint) | unknown | Keep — Tier 1 | |
| P6 | One audit record for every change | daily (likely — praised, not measured) | Keep — Tier 1 | Audit is a `saas-core` module |

## 2. Stations and pricing (gaming)

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| G1 | Bookable stations grouped as category, then type, then the physical unit (e.g. PlayStation, then PS5 four-controller, then Station 01) | unknown | Change — Tier 1: adds PCs as a timed station type | Could serve billiards, rooms and ping-pong too |
| G2 | Hourly price per station type, with several named price levels | unknown | Keep — Tier 1 | |
| G3 | Price per player per hour (in addition to, or instead of, a room price) | unknown | Later (pricing is by tier only) | |
| G4 | Fixed one-time price per session | unknown | Keep — Tier 2 | |
| G5 | Minimum billable minutes | unknown | Keep — Tier 1 | |
| G6 | First N minutes free | unknown | Keep — Tier 2 | |
| G7 | Special price for one particular unit | unknown | Keep — Tier 2 | |
| G8 | Choice per customer: bill the room, or bill each player who joins or leaves | unknown | Later (pricing is by tier only) | |
| G9 | Automatic discounts or surcharges by time of day or day of week (happy hour, weekend) | unknown | Keep — Tier 2 | |
| G10 | Manual discount or surcharge by the cashier, limited per session | unknown | Keep — Tier 1 | Needs a permission and a reason |
| G11 | Tax (inclusive or exclusive), service charge, minimum charge (also scheduled), rounding | unknown | Keep — Tier 1 | Egyptian VAT and e-receipt rules: `/research` |
| G12 | Prices frozen at session start, so a later price change does not alter an open session | unknown | Keep — Tier 1 | |
| G13 | Pricing preview simulator for the admin | unknown | Drop | |

## 3. Sessions (gaming)

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| S1 | Start and end a timed session on a station | daily (likely — praised, not measured) | Keep — Tier 1 | Core job candidate |
| S2 | Pause and resume, with a reason and a pause budget | unknown | Drop | Founder flagged as a possible **Drop** |
| S3 | Move a running session to another station (billing splits correctly) | unknown | Keep — Tier 1 | |
| S4 | Cancel a session (time-limited, by permission) | unknown | Keep — Tier 1 | |
| S5 | One open session per station, guaranteed | unknown | Keep — Tier 1 | |
| S6 | Planned end time, with an alert to the cashier | daily (likely — praised, not measured) | Keep — Tier 1 | |
| S7 | Backdated start (started before it was recorded), with an approver | unknown | Keep — Tier 2 | Fraud risk: `/threat-model` |
| S8 | Players join and leave during a session; capacity limit per price level | unknown | Later (with G3/G8; single → multi is N4) | |
| S9 | Extras on a session (extra controller, headset) with several charging modes, and tracking of lost or damaged items | unknown | Keep — Tier 2 | |
| S10 | Café orders added to the session bill (the "tab") | unknown | Keep — Tier 1 | Core job candidate |
| S11 | Station on/off or network control from the POS | unknown | Keep — Tier 2 | Hardware research; a delighter? |
| S12 | Live floor view of all stations and their state | unknown | Keep — Tier 1 | |

## 4. Selling and payments

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| O1 | Quick sale without a session (a drink only) | daily (likely — praised, not measured) | Keep — Tier 1 | |
| O2 | Open tab, add and remove lines, close later | unknown | Keep — Tier 1 | |
| O3 | Pay with several methods on one bill (cash, card, wallet, transfer) | unknown | Change — Tier 1: method recorded only; card-terminal / e-wallet integration Later (not in Glitch) | Card terminals and Egyptian wallets: `/research` |
| O4 | Move, split and merge orders or individual lines | unknown | Keep — Tier 2 | |
| O5 | Partial refund against a specific payment | unknown | Keep — Tier 2 | |
| O6 | Void an order with a reason (returns stock) | unknown | Keep — Tier 1 | |
| O7 | Daily order numbers per branch | unknown | Keep — Tier 1 | |
| O8 | One ledger of every money movement (sales, refunds, wallet, supplier payments, expenses) | unknown | Keep — Tier 1 | |

## 5. Customers

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| C1 | Customer records (and walk-ins) | unknown | Keep — Tier 2 | PII: Egypt PDPL, `/threat-model` |
| C2 | Customer wallet (prepaid balance) | unknown | Later (prepaid hours not used) | Possibly the form of "prepaid hours"; or prepaid **hours** as their own thing? |
| C3 | Loyalty points with expiry | unknown | Keep — Tier 2 | |
| C4 | Customer price groups | unknown | Keep — Tier 2 | |

## 6. Shifts, cash and staff

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| W1 | Shift open and close with cash counting per drawer | unknown | Keep — Tier 1 | |
| W2 | Paid-outs from the drawer (expenses paid in cash) | unknown | Keep — Tier 1 | |
| W3 | X report (mid-shift) and Z report (close) | daily (likely — praised, not measured) | Keep — Tier 1 | |
| W4 | Business day and end-of-day close (a day that runs past midnight) | unknown | Keep — Tier 1 | |
| W5 | Employees, roles, permissions, branch assignment | unknown | Keep — Tier 1 | Identity and RBAC are `saas-core` modules |
| W6 | Clock in and out with a passcode | unknown | Keep — Tier 1 | |
| W7 | Work contracts, attendance summaries, payroll | unknown | Keep — Tier 2 | Probably `Later` |
| W8 | Workstation sign-in with an employee passcode | unknown | Keep — Tier 1 | |

## 7. Stock and suppliers

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| I1 | Stock per branch, deducted by sales; adjustments; transfers between branches | unknown | Keep — Tier 1 (with the café product catalogue) | |
| I2 | Low-stock (reorder point) alerts | unknown | Keep — Tier 2 | |
| I3 | Recipes (a drink consumes ingredients) | unknown | Keep — Tier 2 | |
| I4 | Suppliers, purchase invoices, receiving, supplier payments | unknown | Keep — Tier 2 | |
| I5 | Expenses against approved reasons | unknown | Keep — Tier 2 | |

## 8. Offline

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| F1 | Branch keeps working when the internet is down, then syncs | daily (likely — praised, not measured) | Change — Tier 1: local-first, not a fallback | Founder flagged **Change**. Sync model, conflict policy and money correctness: early `/research` + `/threat-model`, before `/setup-stack` |
| F2 | Offline actions applied on the server in device order, never twice | unknown | Keep — Tier 1 | |
| F3 | A day closed offline whose server totals differ is flagged for review | unknown | Keep — Tier 1 | |
| F4 | Clear offline, syncing, failed and conflict states on the POS | unknown | Keep — Tier 1 | |

## 9. Devices and other

| # | Idea | Used today | Decision | Notes / questions for research |
|---|---|---|---|---|
| D1 | Receipt, kitchen and bar printers; cash drawers; displays per workstation | unknown | Keep — Tier 1: receipt printer + cash drawer; Tier 2: kitchen/bar printers, displays | Printer protocols on Windows: `/research` |
| D2 | Coupons and promotions | unknown | Keep — Tier 2 | |
| D3 | In-app notifications | unknown | Keep — Tier 2 | |
| D4 | Webhooks for integrations | unknown | Keep — Tier 2 | |
| D5 | Support tickets and complaints | unknown | Keep — Tier 2 | |
| D6 | Owner mobile app (snapshot, alerts, approvals) | unknown | Change — Tier 1: Android only (iOS later), same capabilities as N2 | |
| D7 | Customer app (wallet, availability, reservations) | unknown | Later (Glitch never built it) | Was future in Glitch |

## 10. Other verticals (probably `Later`)

Restaurant: kitchen display and stations, item routing to stations, tables and
floor plan, modifiers and combos, preset button panels, delivery zones and
drivers, reservations, waiting list.
Retail: product variants, sell by weight, item packages, gift cards, returns
and exchanges.

| # | Idea | Used today | Decision | Notes |
|---|---|---|---|---|
| V1 | Restaurant set (above) | unknown | Later (future module) | |
| V2 | Retail set (above) | unknown | Later (future module) | |

---

## Leads for the early research (unverified)

These come from Glitch's own notes, **not from primary sources**. They are
starting points for the desktop-client `/research`, which must confirm or
refute each one against official documentation and a run on real Windows 10/11
and Windows 7 64-bit VMs:

- Windows 7 tops out at Chromium 109 (Chrome, Edge, WebView2).
- Tauri 2 did not start on Windows 7: the WebView2 loader it links returned
  `0x80070032` (not supported).
- Glitch's Windows 7 build fell back to Electron 22, said to be the last Electron
  that runs on Windows 7.

## New ideas

| # | Idea | Source (customer, competitor, founder) | Decision | Notes |
|---|---|---|---|---|
| N1 | Open item: an item bought from outside added to the bill under its own name and price | Customer (praised by all 3) | Keep — Tier 1 | Permission + logged reason + owner-set maximum price (principle 4) |
| N2 | Owner web dashboard: reports, activity log, live floor, configuration | Founder | Keep — Tier 1 | |
| N3 | Simple café table tab (not a restaurant floor plan) | Founder (assumption — no customer evidence yet) | Keep — Tier 1 | |
| N4 | Change the price tier during a running session (e.g. single → multi), billed correctly per period | Founder | Keep — Tier 1 | |
| N5 | Subscription control: tenant active/suspended; bounded offline grace, then the app must reach the server | Founder (Glitch had edition control) | Keep — Tier 1 | The one named exception to principle 2; design → `/license-design` + `/research` |
| N6 | Automatic PC lock/unlock when session time ends — client agent on every PC that resists customer bypass | Founder | Keep — Tier 2 | Own `/research` + `/threat-model` |
