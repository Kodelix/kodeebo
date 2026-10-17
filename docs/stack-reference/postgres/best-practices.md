# PostgreSQL — Best Practices (RLS multi-tenancy, migrations, ops)

Last verified: 2026-10-11. Marker: **[S]** = stated by the cited source; **[R]** = recommendation / inference by this doc's author, built on cited facts (verify in your own tests).

## 1. Tenant isolation with Row-Level Security (default tenancy model)

Source for all [S] below: [Row Security Policies](https://www.postgresql.org/docs/current/ddl-rowsecurity.html), [CREATE POLICY](https://www.postgresql.org/docs/current/sql-createpolicy.html), [CREATE ROLE](https://www.postgresql.org/docs/current/sql-createrole.html), [ALTER TABLE](https://www.postgresql.org/docs/current/sql-altertable.html).

### Who bypasses RLS (the classic leak)
- **[S]** Superusers and roles with `BYPASSRLS` always bypass RLS. Table owners bypass it unless `ALTER TABLE ... FORCE ROW LEVEL SECURITY`. `BYPASSRLS` defaults to `NOBYPASSRLS`; only a superuser/BYPASSRLS role can grant it.
- **[R]** Use at least two roles: `migrator` (owns tables, runs DDL, never used by the app at runtime) and `app` (LOGIN, `NOBYPASSRLS`, NOT owner, only DML grants). An `admin_batch` role (`BYPASSRLS`) is optional and exists only if an ADR accepts it, for audited cross-tenant jobs only: a standing bypass role turns one bug or one stolen credential into access to every tenant. Without it, cross-tenant work iterates tenants with the tenant context set, one transaction per tenant. Never connect the app as `postgres`. (Revised 2026-10-17: Kodeebo ADR-0001 forbids any `BYPASSRLS` runtime, job or support role.)
- **[R]** Apply `ENABLE` **and** `FORCE ROW LEVEL SECURITY` on every tenant table so an accidental owner connection is still filtered.
- **[S]** With RLS enabled and no policy, access is default-deny; if only RESTRICTIVE policies exist nothing is accessible (need at least one PERMISSIVE).
- **[S]** `TRUNCATE` and `REFERENCES` are not subject to RLS; unique/PK/FK checks bypass RLS, which is a covert channel (a duplicate-key error reveals a hidden row). Docs advise surrogate/generated keys instead of externally meaningful keys. **[R]** So: make tenant-scoped uniqueness `UNIQUE (tenant_id, natural_key)` and keep PKs as `uuidv7()`/surrogate.

### Policy shape
```sql
ALTER TABLE invoice ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice FORCE  ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON invoice
  USING      (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
  WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
```
- **[S]** `current_setting(name, missing_ok=true)` returns NULL when unset; **[S]** a USING expression that yields false/NULL silently suppresses rows, WITH CHECK false/NULL raises an error. **[R]** Therefore an unset tenant GUC = zero rows visible and writes rejected (fail closed). Do not use `COALESCE` to a default tenant. **[R]** Caveat with pooled sessions: after a transaction-local `set_config(..., true)` ends, the GUC reads `''` (empty string), not NULL, in that session, and `''::uuid` raises an error. Write the predicate as `tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid` so an unset context yields zero rows in both cases.
- **[S]** If `WITH CHECK` is omitted for ALL/UPDATE policies, `USING` is reused; for INSERT you need `WITH CHECK`. Be explicit.
- **[S]** Policies don't allow aggregates/window functions; expressions run with the invoking user's privileges. Combine PERMISSIVE (OR) with RESTRICTIVE (AND). **[R]** Put the hard tenant predicate in a RESTRICTIVE policy so any later permissive "sharing" policy cannot widen beyond the tenant.
- **[S]** `INSERT ... ON CONFLICT DO UPDATE` and `MERGE` are policy-checked; failing SELECT/USING in ON CONFLICT is an error, not silent skip. `SELECT ... FOR UPDATE/SHARE` needs both SELECT and UPDATE policies. There is no separate MERGE policy.
- **[S]** Views run with the **view owner's** rights unless created with `security_invoker`. **[R]** Always create views over tenant tables `WITH (security_invoker = true)`, otherwise the view owner (often the owner role) can bypass RLS.
- **[S]** Sub-SELECTs in policies can race; fixes: `FOR SHARE` in sub-select, stricter locking, or security-definer function. **[R]** Prefer policies that compare only the row's own `tenant_id` to the GUC — the docs call per-row-value-only policies "simplest and best-performing".

### Leakproof / side-channels
- **[S]** Only `LEAKPROOF` functions may run before the policy check; the planner may reorder others after it. **[R]** Never mark custom functions leakproof just for speed; instead make sure the `tenant_id` column is indexed and in the plan so the policy qual is an index condition. Error messages from casts/operators on user data can still be timing/error oracles — accept or avoid exposing raw DB errors to clients.

### Tenant context with connection pools / PgBouncer transaction mode
- **[S]** `set_config(name, value, is_local)`: `true` = value lasts only for the current transaction; `false` = rest of session ([functions-admin](https://www.postgresql.org/docs/current/functions-admin.html)).
- **[S]** PgBouncer transaction pooling "breaks client expectations of the server by design"; `SET/RESET`, `LISTEN`, `WITH HOLD CURSOR`, `PREPARE/DEALLOCATE`, session advisory locks, `LOAD` are listed as never compatible; protocol-level prepared statements work when `max_prepared_statements` is non-zero (default 200); `server_reset_query` isn't applied in transaction mode by default; `pool_mode` default is `session` ([features](https://www.pgbouncer.org/features.html), [config](https://www.pgbouncer.org/config.html)). The PgBouncer docs fetched do not explicitly address `SET LOCAL`.
- **[R]** Therefore: open a transaction per request and run `SELECT set_config('app.tenant_id', $1, true)` as the first statement (equivalently `SET LOCAL`, but `set_config` is parameterisable → no string interpolation/injection). Never use session-level `SET app.tenant_id` with transaction pooling: the value can leak to the next client that gets that server connection. Add an integration test that runs two tenants through a pool of size 1 and asserts no cross-read.
- **[R]** Reset on error paths: because `is_local=true` ends at COMMIT/ROLLBACK there is nothing to clean up — this is the main reason to prefer it.
- **[R]** Keep long-lived admin connections (migrations, `LISTEN/NOTIFY`, advisory-lock leader election) on a direct session-mode connection, not the transaction pool.
- PgBouncer security: latest fetched release is 1.26.0 (2026-09-23) fixing 3 CVEs (SCRAM nonce crash, packet-buffer infinite loop, unbounded SCRAM iterations); 1.25.1 (2025-12-03) fixed unauthenticated arbitrary SQL during auth with specific `search_path`/`auth_query` configs ([changelog](https://www.pgbouncer.org/changelog.html)). **[R]** Pin and patch PgBouncer like Postgres.

### pg_dump and RLS
- **[S]** `pg_dump` sets `row_security=off` by default so all rows are dumped; a role lacking bypass gets an error rather than a partial dump. `--enable-row-security` dumps only visible rows (use with `--inserts` since `COPY FROM` doesn't support row security) ([pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)). **[R]** Per-tenant export = `--enable-row-security --inserts` as a tenant-scoped role; full backups run as a superuser/BYPASSRLS role.

### Alternatives (when RLS isn't enough)
**[R]** Schema-per-tenant or database-per-tenant for tenants with contractual isolation; the RLS default fits many small tenants. Decision is an ADR, not covered by sources here.

## 2. Performance and indexing

- **[R]** Index `tenant_id` as the leading column of every composite index used by tenant queries (the policy qual is `tenant_id = ...`). PG 18 adds multicolumn B-tree **skip scan** ([Release 18](https://www.postgresql.org/docs/current/release-18.html)), which helps queries lacking early-column restrictions but does not replace a tenant-leading index. [S for the feature, R for advice]
- **[S]** `uuidv7()` (PG 18) generates time-ordered v7 UUIDs; `uuidv4()` alias added; optional `shift` interval; `uuid_extract_timestamp()`/`uuid_extract_version()` (added in 17) ([functions-uuid](https://www.postgresql.org/docs/current/functions-uuid.html), [Release 17](https://www.postgresql.org/docs/17/release-17.html)). **[R]** Prefer `uuidv7()` for PKs on write-heavy tables (index locality) — on PG < 18 generate in the app. UUIDv7 embeds creation time: treat as non-secret.
- **[S]** AIO: `io_method=worker` default, `io_workers` default 3, restart required; `io_uring` needs a liburing build; `pg_aios` view shows in-flight AIO ([runtime-config-resource](https://www.postgresql.org/docs/current/runtime-config-resource.html)). **[R]** Keep defaults; benchmark `io_uring` only on a Linux kernel/image you control (the official Docker image build flags: NOT SOURCEABLE).
- **[S]** PG 17+: `transaction_timeout`; `idle_in_transaction_session_timeout`, `statement_timeout`, `lock_timeout` all default 0 (disabled) and docs advise against setting them globally in `postgresql.conf`; `idle_session_timeout` is risky with connection-pool middleware ([runtime-config-client](https://www.postgresql.org/docs/current/runtime-config-client.html)). **[R]** Set per role: `ALTER ROLE app SET statement_timeout='5s'; ALTER ROLE app SET idle_in_transaction_session_timeout='30s';` and a separate `migrator` role with different values.
- **[S]** `VACUUM`/`ANALYZE` now recurse into partitions in 18; use `ONLY` for parent-only.

## 3. Safe migrations (zero/low-downtime)

Source: [ALTER TABLE](https://www.postgresql.org/docs/current/sql-altertable.html), [CREATE INDEX](https://www.postgresql.org/docs/current/sql-createindex.html), [runtime-config-client](https://www.postgresql.org/docs/current/runtime-config-client.html).

1. **[R]** Start every migration session with `SET lock_timeout = '3s'` (+ retry loop). **[S]** lock_timeout aborts a statement waiting longer than the limit for any lock; applies per lock acquisition. Without it a queued `ACCESS EXCLUSIVE` request blocks all later queries behind it (mechanism: **[R]**).
2. **[S]** `CREATE INDEX CONCURRENTLY`: no write-blocking lock, two table scans, waits for older transactions, cannot run inside a transaction block, one concurrent build per table at a time, may leave an `INVALID` index on failure (drop and retry, or `REINDEX INDEX CONCURRENTLY`), not supported on partitioned parents (build per-partition concurrently, then create the parent index non-concurrently — metadata only). **[R]** Migration tool must run such steps outside a transaction (e.g. a "no-transaction" migration) and check `pg_index.indisvalid` afterwards.
3. **[S]** `ADD CONSTRAINT ... NOT VALID` then `VALIDATE CONSTRAINT` (validate takes `SHARE UPDATE EXCLUSIVE`, doesn't block writes). FK add needs `SHARE ROW EXCLUSIVE` on both tables. Applies to CHECK and FK; in PG 18 also NOT NULL (`NOT VALID` support) ([Release 18](https://www.postgresql.org/docs/current/release-18.html)).
4. **[S]** `SET NOT NULL` skips the scan if a valid CHECK constraint proves no NULLs. **[R]** Pattern: `ADD CONSTRAINT c CHECK (col IS NOT NULL) NOT VALID` -> `VALIDATE` -> `SET NOT NULL` -> drop the CHECK.
5. **[S]** `ADD COLUMN` with a non-volatile DEFAULT needs no rewrite; volatile defaults, stored generated columns, identity columns, constrained domains rewrite the table. `ALTER COLUMN TYPE` rewrites unless binary-coercible and no collation change.
6. **[S]** `ATTACH PARTITION` scan avoided with a pre-validated CHECK; `DETACH PARTITION ... CONCURRENTLY` available.
7. **[R]** Expand/contract: ship additive migrations first, deploy code, then drop; self-hosted customers upgrade across versions so every migration must be idempotent and ordered, tested from N-2.
8. **[R]** Adding RLS to an existing table: `ENABLE`+`FORCE`, add policies in the same transaction (an enabled table with no policy is default-deny and will black out the app).
9. **[S]** PG 17+: maintenance operations use a safe `search_path`; functions in expression indexes must be schema-qualified ([Release 17](https://www.postgresql.org/docs/17/release-17.html)).

## 4. Backups and restore

Source: [Backup chapter](https://www.postgresql.org/docs/current/backup.html), [Continuous archiving](https://www.postgresql.org/docs/current/continuous-archiving.html), [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html), [pg_upgrade](https://www.postgresql.org/docs/current/pgupgrade.html).

| | Logical (`pg_dump`/`pg_dumpall`) | Physical (base backup + WAL archive) |
|---|---|---|
| What | SQL/custom/directory/tar dump of one DB; `pg_dumpall --globals-only` for roles/tablespaces | `pg_basebackup` (tar, `-Xstream`) + continuous WAL archiving |
| PITR | **No** | **Yes** (`recovery.signal`, `restore_command`, `recovery_target_time`/`_name`, `recovery_target_timeline`) |
| Cross-major restore | Yes | No (same major; whole cluster only) |
| Parallel | Directory format `-Fd -j N`; `pg_restore -j N` | n/a |
| Locking | Consistent snapshot, doesn't block readers/writers | Online |
| Incremental | no | **PG 17+**: `pg_basebackup --incremental`, needs `summarize_wal`; restore with `pg_combinebackup` |

- **[R]** Do both: nightly `pg_dump -Fd` (portable, per-DB, tested via restore) AND physical + WAL archive for PITR. A backup that has never been restored is not a backup — schedule an automated restore test.
- **[S]** `pg_dump` restore of a dump executes arbitrary code from source superusers — inspect dumps from untrusted sources. Use `--no-owner` for restoring under a different owner.
- **[S]** Monitor `pg_stat_archiver`; `archive_command` must return non-zero on failure; use `archive_timeout`/`pg_switch_wal()` for low-traffic systems.
- PITR tools (all fetched 2026-10-11):
  - **pgBackRest** — MIT, v2.59.3 (2026-10-04); repo was **archived 2026-04-27 then revived** with a sponsor coalition and releases resumed (2.59.0 on 2026-07-20) ([GitHub](https://github.com/pgbackrest/pgbackrest), [pgbackrest.org](https://pgbackrest.org/), corroboration: [Percona](https://percona.community/blog/2026/04/28/pgbackrest-is-archived-what-now/)). Features: parallel/async WAL push, full/diff/incr (block-level), lz4/zstd, repo encryption, S3/Azure/GCS. **[R]** Note the bus-factor/funding history when choosing it as the sole tool for a customer bundle.
  - **Barman** 3.20.1 (2026-09-29) ([pgbarman.org](https://pgbarman.org/)); licence and supported-PG matrix: NOT SOURCEABLE from the page fetched.
  - **WAL-G** — Postgres primary support, also MySQL/SQL Server, MongoDB (beta) ([GitHub](https://github.com/wal-g/wal-g)); release version/date NOT SOURCEABLE from the page fetched.
- **[S]** `pg_upgrade` for major upgrades: `--check` (dry run, safe even with old server running), `--link` (fast; unsafe to revert once new cluster started — restore from backup), `--clone`, `--swap` (18; destructive once started), `--jobs N`; statistics transferred by default in 18, then `vacuumdb --all --analyze-in-stages --missing-stats-only`; install new-version extension binaries first; unsupported reg* types (`regcollation`, `regconfig`, `regdictionary`, `regnamespace`, `regoper`, `regoperator`, `regproc`, `regprocedure`); checksum settings must match. **[R]** Self-hosted upgrade runbook: backup -> `--check` -> upgrade -> REINDEX FTS/trgm (18 collation change) -> analyze -> smoke test; for Docker, remember the 18 PGDATA path change.

## 5. Observability

- **[S]** `pg_stat_statements`: needs `shared_preload_libraries` (restart) + `CREATE EXTENSION` per DB; defaults `max=5000`, `track=top`, `track_utility=on`, `track_planning=off`, `save=on`; `compute_query_id` must be on; keys per (db, user, queryid, toplevel); `queryid` is not stable across major versions; only superuser/`pg_read_all_stats` see other users' query text; `pg_stat_statements_reset(userid, dbid, queryid, minmax_only)`; `pg_stat_statements_info.dealloc` shows evictions ([docs](https://www.postgresql.org/docs/current/pgstatstatements.html)).
- **[R]** Track: top by `total_exec_time`, `mean_exec_time`, `calls`, `rows`, cache hit = `shared_blks_hit/(hit+read)`, `temp_blks_written` (spills), `wal_bytes`, `parallel_workers_launched` vs `_to_launch` (18). Alert on `dealloc` growth (raise `pg_stat_statements.max`). Statement text can contain tenant data only via literals — normalised to `$n`, but disable `track` exposure to tenant-facing roles.
- **[S]** Related views: `pg_stat_io` and `pg_stat_checkpointer` (17+, replace dropped `pg_stat_bgwriter` columns), `pg_wait_events` (17), `pg_aios` (18), `pg_stat_progress_vacuum` (renamed columns in 17), `pg_stat_archiver`, `pg_replication_slots.inactive_since`/`invalidation_reason` (17). PG 19 beta adds `pg_stat_lock`, `pg_stat_recovery`.
- **[R]** Minimum dashboard: connections vs `max_connections`, longest transaction age (`pg_stat_activity`), lock waits, replication lag/slot retained WAL, autovacuum/bloat & dead tuples, archive failures, cache hit ratio, checkpoint frequency, disk free (WAL volume).

## 6. Security hygiene

- **[S]** MD5 passwords deprecated (18); **[R]** use `scram-sha-256`.
- **[S]** PG 17 adds `MAINTAIN` privilege/`pg_maintain` role, `sslnegotiation=direct`, `allow_alter_system`. PG 18 adds OAuth auth method (`oauth_validator_libraries`).
- **[R]** Run minor updates promptly: 18.6 alone fixed 24 CVEs.
- **[R]** Parameterise everything; for tenant GUC use `set_config($1,$2,true)`, never string-concat.

## 7. Testing with Testcontainers

- **[S]** Official modules exist for Node (`@testcontainers/postgresql`), Java (`org.testcontainers:testcontainers-postgresql`), Go (`modules/postgres`, `WithDatabase/WithUsername/WithPassword`), Python (`testcontainers[postgres]`), .NET (`Testcontainers.PostgreSql`); images pinned by tag, e.g. `postgres:16-alpine` ([testcontainers.com](https://testcontainers.com/modules/postgresql/)). Wait strategies/init-scripts: NOT SOURCEABLE from that page.
- **[R]** Pin the exact image used in prod (`postgres:18.6-...`), not `latest`. Run migrations from scratch AND from the previous release's schema dump. RLS tests must connect as the **non-owner, NOBYPASSRLS** `app` role (tests connecting as the container superuser pass vacuously). Test matrix: tenant A cannot SELECT/UPDATE/DELETE/INSERT-as B; unset GUC returns 0 rows; pooled connection reuse (PgBouncer container in transaction mode) doesn't leak; policies exist on every table with a `tenant_id` column (query `pg_policies` + `pg_class.relrowsecurity/relforcerowsecurity`). One container per test suite, truncate/rollback per test — or `CREATE DATABASE ... TEMPLATE` per test.
