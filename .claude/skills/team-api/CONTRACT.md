# /team-api - Handoff Contract

## Role in Pipeline
Cross-team orchestration of one contract change: `api-designer` (via
`/api-contract`) -> backend lead -> client leads, with the breaking-change and
deprecation policy. Called by `/studio` (flow `api-change`), by `/team-feature`
(when the change is BREAKING or touches two or more client layers), and directly.
Feeds `/code-review`, `/story-done`, `/team-qa`, `/changelog`, `/release-notes`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Feature slug or change description; optional `--service` | Yes | - |
| `project.yaml` via `resolve_config` (`stack`, `team.size`, `review_mode`, `automation`, `qa.level`, `testing.strict`) | Yes; a consuming lane with `stack` unset is a named gap | Yes |
| `contracts/`, the last released contract, ADRs (field case, generator, API style), the product's API policy | Contract: the change creates it if absent. Policy absent = window asked, recorded `stated by user` | Edited only through `/api-contract` |
| Spec, research note, threat model | When they exist; threat model required for sensitive surfaces | Yes |
| Client code roots (grep for consumers) | Yes; empty scan = `not run` | Changed by leads under the approved file set |

## Preconditions
- The contract change is approved and written (Phase 2) before any lane starts.
- A BREAKING change has a new major or an Accepted ADR before any lane starts.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. Consumed: `/api-contract`
verdict, CTO-ADR (APPROVE / CONCERNS / REJECT / NOT ASSESSED / skipped).

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `contracts/openapi/<service>.yaml`, generated clients, contract-change record | by `/api-contract` | its own approvals; clients only via the generator |
| `production/api/<slug>/deprecation-plan.md` | headers, dual behaviour, timeline with owners and dates, mobile minimum-version stance, self-hosted notes, support window with its source | DEPRECATING / BREAKING only |
| `production/api/<slug>/impl-<lane>.md`, `contract-tests.md`, `review-*.md`, `migration-guide-draft.md` | per-agent outputs | named paths, bounded exception |
| `production/qa/evidence/<STORY-ID or api-<slug>>/` | request/response per role and negative path (secrets redacted), one trace, deprecation headers | retained |
| `production/api/<slug>/team-api-report.md` | classification, consumer map incl. non-enumerable consumers, tool results, test results, timeline, `Not run / not checked` | written after approval |
| `production/session-state/active.md` "API pipeline — <slug>" block | flow, step, next command | overwritten; exempt |

## Output Guarantees
- Lint, breaking-change diff, client generation, contract tests, authz tests and run-and-observe are each `passed`, `FAILED` or `not run - reason`; none is reported clean when it did not run.
- Authz tests include wrong-tenant -> 404 and are not waived by `qa.level: minimal`.
- Consumers that cannot be enumerated from the repo (self-hosted customers, automations, old app versions) are named as `NOT ASSESSED`, never as "none".
- A support window and header value formats are sourced (policy, user, primary source) or `NOT SOURCEABLE`; never recalled.
- Notices are drafted, never published.

## Immutability Rules
- No contract is written outside `/api-contract`; generated client code is never hand-edited.
- No commit, push, deploy, applied migration or published notice; no story marked Complete; no ADR moved to Accepted by this skill.
