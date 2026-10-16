# /core-upgrade - Handoff Contract

## Role in Pipeline
Moves a product's `core.version` pin: reads the core's changes, plans and applies
the migration, verifies with the product's own tests, then edits the pin. Called
by `/studio` (flow `core`) and, in the core repo's release cycle, after
`/core-release`. Reads what `/core-release` produces (module CHANGELOGs with
Breaking / Deprecated / Migration headings, release notes); hands data and
contract steps to `/db-migration`, `/team-data`, `/api-contract`, `/team-api`;
feeds `/code-review`, `/story-done`, `/dependency-audit`, `/tech-debt`,
`/release-notes`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| `<release-tag>` / `latest` / `check`; `--module` | Optional (asked) | - |
| `project.yaml`: `core.track`, `core.repo`, `core.version`, `core.modules`; `stack` | Yes | `core.version` edited in Phase 6 only |
| Core repo at `core.repo`: tags, module CHANGELOGs, port files, build files, config schema, release policy | Yes; unreadable = `NOT ASSESSED` | Yes - never written |
| Product code roots (`resolve_code_root`), `deploy/`, `.env` examples | Yes; empty = scan `not run` | Changed only by the stack lead under the approved file set |
| `docs/stack-reference/pins.yaml`, `project-coherence.sh` | Yes | Yes |

## Preconditions
- `core.version` and `core.modules` are set (else `/core-use`); the track matches `stack.backend`.
- The target is a released tag above the pin (a lower target is a rollback, refused).

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. In `check` mode COMPLETE
means every consumed module's changes were read; the report names any that were
not.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| Product code/config/test changes | the approved file set only | by the stack lead |
| `project.yaml` `core.version` (and a renamed module in `core.modules`) | the from -> to diff shown in Phase 6 | after an explicit yes; always prompts |
| `production/core/upgrade-<from>-to-<to>-<date>-plan.md`, `-impl.md` | plan and implementation report | named paths, written by agents |
| `production/core/upgrade-<from>-to-<to>-<date>.md` | per-module summary, CHANGELOG-vs-diff findings, impact table, evidence with `not run` rows, deferred deprecations with owner and core removal version/date, pin diff, verdict | written after approval |
| `production/qa/evidence/core-upgrade-<to>/` | run-and-observe evidence | retained |

## Output Guarantees
- Every consumed module and every intermediate release is read, or named as unread with the reason; a missing "Breaking" heading is never reported as "no breaking changes".
- The CHANGELOG is checked against the port diff; the diff wins on disagreement and the disagreement is reported.
- The pin moves only after the dependency resolves and no check is `FAILED`; a `not run` check is listed and caps the verdict.
- Removed symbols are never deferred; deferred deprecations carry a date and an owner.

## Immutability Rules
- The core repo is never written or checked out into the product.
- `project.yaml` keys other than `core.version` / a renamed `core.modules` entry are untouched.
- The pin is never a branch, commit or range and never lowered.
- No commit, push, or applied database migration (`/db-migration` owns apply).
