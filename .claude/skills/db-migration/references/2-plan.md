# /db-migration - Phases 2-3: The Plan and the Review Briefs

> Phases 2-3 of `SKILL.md`.

## Plan file structure

`docs/architecture/migration-plans/<feature>.md` (no template exists under
`.claude/docs/templates/` for migration plans; this structure is the skill's):

1. **Header**: feature, spec/research/threat-model links, stores, tenancy model,
   tool and layout, engine pins (hosted and bundle), date (`date +%F`), **Planned
   by**, Status (`Draft` / `Approved`), verdict.
2. **Change classification** (from Phase 1) and releases needed.
3. **Step table** (below).
4. **Backfill design**.
5. **Skipped-release hazard and self-hosted upgrade path**.
6. **Rollback**, step by step.
7. **Test matrix** and evidence paths.
8. **Release checklist items** (backup step, order, flags, approval of
   destructive steps).
9. **Open questions**, each with an owner.
10. **Lint results** and their resolution (filled in Phase 5).

### Step table

| Step | Release | Phase | Database change | Code change | Safe on its own because | Min engine version | Rollback |
|---|---|---|---|---|---|---|---|
| 1 | R+0 | Expand | e.g. add nullable `plan_code`, `lock_timeout` set | write both columns (flagged) | old code ignores the column | PG x | dev `down`; production: forward-fix |
| 2 | R+0 / R+1 | Migrate | backfill job (not a migration), batched | dual-write live | idempotent, resumable | - | stop the job; re-run |
| 3 | R+1 | Switch | none | reads move to the new column (flag) | both shapes still present | - | flip the flag back |
| 4 | R+n | Contract | drop old column after a guard | remove old reads/writes | guard proves no unmigrated rows and no supported version reads it | - | restore backup (production is forward-only) |

Every row must answer "if a customer is running exactly this schema and either
the previous or the next app version, does it work?". **A step that fails that
question is split.**

## Rules the plan applies (rules/migrations.md, stack reference)

- One logical change per migration file; a `down` for development; production is
  forward-only: a bad migration is fixed by a new one.
- **Postgres (read `docs/stack-reference/postgres/best-practices.md` section 3
  and cite the item; do not restate syntax from memory):** start every migration
  with a `lock_timeout` (the stack reference recommends a short value with a
  retry loop) and run migrations as the `migrator` role with its own
  timeouts, never as the application role; `CREATE INDEX CONCURRENTLY` cannot run
  in a transaction and can leave an `INVALID` index to drop and retry; `NOT
  VALID` then `VALIDATE`; `SET NOT NULL` via a validated CHECK; non-volatile
  `DEFAULT` avoids a rewrite; PG 17+ maintenance uses a safe `search_path`, so
  functions in expression indexes are schema-qualified. Features available only on
  newer majors (for example `uuidv7()` and `NOT NULL ... NOT VALID` are PG 18) are
  checked against the **bundle's** pinned engine and every supported
  upgrade-from engine, not only the hosted one.
- **Mongo (read `docs/stack-reference/mongo/best-practices.md` and
  `.claude/rules/mongo-data.md`):** `_v` on documents, lazy migration, `$jsonSchema`
  validators changed in the order writers-first then validator, `tenant_id`-leading
  indexes. Hosted pins `mongo:9.0.x`, the self-hosted bundle `mongo:8.0.x`
  (`pins.yaml`): a feature that exists only on 9.0 is not usable in the plan.
- **Tenancy:** every tenant-owned table has `tenant_id NOT NULL`, a
  tenant-leading index and RLS `ENABLE` + `FORCE` with policies; views over
  tenant tables are `security_invoker`; unique keys are `(tenant_id, natural_key)`.

## Backfill design (batched, idempotent, resumable)

The backfill is a **job**, not part of the DDL migration transaction.

- **Batching:** keyset pagination on the primary key (time-ordered UUIDs make
  this cheap), bounded batch size, a pause between batches; batch size, pause and
  timeouts are **configuration with typed defaults**, never literals in code.
- **Idempotent:** the update's predicate selects only rows not yet migrated
  (`new IS NULL` or equivalent), so re-running is a no-op on finished rows.
- **Resumable:** progress is derivable from the data (the predicate) or a
  checkpoint; killing the job at any point and restarting loses nothing.
- **Locking:** short transactions, `lock_timeout`/`statement_timeout` on the job's
  connection, no long-running transaction holding a snapshot.
- **Tenancy:** a cross-tenant backfill runs as the audited cross-tenant role
  (the stack reference's `admin_batch` pattern, `BYPASSRLS`, never the app role),
  logged; or per tenant with the tenant context set. State which.
- **Observability:** a span per run, counters for rows migrated and remaining, a
  log event per batch outcome (no row data, no PII), an alert if progress stalls
  (`/observability-plan`).
- **Verification before the contract step:** a read-only query proving zero
  unmigrated rows (and, for dual-written data, equality on a sample); its output
  is retained as evidence.
- **Ownership:** the job's code is a story for the stack lead via
  `data-lead`. This skill designs it and does not write application code.

## Skipped-release hazard and the self-hosted upgrade path

Customers on the self-hosted channel upgrade across several versions
(`rules/migrations.md`; stack reference section 3 item 7: every migration
idempotent, ordered, tested from N-2). A customer who goes R0 -> R3 **never ran
the R1/R2 application code** that dual-writes and runs the backfill. If the
contract migration at R3 drops the old column, it destroys data the backfill never
migrated. This is the plan's central hazard (design reasoning, not a sourced
fact). The plan must choose, with the user, one of:

| Option | How | Cost |
|---|---|---|
| A. Guarded contract | The contract migration starts with a guard that fails closed unless the migrate phase is complete, and the upgrade runner runs the registered, idempotent backfill before the contract step | needs a runner step for backfills; most flexible |
| B. Migrate inside the migration chain | Do the data move as an ordered migration step (batched in a non-transactional migration) so any path executes it | long upgrade for big tables |
| C. Stepping-stone releases | The installer refuses direct upgrades across a flagged release; the customer must pass through R2 | simplest for the code, strictest for the customer; needs the installer to enforce it |

Whichever is chosen, the **contract step ships no earlier than the oldest
supported upgrade-from version's successor of the switch release** (state the
release numbers), and the plan lists, for each supported upgrade-from version,
the sequence of migrations it will execute. The one-shot migration job runs
before the new app starts, the installer backs up before upgrade and supports
rollback (`rules/deploy.md`).

## Rollback, honestly

- **Development:** every migration has a working `down`.
- **Production:** forward-only. For each step the plan states the forward fix (a
  new migration) or the operational rollback (flag flip, stop the job). For the
  contract step the only rollback is **restore from the backup** the release
  checklist requires; say so and say what is lost since the backup.
- **Self-hosted:** rollback = the installer's pre-upgrade backup plus the previous
  version (`rules/deploy.md`); state which migrations make an old app version
  unable to read the new schema and therefore forbid a binary-only rollback.

## Fixed brief: `migration-specialist` (Phase 2)

Fill only the `{...}` slots. Add nothing else: no preferred option, no
expected size.

```text
Plan the migration for /db-migration. Return text only; write no file.

Feature: {slug}   Stores: {postgres | mongo | both}   Tenancy: {tenancy.model | unset}
Changes and classification: {the Phase 1 table, verbatim}
Tool and layout: {name and convention | UNDECIDED}   Next sequence: {NNNN}
Engines - hosted: {pin}  bundle: {pin}  oldest supported upgrade-from: {pin | unknown}
Supported upgrade-from versions: {list | unknown - ask the caller}
Table sizes: {list | unknown - treat as hot}
Inputs (read each): {paths with FOUND/ABSENT}

Method: follow .claude/skills/db-migration/references/2-plan.md (plan structure,
rules, backfill design, skipped-release hazard, rollback) and
.claude/rules/migrations.md. Postgres facts come from
docs/stack-reference/postgres/best-practices.md section 3, Mongo facts from
docs/stack-reference/mongo/best-practices.md; if a fact is not there write
NOT SOURCEABLE and name it - never fill it from memory.

Return: (1) the step table; (2) the proposed migration files: path, content, up
and down, whether non-transactional; (3) the backfill design; (4) the
skipped-release options with a recommendation and the migrations each supported
upgrade-from version executes; (5) rollback per step; (6) test matrix; (7)
release checklist items; (8) every destructive statement listed for explicit user
approval; (9) NOT SOURCEABLE items and open questions with owners.
```

## Review brief: `postgres-specialist`, `mongo-specialist`, `multitenancy-specialist` (Phase 3)

```text
Review this migration plan for /db-migration as {postgres-specialist |
mongo-specialist | multitenancy-specialist}. Return findings as text; edit no file.
Plan: {the migration-specialist output, verbatim}
Scope of your review: {postgres: lock levels and duration, index builds, constraint
validation, RLS and roles, query plans on the new shape | mongo: validators and
validation level/action, _v lazy migration, index order with tenant_id first |
multitenancy: tenant_id, tenant-leading indexes, RLS or schema/database rollout,
cross-tenant backfill role}
Sources: docs/stack-reference/{postgres|mongo}/ and .claude/rules/{migrations|mongo-data}.md.
For each finding: step, severity (blocks / fix / note), the source line, the fix.
Say what you could not verify. Never write engine syntax or a version from memory.
```
