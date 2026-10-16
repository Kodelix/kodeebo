# /create-architecture — Phase 7: Missing ADR List

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 7: Missing ADR List

Based on the full architecture, produce a complete list of ADRs that should exist
but don't yet. Mark each **critical** or not (`workflow-modes.md`: tenancy, identity/auth,
data store, messaging, API style, deployment topology, licensing — when in doubt,
critical). Group by priority:

**Must have before coding starts (Foundation & Core decisions, all critical ones):**
- Tenancy model and isolation (`tenancy.model`)
- Identity and authorization model (and the `saas-core` identity module's role)
- Data store per context (Postgres / Mongo / cache), including the hosted-vs-bundle engine split
- API style, conventions and `contracts/` workflow
- Messaging / async processing (outbox, broker or none)
- Deployment topology for hosted and self-hosted, and the self-hosted upgrade path
- Licensing model for self-hosted (if `distribution.model` includes self-hosted)
- Observability backend (hosted) and the bundle collector configuration

**Should have before the relevant context is built:**
- [e.g. "Billing provider adapter and reconciliation"]
- [e.g. "File upload and storage pipeline"]
- [e.g. "Offline sync policy for mobile"]

**Can defer to implementation:**
- [e.g. "Specific chart library for the dashboard"]

Each entry names the TR-IDs it covers and the research note it needs
(`/research` — gate 1 — runs before the ADR is Accepted).

---
