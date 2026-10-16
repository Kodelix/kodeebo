# /research - Handoff Contract

## Role in Pipeline
DoD gate 1 (`coding-standards.md`). Produces `docs/research/<feature-slug>.md` before
the first line of production code, or re-verifies a layer of
`docs/stack-reference/`. Called by `/dev-story` (research gate), `/story-readiness`,
`/team-feature`, `/integration`, `/threat-model` and `/architecture-decision`; read by
`/story-done` (PE-DOD). Downstream gates read the note's `Status:` line: only `Complete` passes `/dev-story` Gate A, `/story-readiness` and `/story-done` gate 1 outright; a `Draft` note (verdict COMPLETE WITH GAPS) passes only with the user's written acceptance of its named gaps recorded on the story (`Research gap accepted:`).

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| The question and the decision it informs (argument or user) | Yes | - |
| `docs/stack-reference/pins.yaml`, `docs/stack-reference/<layer>/VERSION.md` and siblings for each layer touched | Yes (absence = `NOT SOURCEABLE`, stated) | Yes (except `refresh`) |
| `docs/ROADMAP.md` decisions L1-L4, T1 | When distribution includes self-hosted | Yes |
| `design/specs/<feature>.md`, story file | Optional | Yes |
| Existing `docs/research/*.md` | Optional (reuse) | Yes unless re-verify/extend |
| `project.yaml` via `resolve_config` (`stack`, `workflow`, `review_mode`, `automation`) | Yes | Yes |

## Preconditions
- The request is a "Yes" row of the protocol's table, or the skill reports `EXEMPT` with the row and the existing note to cite.
- The question contains no secret, customer data or internal hostname.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED` (note mode) and
`EXEMPT` (protocol exemption). Precedence: BLOCKED, NOT ASSESSED, COMPLETE WITH
GAPS, COMPLETE. `refresh` emits COMPLETE / COMPLETE WITH GAPS / NOT ASSESSED per layer.
CTO-STACK-RISK (full review mode only): APPROVE / CONCERNS / REJECT / NOT ASSESSED / skipped.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `docs/research/<feature-slug>.md` | The nine template sections; `Status: Complete` only for verdict COMPLETE, else `Draft`; every finding linked and tiered or `NOT SOURCEABLE` | written by `researcher` at the path the skill named after user approval |
| `docs/stack-reference/<layer>/*.md`, `docs/stack-reference/pins.yaml` | changed rows; `Last verified` bumped only when every row was fetched | `refresh` only; asks in every automation mode |

## Output Guarantees
- The report lists each check as `ran` / `not run - reason`; the secret check is labelled read-through, not a scan.
- The Decision section records the user's choice, never the researcher's recommendation alone.
- A stale reference or note is named; a partial refresh is labelled partial.

## Immutability Rules
- Accepted ADRs, specs and stories are never edited by this skill.
- Existing notes are updated only on explicit user choice (re-verify / extend / replace).
- Stale research notes found during `refresh` are listed, never edited.
