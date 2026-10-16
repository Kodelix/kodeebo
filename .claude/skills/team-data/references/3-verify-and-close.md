# /team-data — Phases 7–8: Verification and Report

> Part of `/team-data`. Read again if the conversation was compacted.

## 1. Phase 7 — the test matrix (real dependencies)

Commands come from the `layer-checks.md` lookup table in the `dev-story` skill folder
(`.claude/skills/dev-story/`) and the repo's own scripts; Gradle task names and
`package.json` scripts are confirmed in the build files first. Integration tests run on
**real** Postgres/Mongo/Redis-protocol containers via Testcontainers — never a mocked
database or cache (`testing-standards.md`); images and tags come from
`docs/stack-reference/pins.yaml`, and a mismatch is reported. A missing container
runtime makes every such cell `not run — no container runtime`. Each cell is `passed` /
`FAILED` / `not run — <reason>`.

**Who runs what.** This skill itself runs only `bash .claude/scripts/migration-lint.sh`
(granted). The Testcontainers suites, backfill dry runs, `EXPLAIN` / `explain()`
plans, `docker compose` calls and every other shell command of this matrix are run
by `test-automation-engineer` (integration and tenant-isolation cells) or the owning
specialist (`postgres-specialist` / `mongo-specialist` for query plans) through
`Agent`; their output comes back in the return contract, and a cell nobody ran is
`not run`. No destructive command (`down -v`, drop) is ever run.

| Check | Notes |
|---|---|
| Migration **up on an empty database** | `testing-standards.md` "Every migration" |
| Migration **up on a seeded database** | seeded to realistic shapes; production data never used |
| Migration **down** (development only) | production is forward-only |
| Each **intermediate release state** is safe alone: the app's integration suite is green after the expand step, after the migrate step, and after the contract step | the step table is the checklist |
| Upgrade from the **oldest supported version** (self-hosted multi-version path) | `migration-specialist`'s matrix; no fixtures → `not run — no upgrade fixtures` |
| `bash .claude/scripts/migration-lint.sh` on every migration file | real output; unscanned files named |
| Backfill: idempotent (run twice → same state), resumable (kill mid-run → completes), tenant-batched | dev database |
| **Repository adapters**: round-trip, not-found, constraint violation, pagination boundaries | per adapter |
| **Tenant isolation**: tenant A's rows invisible to tenant B at the repository **and** under the database-level policy (RLS with the pooler's tenant context set per transaction); an unscoped query returns nothing or errors | `/tenant-check` for the tenant-owned tables; **never waived at `qa.level: minimal`** |
| **Outbox**: crash between commit and publish → the event is still delivered; duplicate delivery → the consumer applies once; poison message → DLQ | `messaging-specialist`'s cases |
| **Cache**: hit, miss, invalidation on write, TTL expiry, **cache down → source**, key contains tenant | per the decision record |
| **Query count**: a read path stays within its budget (≤ 5 per request) — a query-count assertion in a test, no N+1 | `performance-standard.md` |
| **Query plans** for each hot query on realistic volume: `EXPLAIN (ANALYZE, BUFFERS)` for Postgres, `explain("executionStats")` for Mongo, saved with the data volume stated | needs a dev database seeded to volume; otherwise `not run — no representative data` and the verdict is capped at `NOT ASSESSED` for a budgeted path |
| Load test of a budgeted hot path | `/load-test`; ADVISORY unless `performance.enforce: block` |
| DSAR export/erase end to end for new personal data | `privacy-compliance-specialist`'s criteria |
| Backup/restore: for a **new** store or a changed backup scope, a restore drill with date, duration and row-count verification saved under `production/qa/evidence/` | not performed → `not run` and a release-checklist item; **a backup never restored counts as no backup** |

`/dependency-audit` is not required unless a new driver or library entered the build;
if one did, `osv-scanner`/`govulncheck` run per `layer-checks.md` or read `not run`.

Spawn the reviewers **in parallel** (named paths, return contract): `data-lead` (final
review of the implemented ripple against the brief and its Senior Bar — a grep of
queries across context folders is part of it), and at `studio` size
`privacy-compliance-specialist`, `security-lead`, `performance-engineer` and
`infra-engineer` with the adversarial instruction. A `FAILED` cell is shown with its
output and not auto-fixed: send it back to the lead, or stop.

## 2. Phase 7 — run and observe

`.claude/docs/run-and-observe.md`. `test-automation-engineer` (or the backend lead) brings up the dev stack (never production; staging only if the user names it explicitly); apply the migrations to the
**dev** database (that is the user's run in `/db-migration`, not this skill's — if
unapplied, say so and report `not run`), call the endpoints or jobs that use the new
schema as each role and with the negative paths (other tenant, no token), and retain
request/response (secrets redacted), one trace, and the relevant log lines in
`production/qa/evidence/<STORY-ID>/`. Capture the cache hit/miss and the outbox row
lifecycle where applicable. A capture that was not retained is an assertion, not
evidence.

## 3. Phase 8 — report and checkpoint

Ask: "May I write the report to `production/data/<slug>/team-data-report.md`?" Then
update `production/session-state/active.md` after every gate and at the end (the
checkpoint — exempt from the prompt; replace this pipeline's own block, do not
append history; `## Studio flow` belongs to `/studio` alone, and the `Flow:` line
names the running flow):

```markdown
## Data pipeline — <slug>
**Goal:** <one sentence>
**Flow:** data-change (team-data)   **Started:** <date>
**Step:** <n>/8 — <phase name>   **Waiting on:** <gate | /db-migration run by the user | nothing>
**Artifacts:** <paths, newest first>
**Skipped:** <step — reason>
**Blockers:** <list or none>
**Next:** <exact command, e.g. `/team-data resume <slug>`>
```

**Checkpoint.** The same update follows `.claude/docs/checkpoint-handoff.md`:
also overwrite `Current task` (`/team-data <slug> — <verdict>`), `Next step` (the
block's **Next:** command), `Blocked on`, `Files in progress` and `Open
questions` in the `<!-- CHECKPOINT -->` block and append the Notes line; leave
the `Flow:` line to `/studio` and other skills' blocks alone. Still updated when
the run ends BLOCKED or the report write is declined.

End with: what was done (paths); what was not done and why; the migration state as the
user reported it (`APPLIED to <env>` / `NOT APPLIED` / `not run`); the release-checklist
items owed (backup step before each destructive step, migration order, restore drill);
**Not run / not checked** (unrun cells, MongoDB backup method `NOT SOURCEABLE`, missing
upgrade fixtures, no representative data); the next command.
