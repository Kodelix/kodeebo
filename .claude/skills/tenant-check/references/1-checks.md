# /tenant-check - Checks T1-T14 and the Audit Brief

> Phases 1 and 3 of `SKILL.md`. Standard: `multitenancy-specialist` Senior Bar,
> `security-baseline.md` (tenant isolation in depth), gate `SL-TENANT-ISOLATION`.
> Every fact about Postgres, Mongo or Redis behaviour comes from
> `docs/stack-reference/`; anything not there is `NOT SOURCEABLE` and routed to
> `/research`. Each check ends `met` / `not met` / `not applicable (reason)` /
> `not run (reason)`, with `file:line` or an output reference.

## 0. Arguments

| Argument | Checks run |
|---|---|
| `full` or none | T1-T14 |
| `<feature-slug>` / `<story-path>` | the tenant-owned tables, collections, cache key families, queues, prefixes, endpoints and jobs that feature/story touches (derive from the spec, story and diff); T1/T2/T3 still run once for the whole product because roles and the catalogue are not per feature |
| `db` | T1-T5, T13 |
| `nosql` | T6 (Mongo) |
| `cache` | T7 |
| `storage` | T8 |
| `jobs` | T9 |
| `quick` is not offered: a partial isolation audit never counts as the pre-release audit |

A narrowed run is named in the report and **cannot yield `APPROVE` for the
product**, only for the scope run; the report states the scope in its verdict line.

## 1. Fixed brief for `multitenancy-specialist` (static audit)

Fill only the `{...}` slots. Add nothing else: no view on maturity, no expected
severity, no opinion on any finding.

```text
Run the static part of a tenant-isolation audit for /tenant-check. Read-only: do
not edit any file.

Scope: {full | feature/story | db | nosql | cache | storage | jobs}
tenancy.model: {value | unset}    Stack: {the stack line}    Distribution: {distribution.model | unset}
Code roots: {resolve_code_root output, or "unresolved"}
Paths: repositories/adapters {paths}; use cases/handlers {paths}; jobs/consumers {paths};
migrations {paths}; deploy DB/pooler/role config {paths}; tests {paths}; threat model {path | none}
Checks to run: read .claude/skills/tenant-check/references/1-checks.md sections T1
and T3-T13 and run: {check IDs}. T2 (catalogue) and T14 (negative tests) are run
by the caller; list the tests you can see and their gaps, do not run them.
Stack facts: read docs/stack-reference/postgres/best-practices.md (section 1, 7),
mongo/best-practices.md (1-2, 4), redis/best-practices.md (1, 3, 5, 10). A fact
not there is NOT SOURCEABLE; do not fill it.
Report each finding as TEN-NNN with check ID, file:line, description, how another
tenant could reach the data, impact, remediation, the negative test that proves it,
and siblings found by grep. Produce the query/path table: location - mechanism -
tenant-scoped? (yes/no/unknown) - negative test (path or none).
State what was NOT reviewed. A layer with no source is "NOT ASSESSED - no source
under <root>", never zero findings. Never print customer data, connection strings
or secrets. Return the report as text.
```

Verify the reply names every check ID assigned; a missing ID is `not run`.

## 2. The checks

### T1 - Database roles (Postgres)
`postgres/best-practices.md` §1. At least two roles: `migrator` owns tables and
runs DDL; `app` is `LOGIN NOBYPASSRLS`, **not owner**, DML grants only. An
`admin_batch` role (`BYPASSRLS`, audited cross-tenant jobs only) exists only if an
ADR accepts it; its absence is not a finding. The app never connects as
superuser or owner.
- Probe: deploy/compose/env examples, migrations that `CREATE ROLE`/`ALTER ROLE`/`GRANT`, the connection configuration per service (which secret/role the API and workers use), the migration job's role.
- With a named non-production database, read-only: role attributes and table owners (catalogue; see `2-catalogue-and-tests.md`). Without one: `static only`, and T1 cannot be `met` for the live roles - `NOT ASSESSED - roles not queried`.
- `statement_timeout` / `idle_in_transaction_session_timeout` set per role (T11).

### T2 - RLS on every tenant table (catalogue)
`ENABLE` **and** `FORCE ROW LEVEL SECURITY` plus at least one policy with
explicit `USING` and `WITH CHECK` on the tenant; the hard predicate is a
RESTRICTIVE policy; an unset tenant setting yields zero rows and rejected writes
(no `COALESCE` to a default tenant). Run by the caller from the catalogue query
(`2-catalogue-and-tests.md`). A CI test performing the same catalogue check must
exist (grep the tests); its absence is a gap even when the live query is clean.
Migration text alone is **not** proof: it makes T2 `static only`
(`NOT ASSESSED - catalogue not run`).

### T3 - Pooler-safe tenant context
Each request opens a transaction and the **first statement** is
`SELECT set_config('app.tenant_id', $1, true)` (transaction-local,
parameterised). Never a session-level `SET`, nor `set_config(..., false)`, with
transaction pooling. Probe: grep the code roots for the context-setting site(s),
for session-level forms, and for string-built settings. An integration test
pushes two tenants through a pool of size 1 and asserts no cross-read (T14).
Long-lived admin connections (migrations, `LISTEN/NOTIFY`, advisory locks) use a
direct session-mode connection, not the transaction pool.

### T4 - Application-layer scoping
Defence in depth: RLS is never the only layer. The repository API takes a
tenant-bound context type, so a query without a tenant does not compile or fails
fast in tests. Every query in scope is listed (`file:line`) with its scope. The
tenant is derived from the authenticated subject's membership, **never** from a
request body, path, header or unverified claim. Object-level authorization:
load -> check tenant and ownership/role -> act. A cross-tenant lookup answers
**404, not 403**, including through unique-constraint errors and pagination
cursors (no existence oracle).

### T5 - Uniqueness, keys, indexes
`UNIQUE (tenant_id, natural_key)` with surrogate primary keys (the reference
explains the duplicate-key covert channel); `tenant_id` leads composite indexes
on hot queries and appears as an index condition in the plan. Views over tenant
tables are created `WITH (security_invoker = true)` (list views and their
option; the catalogue query covers this).

### T6 - MongoDB (when `stack.data` includes Mongo)
Every query goes through a repository that injects `tenant_id` from context;
user input is never merged into a filter (operator-injection defence,
`mongo/best-practices.md` §4: validate types at the boundary, build filters from
explicit fields, no user-supplied `$where`/`$expr`/logical operators);
`tenant_id` is the first key of compound indexes (ESR respected, §2);
`$jsonSchema` validation requires `tenant_id` (§1); scripting disabled where the
reference says so. Probe: grep for ad-hoc collection access outside the
repository, `$where`, and request bodies passed as filters. `not applicable` only
when the stack explicitly has no Mongo (state the config value).

### T7 - Cache and rate-limit keys
Keys are `{product}:{tenant_id}:{entity}:{id}` (or the format fixed by ADR);
every key has a TTL with jitter (`redis/best-practices.md` §1); sessions and
idempotency records are scoped to the tenant too (`idem:<scope>:<key>` where
scope derives from the tenant); the rate-limit key carries the tenant
(`rl:{<tenant>}:...`, §5). Tenant-wide invalidation is possible without `KEYS` or a
full scan; Lua scripts declare every key in `KEYS` (§10); only the
Valkey-portable command subset for customer bundles (§10). A test proves tenant
A's key cannot be read in tenant B's context (T14). Cache decisions live in
`docs/architecture/cache-designs/` (`/cache-design`).

### T8 - Object storage, search, queues
Object keys carry a tenant prefix **enforced in the adapter**, random key
suffixes, signed URLs scoped to the tenant prefix and short-lived; served from a
separate origin; search indexes and exports filter by tenant; queue topics or
partitions carry the tenant. Probe: the storage adapter, presign code, export
code, search query builders.

### T9 - Background jobs, consumers, events, outbox
The tenant is in the message/outbox envelope; the consumer re-establishes
tenant context (and the DB setting of T3) before touching data. Scheduled tasks
iterate tenants in context. Cross-tenant batch work iterates tenants in context
or, where an ADR accepts it, runs as `admin_batch`; either way it writes an
audit record. Probe: job entry points, consumer handlers, the outbox
dispatcher, scheduled-task registrations.

### T10 - Telemetry
`app.tenant_id` is a span and log attribute where known; it is a metric label
only when the tenant count is bounded (`observability-standard.md`). No other
tenant's data in logs, traces or error messages returned to a client.

### T11 - Noisy neighbour
Per-tenant and per-route rate limits (atomic, in the cache), request and payload
caps, bounded pagination, `statement_timeout` per role, per-tenant concurrency
limits for expensive jobs, per-plan quotas from the catalogue (not constants).
Values are configuration. Load behaviour itself is `/load-test`; this check
confirms the controls exist.

### T12 - Admin, impersonation, cross-tenant-by-design
Admin and impersonation require re-authentication or step-up, are time-boxed and
write to the append-only audit log (actor, target, reason). Every cross-tenant-by-design
operation (platform admin, aggregate reports) is listed, separately authorised and
has its own test.

### T13 - Tenant lifecycle
Export uses a tenant-scoped role with `pg_dump --enable-row-security --inserts`
(`postgres/best-practices.md` §1) plus Mongo and object-storage equivalents; a
full backup runs as a role allowed to bypass RLS and is not used for tenant
export. Deletion removes data from primary stores, caches and search, writes an
audit tombstone and states backup-retention expiry. Soft-delete is not tenant
deletion. Coordinate with `privacy-compliance-specialist`; this check confirms the
mechanism exists and is tested, not the legal retention period.

### T14 - Cross-tenant negative tests present **and passing**
For every repository, cache adapter, endpoint and job in scope: tenant B cannot
read, list, update, delete, or infer the existence of tenant A's data (404), including
through unique-constraint errors and pagination cursors. Each endpoint has an
authz test for anonymous, wrong role and wrong tenant. Required properties:
- run against **real dependencies** (Testcontainers), not mocks;
- the DB connection is the **non-owner, `NOBYPASSRLS` app role** (a superuser/owner connection passes vacuously: `invalid evidence`);
- an unset tenant setting returns 0 rows;
- two tenants through a pool of size 1 do not cross-read (T3);
- the tests are in the story's evidence set and their **output** is on disk.
Present is not passing: the tests are run (`2-catalogue-and-tests.md`).
