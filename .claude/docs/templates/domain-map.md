# Domain Map: [Product Title]

> **Status**: [Draft / Under Review / Approved]
> **Created**: [Date]
> **Last Updated**: [Date]
> **Source**: design/product-brief.md

---

## Overview

[One paragraph explaining the product's functional scope. What bounded contexts
does this product need? Reference the MVP, the ICP and the pricing model so any
team member can see the big picture of what needs to be specified and built.]

---

## Bounded Contexts

<!-- A bounded context owns its data and language and talks to others through
     ports/contracts/events. Shared capabilities (identity, billing, licensing,
     notifications, storage, audit) come from `saas-core` — list them as
     "core" contexts and say which module. -->

| # | Context | Kind | Purpose | Owns (data / language) | Owner (agent / person) | Core module? |
|---|---------|------|---------|------------------------|------------------------|--------------|
| 1 | [e.g. Identity & Access] | Generic / Core module | Sign-in, roles, SSO | users, sessions, roles | go-lead / security-lead | `saas-core` identity |
| 2 | [e.g. Billing] | Generic / Core module | Plans, invoices, payments | subscriptions, invoices | pricing-billing-designer | `saas-core` billing |
| 3 | [e.g. Appointments] | Product-specific | The product's core domain | appointments, schedules | domain-architect | — |

---

## Features by Context

<!-- One row per feature; each gets a spec at `design/specs/<feature>.md`.
     Mark features inferred (not explicit in the brief) with "(inferred)". -->

| # | Feature | Context | Category | Priority | Status | Spec | Depends On |
|---|---------|---------|----------|----------|--------|------|------------|
| 1 | [e.g. Team invitations] | Identity & Access | Platform | MVP | [Not Started / In Design / In Review / Approved / Implemented] | [design/specs/team-invitations.md or "—"] | [e.g. Email notifications] |

---

## Categories

| Category | Description | Typical Features |
|----------|-------------|------------------|
| **Platform** | Foundations everything depends on | Tenancy, identity, roles, audit log, settings |
| **Core domain** | What the customer actually pays for | The product's primary workflows |
| **Billing & Licensing** | Money and entitlements | Plans, checkout, invoices, dunning, licence keys |
| **Integrations** | External systems | Payment provider, email/SMS, storage, webhooks, public API |
| **Admin & Support** | Operating the product | Admin console, impersonation, data export/delete |
| **Growth** | Acquisition and retention | Onboarding, trials, lifecycle emails, referrals |
| **Insights** | Analytics and reporting | Dashboards, exports, tracking |
| **Client surfaces** | Apps and sites | Web app shell, mobile apps, marketing site |

[Remove categories that do not apply; add custom ones if needed.]

---

## Priority Tiers

| Tier | Definition | Target Milestone | Specification Urgency |
|------|------------|------------------|----------------------|
| **MVP** | Required for the core journey to work and be sold | Vertical slice / private beta | Specify FIRST |
| **Vertical Slice** | Proves the architecture end to end for one journey | Vertical slice | Specify SECOND |
| **Beta** | Complete functional scope in rough form | Public beta | Specify THIRD |
| **Full Vision** | Polish, edge cases, nice-to-haves | GA and later | Specify as needed |

---

## Dependency Map

[Contexts and features sorted by dependency order — specify and build from top
to bottom. Foundations at the top; wrappers at the bottom.]

### Foundation Layer (no dependencies)

1. [Context/feature] — [one-line rationale]

### Core Layer (depends on foundation)

1. [Context/feature] — depends on: [list]

### Feature Layer (depends on core)

1. [Context/feature] — depends on: [list]

### Presentation Layer (depends on features)

1. [Context/feature] — depends on: [list]

### Hardening Layer (depends on everything)

1. [Context/feature] — depends on: [list]

---

## Ownership & Data Boundaries

| Data / capability | Owning context | Read by | Access path (API / event / read model) |
|-------------------|----------------|---------|---------------------------------------|

<!-- A table or collection has exactly one owner. Cross-context reads go through
     the owner's port, never its tables. -->

---

## Recommended Specification Order

[Combine dependency sort and priority tiers. Specify in this order. Each spec
should be completed and reviewed before starting the next, though independent
features at the same layer can be specified in parallel.]

| Order | Feature | Priority | Layer | Agent(s) | Est. Effort |
|-------|---------|----------|-------|----------|-------------|
| 1 | [First feature to specify] | MVP | Foundation | product-manager | [S/M/L] |
| 2 | [Second feature] | MVP | Foundation | product-manager | [S/M/L] |

[Effort: S = 1 session, M = 2–3 sessions, L = 4+ sessions. A "session" is one
focused conversation producing a complete spec at the effective tier.]

---

## Circular Dependencies

[List circular dependency chains. Break the cycle with a port/event, or specify
the two features together.]

- [None found] OR
- [Context A <-> Context B: description of the cycle and proposed resolution]

---

## High-Risk Areas

[Technically unproven, spec-uncertain, security-sensitive or scope-dangerous
areas. Prototype or research these early regardless of priority tier.]

| Context / feature | Risk Type | Risk Description | Mitigation |
|-------------------|-----------|-----------------|------------|
| [Billing] | [Technical / Security / Compliance / Scope / Provider] | [What could go wrong] | [Research note, prototype, threat model, scope fallback] |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Bounded contexts identified | [N] |
| Features identified | [N] |
| Specs started | [N] |
| Specs reviewed | [N] |
| Specs approved | [N] |
| MVP features specified | [N/total MVP] |
| Features needing a threat model | [N] |

---

## Next Steps

- [ ] Review and approve this domain map
- [ ] Specify MVP-tier features first (use `/design-spec [feature-name]`)
- [ ] Run `/spec-review` on each completed spec
- [ ] Run `/review-all-specs` once MVP specs are done
- [ ] Run `/gate-check` to leave Product Design
- [ ] Validate the highest-risk areas with `/vertical-slice` before committing to Production
