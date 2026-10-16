# /team-data — Phases 5–6: Migration Hand-off, Stories, Ripple

> Part of `/team-data`. Read again if the conversation was compacted.

## 1. Phase 5 — print the `/db-migration` command and pause

`/db-migration` is user-run: it writes the plan, the migration files, runs
`migration-lint.sh`, and owns the separate, explicit apply gate. This skill does
none of that. Print:

```
Run (you):  /db-migration <slug>
  Inputs it will read: production/data/<slug>/data-change-brief.md, design/specs/<slug>.md,
                       docs/research/<slug>.md, docs/architecture/threat-models/<slug>.md (if any)
  Give it: the step table from the brief (its Phase 2 plan starts from it), the hot-table
           sizes you know, the supported upgrade-from versions.
  It will:   write docs/architecture/migration-plans/<slug>.md and the migration files,
             run bash .claude/scripts/migration-lint.sh, run the test matrix, and ask
             separately before applying anything to a named non-production target.
Then:       /team-data resume <slug>
```

Save the checkpoint (`Waiting on: /db-migration run by the user`) and stop. Work that
does not depend on the schema may continue in the meantime: the cache decision, the
messaging design and the contract change (`/api-contract`).

## 2. On `resume` — verify the artifacts on disk

Do not trust a statement that it was run:

- `docs/architecture/migration-plans/<slug>.md` exists and its step table matches the
  approved brief (releases, rollback, backfill, skipped-release option);
- the migration files exist in the project's layout, one logical change per file, with
  `lock_timeout`/`statement_timeout`, online forms (`CONCURRENTLY`, `NOT VALID` then
  `VALIDATE`), and a `down` for development;
- the lint record: re-run `bash .claude/scripts/migration-lint.sh` on those files and
  show its **real output line by line**, naming any file it did not scan; every
  DANGER/WARN/MISSING is resolved (fixed, or approved with the reason) — unresolved →
  `BLOCKED`;
- the migration evidence record (`production/qa/evidence/<STORY-ID>/migration-*.md` or
  `production/qa/migration-<slug>-<date>.md`) and the apply result, which is reported
  as the user stated it: `APPLIED to <env>` / `NOT APPLIED` / `not run`. **This skill
  never applies**, and an apply the user did not report is `NOT APPLIED`.

Artifacts absent → Phase 5 is `NOT ASSESSED — /db-migration not run`; Phases 6–7
cannot establish anything about the schema and the verdict cannot exceed that. Offer:
run it now, or stop with the partial report.

## 3. Phase 6a — stories

If stories for this change exist, use them. Otherwise `/create-stories` from the brief:
a **Data** story per release step (Integration type; expand release, migrate release,
contract release as separate stories — the contract story is Blocked until its release
window), a backend persistence story, a Security story for tenant isolation of a
tenant-owned table, a Config story for retention periods, and a Performance story when
a budgeted hot path is involved. Contract-first and data-first order: Contract → Data →
Backend → Clients.

**Gate — story list.** Present with type, lane, owner, dependencies and the evidence
each produces; the user approves. `/dev-story`'s prerequisites apply per story
(research note, threat model for PII/billing/licensing data, ADRs `Accepted`).

## 4. Phase 6b — the ripple (backend lead)

Resolve the lead from `stack.backend`. Spawn it (and `principal-engineer` for module
boundaries only if a new port is introduced) with: the brief's **ripple list**, the
migration plan and files, the cache decision record, the messaging design, the
contract change record (if any), the stories, `docs/stack-reference/<layer>/` and
`pins.yaml`, `.claude/rules/` for the layer plus `migrations.md`, `cache-code.md`,
`mongo-data.md` as they apply. It first returns the files it will create or change;
ask once for the full set ("May the lead create/change these files?"); then it writes
`production/data/<slug>/impl-ripple.md` (files, commands run with real output
summaries, each check that could not run as `not run — <reason>`).

Instruct, plainly:

- **Every query tenant-scoped**, the tenant from the authenticated context, never the
  request; the database-level isolation backs the application predicate.
- Repository methods purpose-built per use case (no generic `Repository<T>`); the
  persistence adapter implements a port declared by `app`; transactions owned by the
  use case; **no SQL in handlers**.
- **Outbox**: the event row is written in the same transaction as the state change; a
  relay publishes; consumers are idempotent by event ID. No code path writes to the
  database and then a broker, Mongo or the cache in sequence without an outbox or a
  reconciliation job.
- **Cache adapter** exactly per the decision record: key schema with tenant and
  version, TTL with jitter, invalidation on write, stampede control, and **cache-down
  degrades to the source** (tested). Only the command subset common to Redis, Valkey
  and Dragonfly in shared code.
- **Dual-write / backfill code** from the plan: batched, idempotent, resumable,
  outside the migration transaction, tenant-by-tenant; runnable against the dev
  database only from here — **a backfill against real data is a release-time action
  the user performs**.
- DSAR export/erase paths, retention jobs and TTL indexes as designed; no PII in
  telemetry; money, time and ID conventions as in the review.
- Seed data in `tools/seed/` updated; no production data in tests.
- A contract change goes through `/api-contract` before any handler changes.
- Tests first for Logic; migration, outbox, cache and isolation tests are part of the
  change (Phase 7 lists them).

At `small`+ spawn `test-automation-engineer` in parallel for the integration and
migration test gaps (named path `production/data/<slug>/data-tests.md`); it never
weakens or skips an existing test.
