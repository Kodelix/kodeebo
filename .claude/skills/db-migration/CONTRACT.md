# /db-migration - Handoff Contract

## Role in Pipeline
Plans and prepares schema/data changes (expand -> migrate -> contract) for Postgres
and Mongo. Called by `/team-data`, `/team-feature`, `/integration`; reads
`/design-spec`, `/research`, `/threat-model`; feeds `/create-stories`, `/dev-story`
(backfill, dual-write), `/release-checklist` (backup, order), `/story-done`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Feature slug or change description | Yes | - |
| `stack.data`, `tenancy.model`, `review_mode`, `automation` via `resolve_config` | Yes (unset = asked) | Yes |
| Migration tool/layout (ADR or existing migrations) | Needed to write files; absence = plan only, verdict NOT ASSESSED | Yes |
| `docs/stack-reference/pins.yaml`, `postgres/`, `mongo/` | Yes | Yes |
| Supported upgrade-from versions, table sizes | Asked; unknown size = hot, unknown range = NOT ASSESSED path | - |
| `design/specs/<feature>.md`, `docs/research/<feature>.md`, threat model | When they exist | Yes |

## Preconditions
- The change is classified; any change needing expand/contract is not planned as one step.
- Apply requires: plan approved, files written, lint resolved, a named non-production target, and a per-run yes.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. Apply result reported
separately: APPLIED / NOT APPLIED / not run / refused - production.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `docs/architecture/migration-plans/<feature>.md` | step table with release, safe-alone reason, rollback; backfill design; skipped-release option; upgrade path; test matrix; lint results with resolutions | written after approval |
| Migration file(s) in the project's layout | one logical change per file, `lock_timeout`, online forms, `down` for development | written by `migration-specialist` at approved paths |
| `production/qa/evidence/<STORY-ID>/migration-<NNNN>.md` (or `production/qa/migration-<feature>-<date>.md`) | lint output, test-matrix result, apply record | written after approval |

## Output Guarantees
- The real `migration-lint.sh` output is shown line by line; unscanned files are named; the lint is never presented as a verdict.
- Destructive statements appear only in a contract phase with explicit approval and a release-checklist backup step.
- No production apply; no credential in any command, file or transcript.

## Immutability Rules
- Existing migrations are never edited; a bad migration is fixed by a new one.
- No application code (dual-write, backfill job, read switch) is written here.
- Specs, ADRs and stories are not edited here.
