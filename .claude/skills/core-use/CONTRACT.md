# /core-use - Handoff Contract

## Role in Pipeline
Adopts one `saas-core-<track>` module in a product. Called by `/studio` (flow
`core`), `/team-feature` (when the core-first check finds a module), and
`/integration`; fed by `/core-extract` (after the upstream release) and by the
feature spec's Dependencies section; feeds `/code-review`, `/story-done`,
`/dependency-audit` and, later, `/core-upgrade` (which owns every change to an
already-pinned `core.version`).

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| `<module>` argument; optional `--version <release-tag>` | Yes | - |
| `project.yaml`: `core.track`, `core.repo`, `core.version`, `core.modules`; `stack` via `resolve_config` | Yes (`stack.backend` unset = STOP) | `core.*` edited in Phase 5 only, after approval |
| The core repo at `core.repo` (tags, module docs, ports, CHANGELOG, conformance tests) | Yes; unreadable = `NOT ASSESSED` | Yes - never written |
| `design/specs/<feature>.md`, `docs/research/<feature>.md`, `docs/architecture/threat-models/<feature>.md` | When they exist; threat model required for sensitive modules | Yes |
| `docs/stack-reference/pins.yaml`, `bash .claude/scripts/project-coherence.sh` output | Yes | Yes |

## Preconditions
- `core.track` matches `stack.backend` (go->go, ktor->kotlin); a mismatch is `BLOCKED`.
- At least one **released** tag exists in the core repo; a branch or commit is never pinned.
- If `core.version` is already set to another tag, the request is `/core-upgrade`, not this skill.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. Gate verdicts consumed
when `review_mode: full`: CTO-ADR (via `/architecture-decision`), SL-THREAT-MODEL
(via `/threat-model`) - APPROVE / CONCERNS / REJECT / NOT ASSESSED / skipped.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| Dependency declaration, composition-root wiring, config, product tests | the approved file set only | written by the stack lead after the file-set approval |
| `project.yaml` (`core.track`, `core.repo`, `core.version`, `core.modules`) | the diff shown in Phase 5 | written only after an explicit yes; always prompts |
| `production/core/adopt-<module>-<date>-plan.md`, `-impl.md` | plan and implementation report | named paths, written by the spawned agents |
| `production/core/adopt-<module>-<date>.md` | module, tag and how it was verified, fit table, evidence table with `not run` rows, pin diff, gaps, decision-record reference, verdict | written after approval |
| `production/qa/evidence/<id>/` | run-and-observe evidence for callable/visible modules | retained, not discarded |

## Output Guarantees
- The pinned version is a released tag, verified in the core repo; the verification command and output are in the record.
- Every Phase 4 check is `passed`, `FAILED` or `not run - reason`; `COMPLETE` is unreachable with a `not run` row.
- A symbol or config key the core repo does not document is reported `NOT SOURCEABLE`, never guessed.
- A track mismatch, a missing release, or a missing threat model for a sensitive module is `BLOCKED`, never a warning.

## Immutability Rules
- The core repo is never written, checked out into the product, vendored or forked.
- `project.yaml` keys other than `core.*` are never touched.
- Specs, ADRs and stories are not edited here; the ADR is created through `/architecture-decision`.
- No commit, push or credential handling.
