# Domain Map: Kodeebo — by Kodelix

> **Status**: Draft
> **Created**: 2026-10-20
> **Last Updated**: 2026-10-20 (second pass: founder decisions on refunds, complaints, accessories, G9, discounts, tax hierarchy)
> **Source**: design/product-brief.md (Tier 1/Tier 2 from the brief; founder decisions of 2026-10-19 and 2026-10-20 recorded below)

---

## Overview

Kodeebo is one product in three layers (founder, 2026-10-19). **Layer 1** holds the capabilities any Kodelix SaaS needs (tenancy, identity, authorization, audit, operator access, licensing, plans and subscription, notifications, jobs, observability, analytics, storage). They are built inside Kodeebo behind the ports the future `saas-core-kotlin` will expose, and each is scheduled for `/core-extract` — never core-first. **Layer 2** holds the Kodeebo platform modules every vertical shares (venue configuration, sync, the Windows counter shell, catalogue, orders and bills, payments, tax and receipts, the money ledger, shifts and End Day, staff, inventory, customers, reports, fleet health, client surfaces, integrations). **Layer 3** holds the verticals, enabled per tenant by entitlement: Gaming Lounge and Café now; Restaurant and Retail later (placeholders, no specs). The customer is an owner-operator of a PlayStation or gaming lounge or a café in Egypt; the pricing model is an EGP subscription per venue (anchor 10,000 EGP/year, `/pricing-strategy` pending); the Tier 1 release must let the three founding lounges leave Glitch without losing anything.

**What this map is.** 32 bounded contexts, 89 features (each a spec at `design/specs/<key>.md`), 3 cross-context items that are not contexts (two shared kernels and the vertical module contract), a dependency order, and the ordered list of ADRs and research the order implies. The 32 contexts are **logical boundaries**. Whether small contexts share a Gradle module, with the boundary enforced by an architecture test, is decided in the module-structure ADR, so the build stays light for one developer. Contexts are modules of one Ktor modular monolith, never separate services.

**Stack at the time of writing** (`project.yaml`, written by `/setup-stack` today): backend `ktor` (ADR-0006), data `postgres`, tenancy `shared-schema-rls` (ADR-0001), distribution `hosted`, deploy `compose-vps` (ADR-0009), `core.track: kotlin`. `core.version` is unset, so every Layer 1 context follows the "shared core absent" path (`coordination-rules.md`): a product-local module behind the port the core will expose, one umbrella ADR, `/core-extract` scheduled per module. Still pending, with their triggers: `stack.desktop` (desktop-runtime ADR, after the sync spike's phase 5), `stack.web` (dashboard real-time ADR and web stack), `stack.mobile` (spikes S32/S33; the owner Android app is a PWA wrapped for Google Play, provisional), `stack.site` (GTM plan), `stack.messaging` (jobs ADR). **Data stores:** PostgreSQL only. Elasticsearch and Kafka/RabbitMQ are excluded at start (founder, 2026-10-20). A cache — in-process, or Dragonfly/Valkey — is decided per story under DoD gate 5 when the first story needs one; no store is added by this map.

**Inputs read.** `design/product-brief.md`, `design/product-principles.md`, `design/glitch-idea-pool.md` (coverage check below), `project.yaml`, `docs/stack-reference/pins.yaml`, ADR-0001..0009, `docs/registry/architecture.yaml`, `docs/architecture/licence-model.md`, `docs/research/local-first-sync.md` (open questions), `docs/research/desktop-client-adr-followups.md`.

**Gates not run.** `CTO-CONTEXT-BOUNDARY`, `PR-SCOPE` and `PD-FEATURES` were skipped — Lean review mode (not an approval). The brief's Tier 1 estimate (10–14 months, team of 2) is unvalidated; `/estimate` is the follow-up. `design/specs/pricing-model.md` and `design/registry/entities.yaml` do not exist yet, so plan, entitlement and quota keys are not reconciled with a catalogue.

**Coverage check (idea pool).** Every `Keep` row of `design/glitch-idea-pool.md` maps to a spec key. One was missing and is added: **D2 coupons and promotions** (`coupons-promotions`). D5 is split into Kodelix support tickets (`support-desk`) and venue customer complaints (`customer-complaints`, new, founder 2026-10-20). O5 partial refund moved to Tier 1 with full refund (`refunds`, founder 2026-10-20). G10 is split into the discount model (`discounts`) and the manual surcharge (`bill-exceptions`). D3 in-app notifications is covered by `owner-alerts` (push is `push-notifications`, `[new]`). D1 is split into `counter-printing-drawer` (Tier 1) and `kitchen-bar-printers-displays` (Tier 2). I5 `expenses` sits in Shifts, Cash & End Day beside paid-outs. `Change` rows: P3 → `branches-settings` and `device-seats-enrolment`; G1 → `stations-catalogue`; O3 → `payments-tender`; F1 → `sync-protocol` and `counter-shell`; D6 → `owner-android-app`. `Later` and `Drop` rows have no spec by design (G3, G8, S8, C2, D7, V1, V2, S2, G13).

**Tags in the Feature cell** (the template's columns are a fixed contract, so the brief tier is a tag): `[T1]` brief Tier 1; `[T2]` brief Tier 2; `[Later]` brief Later; `[new]` not in the brief or the idea pool. `(inferred)` marks a feature the brief does not name. Differences from the brief of 2026-10-16, now applied to `design/product-brief.md` (decision log, 2026-10-20): `tips` is Tier 1; `plans-entitlements` (minimum: module flags and limits per tenant) and `owner-alerts` are pulled from Tier 2 into Tier 1; full and partial `refunds` and `recipes` are Tier 1; `data-import` is a future onboarding spec for new venues, `[Later]`, and the brief's "no Glitch import tool — the founder moves the 3 customers by hand" stands unchanged.

**Contexts, one paragraph each.**

*Layer 1 — Kodelix capabilities (Extract-candidate: product-local behind the future `saas-core-kotlin` port).*
- **Tenancy & Tenant Lifecycle** owns tenants, tenant status, the ADR-0002 scope helper and tenant-to-connection resolver, closure (DEL-2), export (EXP-2), provisioning, and the import jobs of a future onboarding. Core module `tenancy`.
- **Identity & Authentication** owns the three realms' credentials, sessions, second factors, passkeys, recovery and the counter PIN verifier (ADR-0007). Core module `identity`, with `otp` and `ratelimit` inside it.
- **Roles & Permissions** owns roles as tenant rows, the permission catalogue and limits, the authority snapshot and one-shot overrides (ADR-0008). The mechanism is the core module `authz`; the Kodeebo catalogue stays product-only.
- **Audit & Activity Trail** owns the hash-chained activity trail kept 5 years (ADR-0008). Core module `audit`.
- **Operator Console & Support Access** owns the operator realm, owner-granted support sessions and journal, the redacted diagnostic bundle, and Kodelix support tickets (ADR-0004, ADR-0007). Venue customer complaints are not here: they are venue data in Customers, Loyalty & Complaints. Core module `operator`.
- **Licensing & Device Seats** owns seats, devices, seat moves, the offline lease and its clock-tamper handling (`licence-model.md` is the module's spec). Core module `licensing`.
- **Plans, Entitlements & Subscription** owns the plan catalogue (global), module entitlements per tenant, limits, subscription status (N5) and, later, invoices. Core module `billing`.
- **Notifications** owns channels, templates (AR/EN), delivery tracking and the only mail/push clients. Core module `notify`. Provider choice pends research.
- **Jobs & Outbox** owns the scheduler, the transactional outbox and the per-tenant sweep on PostgreSQL. Core module `jobs`. The jobs ADR fixes its table class.
- **Observability** is server-wide plumbing: the OpenTelemetry Java agent (ADR-0006), a thin Ktor plugin for log correlation, Collector pipelines, redaction, SLOs. Open source adopted through OpenTelemetry, no fork. Core module `observability`.
- **Product Analytics** owns the event taxonomy and server-side business events (consent-gated, PII-free). Core module `analytics`.
- **Storage & Backup** owns object-storage access, backups, restore replay, the control-journal home. Core module `storage`.

*Layer 2 — Kodeebo platform modules, shared by every vertical (product-only).*
- **Venue Configuration** owns branches, branch settings, owner-set limits and thresholds and reason lists: the owner-sets-the-rules principle as data.
- **Sync** owns the command protocol, inbox, ordering, idempotency, server-to-device feeds, the review queue and clone/restore detection. A money fact is never rejected: it is recorded and flagged for review.
- **Counter Shell** is the Windows client: encrypted local store, start check and salvage, printing and cash drawer, installer and updater, and PIN sign-in and override on the device. Runtime pends the desktop ADR.
- **Catalogue** owns café products, categories and prices. Tax and service values for a category or item are not catalogue data: Tax & Receipts owns them (override hierarchy, below).
- **Orders & Bills** owns bills, lines, tabs, daily order numbers, order types (data), void, manual surcharge, open item, and the one discount model (owner-defined discounts and every discount applied).
- **Payments & Tender** owns payments (method recorded only), tips, and full and partial refunds.
- **Tax & Receipts** owns the tax, service charge, minimum charge and rounding rules — their values at every level of the override hierarchy and their resolution — receipt content and numbering, and later ETA submission.
- **Money Ledger** owns the append-only ledger of every money movement; a correction is a new entry.
- **Shifts, Cash & End Day** owns shifts, cash counts, paid-outs, expenses, X and Z reports, the business day and End Day.
- **Staff & Attendance** owns staff records, branch assignment, clock in/out, later contracts and payroll.
- **Inventory** owns stock per branch, adjustments, transfers, recipes (Tier 1: stock is deducted through the recipe when an item has one), accessory units with a state per unit (Tier 2), later purchasing.
- **Customers, Loyalty & Complaints** owns customer records (PII), loyalty, price groups and venue customer complaints. Tier 2. A complaint does not need a customer record (walk-ins complain too).
- **Reports & Insights** owns the server-side read models behind owner reports.
- **Fleet Health & Diagnostics** owns device heartbeat, version, sync lag, crash records carried through sync, and the console views (built by us; logs/metrics/traces stay on OpenTelemetry).
- **Client Surfaces** is the owner web dashboard (PWA), the Android app (PWA wrapped for Google Play) and the marketing site. It owns no tables.
- **Integrations & Webhooks** owns outbound webhooks; ETA and payment-provider adapters sit behind ports.

*Layer 3 — verticals, enabled per tenant by entitlement.*
- **Gaming Lounge** owns stations, sessions and station pricing. **Café** owns table tabs. **Restaurant** and **Retail** are Later placeholders: no specs, but the module contract must leave room for them.

---

## Architecture Principles

Founder decisions of 2026-10-19 and 2026-10-20. Stories and reviews cite them by name.

**P-ONCE — every shared capability exists once.** A shared capability lives in its owning context behind one port, and every feature uses that port. No feature re-implements notifications, the activity trail, authorization, or money, tax and time rules, or localization. Enforced by architecture tests (the Kotlin option — for example Konsist or ArchUnit — is chosen by `/research` in the module-structure ADR; for instance, no context but Notifications may import a mail client) plus code review.

**P-PLUMB — observability and logging are installed once, server-wide.** The OpenTelemetry Java agent (ADR-0006) and one thin Ktor plugin of our own for request-scoped log fields and `trace_id` correlation. Features add only their own business events. The plugin must not be `KtorServerTelemetry` or any second SDK beside the agent (registry `FP-OTEL-LIBRARY-INSTRUMENTATION-WITH-AGENT`, `FP-SECOND-OTEL-SDK-R2`).

**P-LOC — localization.** Code holds keys only. AR and EN resource files exist per client and for server messages. There is one glossary in `design/localization/` (the folder does not exist yet). Arabic and RTL first; formatting comes from `localization-kernel`; a pseudo-localization test runs. `localization-lead` and `/localize` own the details.

**P-CLEAN — clean architecture from the first line.** `{domain,app,adapters}` per context, dependencies pointing inward, ports at every boundary (`.claude/docs/clean-architecture.md`).

**P-CORE — nothing core-first.** Layer 1 is product code behind core-shaped ports. Extraction is a scheduled `/core-extract`, once the module is stable and a second product needs it.

**P-VERTICAL — platform never imports a vertical.** A vertical implements platform ports (`EndDayBlocker`, entitlement check, floor-view tiles); the platform defines them.

## Recorded Feature Rules

Founder decisions that bind the named specs. `/design-spec` writes each as testable rules; a spec may not contradict them without a new founder decision recorded here.

**Business rules (founder, 2026-10-20, first pass).**
- **End Day** is refused while any bill, session or shift is open (`business-day-end-day`, through the `EndDayBlocker` port). The business day is closed by End Day, not by the clock.
- **Money facts are never rejected.** A money fact that happened at the counter is recorded as it happened and flagged for review (`sync-protocol`, `sync-review-conflicts`).
- **Backdate limits are owner-set** (`owner-limits-reasons`; used by `backdated-start` and any backdated record).
- **X report** for cashiers; **Z report** by a manager or a night-shift role (`x-z-reports`, permissions in `roles-permissions`).
- **Staff add and disable are owner-only** (`staff-records`, `roles-permissions`; ADR-0008 owner-only keys).
- **Remote approval** from the phone or the dashboard is decided; it is designed after the sync ADR and the notifications research (`remote-approval`).

**Void, refund and partial refund (founder, 2026-10-20).** *Void* is before payment: no money was taken. *Refund* is the full amount, after payment. *Partial refund* is part of a paid bill, after payment. All three need a permission and a reason from the reason list. Full and partial refunds are Tier 1: money leaves the drawer and the cash count depends on it (`bill-exceptions` for void; `refunds` for both refunds; recorded in `money-ledger`, `shifts-cash`, `x-z-reports`, `owner-reports`).

**One discount model (founder, 2026-10-20; `discounts`).** At the counter the cashier sees the fixed discounts the owner defined (each a percentage or an amount) and picks one, or chooses *open* and enters a percentage or an amount. Only the discounts the cashier's role allows are shown. Every discount needs a reason and respects the per-role maximum (a permission limit, ADR-0008). A discount applies to the bill or to a line. Every discount is recorded on the bill and the receipt, in the money ledger, the activity trail, the shift close, the Z report and the owner reports. Under P-ONCE, coupons (`coupons-promotions`) and G9's automatic discounts (`advanced-pricing`) apply through this model's port and are recorded the same way; the manual surcharge (G10) stays in `bill-exceptions`.

**G9 time-based pricing (founder, 2026-10-20; `advanced-pricing`).** Covers both automatic discounts and automatic surcharges, by day of week or time of day.

**Tax, service and minimum-charge override hierarchy (founder, 2026-10-20; `tax-service-rules`).** Tax, service charge and minimum charge resolve from the most specific level that sets them: branch default → order type → catalogue category → item (a POS menu item or an inventory item). The most specific wins. Order types are data (rows owned by Orders & Bills): takeaway, drive-thru, delivery, table, session, direct sale/retail, custom item; a restaurant type such as drive-thru or delivery needs no code change later. Each of tax, service charge, minimum charge and rounding is owner-configurable, on or off with its value. The minimum charge keeps its schedule (G11) and can differ by order type, for example on for tables and sessions and off for takeaway. Rounding is per branch only. Tax & Receipts owns the values at every level and their resolution; the caller passes branch, order type, category and item ids.

**Item kinds and recipes (founder, 2026-10-20; `product-catalogue`, `stock-core`, `recipes`, `accessories`).** Every item has one kind, defined in the catalogue and inventory specs: (1) **sold without stock** — a service or station time; (2) **sold with 1:1 stock** — each sale deducts one unit of its stock item; (3) **sold through a recipe** — each sale deducts the recipe's ingredients; (4) **asset, not sold, with a state** — accessories (state per unit, Tier 2); (5) **custom item** — the open item (N1), no stock. Recipes are Tier 1 from day one: when an item has a recipe, stock is deducted through it. Catalogue owns the sellable kinds (1, 2, 3, 5) and the item-to-stock or item-to-recipe link; Inventory owns stock items, recipes and assets (4).

**Venue customer complaints (founder, 2026-10-20; `customer-complaints`, Tier 2).** A complaint carries a reason from the reason list, links to a bill, a session or a station, and optionally to a compensation (a discount or a refund, through their ports). It is in the activity trail and the owner reports. It is venue data, not an Operator Console ticket. The link to a session or station is an opaque subject reference, so the platform does not import the Gaming vertical (P-VERTICAL).

**Accessories (founder, 2026-10-20; `accessories`, Tier 2 with S9).** PS and PC controllers and headsets are stock per branch with a state per unit: available, with a customer, damaged, lost, under repair. `session-extras` (S9) changes a unit's state through the accessories port and charges for extras and for loss or damage.

**Tips (founder, 2026-10-20; `tips`, Tier 1).** The owner enables tips per branch. A tip is recorded per bill and per payment method, is never sales revenue or in the taxable base, is distinct from the service charge, and is shown in the shift close and the Z report.

---

## Bounded Contexts

<!-- Layer in the Kind cell: L1 Kodelix capability, L2 Kodeebo platform, L3 vertical. Core module: Extract-candidate = product-local behind the future saas-core-kotlin port, /core-extract scheduled (umbrella ADR). The two shared kernels and the module contract are not contexts. -->

| # | Context | Kind | Purpose | Owns (data / language) | Owner (agent / person) | Core module? |
|---|---------|------|---------|------------------------|------------------------|--------------|
| 1 | Tenancy & Tenant Lifecycle | L1 · Generic | Tenant isolation, provisioning, closure, export | tenants, tenant_status, import_jobs; scope, resolver | multitenancy-specialist / cto | `tenancy` — Extract-candidate |
| 2 | Identity & Authentication | L1 · Generic | Sign-in on three realms, second factors, recovery, counter PIN | logins, credentials, sessions, PIN verifiers | auth-identity-specialist / security-lead | `identity` (+ `otp`, `ratelimit`) — Extract-candidate |
| 3 | Roles & Permissions | L1 · Generic (catalogue product-only) | Custom roles, permission catalogue, limits, overrides | roles, role assignments, authority snapshot, override grants | auth-identity-specialist / product-manager | `authz` mechanism — Extract-candidate; catalogue Product-only |
| 4 | Audit & Activity Trail | L1 · Generic | One tamper-evident record for every change | activity trail, chain heads | security-lead / principal-engineer | `audit` — Extract-candidate |
| 5 | Operator Console & Support Access | L1 · Generic | Kodelix operator realm, owner-granted support, tickets | operators, support grants, support journal, tickets | security-lead / customer-success | `operator` — Extract-candidate |
| 6 | Licensing & Device Seats | L1 · Generic | Per-device seats, enrolment, offline lease | seats, devices, seat moves, lease log | licensing-specialist / cto | `licensing` — Extract-candidate |
| 7 | Plans, Entitlements & Subscription | L1 · Generic | What a tenant may use, subscription state, invoices | plan catalogue (global), entitlements, limits, subscriptions | pricing-billing-designer / product-director | `billing` — Extract-candidate |
| 8 | Notifications | L1 · Generic | Every email, push and in-app message, once | channels, templates, delivery log | integrations-engineer / product-manager | `notify` — Extract-candidate |
| 9 | Jobs & Outbox | L1 · Generic | Scheduled work and reliable events on PostgreSQL | outbox rows, job state | messaging-specialist / ktor-lead | `jobs` — Extract-candidate |
| 10 | Observability | L1 · Generic | Logs, metrics, traces, SLOs, alerts | pipelines, dashboards, alert rules | observability-engineer / sre-lead | `observability` — Extract-candidate (adopts open source, no fork) |
| 11 | Product Analytics | L1 · Generic | Server-side business events, activation measures | event taxonomy, event records | product-analytics-engineer / product-director | `analytics` — Extract-candidate |
| 12 | Storage & Backup | L1 · Generic | Object storage, backups, restore replay | exports, backups, control journal | infra-engineer / data-lead | `storage` — Extract-candidate |
| 13 | Venue Configuration | L2 · Product-specific | Branches, settings, owner-set limits and reasons | branches, settings, limits, reason lists | product-manager / domain-architect | — |
| 14 | Sync | L2 · Product-specific | Local-first protocol between counter and server | inbox, command log, feeds, review queue | offline-sync-specialist / cto | — |
| 15 | Counter Shell | L2 · Product-specific | The Windows client | local encrypted store, device settings | principal-engineer / ux-designer | — |
| 16 | Catalogue | L2 · Product-specific | Café products and prices | products, categories, price lists | product-manager | — |
| 17 | Orders & Bills | L2 · Product-specific | The bill, its lines and exceptions | bills, lines, tabs, order numbers, order types, discount definitions, applied discounts | product-manager / domain-architect | — |
| 18 | Payments & Tender | L2 · Product-specific | How a bill is paid (method recorded only) | payments, tips, refunds | product-manager | — |
| 19 | Tax & Receipts | L2 · Product-specific | Tax, service, minimum charge, rounding; receipts | tax, service and minimum-charge rule sets (four levels), rounding per branch, receipts, receipt numbers | product-manager / domain-architect | — |
| 20 | Money Ledger | L2 · Product-specific | The append-only record of every money movement | ledger entries | domain-architect / security-lead | — |
| 21 | Shifts, Cash & End Day | L2 · Product-specific | Drawer, shifts, X/Z, business day | shifts, cash counts, paid-outs, expenses, business days | product-manager | — |
| 22 | Staff & Attendance | L2 · Product-specific | People, branch assignment, attendance | staff, branch assignment, attendance | product-manager | — |
| 23 | Inventory | L2 · Product-specific | Stock per branch | stock levels, movements, accessory units, recipes, purchases | product-manager | — |
| 24 | Customers, Loyalty & Complaints | L2 · Product-specific | Customer records, loyalty and venue complaints (PII) | customers, loyalty, price groups, complaints | product-manager / privacy-compliance-specialist | — |
| 25 | Reports & Insights | L2 · Product-specific | Owner-facing read models | report read models | product-manager | — |
| 26 | Fleet Health & Diagnostics | L2 · Product-specific | Device health and crash capture through sync | device heartbeats, crash records | sre-lead / offline-sync-specialist | — (device telemetry may be extracted later) |
| 27 | Client Surfaces | L2 · Product-specific (client, no tables) | Owner web dashboard, Android app, marketing site | UI state only | web-lead / android-lead / design-director | — |
| 28 | Integrations & Webhooks | L2 · Product-specific | Outbound webhooks; external adapters behind ports | webhook endpoints, delivery log | integrations-engineer | — |
| 29 | Gaming Lounge | L3 · Product-specific | Stations and timed sessions | stations, sessions, station price tiers | product-manager / domain-architect | — |
| 30 | Café | L3 · Product-specific | Simple table tabs | café tables | product-manager | — |
| 31 | Restaurant (Later) | L3 · Product-specific | Floor plans, kitchen display, delivery — placeholder | — | — | — |
| 32 | Retail (Later) | L3 · Product-specific | Variants, weight, returns — placeholder | — | — | — |

---

## Features by Context

<!-- One row per feature; spec at `design/specs/<key>.md`. Tags: [T1]/[T2]/[Later] brief tier; [new] not in brief or idea pool; (inferred) = not named in the brief. -->

| # | Feature | Context | Category | Priority | Status | Spec | Depends On |
|---|---------|---------|----------|----------|--------|------|------------|
| 1 | Tenant scope and RLS foundation [T1] | Tenancy & Tenant Lifecycle | Platform | MVP | Not Started | design/specs/tenant-foundation.md | — |
| 2 | Tenant provisioning and guided install [new] (inferred) | Tenancy & Tenant Lifecycle | Admin & Support | MVP | Not Started | design/specs/tenant-provisioning.md | tenant-foundation, dashboard-sign-in, branches-settings, device-seats-enrolment, operator-console |
| 3 | Tenant closure, export and staff erasure [new] (inferred) | Tenancy & Tenant Lifecycle | Admin & Support | MVP | Not Started | design/specs/tenant-closure-export.md | tenant-foundation, jobs-outbox, backup-restore, activity-trail |
| 4 | Demo tenant for referral partners [new] (inferred) | Tenancy & Tenant Lifecycle | Growth | Beta | Not Started | design/specs/demo-tenant.md | tenant-provisioning, product-catalogue, stations-catalogue |
| 5 | Onboarding data import, CSV/Excel [Later] | Tenancy & Tenant Lifecycle | Admin & Support | Full Vision | Not Started | design/specs/data-import.md | tenant-provisioning, product-catalogue, staff-records, customers, jobs-outbox |
| 6 | Dashboard sign-in, 2FA, passkeys, recovery [T1] | Identity & Authentication | Platform | MVP | Not Started | design/specs/dashboard-sign-in.md | tenant-foundation, owner-alerts |
| 7 | Counter PIN enrolment and sign-in (W8) [T1] | Identity & Authentication | Platform | MVP | Not Started | design/specs/counter-pin.md | dashboard-sign-in, staff-records, counter-shell, roles-permissions |
| 8 | Roles and permission catalogue (W5) [T1] | Roles & Permissions | Platform | MVP | Not Started | design/specs/roles-permissions.md | dashboard-sign-in, activity-trail |
| 9 | One-shot override on the counter [new] (inferred) | Roles & Permissions | Platform | MVP | Not Started | design/specs/counter-overrides.md | roles-permissions, counter-pin, counter-shell |
| 10 | Remote approval from phone or dashboard [new] | Roles & Permissions | Platform | Beta | Not Started | design/specs/remote-approval.md | counter-overrides, sync-feeds, push-notifications, dashboard-shell |
| 11 | Activity trail (P6) [T1] | Audit & Activity Trail | Platform | MVP | Not Started | design/specs/activity-trail.md | tenant-foundation |
| 12 | Operator console [new] (inferred) | Operator Console & Support Access | Admin & Support | MVP | Not Started | design/specs/operator-console.md | tenant-foundation, activity-trail |
| 13 | Owner-granted support access and diagnostic bundle [new] (inferred) | Operator Console & Support Access | Admin & Support | MVP | Not Started | design/specs/support-access.md | operator-console, activity-trail |
| 14 | Kodelix support tickets (D5) [T2] | Operator Console & Support Access | Admin & Support | Beta | Not Started | design/specs/support-desk.md | operator-console, owner-alerts |
| 15 | Device seats and enrolment (D1-A) [T1] | Licensing & Device Seats | Billing & Licensing | MVP | Not Started | design/specs/device-seats-enrolment.md | tenant-foundation, dashboard-sign-in, plans-entitlements |
| 16 | Offline lease and N5 grace [T1] | Licensing & Device Seats | Billing & Licensing | MVP | Not Started | design/specs/offline-lease.md | device-seats-enrolment, sync-protocol, subscription-control, money-time-rules |
| 17 | Plans and entitlements, minimum: modules and limits per tenant (P1) [T2] | Plans, Entitlements & Subscription | Billing & Licensing | MVP | Not Started | design/specs/plans-entitlements.md | tenant-foundation |
| 18 | Plan tiers and per-tenant overrides (P2) [T2] | Plans, Entitlements & Subscription | Billing & Licensing | Beta | Not Started | design/specs/plan-tiers-overrides.md | plans-entitlements |
| 19 | Subscription control, active or suspended (N5) [T1] | Plans, Entitlements & Subscription | Billing & Licensing | MVP | Not Started | design/specs/subscription-control.md | plans-entitlements, operator-console |
| 20 | Subscription billing and invoices [new] (inferred) | Plans, Entitlements & Subscription | Billing & Licensing | Beta | Not Started | design/specs/subscription-billing.md | plans-entitlements, subscription-control |
| 21 | Referral partner tracking [new] (inferred) | Plans, Entitlements & Subscription | Growth | Full Vision | Not Started | design/specs/referral-partners.md | subscription-billing |
| 22 | Owner alerts, email and in-app (D3) [T2] | Notifications | Integrations | MVP | Not Started | design/specs/owner-alerts.md | jobs-outbox, localization-kernel |
| 23 | Push notifications [new] (inferred) | Notifications | Integrations | Beta | Not Started | design/specs/push-notifications.md | owner-alerts |
| 24 | Jobs and transactional outbox [new] (inferred) | Jobs & Outbox | Platform | MVP | Not Started | design/specs/jobs-outbox.md | tenant-foundation |
| 25 | Telemetry pipeline [new] (inferred) | Observability | Platform | MVP | Not Started | design/specs/telemetry-pipeline.md | — |
| 26 | SLOs, alerting and runbooks [new] (inferred) | Observability | Platform | MVP | Not Started | design/specs/slos-alerting.md | telemetry-pipeline, owner-alerts |
| 27 | Event taxonomy and server-side business events [new] (inferred) | Product Analytics | Insights | MVP | Not Started | design/specs/event-taxonomy-analytics.md | tenant-foundation |
| 28 | Backups and restore drill [new] (inferred) | Storage & Backup | Platform | MVP | Not Started | design/specs/backup-restore.md | tenant-foundation |
| 29 | Branches and venue settings (P3) [T1] | Venue Configuration | Platform | MVP | Not Started | design/specs/branches-settings.md | tenant-foundation, roles-permissions |
| 30 | Owner-set limits and reason lists (P5) [T1] | Venue Configuration | Platform | MVP | Not Started | design/specs/owner-limits-reasons.md | branches-settings, roles-permissions |
| 31 | Sync protocol: commands, ordering, idempotency (F1, F2) [T1] | Sync | Platform | Vertical Slice | Not Started | design/specs/sync-protocol.md | tenant-foundation, device-seats-enrolment, money-time-rules |
| 32 | Server-to-device feeds (F1) [T1] | Sync | Platform | Vertical Slice | Not Started | design/specs/sync-feeds.md | sync-protocol, branches-settings, roles-permissions |
| 33 | Sync states, review queue and clone/restore detection (F3, F4) [T1] | Sync | Platform | MVP | Not Started | design/specs/sync-review-conflicts.md | sync-protocol, money-ledger, owner-alerts |
| 34 | Counter app shell: runtime, encrypted store, start check, salvage [T1] | Counter Shell | Client surfaces | Vertical Slice | Not Started | design/specs/counter-shell.md | sync-protocol, localization-kernel, money-time-rules |
| 35 | Receipt printing and cash drawer (D1) [T1] | Counter Shell | Client surfaces | Vertical Slice | Not Started | design/specs/counter-printing-drawer.md | counter-shell, localization-kernel |
| 36 | Counter installer, updater and minimum version [new] (inferred) | Counter Shell | Client surfaces | MVP | Not Started | design/specs/counter-install-update.md | counter-shell, sync-protocol |
| 37 | Kitchen and bar printers, displays (D1) [T2] | Counter Shell | Client surfaces | Beta | Not Started | design/specs/kitchen-bar-printers-displays.md | counter-printing-drawer |
| 38 | Product catalogue (I1) [T1] | Catalogue | Core domain | Vertical Slice | Not Started | design/specs/product-catalogue.md | tenant-foundation, branches-settings |
| 39 | Bills and tabs: quick sale, open tab, daily order numbers (O1, O2, O7) [T1] | Orders & Bills | Core domain | Vertical Slice | Not Started | design/specs/bills-and-tabs.md | product-catalogue, tax-service-rules |
| 40 | Void, manual surcharge and open item with reasons (O6, G10 surcharge, N1) [T1] | Orders & Bills | Core domain | MVP | Not Started | design/specs/bill-exceptions.md | bills-and-tabs, roles-permissions, counter-overrides, owner-limits-reasons, activity-trail |
| 41 | Discounts: one model — owner-defined fixed discounts and open discounts, per role, on the bill or a line (G10) [T1] | Orders & Bills | Core domain | MVP | Not Started | design/specs/discounts.md | bills-and-tabs, tax-service-rules, roles-permissions, owner-limits-reasons, money-ledger, activity-trail |
| 42 | Move, split and merge orders (O4) [T2] | Orders & Bills | Core domain | Beta | Not Started | design/specs/order-restructure.md | bills-and-tabs, bill-exceptions |
| 43 | Coupons and promotions (D2) [T2] | Orders & Bills | Core domain | Beta | Not Started | design/specs/coupons-promotions.md | bills-and-tabs, discounts, owner-limits-reasons |
| 44 | Payments and tender, method recorded only (O3) [T1] | Payments & Tender | Core domain | Vertical Slice | Not Started | design/specs/payments-tender.md | bills-and-tabs, money-ledger |
| 45 | Tips (gratuity) [T1] (founder, 2026-10-20) | Payments & Tender | Core domain | MVP | Not Started | design/specs/tips.md | payments-tender, money-ledger, tax-service-rules, branches-settings |
| 46 | Full and partial refund after payment (O5) [T1] (founder, 2026-10-20; was Tier 2) | Payments & Tender | Core domain | MVP | Not Started | design/specs/refunds.md | payments-tender, bill-exceptions, money-ledger, roles-permissions, owner-limits-reasons, activity-trail |
| 47 | Tax, service charge, minimum charge and rounding rules, with the override hierarchy (G11) [T1] | Tax & Receipts | Core domain | Vertical Slice | Not Started | design/specs/tax-service-rules.md | money-time-rules, branches-settings, product-catalogue |
| 48 | Receipt content, numbering and ETA-ready fields [T1] | Tax & Receipts | Core domain | MVP | Not Started | design/specs/receipts-numbering.md | tax-service-rules, discounts, counter-printing-drawer, localization-kernel |
| 49 | ETA e-receipt submission [new] | Tax & Receipts | Integrations | Beta | Not Started | design/specs/eta-e-receipt.md | receipts-numbering, jobs-outbox |
| 50 | Money ledger (O8) [T1] | Money Ledger | Core domain | Vertical Slice | Not Started | design/specs/money-ledger.md | tenant-foundation, money-time-rules, activity-trail |
| 51 | Shifts and cash count (W1) [T1] | Shifts, Cash & End Day | Core domain | MVP | Not Started | design/specs/shifts-cash.md | money-ledger, payments-tender, tips, refunds, discounts, roles-permissions |
| 52 | Paid-outs from the drawer (W2) [T1] | Shifts, Cash & End Day | Core domain | MVP | Not Started | design/specs/paid-outs.md | shifts-cash, owner-limits-reasons, bill-exceptions |
| 53 | X and Z reports (W3) [T1] | Shifts, Cash & End Day | Core domain | MVP | Not Started | design/specs/x-z-reports.md | shifts-cash, paid-outs, tips, refunds, discounts, roles-permissions |
| 54 | Business day and End Day (W4) [T1] | Shifts, Cash & End Day | Core domain | MVP | Not Started | design/specs/business-day-end-day.md | shifts-cash, x-z-reports, vertical-module-contract |
| 55 | Expenses against approved reasons (I5) [T2] | Shifts, Cash & End Day | Core domain | Beta | Not Started | design/specs/expenses.md | paid-outs, owner-limits-reasons |
| 56 | Staff records and branch assignment (W5) [T1] | Staff & Attendance | Platform | MVP | Not Started | design/specs/staff-records.md | tenant-foundation, branches-settings, dashboard-sign-in |
| 57 | Clock in and out (W6) [T1] | Staff & Attendance | Core domain | MVP | Not Started | design/specs/clock-in-out.md | staff-records, counter-pin |
| 58 | Work contracts, attendance summaries, payroll (W7) [T2] | Staff & Attendance | Core domain | Beta | Not Started | design/specs/payroll-contracts.md | clock-in-out |
| 59 | Stock per branch, deduction, adjustments, transfers (I1) [T1] | Inventory | Core domain | MVP | Not Started | design/specs/stock-core.md | product-catalogue, bills-and-tabs, branches-settings |
| 60 | Accessories: controllers and headsets as units per branch with a state per unit [new] [T2] (founder, 2026-10-20; with S9) | Inventory | Core domain | Beta | Not Started | design/specs/accessories.md | stock-core, branches-settings, activity-trail |
| 61 | Low-stock alerts (I2) [T2] | Inventory | Core domain | Beta | Not Started | design/specs/low-stock-alerts.md | stock-core, owner-alerts |
| 62 | Recipes, stock deducted through the recipe (I3) [T1] (founder, 2026-10-20; was Tier 2) | Inventory | Core domain | MVP | Not Started | design/specs/recipes.md | stock-core, product-catalogue |
| 63 | Suppliers, purchase invoices, receiving, supplier payments (I4) [T2] | Inventory | Core domain | Beta | Not Started | design/specs/purchasing-suppliers.md | stock-core, money-ledger |
| 64 | Customer records and walk-ins (C1) [T2] | Customers, Loyalty & Complaints | Core domain | Beta | Not Started | design/specs/customers.md | tenant-foundation, bills-and-tabs |
| 65 | Loyalty points and price groups (C3, C4) [T2] | Customers, Loyalty & Complaints | Core domain | Beta | Not Started | design/specs/loyalty-price-groups.md | customers, session-pricing |
| 66 | Venue customer complaints: reason, linked bill, session or station, optional compensation [new] [T2] (founder, 2026-10-20) | Customers, Loyalty & Complaints | Core domain | Beta | Not Started | design/specs/customer-complaints.md | owner-limits-reasons, bills-and-tabs, discounts, refunds, activity-trail |
| 67 | Owner reports: daily report and cash reconciliation [T1] | Reports & Insights | Insights | MVP | Not Started | design/specs/owner-reports.md | money-ledger, shifts-cash, business-day-end-day, discounts, refunds, sync-protocol |
| 68 | Fleet health: heartbeat, version, sync lag, offline age [new] (inferred) | Fleet Health & Diagnostics | Admin & Support | MVP | Not Started | design/specs/fleet-health.md | sync-protocol, operator-console, telemetry-pipeline |
| 69 | Crash capture through sync [new] (inferred) | Fleet Health & Diagnostics | Admin & Support | MVP | Not Started | design/specs/crash-capture.md | fleet-health, sync-protocol, counter-shell |
| 70 | Owner dashboard shell and navigation (N2) [T1] | Client Surfaces | Client surfaces | Vertical Slice | Not Started | design/specs/dashboard-shell.md | dashboard-sign-in, localization-kernel, roles-permissions |
| 71 | Dashboard: activity log and report views (N2) [T1] | Client Surfaces | Client surfaces | Vertical Slice | Not Started | design/specs/dashboard-reports-activity.md | dashboard-shell, activity-trail, money-ledger |
| 72 | Dashboard: live floor and real-time updates (N2, S12) [T1] | Client Surfaces | Client surfaces | MVP | Not Started | design/specs/dashboard-live-floor.md | dashboard-shell, sync-feeds, sessions |
| 73 | Dashboard: configuration screens (N2) [T1] | Client Surfaces | Client surfaces | MVP | Not Started | design/specs/dashboard-config.md | dashboard-shell, branches-settings, owner-limits-reasons, staff-records, roles-permissions |
| 74 | Owner Android app, PWA in a Play wrapper (D6) [T1] | Client Surfaces | Client surfaces | MVP | Not Started | design/specs/owner-android-app.md | dashboard-shell |
| 75 | Marketing site [new] (inferred) | Client Surfaces | Client surfaces | Beta | Not Started | design/specs/marketing-site.md | localization-kernel |
| 76 | Webhooks (D4) [T2] | Integrations & Webhooks | Integrations | Beta | Not Started | design/specs/webhooks.md | jobs-outbox, roles-permissions |
| 77 | Station catalogue: category, type, unit, PCs as timed stations (G1) [T1] | Gaming Lounge | Core domain | Vertical Slice | Not Started | design/specs/stations-catalogue.md | tenant-foundation, branches-settings, vertical-module-contract |
| 78 | Hourly pricing, price tiers, minimum minutes, frozen prices, tier change (G2, G5, G12, N4) [T1] | Gaming Lounge | Core domain | Vertical Slice | Not Started | design/specs/session-pricing.md | stations-catalogue, money-time-rules, tax-service-rules |
| 79 | Sessions: start, end, move, cancel, timer, café items on the tab (S1, S3–S6, S10) [T1] | Gaming Lounge | Core domain | Vertical Slice | Not Started | design/specs/sessions.md | session-pricing, bills-and-tabs, vertical-module-contract |
| 80 | Live floor view on the counter (S12) [T1] | Gaming Lounge | Core domain | MVP | Not Started | design/specs/floor-view.md | sessions, counter-shell |
| 81 | Fixed price, free minutes, unit price, and automatic time-based pricing — discounts and surcharges by day of week or time of day (G4, G6, G7, G9) [T2] | Gaming Lounge | Core domain | Beta | Not Started | design/specs/advanced-pricing.md | session-pricing, discounts |
| 82 | Session extras and lost/damaged tracking (S9) [T2] | Gaming Lounge | Core domain | Beta | Not Started | design/specs/session-extras.md | sessions, accessories |
| 83 | Backdated start with an approver (S7) [T2] | Gaming Lounge | Core domain | Beta | Not Started | design/specs/backdated-start.md | sessions, counter-overrides, owner-limits-reasons |
| 84 | Station power and network control (S11) [T2] | Gaming Lounge | Core domain | Beta | Not Started | design/specs/station-control.md | sessions |
| 85 | Automatic PC lock and unlock agent (N6) [T2] | Gaming Lounge | Core domain | Beta | Not Started | design/specs/pc-lock-agent.md | sessions, station-control |
| 86 | Café table tab (N3) [T1] | Café | Core domain | MVP | Not Started | design/specs/cafe-table-tabs.md | bills-and-tabs, vertical-module-contract |
| 87 | Money and time rules kernel [new] (inferred) | Shared kernel | Platform | MVP | Not Started | design/specs/money-time-rules.md | — |
| 88 | Localization kernel: AR/EN, RTL, EGP, Africa/Cairo (P4) [T1] | Shared kernel | Platform | MVP | Not Started | design/specs/localization-kernel.md | — |
| 89 | Vertical module contract [new] (inferred) | Shared kernel | Platform | MVP | Not Started | design/specs/vertical-module-contract.md | plans-entitlements, tenant-foundation |

---

## Categories

| Category | Description | Typical Features |
|----------|-------------|------------------|
| **Platform** | Foundations everything depends on | Tenancy, identity, roles, trail, settings, sync, jobs, kernels |
| **Core domain** | What the customer actually pays for | Sessions, bills, payments, ledger, shifts, stock |
| **Billing & Licensing** | Money and entitlements | Plans, subscription control, device seats, offline lease |
| **Integrations** | External systems | Notifications, ETA, webhooks |
| **Admin & Support** | Operating the product | Operator console, support access, provisioning, fleet health |
| **Growth** | Acquisition and retention | Demo tenant, referral partners |
| **Insights** | Analytics and reporting | Owner reports, event taxonomy |
| **Client surfaces** | Apps and sites | Counter shell, owner dashboard, Android app, marketing site |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Specification Urgency |
|------|------------|------------------|----------------------|
| **MVP** | Tier 1 of the brief (what the 3 customers need to switch) plus the foundations under it; 48 features | M2 private beta, M3 release | Foundations first (orders 1–19); breadth after the vertical slice (orders 34–62) |
| **Vertical Slice** | The M1 journey: start session, add a café item, close and pay, sync, see it on the owner dashboard; 14 features | M1 vertical slice | Specify between the MVP foundations and the rest of the MVP, following the brief's build order |
| **Beta** | Tier 2 of the brief and the post-Tier-1 increments (ETA, push, billing); 25 features | After the Tier 1 release | Specify third |
| **Full Vision** | Later items with a spec (onboarding import, referral tracking); 2 features. Restaurant and Retail have no specs | M4+ | Specify as needed |

---

## Dependency Map

### Foundation Layer (no dependencies beyond ADRs)

1. `tenant-foundation` — scope helper, RLS roles, resolver (ADR-0001..0003; ADR-covered, short spec).
2. `money-time-rules`, `localization-kernel` — shared kernels; no data.
3. `jobs-outbox`, `activity-trail` — need tenancy.
4. `owner-alerts` — the Notifications email port that sign-in recovery uses; needs jobs and localization.
5. `dashboard-sign-in`, `roles-permissions` — need tenancy, audit and the email port.
6. `plans-entitlements` (minimum), `vertical-module-contract`.
7. `telemetry-pipeline`, `event-taxonomy-analytics`.
8. `branches-settings`, `owner-limits-reasons`, `staff-records`.
9. `device-seats-enrolment` — needs identity, plans and the credential ADR.

### Core Layer (depends on foundation)

1. `operator-console`, `support-access` — depend on the operator realm, tenancy, audit.
2. `subscription-control` — depends on plans-entitlements and operator-console.
3. `sync-protocol`, `sync-feeds` — depend on device seats and the sync ADR.
4. `counter-shell` — depends on sync, the desktop ADR and the kernels.
5. `product-catalogue`, `stations-catalogue`, `session-pricing`.

### Feature Layer (depends on core)

1. `sessions`, `bills-and-tabs`, `tax-service-rules`, `payments-tender`, `money-ledger`, `counter-printing-drawer`, `cafe-table-tabs`.
2. `counter-pin`, `counter-overrides`, `bill-exceptions`, `discounts`, `tips`, `refunds`, `receipts-numbering`.
3. `shifts-cash`, `paid-outs`, `x-z-reports`, `business-day-end-day` — depend on the ledger, payments, roles and the `EndDayBlocker` port.
4. `offline-lease` — depends on device seats, sync, subscription control.
5. `sync-review-conflicts`, `stock-core`, `recipes`, `clock-in-out`, `floor-view`.
6. `fleet-health`, `crash-capture` — depend on sync, observability, the console.
7. `tenant-provisioning`, `tenant-closure-export`, `counter-install-update`, `owner-reports`.

### Presentation Layer (depends on features)

1. `dashboard-shell`, `dashboard-reports-activity`, `dashboard-live-floor` (needs the dashboard real-time ADR), `dashboard-config`.
2. `owner-android-app` (needs the owner-client ADR; spikes S32/S33).

### Hardening Layer (depends on everything)

1. `slos-alerting`, `backup-restore` drills, `event-taxonomy-analytics` views.
2. Beta and Full Vision features hang off the layers above.

**Bottlenecks** (many dependents, high risk): Tenancy; Identity; Roles & Permissions; Sync (all counter data; gated by the sync spike's phases 4–5); Orders & Bills (gaming, café, payments, ledger, inventory, shifts); the `money-time-rules` kernel; Counter Shell (gated by the desktop ADR).

**Leaf nodes** (specify late): `webhooks`, `pc-lock-agent`, `station-control`, `loyalty-price-groups`, `payroll-contracts`, `marketing-site`, `referral-partners`, `data-import`; the Restaurant and Retail placeholders.

---

## Ownership & Data Boundaries

| Data / capability | Owning context | Read by | Access path (API / event / read model) |
|-------------------|----------------|---------|---------------------------------------|
| tenants, tenant_status (CP) | Tenancy & Tenant Lifecycle | Plans, Licensing, Jobs, Operator Console | Tenancy port; job scheduler lists ids as `platform_rt` |
| logins, credentials, sessions (PL) | Identity & Authentication | every authenticated context | `LoginLookup`, session port; never the tables |
| roles, assignments, authority snapshot | Roles & Permissions | Sync (feed), Counter Shell, all use cases | `PermissionChecker` port; snapshot in the config feed |
| activity trail | Audit & Activity Trail | Dashboard, Operator Console | `ActivityTrail.record`; read model for views |
| operators, support grants, support journal | Operator Console & Support Access | Tenancy (`SupportGrants`), Audit | Grant port; support verbs only |
| seats, devices, seat moves, lease log (TD) | Licensing & Device Seats | Sync, Counter Shell, Operator Console | `DeviceCredentialVerifier`, lease items as opaque feed payloads |
| plan catalogue (G), entitlements, limits, subscription state | Plans, Entitlements & Subscription | Licensing, verticals, Counter Shell, Dashboard | `EntitlementChecker` port; event `tenant_suspended` |
| notification channels, templates, delivery log | Notifications | any context that notifies | `Notifier` port; the caller passes the recipient |
| outbox rows, job state | Jobs & Outbox | every context that emits events | outbox port; per-tenant sweep |
| branches, settings, owner limits, reason lists | Venue Configuration | Tax & Receipts, Orders, Shifts, Gaming, Sync (feed) | settings port; config feed to devices |
| inbox, command log, feeds, review queue | Sync | Reports, Fleet Health, Dashboard | command ports of the owning contexts; review-queue read model |
| local encrypted store (device) | Counter Shell | — | device-local; synced only through Sync |
| products, categories, price lists | Catalogue | Orders, Gaming, Inventory | catalogue port |
| bills, lines, tabs, order numbers | Orders & Bills | Payments, Ledger, Reports | bill port; lines carry an opaque `source` id |
| order types (data) | Orders & Bills | Tax & Receipts, verticals, Dashboard | order-type port; tax rules receive the id as a caller-passed value |
| discount definitions, applied discounts | Orders & Bills | Tax & Receipts (receipt), Ledger, Shifts, Reports, Coupons, Gaming (G9) | `Discounts` port; entries to the ledger and the trail |
| payments, tips, refunds | Payments & Tender | Ledger, Shifts, Reports | payment port; entries to the ledger |
| tax, service and minimum-charge rule sets at four levels, rounding per branch, receipts, receipt numbers | Tax & Receipts | Orders, Gaming, Counter Shell, ETA adapter, Dashboard | rule resolution (most specific wins) with caller-passed branch, order type, category and item ids; receipt port. All rule values, branch level included, are owned here (moved from Venue Configuration, 2026-10-20) |
| ledger entries | Money Ledger | Shifts, Reports, Dashboard | `Ledger.append` only; read models for views |
| shifts, cash counts, paid-outs, expenses, business days | Shifts, Cash & End Day | Reports, Dashboard | shift port; `EndDayBlocker` implemented by verticals |
| staff, branch assignment, attendance | Staff & Attendance | Roles, Identity, Shifts, Reports | staff port; staff feed |
| stock levels, movements, accessory units, recipes, purchases | Inventory | Orders, Reports | stock port; movements as commands |
| customers, loyalty, price groups (PII) | Customers, Loyalty & Complaints | Orders, Gaming | customer port |
| complaints | Customers, Loyalty & Complaints | Reports, Dashboard, Audit | complaint port; opaque subject reference (bill, session, station); compensation through the `Discounts` and refund ports |
| report read models | Reports & Insights | Dashboard | read-model API |
| device heartbeats, crash records | Fleet Health & Diagnostics | Operator Console | read model for console views |
| webhook endpoints, delivery log | Integrations & Webhooks | — | outbox-driven delivery |
| stations, sessions, station price tiers | Gaming Lounge | Orders (lines), Shifts (blocker), Dashboard, Counter Shell | session port; opaque `source` on bill lines |
| café tables | Café | Orders | café port |
| import jobs, uploaded import files | Tenancy & Tenant Lifecycle | — | calls Catalogue, Staff, Customers command ports; never their tables |
| event records, event taxonomy | Product Analytics | Operator Console views | `AnalyticsEvent.emit` |
| exports, backups, control journal | Storage & Backup | Tenancy (closure), Sync (restore replay) | storage port |

**Tenant-scoped (TD):** orders, ledger, shifts, staff, stock, catalogue, sync inbox, seats, import jobs, the trail. **Control plane (CP):** tenant status, usage counts, restore watermark. **Global (G):** plan catalogue, tax-rate tables, retention table. **Operator realm (OP):** no tenant. **Pre-context lookup (PL):** login identities, sessions, device credentials. No entity is claimed by two contexts.

---

## Recommended Specification Order

| Order | Feature | Priority | Layer | Agent(s) | Est. Effort |
|-------|---------|----------|-------|----------|-------------|
| 1 | tenant-foundation | MVP | Foundation | multitenancy-specialist, domain-architect | S |
| 2 | money-time-rules | MVP | Foundation | domain-architect, principal-engineer | L |
| 3 | localization-kernel | MVP | Foundation | localization-lead | M |
| 4 | jobs-outbox | MVP | Foundation | messaging-specialist, ktor-lead | M |
| 5 | activity-trail | MVP | Foundation | security-lead, product-manager | M |
| 6 | owner-alerts | MVP | Foundation | integrations-engineer, product-manager | M |
| 7 | dashboard-sign-in | MVP | Foundation | auth-identity-specialist | M |
| 8 | roles-permissions | MVP | Foundation | auth-identity-specialist, product-manager | M |
| 9 | plans-entitlements | MVP | Foundation | pricing-billing-designer | M |
| 10 | vertical-module-contract | MVP | Foundation | domain-architect, principal-engineer | M |
| 11 | telemetry-pipeline | MVP | Foundation | observability-engineer | S |
| 12 | event-taxonomy-analytics | MVP | Foundation | product-analytics-engineer | M |
| 13 | branches-settings | MVP | Foundation | product-manager | S |
| 14 | owner-limits-reasons | MVP | Foundation | product-manager | M |
| 15 | staff-records | MVP | Foundation | product-manager, auth-identity-specialist | M |
| 16 | device-seats-enrolment | MVP | Foundation | licensing-specialist | L |
| 17 | operator-console | MVP | Core | product-manager, auth-identity-specialist | M |
| 18 | support-access | MVP | Core | security-lead | M |
| 19 | subscription-control | MVP | Core | pricing-billing-designer, licensing-specialist | M |
| 20 | sync-protocol | Vertical Slice | Core | offline-sync-specialist, domain-architect | L |
| 21 | sync-feeds | Vertical Slice | Core | offline-sync-specialist | L |
| 22 | counter-shell | Vertical Slice | Core | principal-engineer, ux-designer | L |
| 23 | product-catalogue | Vertical Slice | Core | product-manager | M |
| 24 | stations-catalogue | Vertical Slice | Core | product-manager | M |
| 25 | tax-service-rules | Vertical Slice | Feature | product-manager, domain-architect | M |
| 26 | session-pricing | Vertical Slice | Core | product-manager, domain-architect | L |
| 27 | bills-and-tabs | Vertical Slice | Feature | product-manager | M |
| 28 | sessions | Vertical Slice | Feature | product-manager | L |
| 29 | money-ledger | Vertical Slice | Feature | domain-architect, security-lead | M |
| 30 | payments-tender | Vertical Slice | Feature | product-manager | M |
| 31 | counter-printing-drawer | Vertical Slice | Feature | principal-engineer | M |
| 32 | dashboard-shell | Vertical Slice | Presentation | web-lead, ux-designer | M |
| 33 | dashboard-reports-activity | Vertical Slice | Presentation | web-lead, product-manager | M |
| 34 | counter-pin | MVP | Feature | auth-identity-specialist | M |
| 35 | counter-overrides | MVP | Feature | auth-identity-specialist, product-manager | L |
| 36 | bill-exceptions | MVP | Feature | product-manager | M |
| 37 | discounts | MVP | Feature | product-manager, domain-architect | M |
| 38 | tips | MVP | Feature | product-manager, domain-architect | M |
| 39 | refunds | MVP | Feature | product-manager | M |
| 40 | receipts-numbering | MVP | Feature | product-manager | M |
| 41 | shifts-cash | MVP | Feature | product-manager | M |
| 42 | paid-outs | MVP | Feature | product-manager | S |
| 43 | x-z-reports | MVP | Feature | product-manager | M |
| 44 | business-day-end-day | MVP | Feature | product-manager, domain-architect | L |
| 45 | cafe-table-tabs | MVP | Feature | product-manager | S |
| 46 | floor-view | MVP | Feature | product-manager, ux-designer | M |
| 47 | offline-lease | MVP | Feature | licensing-specialist, security-lead | L |
| 48 | sync-review-conflicts | MVP | Feature | offline-sync-specialist | L |
| 49 | clock-in-out | MVP | Feature | product-manager | S |
| 50 | stock-core | MVP | Feature | product-manager | L |
| 51 | recipes | MVP | Feature | product-manager | M |
| 52 | owner-reports | MVP | Feature | product-manager | M |
| 53 | fleet-health | MVP | Feature | sre-lead, offline-sync-specialist | M |
| 54 | crash-capture | MVP | Feature | sre-lead, offline-sync-specialist | M |
| 55 | counter-install-update | MVP | Feature | principal-engineer, release-manager | M |
| 56 | dashboard-live-floor | MVP | Presentation | web-lead | M |
| 57 | dashboard-config | MVP | Presentation | web-lead, product-manager | L |
| 58 | owner-android-app | MVP | Presentation | android-lead | M |
| 59 | tenant-provisioning | MVP | Hardening | product-manager, customer-success | M |
| 60 | backup-restore | MVP | Hardening | data-lead, sre-lead | M |
| 61 | tenant-closure-export | MVP | Hardening | multitenancy-specialist, privacy-compliance-specialist | L |
| 62 | slos-alerting | MVP | Hardening | sre-lead, observability-engineer | M |
| 63 | order-restructure | Beta | Feature | product-manager | M |
| 64 | coupons-promotions | Beta | Feature | product-manager | M |
| 65 | customers | Beta | Feature | product-manager, privacy-compliance-specialist | M |
| 66 | loyalty-price-groups | Beta | Feature | product-manager | M |
| 67 | customer-complaints | Beta | Feature | product-manager, privacy-compliance-specialist | M |
| 68 | expenses | Beta | Feature | product-manager | S |
| 69 | low-stock-alerts | Beta | Feature | product-manager | S |
| 70 | accessories | Beta | Feature | product-manager | S |
| 71 | purchasing-suppliers | Beta | Feature | product-manager | L |
| 72 | payroll-contracts | Beta | Feature | product-manager | M |
| 73 | advanced-pricing | Beta | Feature | product-manager, domain-architect | L |
| 74 | session-extras | Beta | Feature | product-manager | M |
| 75 | backdated-start | Beta | Feature | product-manager, security-lead | M |
| 76 | station-control | Beta | Feature | product-manager, principal-engineer | M |
| 77 | pc-lock-agent | Beta | Feature | principal-engineer, security-lead | L |
| 78 | kitchen-bar-printers-displays | Beta | Feature | principal-engineer | M |
| 79 | plan-tiers-overrides | Beta | Feature | pricing-billing-designer | M |
| 80 | subscription-billing | Beta | Feature | pricing-billing-designer, integrations-engineer | L |
| 81 | push-notifications | Beta | Feature | integrations-engineer | M |
| 82 | remote-approval | Beta | Feature | auth-identity-specialist, product-manager | L |
| 83 | support-desk | Beta | Feature | customer-success | M |
| 84 | webhooks | Beta | Feature | integrations-engineer, api-designer | M |
| 85 | eta-e-receipt | Beta | Feature | integrations-engineer | L |
| 86 | demo-tenant | Beta | Feature | customer-success | S |
| 87 | marketing-site | Beta | Presentation | astro-specialist, design-director | M |
| 88 | data-import | Full Vision | Feature | product-manager, privacy-compliance-specialist | L |
| 89 | referral-partners | Full Vision | Feature | sales-lead, product-manager | S |

[Effort: S = 1 session, M = 2–3 sessions, L = 4+ sessions. A spec that depends on a pending ADR (next section) waits for it. `eta-e-receipt` moves into Tier 1 if the ETA per-venue inquiry puts a founding venue on an e-receipt list (brief, risk 7).]

---

## Circular Dependencies

No true cycle remains. Eight apparent cycles are broken by an explicit decision, recorded here (founder, 2026-10-20).

| Apparent cycle | Resolution | Kind |
|----------------|-----------|------|
| End Day (platform) needs open sessions (vertical) | Platform owns the `EndDayBlocker` port; each vertical implements it. End Day is refused while any bill, session or shift is open | Port |
| Sessions ↔ Orders | Gaming depends on Orders; bill lines carry an opaque `source` id; Orders never imports Gaming | Port / opaque id |
| Sync ↔ every context | Sync calls each context's command port; contexts write through a domain-owned command-log port that Sync implements. A money fact is never rejected: Sync records it and flags it for review | Port |
| Licensing ↔ Sync | Licensing owns device credentials and the lease; the lease travels as an opaque feed item. Sync depends on a Licensing `DeviceCredentialVerifier` port; Licensing never imports Sync | Port |
| Plans ↔ Licensing | Licensing reads plan claims and subscribes to `tenant_suspended`; Plans does not depend on Licensing | One-direction event |
| Identity ↔ Notifications | The caller passes the recipient; Notifications never looks up identity | Caller-passed value |
| Fleet Health ↔ Operator Console | The console reads a Fleet Health read model; Fleet Health does not depend on the console | One-direction read model |
| Tax & Receipts ↔ Orders & Bills (order types) | Bills need tax rules; tax rules resolve by order type, which Orders owns. The caller passes branch, order type, category and item ids; tax rules never import Orders (founder decision 2026-10-20, recorded with the hierarchy) | Caller-passed value |

---

## Still-Missing ADRs and Research

Ordered by what unblocks the specification order. Every item is `NOT DONE`; none is written by this skill.

| # | Item | Kind | Unblocks | Trigger / note |
|---|------|------|----------|----------------|
| 1 | Sync ADR (OQ3, 5, 6, 7, 13, 27, 29, 30 and OQ31 salvage) | ADR | sync-protocol, sync-feeds, sync-review-conflicts, fleet-health, crash-capture | After the sync spike's phases 4 and 5 |
| 2 | Desktop-runtime ADR (Compose Desktop or Electron); sets `stack.desktop` | ADR | counter-shell and everything on the counter | After the sync spike's phase 5 |
| 3 | Core-extraction policy (umbrella): what is local, why, extraction trigger per Layer 1 module | ADR | every Layer 1 story | Before the first Layer 1 story; `/core-extract` scheduled per module |
| 4 | Module-structure and architecture-test ADR: which contexts share a Gradle module, P-ONCE enforcement (test tool by `/research`, for example Konsist or ArchUnit) | ADR + research | first backend story | Before the first backend story |
| 5 | **Jobs / outbox ADR**: PostgreSQL scheduler and outbox, table class (registry `FP-QUEUE-WITHOUT-ADR-R2`); decides whether `stack.messaging` is set to `none` | ADR | jobs-outbox, owner-alerts, eta-e-receipt, webhooks | Before the jobs-outbox spec |
| 6 | Money and time rules ADR (rules as data, one shared vector suite on device and server; OQ8, OQ23) | ADR | money-time-rules, tax-service-rules, session-pricing, discounts, tips, refunds | Before the money-time-rules spec |
| 7 | Localization architecture (`localization-lead`, `/localize`; glossary in `design/localization/`; pseudo-localization test) | Research + ADR | localization-kernel, every screen | Before the first screen |
| 8 | **`/observability-plan`** (OpenTelemetry Collector pipelines, redaction, fleet health, crash capture, the thin Ktor plugin) | Plan | telemetry-pipeline, fleet-health, crash-capture, slos-alerting | Before the telemetry-pipeline spec |
| 9 | **Event taxonomy** (`docs/analytics/`, `product-analytics-engineer`) | Plan | event-taxonomy-analytics | After the observability plan |
| 10 | **Notifications provider research** → notifications ADR (email, Web Push, FCM; remote-approval channel; no SMS for recovery, ADR-0007) | Research + ADR | owner-alerts, push-notifications, remote-approval | Before the owner-alerts spec |
| 11 | Credential ADR (device credentials; `device_rt` or merged into `app_rt`) | ADR | device-seats-enrolment, sync-protocol | Before device-seats-enrolment |
| 12 | Key-custody ADR (device store key as PIN pepper, server pepper KMS) | ADR | counter-shell, counter-pin | After the desktop ADR |
| 13 | Licensing ADR (Ed25519 library choice; N5 grace; `licence-model.md` becomes its basis) | ADR | offline-lease | Before offline-lease |
| 14 | Storage / server-sync-state ADR (control journal, restore replay, deploy-record store) | ADR | backup-restore, sync-protocol | Before backup-restore |
| 15 | Limits ADR (per-plan `statement_timeout`, quotas) | ADR | plans-entitlements | Before plans-entitlements |
| 16 | **Dashboard real-time ADR** (OQ30; SSE or WebSocket from one backend instance; web stack; sets `stack.web`) | ADR | dashboard-shell, dashboard-live-floor | Before dashboard-shell |
| 17 | Owner-client ADR (TWA or WebView Play wrap; spikes S32/S33; sets `stack.mobile`) | ADR + spikes | owner-android-app | Spikes S32/S33 report |
| 18 | Updater and installer ADR (OQ21) | ADR | counter-install-update | After the desktop ADR |
| 19 | Vertical-module-contract ADR (`EndDayBlocker`, entitlement check, floor-view tiles) | ADR | vertical-module-contract, End Day, verticals | Before the vertical-module-contract spec |
| 20 | ETA ADR (signing location, integration) | ADR | eta-e-receipt | Before eta-e-receipt, or earlier if the ETA inquiry triggers Tier 1 |
| 21 | `/pricing-strategy` → `design/specs/pricing-model.md` and `design/registry/entities.yaml` | Skill output | plans-entitlements, subscription-billing | Before plans-entitlements |
| 22 | Hosted data-residency research (open in the brief) | Research | production tenant | Before the first production tenant |

---

## High-Risk Areas

| Context / feature | Risk Type | Risk Description | Mitigation |
|-------------------|-----------|-----------------|------------|
| Sync (sync-protocol, sync-review-conflicts) | Technical / Security | Lost or double-counted money or time; unproven until the spike's phases 4–5; rollback and renumbering blind spot (OQ27); store faults offline (OQ31) | Sync spike with fault injection (in flight); sync ADR; money-trail threat model before its first spec |
| Counter Shell | Technical | Runtime undecided (Compose Desktop or Electron); 4 GB HDD-class reference PC; 3 s ceiling | Desktop spike; desktop ADR; `perf-budgets.md` |
| Offline lease (N5) | Security | Clock tampering extends grace | Licensing threat model update; licensing ADR |
| money-time-rules | Technical | Device and server compute different totals (OQ23) | Shared vector suite; money/time ADR |
| Tenancy and RLS | Security | A cross-tenant read is a security bug | ADR-0001..0003; catalogue test; `/tenant-check` per story |
| Owner Android app | Provider | PWA in a Play wrapper is provisional | Spikes S32/S33; owner-client ADR |
| Dashboard real-time | Technical | One backend instance and no broker: fan-out lives in the process | Dashboard real-time ADR names the limit and the revisit trigger |
| Crash capture, fleet health | Compliance | Diagnostics must stay PII-free (PDPL) | Telemetry/diagnostics threat model; redaction in the observability plan |
| Staff attendance, customers, customer complaints, data-import | Compliance | Personal data (PDPL); import is an untrusted file upload | Privacy review; personal-data intake threat model before customers, customer-complaints and data-import |
| ETA e-receipt | Compliance | Mandate depends on the venue's ETA list (brief, risk 7) | Tier 1 is ETA-ready; ETA ADR; trigger moves it into Tier 1 |
| Jobs on PostgreSQL | Technical | Per-tenant sweep cost grows with tenant count | Jobs ADR; control-plane pending-work list (registry `IC-OUTBOX-SWEEP-R2`) |
| Tier 1 scope | Scope | 10–14 months, team of 2, unvalidated; 62 Tier 1 and foundation specs | `/estimate`; the slice first; the build order |
| Windows 10 end of support | Compliance | Consumer ESU ends 2027-10-12 | Brief decision; revisit before that date |
| Caching | Technical | No cache decision exists yet | Decided per story under DoD gate 5; none assumed |

### Threat models

Grouped so one model covers several features. **13 features are covered by existing threat models** (update at spec time if the spec changes the surface): tenant-isolation covers `tenant-foundation`, `tenant-provisioning`, `tenant-closure-export`; staff-auth covers `dashboard-sign-in`, `counter-pin`, `roles-permissions`, `counter-overrides`, `activity-trail`, `operator-console`, `support-access`, `staff-records`; licensing covers `device-seats-enrolment`, `offline-lease`. **22 features need 6 new models**, each written **before the first spec of its group**, not all now:

| New threat model | Covers | Written before |
|------------------|--------|----------------|
| Sync and money trail | sync-protocol, sync-review-conflicts, bill-exceptions, discounts, payments-tender, tips, refunds, money-ledger, paid-outs, backdated-start (10) | spec 20, `sync-protocol` (backdated-start extends it when specified) |
| Telemetry and diagnostics | fleet-health, crash-capture (2) | spec 53, `fleet-health` |
| Owner clients and approvals | dashboard-live-floor, owner-android-app, remote-approval (3) | spec 56, `dashboard-live-floor` |
| Personal-data intake | customers, customer-complaints, data-import (3) | spec 65, `customers` |
| External integrations | webhooks, eta-e-receipt, subscription-billing (3) | spec 80, `subscription-billing` (or earlier if the ETA trigger fires) |
| PC lock agent | pc-lock-agent (1) | spec 77, `pc-lock-agent` |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Bounded contexts identified | 32 (30 live, 2 Later placeholders) |
| Features identified | 89 (MVP 48, Vertical Slice 14, Beta 25, Full Vision 2) |
| Specs started | 0 |
| Specs reviewed | 0 |
| Specs approved | 0 |
| MVP features specified | 0/48 (0/62 including the Vertical Slice) |
| Features needing a threat model | 35 (13 covered by existing models, 22 need 6 new models) |

---

## Next Steps

- [ ] Review and approve this domain map
- [ ] Apply the brief drift (tips Tier 1, plans-entitlements and owner-alerts in the MVP, D2 covered, data-import Later) to `design/product-brief.md`
- [ ] Write the umbrella core-extraction ADR and the module-structure ADR (missing-ADR items 3 and 4) before the first backend story
- [ ] Specify the foundations in order 1–19 (`/design-spec tenant-foundation` first)
- [ ] Run `/spec-review` on each completed spec; `/review-all-specs` once the MVP specs are done
- [ ] Run `/estimate` on this map (the brief's 10–14 months is unvalidated)
- [ ] Run `/gate-check` to leave Product Design
- [ ] Validate the highest-risk areas with `/vertical-slice` once the sync and desktop ADRs exist
