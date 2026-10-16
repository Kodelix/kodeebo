# PostgreSQL — Breaking / Behaviour Changes (17 → 18, plus 19 beta preview)

Last verified: 2026-10-11. Every row cites a fetched page. Impact column = what it means for a multi-tenant RLS SaaS shipped via Docker Compose + self-hosted upgrades (impact column is analysis, not sourced).

## 17 → 18 (GA 2025-09-25) — [Release 18 notes, "Migration to Version 18"](https://www.postgresql.org/docs/current/release-18.html)

| Change | Detail | Impact for us |
|---|---|---|
| Data checksums on by default | `initdb` enables checksums; opt out with `--no-data-checksums`. `pg_upgrade` requires old/new clusters to have the **same** checksum setting. | Upgrading a 17 (no checksums) customer cluster into a fresh 18 cluster fails unless you init the new cluster with `--no-data-checksums` (or enable checksums on the old one first). Handle in the upgrade script. |
| Docker image PGDATA/VOLUME change | 18+ images use version-specific PGDATA (`/var/lib/postgresql/18/docker`); mount `/var/lib/postgresql`. [Docker image](https://hub.docker.com/_/postgres) | Compose files that mount `.../data` silently lose persistence on 18. Update every compose file and the self-hosted bundle. |
| MD5 password auth deprecated | `CREATE/ALTER ROLE` with MD5 passwords warns; silence via `md5_password_warnings=off`; removal in a future major. | Use SCRAM-SHA-256 everywhere; check PgBouncer `auth_type`/userlist hashes. |
| VACUUM/ANALYZE recurse into partition children by default | New `ONLY` option restores parent-only behaviour. | Partitioned tenant tables: manual VACUUM/ANALYZE now touches all children (longer). |
| `COPY FROM` CSV: `\.` no longer EOF marker | `\.` must be alone on its line; `psql \copy` still treats it as EOF; old psql vs 18 server may misbehave. | Re-test CSV import/export jobs. 18.6 also requires a `\.` terminator after failing `COPY ... FROM STDIN` in test scripts ([18.6 notes](https://www.postgresql.org/docs/release/18.6/)). |
| AFTER triggers run as the role active when the event was **queued** | Previously the role at fire time (e.g. COMMIT). | Matters if tenant context is switched via `SET ROLE` mid-transaction. Re-test trigger-based audit/outbox code. |
| Time-zone abbreviation lookup order changed | Session TZ abbreviations checked before `timezone_abbreviations`. | Low. |
| Unlogged partitioned tables disallowed / `SET [UN]LOGGED` enforced | | Low. |
| Rule privileges removed from GRANT/REVOKE | Non-functional since 8.2. | None. |
| `pg_backend_memory_contexts`: `parent` column removed (use `path`); `level` and `pg_log_backend_memory_contexts()` now 1-based | | Observability dashboards using this view. |
| Full-text search uses the cluster default collation provider (ICU/builtin/libc) instead of always libc | Notes recommend reindexing all FTS and `pg_trgm` indexes after `pg_upgrade`. | Add `REINDEX` step for FTS/trgm indexes to the upgrade runbook if cluster provider is not libc. |

Behaviour worth knowing (not "breaking", same page): generated columns default to **virtual**; `io_method` default `worker` (restart required to change; `io_uring` needs a liburing build) — [runtime-config-resource](https://www.postgresql.org/docs/current/runtime-config-resource.html); `pg_upgrade` now retains optimizer statistics (extended stats not preserved) — [pg_upgrade](https://www.postgresql.org/docs/current/pgupgrade.html).

## 16 → 17 (GA 2024-09-26) — [Release 17 notes](https://www.postgresql.org/docs/17/release-17.html)

| Change | Detail |
|---|---|
| Safe `search_path` during maintenance ops | `ANALYZE`, `CLUSTER`, `CREATE INDEX`, `VACUUM`, `REINDEX`, matview refresh etc. run with a safe search_path: functions used by expression indexes / matviews must be schema-qualified or set their own `search_path` or maintenance may fail. **Common breakage in RLS helper functions used inside index expressions.** |
| `old_snapshot_threshold` removed | |
| `SET SESSION AUTHORIZATION` now based on session user's superuser status at command time | |
| `db_user_namespace`, `adminpack` removed | |
| `pg_walfile_name()`/`_offset()` report current segment at file boundary | |
| `pg_stat_bgwriter`: `buffers_backend`, `buffers_backend_fsync` removed (moved to `pg_stat_io`; checkpoint columns moved to new `pg_stat_checkpointer`) | |
| `pg_stat_statements`: `blk_read_time`/`blk_write_time` renamed `shared_blk_read_time`/`shared_blk_write_time` | Update dashboards/queries. |
| Catalog renames: `pg_collation.colliculocale` -> `colllocale`; `pg_database.daticulocale` -> `datlocale` | |
| `pg_stat_progress_vacuum`: `max_dead_tuples` -> `max_dead_tuple_bytes`, `num_dead_tuples` -> `num_dead_item_ids` | |
| Interval `ago` only at end of value | |

## 18.x minor-release actions — [18.6 notes (2026-08-13)](https://www.postgresql.org/docs/release/18.6/)

- 24 CVEs fixed; no dump/restore needed.
- New `output_plugin_libraries` parameter restricts logical-decoding output plugins (CVE-2026-6471) — review if using custom logical-decoding output plugins.
- Run the GIN `reltuples` check query from the notes; reindex `contrib/btree_gist` and `contrib/ltree` indexes if used; if coming from < 18.2, read the 18.2 section (E.4).
- `uuidv7()` fix: out-of-range `shift` previously produced a garbage UUID (per release-note summary; see [functions-uuid](https://www.postgresql.org/docs/current/functions-uuid.html) for the 1970..~10889 range and error behaviour).

## PostgreSQL 19 (BETA — Beta 4 on 2026-09-24; do not ship) — [19 Beta 1 announcement](https://www.postgresql.org/about/news/postgresql-19-beta-1-released-3313/)

Listed incompatibilities (may change before GA): JIT disabled by default; `default_toast_compression` defaults to `lz4`; RADIUS authentication removed; `vacuumdb --analyze-only` now analyzes partitioned tables by default. Not breaking but relevant: data checksums can be toggled online; parallel autovacuum; `REPACK ... CONCURRENTLY`; `pg_stat_lock`; `ALTER TABLE ... MERGE/SPLIT PARTITIONS`; `GROUP BY ALL`; MD5 client-side warning. Full list: NOT SOURCEABLE beyond the announcement (the 19 release-notes page was not fetched).
