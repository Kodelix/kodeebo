# Tracking Plan: [Product]

> **Path**: `docs/analytics/tracking-plan.md` · **Status**: Draft | Active · **Owner**: product-analytics-engineer · **Reviewers**: product-manager, security-lead (privacy)
> **Last reviewed**: [YYYY-MM-DD] · **Tooling**: [analytics provider / self-hosted pipeline — pinned in `docs/stack-reference/`]
> **Related**: `design/product-brief.md` (success metrics), `design/growth/` (activation metrics, lifecycle journeys, experiments), UX specs (Actions & Events)

<!-- Every event exists to answer a named question. If no one will use the answer, do not track it.
     Naming: object_action in snake_case past tense (`invitation_sent`). One event per user-meaningful action; do not encode values in event names.
     Client events carry no PII; respect consent. Server-side events for anything money- or entitlement-related (source of truth). -->

## 1. Questions the Data Must Answer

| ID | Question | Decision it informs | Metric | Owner |
|----|----------|--------------------|--------|-------|
| Q1 | [Do new tenants reach first value?] | [Onboarding changes] | Activation rate within 7 days | |
| Q2 | [Where do trials drop off?] | | Funnel conversion | |

## 2. Metric Definitions

| Metric | Definition (numerator / denominator, window) | Source events | Segments |
|--------|---------------------------------------------|---------------|----------|
| Activation | [tenants with `[activation_event]` within 7 days of `tenant_created` / tenants created] | | plan, locale, acquisition channel |
| Retention (WAU) | | | |
| Trial -> paid | | | |

## 3. Event Catalog

| Event | When it fires (exact trigger) | Source (client / server) | Properties | PII? | Consent category | Question(s) | Owner | Status |
|-------|------------------------------|-------------------------|-----------|------|------------------|-------------|-------|--------|
| `tenant_created` | After server confirms workspace creation | server | `plan`, `locale`, `source` | No | necessary | Q1 | | Planned |
| `invitation_sent` | After the invite API returns 201 | server | `role`, `seats_used`, `plan` | No (no email) | necessary | Q1 | | Planned |
| `upgrade_dialog_viewed` | Plan Gate prompt rendered | client | `gate_key`, `plan` | No | analytics | Q2 | | Planned |

## 4. Property Dictionary

| Property | Type | Allowed values / format | Description | PII? | Used by events |
|----------|------|------------------------|-------------|------|----------------|
| `plan` | enum | `free`, `starter`, `team`, `enterprise` | Plan at event time | No | most |
| `locale` | enum | `ar`, `en` | UI locale | No | most |
| `tenant_id` | string (opaque, hashed per analytics policy) | | Tenant identifier | Pseudonymous | server events |

## 5. Identity Model

- **Anonymous ID** -> **user ID** merge rule: [on sign-up/sign-in]; **tenant** as group
- Identifiers sent to the analytics provider: [opaque IDs only — never email, phone, name, national ID]
- Cross-device and cross-tenant handling: [...]

## 6. PII & Privacy Rules

- **No PII in events or properties**: no emails, phone numbers, names, addresses, national IDs, free-text user input, or full IPs. Use opaque IDs and coarse buckets (e.g. seat count ranges).
- **No secrets or tokens** in any property or URL captured by auto-instrumentation; disable auto-capture of input values and URLs with tokens.
- **Free text** (search queries, error messages) is not sent; send only length or category.
- **Retention**: [N months raw, aggregates longer]; deletion on tenant/user erasure request (PDPL / GDPR): [how, SLA]
- **Data location & processors**: [provider region, DPA, sub-processors listed]
- **Access**: [roles who may query raw events]

## 7. Consent

| Category | What it covers | Default | Collected how | Effect when declined |
|----------|---------------|---------|---------------|---------------------|
| Necessary (service operation & security metrics) | Server-side operational events, billing, audit | On | Terms/privacy notice | — |
| Analytics | Product-usage events on clients | [Off until consent in regions that require it] | Consent banner / settings | No client analytics events fired; server aggregate metrics only |
| Marketing | Lifecycle email and attribution | Off | Explicit opt-in | No marketing events or emails |

- Consent state is stored per user and checked **before** any client event is sent; changes apply immediately
- **Self-hosted**: telemetry and analytics are **off by default** and never phone home without explicit opt-in; the bundle documents what would be sent

## 8. Implementation Rules

- Events are defined in a typed, versioned schema shared by clients and backend (generated from this plan or `contracts/`)
- Client sends via one wrapper that enforces consent and strips disallowed fields
- Server events are emitted after the state change commits (outbox) so counts match reality
- Each event has a test (fires once per action, correct properties, no PII, not fired when consent is off)
- Changes follow: update plan -> review -> implement -> verify in the debug view -> release; breaking renames use a new event name and a deprecation period

## 9. Dashboards & Alerts

| Dashboard / alert | Audience | Metrics | Link |
|-------------------|----------|---------|------|
| Activation funnel | product | | |
| Instrumentation health (events per day by name, schema violations) | analytics | | |

## 10. Change Log

| Date | Event / property | Change | Reason | Approver |
|------|------------------|--------|--------|----------|
