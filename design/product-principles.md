# Product Principles: Kodeebo — by Kodelix

## Document Status
- **Version**: 1.0
- **Last Updated**: 2026-10-16
- **Approved By**: founder (locked in `/brainstorm`); product-director gate PD-PRODUCT-PRINCIPLES skipped — Lean mode (not an approval)
- **Status**: Approved by founder

---

## Core Promise

> Lounge and café owners stop money leaking — every pound and every station minute
> leaves a trail they can see from anywhere, while the counter stays fast whether or
> not the internet is up.

---

## Value Alignment

| Rank | Customer value | How the product delivers it |
| ---- | ---- | ---- |
| 1 | Outcome — money recovered (no leakage) | Every money and time event recorded with actor and reason; ledger; X/Z reports; drawer reconciliation |
| 2 | Control — trust in staff without being there | Activity log, permissions, owner web dashboard and Android app |
| 3 | Effort — speed at the counter | Local-first cashier app; ≤ 3 taps for the top actions; never waits on the network |
| N/A | Belonging (community) | Not a differentiator for a POS |

---

## The Principles

### Principle 1: Every pound leaves a trail

**One-Sentence Definition**: Every money and time event records who, when and why, and a correction is a new record — never an edit or a delete.

**Customer Values Served**: Outcome (leakage stopped), Control.

**Decision Test**: If we are debating a faster flow that skips a record and a slower one that keeps it, we keep the record.

**Measurable form**: 100% of voids, discounts, cancellations, paid-outs, open items, tier changes and backdated starts carry an actor and a reason; money records are never hard-deleted.

| Function | This Principle Says... | Example |
| ---- | ---- | ---- |
| **Product** | Every exception path produces an auditable event | A void without a reason cannot be completed |
| **Design / UX** | Reason capture is part of the flow, made fast (pick-list first) | Reason lists (P5) shown as large buttons |
| **Engineering** | Append-only money and audit records; corrections reverse, never mutate | Refund = new ledger entry linked to the original |
| **Security & Privacy** | Audit integrity is protected on the device and the server | Local records encrypted; tampering detectable |
| **Pricing & Growth** | The activity log is a core selling point, never paywalled out of the base plan | Owner sees the full log on every plan |
| **Support & Success** | Disputes are settled from the trail | Support answers "who voided this?" from the log |

**Serving**: the activity log (P6); the ledger (O8); open item by permission with a reason (N1).
**Violating**: editing a closed bill in place; deleting a session to "fix" it; a cashier action with no actor.

---

### Principle 2: The counter never waits

**One-Sentence Definition**: The cashier works from local data, and no counter action waits on the network or the server — **with one named exception: subscription control (N5) may require the server after a long, known offline grace period.**

**Customer Values Served**: Effort, Outcome (no lost sessions).

**Decision Test**: If a feature needs the server to answer before the cashier can continue, redesign it or take it off the counter.

**Measurable form**: core counter actions (start session, add item, close bill) meet a p95 budget on the reference Windows PC, set in `docs/architecture/perf-budgets.md`; behaviour is identical with the internet unplugged, until the N5 grace period ends.

| Function | This Principle Says... | Example |
| ---- | ---- | ---- |
| **Product** | Server-only features live in the owner surfaces, not the counter | Owner approvals that need the server never block a sale |
| **Design / UX** | Sync state is visible but never modal | A quiet offline/syncing indicator (F4) |
| **Engineering** | Local-first: local store and business logic are the source of truth on the device | Close a bill offline; it syncs later in device order, never twice (F2) |
| **Security & Privacy** | Local data is encrypted at rest | Queued changes encrypted until sent |
| **Pricing & Growth** | Offline grace length is a known, communicated number | The owner is warned well before grace ends |
| **Support & Success** | "Internet down" is not an incident for the venue | Support playbooks treat it as normal operation |

**Serving**: F1–F4; prices frozen at session start (G12).
**Violating**: a sale that spins waiting for the server; an online-only price lookup at the counter.

---

### Principle 3: Fast for a tired cashier at 2 a.m.

**One-Sentence Definition**: The counter screen is built for speed and glanceability, in Egyptian Arabic, right-to-left.

**Customer Values Served**: Effort.

**Decision Test**: Between a flexible counter screen and a fixed fast one, the counter gets the fast one; flexibility goes to the owner.

**Measurable form**: the top 10 counter actions take ≤ 3 taps; a new cashier is productive after one shift (validated in UAT).

| Function | This Principle Says... | Example |
| ---- | ---- | ---- |
| **Product** | Counter features earn their place by frequency | Rare admin tasks live in the dashboard |
| **Design / UX** | Large targets, live floor at a glance, no deep menus | Station tiles with timer and state (S12) |
| **Engineering** | Startup and interaction latency are budgets, not hopes | Measured on the reference PC |
| **Security & Privacy** | Fast sign-in that stays accountable | Employee passcode (W8), not shared accounts |
| **Pricing & Growth** | Demo-able in minutes by a referral partner | The guided demo shows the night shift flow |
| **Support & Success** | One-shift onboarding for new cashiers | Short Arabic training card |

**Serving**: quick takeaway sale (O1); session timer and planned-end alert (S6).
**Violating**: a settings panel on the counter; a five-step flow for a common action.

---

### Principle 4: The owner sets the rules; the counter follows them

**One-Sentence Definition**: Flexibility lives in owner configuration — price tiers, reasons, permissions, limits — not in cashier discretion.

**Customer Values Served**: Control, Outcome.

**Decision Test**: When a cashier needs an exception, it is a permission plus a reason, or an owner approval — never a free-text workaround. **Applied to the open item (N1):** a free name and price typed by the cashier requires a permission, is logged with a reason (principle 1), and is capped by an owner-set maximum price.

**Measurable form**: every exception path maps to a named permission; every limit or price is configuration, never an inline value.

| Function | This Principle Says... | Example |
| ---- | ---- | ---- |
| **Product** | Exceptions are designed, not improvised | Manual discount limited per session (G10) |
| **Design / UX** | The counter shows only what the role permits | A cashier never sees the void button without the permission |
| **Engineering** | Limits, prices, reasons are data, enforced on device and server | Max open-item price checked locally and on sync |
| **Security & Privacy** | Least privilege by role (W5) | Manager approves; cashier requests |
| **Pricing & Growth** | Owner configurability is a selling point | "You decide what your staff can do" |
| **Support & Success** | Support changes rules in the dashboard, not by hand | No database edits for customers |

**Serving**: reason lists (P5); roles and permissions (W5); owner-set maximum for open items.
**Violating**: a cashier free-typing a price without limits; a hardcoded discount ceiling.

---

### Principle 5: Built in Arabic, not translated into it

**One-Sentence Definition**: Arabic and RTL are the primary design; English is complete but second.

**Customer Values Served**: Effort, Trust.

**Decision Test**: A screen is designed and reviewed in Arabic first; a layout that only works in English fails.

**Measurable form**: every screen ships with Arabic RTL screenshot evidence; no hardcoded strings.

| Function | This Principle Says... | Example |
| ---- | ---- | ---- |
| **Product** | Copy written in Egyptian Arabic, not formal translation | Cashier-facing labels in the words cashiers use |
| **Design / UX** | RTL layout, bidi numbers and EGP formatting by default | Receipts print correctly in Arabic |
| **Engineering** | i18n from the first screen | String keys, no literals |
| **Security & Privacy** | Consent and privacy texts in Arabic | PDPL notices readable by staff |
| **Pricing & Growth** | Marketing in Arabic first | Demo in Arabic |
| **Support & Success** | Support in Egyptian Arabic | Help content Arabic-first |

**Serving**: P4; Arabic receipts.
**Violating**: shipping an English-only screen "to translate later"; mirrored icons that break meaning.

---

## Anti-Principles (What This Product Is NOT)

- **NOT dependent on the internet at the counter**: no counter action waits on the network (principle 2) — the only exception is the N5 grace period.
- **NOT editable after the fact**: no silent edits or deletes of money, time or audit records (principle 1).
- **NOT a configurable counter**: no configuration knob on the counter screen when it can live in the owner dashboard (principle 3).
- **NOT a restaurant or retail system — yet**: floor plans, kitchen display, delivery and retail features stay out of the gaming + café product; they come later as modules (protects principle 3's focus).
- **NOT Glitch rebuilt**: no Glitch design, data model, business rules or code carried over — a clean-room rebuild.

---

## Principle Conflict Resolution

| Priority | Principle | Rationale |
| ---- | ---- | ---- |
| 1 | Every pound leaves a trail | The product's reason to exist is stopping leakage; a fast but untraceable flow defeats it |
| 2 | The counter never waits | Speed and availability are the proof of the positioning; second only to correctness of money |
| 3 | The owner sets the rules | Control is the buyer's value; it constrains how speed is achieved |
| 4 | Fast for a tired cashier at 2 a.m. | Speed within the trail and the rules — e.g. a reason prompt slows the cashier, but the record wins; make the prompt fast instead |
| 5 | Built in Arabic | A quality bar on everything, rarely in conflict; when it is, Arabic wins over English |

**Resolution Process**: identify the tension → consult the ranking → serve the lower principle partially if possible → otherwise the higher wins → record it in the spec or ADR → escalate fundamental conflicts to `product-director`.

---

## Trust Alignment

| Trust dimension | Which principle serves it | How |
| ---- | ---- | ---- |
| **Security & tenant isolation** | 1, 4 | Audit integrity; least privilege; tenant scoping (engineering standard) |
| **Reliability & transparency** | 2 | Counter works offline; visible sync state; flagged offline-day differences (F3) |
| **Privacy & data ownership** | — (gap, deliberate for now) | Covered by the security baseline and PDPL work (staff data Tier 1, customer PII Tier 2), not a differentiator |
| **Commercial fairness** | 2 (exception) | The offline grace period is long, known and warned in advance |

---

## Experience Arc

### First-Session Arc (guided demo and install)

| Phase | Duration | Target feeling | Principle(s) | Mechanics |
| ---- | ---- | ---- | ---- | ---- |
| Arrival | 0–5 min | "This is mine — in Arabic" | 5 | Arabic-first install and sign-in |
| First value | 5–15 min | Relief — "it works, even unplugged" | 2, 3 | Start a session, add a drink, close, with the cable pulled |
| Set-up | 15–60 min | Control | 4 | Owner sets tiers, reasons, roles with the installer |
| Hook | End of first night | "I can see everything" | 1 | Owner opens the Z report and the activity log on their phone |

### Long-Term Progression
First week: cashiers stop asking; first month: the owner trusts the daily report; first renewal: the history and stock make leaving costly; expansion: a second branch or a future module.

---

## Reference Products

| Reference | What We Take From It | What We Do Differently | Which Principle It Validates |
| ---- | ---- | ---- | ---- |
| Glitch (founder's previous system) | The capability baseline only | Clean-room design and code | 1, 2 (customers praise log and offline) |
| Waqtak, PlayMasr, HSYS (`business/competitors/`, captured 2026-10-16; vendor claims, untested) | Offline/hybrid counter and a remote owner view are table stakes; trials of 7–14 days; software-only prices EGP 1,500–4,788/yr | Trail depth on every exception (actor + reason, append-only); on-site install, training and support; no fixed offline stop beyond the N5 grace; no competitor named in customer copy | 1, 2 |

---

## Principle Validation Checklist

- [x] **Count**: 5 principles
- [x] **Falsifiable**: each has a measurable form
- [x] **Constraining**: each forces a "no" (see Violating)
- [x] **Cross-functional**: function tables filled
- [x] **Decision-tested**: decision tests against real choices (open item, grace period, reason prompts)
- [x] **Anti-principles defined**: 5
- [x] **Priority-ranked**
- [x] **Value-aligned**: top 3 values covered
- [ ] **Trust-covered**: privacy has no owner principle — recorded as a deliberate gap
- [ ] **Memorable**: to be checked with the team
- [x] **Core promise served**

---

## Next Steps

- [ ] PD-PRODUCT-PRINCIPLES review when review mode allows (skipped in Lean mode)
- [ ] Link from `PRODUCT.md` when `/impeccable init` runs
- [ ] First principle review after 2 sprints
