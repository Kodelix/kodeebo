# /api-contract - Handoff Contract

## Role in Pipeline
Contract-first gate: the OpenAPI change in `contracts/` precedes handler code
(`api-standards.md`, `rules/contracts.md`). Called by `/team-api`, `/team-feature`,
`/integration`; reads from `/design-spec`, `/research`, `/threat-model`; feeds
`/create-stories` (Contract stories), `/dev-story`, `/code-review`, `/story-done`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Feature slug or `check [service]`; service name | Yes | - |
| `design/specs/<feature>.md`, `docs/research/<feature>.md` | When they exist; absence recorded | Yes |
| `docs/architecture/threat-models/<feature>.md` | For sensitive surfaces | Yes |
| `contracts/openapi/*.yaml`; last released contract via git tag | Baseline for the diff (absence = diff `not run`) | Existing file edited only after approval |
| ADRs (field case, generator, API policy) | Field-case ADR, or the user's answer | Yes |
| `project.yaml` via `resolve_config` (`stack`, `review_mode`, `automation`, `testing.strict`) | Yes | Yes |

## Preconditions
- `contracts/` has an OpenAPI file, or the change creates the first one. `check` mode with no contract reports `NOT ASSESSED`.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. CTO-ADR (breaking changes,
full review mode): APPROVE / CONCERNS / REJECT / NOT ASSESSED / skipped.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `contracts/openapi/<service>.yaml` | the approved change | written after explicit approval |
| Generated clients (TS / KMP / Swift per stack) | produced only by the repo-defined generator | never hand-edited; `not regenerated` when no generator exists |
| `production/qa/evidence/<STORY-ID>/contract-change.md` (or `production/qa/contract-change-<service>-<date>.md`) | checklist result (labelled review), tooling table with commands/exit codes or `not run - reason`, BREAKING table, contract-test plan, verdict | written after approval |

## Output Guarantees
- Lint, breaking-change diff and client generation are reported with real output or `not run - tooling not in the stack reference and not set up in this repository`, never as passed.
- Every change is classified ADDITIVE or BREAKING against the last released contract (manual diff labelled as such).
- A BREAKING change is never written without a new major version or an Accepted ADR.

## Immutability Rules
- No handler, migration or client code is written or edited by this skill.
- Generated code is never hand-edited.
- Specs, ADRs and stories are not edited here.
