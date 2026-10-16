# /create-architecture — Phase 2: Ownership, Data Stores and Tenancy

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Ownership, Data Stores and Tenancy

### 2a. Data store per context

For each bounded context, choose the store(s) from `stack.data` (postgres, mongo,
redis, dragonfly) and justify the choice against the context's access patterns:

| Context | Primary store | Why (access pattern, consistency need) | Secondary (cache / search / blob) | Retention / PII | Notes |
|---------|---------------|----------------------------------------|-----------------------------------|-----------------|-------|

Rules:
- **One owner per table/collection.** A context never reads or writes another
  context's storage; cross-context needs go through its `app` API or events.
- **PostgreSQL is the default** for transactional, relational and money data;
  Mongo only where the document shape is the access pattern (justify per context).
  Redis/Valkey/Dragonfly are for cache, rate limits, sessions, idempotency keys —
  not a system of record.
- **Hosted vs self-hosted engines differ by licence** (`.claude/rules/deploy.md`).
  If `distribution.model` is `hybrid` or `self-hosted`, every store choice is
  stated for both editions: cache is **Valkey** in `deploy/self-hosted/` (Dragonfly
  and Redis >= 7.4 are not allowed there), MongoDB is the **official image
  referenced, never shipped or derived**, and code must stay on the portable
  command subset. A choice that cannot run in the customer bundle is a finding
  now, not at release.
- Name the pinned image/version from `pins.yaml` for each store; any divergence
  between hosted and bundle (`mongo:9.0.2` vs `mongo:8.0.32`) is stated.
- Retention, export and delete behaviour (Egypt PDPL / GDPR) per store holding PII,
  with the owning context named.
- Migrations: forward-only in production, expand→migrate→contract, with the
  self-hosted multi-version upgrade in mind (Phase 5).

### 2b. Tenancy model

Read `tenancy.model` from the config block (`shared-schema-rls`, `schema-per-tenant`,
`db-per-tenant`, `single-tenant`). If it is empty, stop and ask — tenancy is a
Foundation decision and is never defaulted. Then specify, for **this** model:

- **Isolation in depth**: application-layer scoping in every repository query
  **and** the second layer the model provides (Postgres RLS policies, schema or
  database per tenant). Name how tenant context is established (token claim →
  request context → port argument → adapter), and that no query is built without it.
- **Tenant-scoped storage in each store**: Postgres (`tenant_id` + RLS), Mongo
  (`tenant_id` filter inside the repository only), Redis keys (tenant ID in every
  key), object storage (tenant prefix), search/analytics.
- **Hosted vs self-hosted tenancy**: a self-hosted install is typically
  single-tenant or a small tenant set — say how the same code runs with one
  tenant, and what the model is when `distribution.model` is `hybrid`.
- **Noisy-neighbour controls**: per-tenant rate limits, quotas, pool limits, job fairness.
- **Cross-tenant access paths**: admin/impersonation, support tooling, reporting —
  each listed, each with an audit-log entry and a threat-model path.
- **Negative-test requirement**: a cross-tenant test per context (the architecture
  states it; `/create-stories` turns it into acceptance criteria).

Consult `multitenancy-specialist` (via `Agent`) for the isolation design and
`data-lead` for the store choices when the domain map has more than two contexts
or any context is HIGH risk. Pass the context cards and the relevant
stack-reference excerpts; they return recommendations, the user decides.

### 2c. Ownership map

Combine into one ownership table per layer, then an ASCII or Mermaid diagram:

- **Owns** (data and state), **Exposes**, **Consumes**, **Stores used**, **Tenancy enforcement point**.
- **Stack APIs used**: the specific packages/classes/endpoints the module calls
  directly, with version and risk level noted.

**Stack awareness check**: For every API listed, verify against the stack
reference (`docs/stack-reference/<layer>/` plus `deprecated-apis.md`). If it is
beyond the reference, flag it:

```
⚠️  [package.function()] — [layer] [pinned version] (post-cutoff / HIGH risk)
    Verified against: docs/stack-reference/[layer]/[file].md
    Behaviour confirmed: [yes / NEEDS VERIFICATION / NOT SOURCEABLE]
```

Get user approval on the data store choices and the tenancy model separately
(they are two decisions), then record both in `production/session-state/active.md`;
they are written at Phase 8. Each becomes a critical ADR in Phase 7.

---
