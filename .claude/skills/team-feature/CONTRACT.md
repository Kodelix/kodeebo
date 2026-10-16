# /team-feature - Handoff Contract

## Role in Pipeline
Team form of the `/studio` feature backbone: one feature from research to the
`/story-done` hand-off, layers worked in parallel after the contract. Called by
`/studio` (flow `feature`) and directly by the user. Invokes `/research`,
`/design-spec` or `/quick-spec`, `/threat-model`, `/api-contract` or `/team-api`,
`/team-data` or `/db-migration` (user-run), `/cache-design`, `/ux-design`,
`/ux-review`, `/team-ui`, `/architecture-decision`, `/create-epics`,
`/create-stories`, `/story-readiness`, `/code-review`, `/smoke-check`,
`/team-qa`, `/release-notes`, `/core-use`, `/core-extract`; hands `/dev-story`
(optional) and `/story-done` to the user.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Feature sentence or slug; or `resume [slug]` with the "Feature pipeline — <slug>" (or "Studio flow") block of `production/session-state/active.md` | Yes | - |
| `project.yaml` via `resolve_config` (`stack`, `workflow`, `team.size`, `review_mode`, `automation`, `qa.level`, `testing.strict`, `system_overrides`); `core.*` | Yes; an unset layer the feature needs is a STOP for that layer | Yes |
| `design/product-brief.md`, `design/specs/domain-map.md`, existing spec / research / threat model / contract / ADRs / epics | Inventoried FOUND or ABSENT | Yes (owned and edited by their skills) |
| `docs/stack-reference/`, `pins.yaml`, `.claude/rules/*.md` | For leads' briefs | Yes |

## Preconditions
- `stack` resolves for every layer the feature needs, else that layer is not implemented by the run.
- `PRODUCT.md` exists for a UI feature (else `/impeccable init`).
- The user approved the plan (Phase 1) before any work.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. `COMPLETE` never means
"Done": only `/story-done` marks a story Complete. Consumed verdicts: QA sign-off
(`NOT ASSESSED` / `APPROVED` / `APPROVED WITH CONDITIONS` / `NOT APPROVED`),
`/code-review` (APPROVE / CONCERNS / REJECT / NOT ASSESSED), gate verdicts
recorded as `[GATE-ID] skipped - <mode> mode` when skipped.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `production/features/<slug>/routing.md` | bounded context, lanes and leads, trigger table, ADR candidates, core-vs-product findings, open questions | written by `principal-engineer` |
| `production/features/<slug>/architecture.md`, `consult-*.md`, `impl-<story-id>-<lane>.md`, `review-*.md` | per-agent outputs, one file each | named paths, bounded exception |
| `production/features/<slug>/feature-report.md` | plan table with every step ran / skipped - reason / BLOCKED, active set, artifacts, gates, per-story `/story-done` command and evidence state, QA verdict, `Not run / not checked` | written after approval |
| `production/session-state/active.md` CHECKPOINT block (`Flow:`, `Current task:`, `Next step:`, `Blocked on:`) and its "Feature pipeline — <slug>" block | flow, step, waiting-on, artifacts, skipped, blockers, next command | overwritten after every gate; exempt from the prompt |
| Specs, contracts, migration plans, ADRs, stories, QA plans, evidence | by the invoked skills | their own approvals |

## Output Guarantees
- Every backbone step appears in the plan table as `ran`, `skipped - <named reason>` or `BLOCKED`; the always-prompt gates (research conclusion, spec approval, residual risk, ADR, story list, each story's Done, release go/no-go, destructive data step, external publication) prompt in every automation mode.
- The active set and the agents not spawned are stated before Phase 1.
- Client lanes start after the contract is merged, not after the backend is finished; verification of client stories waits for a callable backend.
- A check that did not run is `not run - reason`; QA `NOT ASSESSED` makes the feature verdict `NOT ASSESSED`.
- User-only skills (`/dev-story`, `/story-done`, `/db-migration`, `/hotfix`) are printed as commands, never executed or imitated for their apply/close steps.

## Immutability Rules
- No story is marked Complete; no ADR is moved to Accepted; no migration is applied; no commit, push or deploy.
- Specs, contracts and ADRs are edited only through their owning skills.
- Existing source is changed only by leads, under the file set the user approved for the wave.
