# Migration Plan: [change]

> Written by `/db-migration` before any migration file. Rules: `.claude/rules/migrations.md`.
> Output of `bash .claude/scripts/migration-lint.sh` is attached for every file.

## Change
<!-- What changes in the data model and why; link spec, ADR, story. -->

## Phases (expand → migrate → contract)
| Phase | Release | Migration files | App change | Safe to run alone? |
|---|---|---|---|---|
| Expand | vX.Y | `NNNN_add_...` | dual-write / read old | yes |
| Migrate | vX.Y | backfill job | switch reads | yes |
| Contract | vX.Y+1 | `NNNN_drop_...` | remove old path | after all installs ≥ vX.Y |

## Locking and safety
- `lock_timeout` / `statement_timeout`:
- Indexes `CONCURRENTLY` (non-transactional migration):
- Constraints `NOT VALID` → `VALIDATE` later:
- Tables touched and their size / write rate:

## Backfill
<!-- Batched, idempotent, resumable: batch size, ordering key, throttle, progress metric, how to resume. -->

## Tenancy
<!-- tenant_id NOT NULL, index leading with tenant_id, RLS policy (ENABLE + FORCE), cross-tenant test. -->

## Self-hosted upgrade path
<!-- Which customer versions can upgrade directly; skipped-version behaviour; backup-before-upgrade step in the installer. -->

## Rollback
<!-- Dev: down migrations. Production: forward fix plan; what is irreversible (DROP/TRUNCATE) and the backup that covers it. -->

## Verification
- [ ] Up on empty DB · up on seeded DB · down (dev) · integration suite green
- [ ] migration-lint output reviewed (DANGER items approved by the user)
- [ ] Backup verified restorable before contract phase
