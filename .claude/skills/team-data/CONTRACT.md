# /team-data - Handoff Contract

## Role in Pipeline
Cross-specialist orchestration of one schema or data change: `data-lead` review,
store-specialist designs, the rollout plan, the `/db-migration` hand-off (user-run),
and the backend ripple (persistence, outbox, cache, tenancy). Called by `/studio`
(flow `data-change`), by `/team-feature` (when a change spans two or more of schema,
cache and messaging, or touches a tenant-owned table), and directly. Calls
`/cache-design`, `/tenant-check`, `/api-contract`, `/architecture-decision`,
`/create-stories`; feeds `/code-review`, `/story-done`, `/release-checklist`,
`/load-test`, `/team-qa`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Feature slug or change description; or `resume [slug]` | Yes | - |
| `project.yaml` via `resolve_config` (`stack.data`, `tenancy`, `distribution`, backend, `team.size`, `review_mode`, `automation`, `qa.level`, `testing.strict`, `performance.enforce`) | Yes; `data` or a needed `tenancy` unset = STOP | Yes |
| Spec, research note, threat model, domain map, registry, ADRs, existing migrations and tool/layout | Inventoried FOUND or ABSENT | Yes |
| `docs/stack-reference/` postgres, mongo, redis, dragonfly and `pins.yaml`; `.claude/rules/migrations.md`, `mongo-data.md`, `cache-code.md` | Yes | Yes |
| Table sizes, supported upgrade-from versions | Asked; unknown size = hot; unknown range = `NOT ASSESSED` path | - |

## Preconditions
- Read and write patterns are written before any design is accepted.
- A store not in `stack.data` is an ADR decision, not part of this run.
- `/db-migration` is run by the user; without its artifacts the run is `NOT ASSESSED`.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence: BLOCKED,
NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. Consumed: `/db-migration` result
(`APPLIED` / `NOT APPLIED` / `not run` as the user reports), `migration-lint.sh`
observations, CTO-ADR (APPROVE / CONCERNS / REJECT / NOT ASSESSED / skipped),
SL-TENANT-ISOLATION via `/tenant-check`.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `production/data/<slug>/data-lead-review.md` | read patterns first, store, ownership, tenancy, invariants, consistency, retention, backup impact, bundle rules | by `data-lead` |
| `production/data/<slug>/<specialist>.md`, `data-change-brief.md` | per-specialist designs; step table by release, ripple list, test matrix, destructive steps, risks | named paths, bounded exception |
| `docs/architecture/cache-designs/<slug>.md` | via `/cache-design` (or a written "no cache") | its own approval |
| Migration plan and files | via `/db-migration` | user-run; never written or applied here |
| Persistence, outbox, cache and tenancy code and tests | the approved file set only | by the backend lead |
| `production/data/<slug>/impl-ripple.md`, `data-tests.md`, `review-*.md` | implementation report, test gaps, reviews | named paths |
| `production/qa/evidence/<STORY-ID>/` | run-and-observe captures, query plans, restore-drill record | retained |
| `production/data/<slug>/team-data-report.md` | classification, decisions, step table, lint output, test matrix with every cell, `Not run / not checked` | after approval |

## Output Guarantees
- Every matrix cell is `passed`, `FAILED` or `not run - reason`; lint output is shown line by line with unscanned files named.
- Tenant-isolation tests for a tenant-owned table are never waived; an absent one is `BLOCKED`.
- A destructive statement appears only in a contract-phase story with its own approval and a backup step in the release checklist.
- MongoDB backup/restore method is `NOT SOURCEABLE` until researched; it is never recalled.
- A restore drill not performed is `not run`; a backup never restored counts as no backup.

## Immutability Rules
- No migration applied, no backfill on real data, no deletion, no credential or connection string in any command, file or transcript.
- Existing migrations are never edited; schema changes are written only through `/db-migration`.
- No commit, push or deploy; no story marked Complete; no ADR moved to Accepted by this skill.
