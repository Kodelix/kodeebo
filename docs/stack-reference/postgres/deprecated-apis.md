# PostgreSQL — Deprecated / Removed APIs

Last verified: 2026-10-11. "Deprecated" = still works, will be removed; "Removed" = gone in that version.

| Deprecated / removed | Replacement | Since | Source |
|---|---|---|---|
| MD5 password authentication / MD5-hashed role passwords (deprecated; warnings on CREATE/ALTER ROLE; silence with `md5_password_warnings=off`) | `scram-sha-256` (`password_encryption`) | 18 (deprecated; client warning setting also in 19 beta) | [Release 18](https://www.postgresql.org/docs/current/release-18.html), [CREATE ROLE](https://www.postgresql.org/docs/current/sql-createrole.html) |
| RADIUS authentication (removed) | another auth method (SCRAM, cert, LDAP, OAuth) | 19 (beta, not GA) | [19 Beta 1](https://www.postgresql.org/about/news/postgresql-19-beta-1-released-3313/) |
| `pg_backend_memory_contexts.parent` column | `path` column (also levels now 1-based) | 18 (removed) | [Release 18](https://www.postgresql.org/docs/current/release-18.html) |
| Rule privileges in GRANT/REVOKE | none (were non-functional since 8.2) | 18 (removed) | [Release 18](https://www.postgresql.org/docs/current/release-18.html) |
| Unlogged partitioned tables | logged partitioned table (or unlogged leaf partitions as supported) | 18 (disallowed) | [Release 18](https://www.postgresql.org/docs/current/release-18.html) |
| `COPY FROM` CSV treating `\.` as EOF | place `\.` alone on its own line / just end input | 18 | [Release 18](https://www.postgresql.org/docs/current/release-18.html) |
| `old_snapshot_threshold` | none (feature removed; use `idle_in_transaction_session_timeout`, `transaction_timeout` to bound long transactions — mapping is analysis, not in notes) | 17 (removed) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| `db_user_namespace` | none | 17 (removed) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| `adminpack` extension | none (was for pgAdmin III) | 17 (removed) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| `pg_stat_bgwriter.buffers_backend`, `.buffers_backend_fsync` | `pg_stat_io` | 17 (removed) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| `pg_stat_bgwriter` checkpoint columns | `pg_stat_checkpointer` view | 17 (moved) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| `pg_stat_statements.blk_read_time` / `blk_write_time` | `shared_blk_read_time` / `shared_blk_write_time` | 17 (renamed) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| `pg_collation.colliculocale`, `pg_database.daticulocale` | `colllocale`, `datlocale` | 17 (renamed) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| `pg_stat_progress_vacuum.max_dead_tuples` / `num_dead_tuples` | `max_dead_tuple_bytes` / `num_dead_item_ids` | 17 (renamed) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| Unqualified function names inside expression indexes / matviews relying on caller `search_path` | schema-qualify or set function `search_path` | 17 (maintenance ops use safe search_path) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| `uuid-ossp` / `pgcrypto` just to get random UUIDs | built-in `gen_random_uuid()` / `uuidv4()`; time-ordered: `uuidv7()` | `uuidv7()`/`uuidv4()` added in 18 (the claim that `gen_random_uuid()` is core-built-in: shown in current functions-uuid docs; version it appeared: NOT SOURCEABLE here) | [functions-uuid](https://www.postgresql.org/docs/current/functions-uuid.html) |
| `ALTER SYSTEM`-driven config in managed images | `allow_alter_system=off` to forbid | 17 (new control, not a deprecation) | [Release 17](https://www.postgresql.org/docs/17/release-17.html) |
| Docker: mounting volume at `/var/lib/postgresql/data` on 18+ | mount `/var/lib/postgresql`; PGDATA `/var/lib/postgresql/18/docker` | 18 image | [Docker image](https://hub.docker.com/_/postgres) |
| PostgreSQL 14 (and 13 and older) | upgrade to 18 | 14 EOL 2026-11-12; 13 EOL 2025-11-13 | [Versioning policy](https://www.postgresql.org/support/versioning/) |
