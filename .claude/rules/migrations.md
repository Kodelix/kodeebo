---
paths:
  - "**/migrations/**"
  - "**/*.sql"
---

# Database Migration Rules (PostgreSQL)

- One logical change per migration; filename `NNNN_<verb>_<object>.sql` (or the tool's convention per ADR).
- Every migration has a **down** for development; production is forward-only — a bad migration is fixed by a new one.
- **Expand → migrate → contract** for any change a running version depends on: add new column/table, dual-write/backfill, switch reads, remove old in a later release. Self-hosted customers upgrade across several versions — each step must be safe on its own.
- Never in one step on a hot table: `ALTER COLUMN TYPE`, `ADD COLUMN ... NOT NULL` without a default, `CREATE INDEX` without `CONCURRENTLY`, adding a foreign key without `NOT VALID` + `VALIDATE` later. Set `lock_timeout` and `statement_timeout` in migrations.
- `DROP`/`TRUNCATE`/data-deleting statements need explicit user approval and a backup step in the release checklist.
- Backfills run in batches outside the migration transaction, idempotent and resumable.
- Every tenant-owned table has `tenant_id NOT NULL`, an index leading with `tenant_id`, and an RLS policy (per `tenancy.model`).
- Money as `bigint` minor units + currency; timestamps `timestamptz`; IDs `uuid` (v7) or ULID — never `serial` exposed externally.
- Constraints in the database (NOT NULL, CHECK, UNIQUE, FK) back up domain invariants.
- Tested: up on empty, up on seeded, down (dev), and the integration suite green after.
