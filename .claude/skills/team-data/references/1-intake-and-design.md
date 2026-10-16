# /team-data — Phases 1–4: Intake, Review, Specialist Designs, Brief

> Part of `/team-data`. Read again if the conversation was compacted.

## 1. Intake

- `resume [slug]`: read the "Data pipeline — <slug>" block of
  `production/session-state/active.md` and `production/data/<slug>/`; restate the
  phase and what it waits on; continue there. Nothing found → say so, start fresh.
- Resolve the code roots with `bash .claude/hooks/yaml-helper.sh resolve_code_root` before locating repositories, migrations and ripple files; an empty result means that scan **did not run** — say so, never "no files found".
- Otherwise restate the change in one sentence in the user's language; derive
  `<slug>` (kebab-case; the spec stem when it belongs to a feature, since the
  feature's workflow tier is keyed by it — `workflow-modes.md`).

Inventory, each row FOUND or ABSENT:

| Artifact | Path |
|---|---|
| Spec (Data & Contracts, Non-Functional: caching, retention) | `design/specs/<slug>.md` |
| Research note | `docs/research/<slug>.md` |
| Threat model (PII, billing, licensing, upload, export/delete) | `docs/architecture/threat-models/<slug>.md` |
| Domain map: the context that owns the data | `design/specs/domain-map.md` |
| Registry (plans, roles, permissions, quotas, events) | `design/registry/entities.yaml` |
| Existing migrations and the migration tool/layout (ADR or files) | the project's migration directory; `docs/architecture/adr-*.md` |
| Existing migration plan / cache decision | `docs/architecture/migration-plans/<slug>.md`, `docs/architecture/cache-designs/<slug>.md` |
| Supported upgrade-from versions (self-hosted) | the release policy / `release-manager`'s matrix — absent → asked, recorded `stated by user` |
| Table sizes / row counts on the largest installs | asked; **unknown = treated as hot** |
| ADRs on stores, messaging, tenancy | `docs/architecture/adr-*.md` |

A feature that needs research and has none: `/research` first (DoD gate 1; sensitive
data always needs it).

## 2. Classify and fire the triggers

Classify each element of the change on the expand/contract taxonomy
(`.claude/rules/migrations.md`): **additive** (new nullable column, new table, new
index built concurrently) · **expand** (add the new shape alongside the old) ·
**migrate** (dual-write, backfill, switch reads) · **contract** (remove the old
shape in a later release) · **destructive** (`DROP`, `TRUNCATE`, data deletion — own
approval, backup step) · **in-place hazardous** (`ALTER COLUMN TYPE`, `ADD COLUMN ...
NOT NULL` without default, index without `CONCURRENTLY`, foreign key without `NOT
VALID`) — never one step on a hot table.

Fire the triggers; each row states the evidence from the sentence/spec or `not
fired — <reason>`:

| Trigger | Fires when | Owner |
|---|---|---|
| Relational schema | a table, column, constraint, index, RLS policy or partition changes (store `postgres`) | `postgres-specialist` |
| Document model | a collection, validator or index changes (store `mongo`) | `mongo-specialist` |
| Rollout / migration | any schema or data change a running version depends on; any backfill | `migration-specialist` (always, with a schema change) |
| Cache | a hot read path is added/changed, or a cache key family's data changes shape or invalidation | `cache-specialist` via `/cache-design` |
| Messaging | a write must publish an event; a queue/stream/consumer changes; an event schema changes | `messaging-specialist` |
| Tenancy | a tenant-owned table/collection is added, or `tenancy.model` is not `shared-schema-rls` | `multitenancy-specialist` |
| Retention / PII | personal data is added, moved or deleted; a purge job; export/delete (DSAR) paths | `privacy-compliance-specialist` (studio) with `data-lead` |
| Contract | an API or event contract changes with the data | `/api-contract` / `/team-api` first |
| New store / engine | a store not in `stack.data` | ADR via `cto`; licence review for bundles |

Print the table. A trigger that fired for an agent outside the active set is
routed through `data-lead` with an informational note, and named in the report.

## 3. Phase 2 — the data-lead review (read patterns first)

Spawn `data-lead` via `Agent` with the intake summary, the classification, the
trigger table and the paths (do not paste documents). Named output
`production/data/<slug>/data-lead-review.md`. It must settle, each as a section:

1. **Read and write patterns, written first** — the queries, their filters,
   sorts, frequency, expected volume and latency budget (from
   `docs/architecture/perf-budgets.md` when the row exists, else `budget not yet
   set`). **"We will add an index later" is not a design.** No section below is
   accepted without this one.
2. **Store decision** — what, why, the rejected alternatives; Postgres by default;
   Mongo only for document-shaped data by ADR; a Redis-protocol store is never the
   system of record.
3. **Ownership** — the owning bounded context; no context reads another context's
   tables (a grep of SQL across context folders is part of the review); cross-context
   data moves through the owning context's `app` API or events.
4. **Tenancy** — `tenant_id NOT NULL`, an index leading with `tenant_id`,
   database-level enforcement for the model (RLS with `FORCE ROW LEVEL SECURITY` on
   Postgres; repository-enforced filter on Mongo), and the cross-tenant negative
   test that will prove it.
5. **Invariants in the database** — NOT NULL, CHECK, `UNIQUE (tenant_id, natural_key)`,
   FK; conventions: money as `bigint` minor units + currency, `timestamptz`,
   UUIDv7/ULID IDs, no exposed sequences.
6. **Consistency** — transactional outbox for any write that publishes; idempotent
   consumers; no dual write; reconciliation jobs where an outbox is not possible.
7. **Retention and deletion** — per data class: retention period (legal periods are
   `privacy-compliance-specialist`'s and `security-lead`'s call — stated as inputs,
   not invented), soft vs hard delete, tenant offboarding, DSAR export/erase paths.
8. **Backup and recovery impact** — RPO/RTO per store; Postgres PITR method per the
   reference; a restore drill with evidence for a **new** store or a changed backup
   scope. **MongoDB backup and restore are not covered by the stack reference:
   `NOT SOURCEABLE` → `/research` and an ADR before the method is chosen.**
9. **Customer-bundle rules** — Valkey for cache, the official Mongo image
   reference only (never a shipped binary or derived image), Dragonfly hosted-only,
   OTel Collector only (`docs/ROADMAP.md` L1–L4, `.claude/rules/deploy.md`).
10. **Which specialists run in Phase 3, and what each is asked.**

## 4. Phase 3 — specialist designs, in parallel

State the active specialists and any trigger-fired agent not spawned (with why).
Then, in **one message**, spawn every fired specialist and invoke `/cache-design`
when the cache trigger fired. Briefs: the `data-lead-review.md` path, the
classification, `docs/stack-reference/<store>/` (all four files) and `pins.yaml`,
the relevant `.claude/rules/*.md` (`migrations.md`, `mongo-data.md`,
`cache-code.md`, `security-sensitive.md` for PII/tenancy paths). Each writes to its
named file and returns the contract.

- `postgres-specialist`: target DDL as a design (columns, types, constraints,
  indexes with the read pattern each serves, RLS policy and the pooler-safe tenant
  context), the `EXPLAIN (ANALYZE, BUFFERS)` plan **to be captured** for each hot
  query, lock behaviour of each statement, partitioning if justified. It writes
  design text and SQL for review; migration files are `/db-migration`'s.
- `mongo-specialist`: document model, `$jsonSchema` validator, ESR-ordered indexes,
  tenant filter enforcement, operator-injection prevention, write concern, TTL
  indexes, lazy `_v` migration; the SSPL/bundle rule is stated, never interpreted
  (raised to `data-lead` → `security-lead` → `cto`).
- `migration-specialist`: the **step table** (release, database change, code change,
  why safe alone, rollback), the backfill design (batched, idempotent, resumable,
  outside the migration transaction), the hazard of skipped releases for
  self-hosted customers and the options, and the upgrade path from the oldest
  supported version. It plans; it does not run.
- `/cache-design <slug>`: the cache decision record (or a written "no cache").
- `messaging-specialist`: the outbox row shape and relay, delivery semantics,
  consumer idempotency by event ID, ordering key, retry/DLQ, lag metric, the event
  schema and its versioning. A public event/webhook change is a contract change:
  `/api-contract`.
- `multitenancy-specialist`: isolation fit for `tenancy.model`, tenant-context
  propagation through the pool, noisy-neighbour controls, the cross-tenant tests.

If two specialists disagree (an index vs a write-amplification cost; a cache TTL vs
a consistency requirement), do not pick: present both with their evidence to
`data-lead`, then the user; a technical deadlock goes to `cto`.

## 5. Phase 4 — the data change brief

Resume `data-lead` (or spawn it with the specialist file paths) to integrate into
`production/data/<slug>/data-change-brief.md`: the target model; the **step table**
by release; the **ripple list** — every place code must change with the schema
(repository methods and queries, read models, cache key families and their
invalidation, events and consumers, API contract impact, DSAR export/erase,
backups, seed data in `tools/seed/`); the test matrix to be run (Phase 7); the
risks with owners; the destructive steps listed separately; open questions.

**Gate — design approved.** `AskUserQuestion`: approve · revise (name the section;
the same agent re-drafts) · stop. Then:

- **ADR (always prompts):** a store, messaging or tenancy decision is a critical
  ADR (`workflow-modes.md`): required at `standard` and `full`; at `minimal` the
  decision log in `design/product-brief.md` instead (asked). Invoke
  `/architecture-decision "<title>"`; `CTO-ADR` runs per `review_mode`. The ADR moves
  to `Accepted` only by the user (or `cto` on the user's explicit confirmation).
- **Destructive steps (always prompt):** each is listed with the data it deletes,
  the release it is scheduled for (the contract phase, never the expand release), the
  backup step it needs in `/release-checklist`, and its own yes/no. A "no" removes
  the step from the plan; it does not stop the rest.
