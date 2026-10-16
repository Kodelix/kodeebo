# Triggers

Lookup tables for `/story-readiness`. They restate `research-protocol.md` and
`security-baseline.md` so a check can be made without a second read; if the
documents change, those documents win — re-read them when a case is borderline.

## Research required or exempt (DoD gate 1)

Source: `.claude/docs/research-protocol.md` → "When research is required".

| Change | Research note required? |
|---|---|
| New feature, new integration, new external provider | **Yes** |
| New library, framework feature, or major version bump | **Yes** |
| Anything touching auth, billing, licensing, crypto, file upload, PII | **Yes** — and it feeds the threat model |
| Bug fix inside existing, already-researched code | No — cite the existing note |
| Copy, styling, config value change | No |

A story claims exemption by writing `Research: exempt — [row]` and, for the bug
fix row, citing the existing note's path. The claim is checked against the
story's content: an exempt story that introduces a new endpoint, dependency,
provider, schema or sensitive area is not exempt.

## Threat-model triggers

Source: `.claude/docs/security-baseline.md` → "Threat modelling". The story (or
the feature it implements) touches one or more of:

- authentication
- the authorization model (roles, permissions, policy)
- billing
- licensing
- file upload
- webhooks
- PII export or delete
- admin or impersonation
- a new external integration

Model location: `docs/architecture/threat-models/<feature>.md` (from
`/threat-model`; template `.claude/docs/templates/threat-model.md`). Gate:
SL-THREAT-MODEL.

Borderline cases lean to "trigger applies": a story that adds a field to an
existing billing object, or an endpoint behind existing authz, is judged by
whether it changes who can do what or what money or personal data moves — say
which way you judged it and why in the Passing Checks line.

## Hot paths (cache decision and perf budget must be referenced)

A story touches a hot path when any of these holds:

- code that runs on every authenticated request (auth/session middleware, tenant resolution, entitlement or permission lookup, rate limiting)
- a list, search or export endpoint (pagination, filtering, sorting, N+1 exposure)
- a background job or consumer that iterates many rows or tenants
- a read the spec gives a p95 target for, or a table expected to grow with tenant count
- a mobile or web screen on the core journey with a stated load-time budget

Sources: `docs/architecture/perf-budgets.md` (budget rows), the spec's
Non-Functional Requirements (Caching Decision), `.claude/docs/caching-standard.md`,
`.claude/docs/performance-standard.md`.

## Layer to owner agent

| Layer / lane | Owner agent (roster) |
|---|---|
| Contracts (`contracts/`) | `api-designer` |
| Go backend | `go-lead` |
| Ktor backend | `ktor-lead` |
| Data (schema, cache, messaging) | `data-lead` |
| Web SPA / marketing site | `web-lead` |
| Android | `android-lead` |
| iOS | `ios-lead` |
| KMP shared module | `kmp-specialist` |
| Platform (CI, compose, installer) | `platform-lead` |
| Security-sensitive review | `appsec-engineer` (under `security-lead`) |

Work is routed by `principal-engineer`; this table is for naming, not assignment.
