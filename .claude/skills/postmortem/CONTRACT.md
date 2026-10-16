# /postmortem - Handoff Contract

## Role in Pipeline
The step after `/incident`: a blameless review of a resolved incident with a
timeline from evidence, contributing factors, SLO impact and owned, dated
actions. Called by `/incident` (hand-off), `/hotfix` (post-incident review),
`/team-security` and `/team-release` (after a release incident). Read by
`/retrospective`, `/create-stories` (actions), `/observability-plan` (detection
actions), `SRE-OPERABILITY` (incident readiness evidence).

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| `production/incidents/incident-*.md` (status Resolved) | Yes | Status/link updated after approval |
| Diagnosis and comms drafts, hotfix record | When they exist (absence recorded) | Yes |
| `docs/architecture/slos.md` | For SLO impact (absent = NOT ASSESSED for that section) | Yes |
| `docs/runbooks/` runbook used | When one exists | Edited only with approval |
| git history, release files, user-supplied dashboard/alert exports | Evidence for the timeline (unreadable = NOT READ) | Yes |
| `project.yaml` via `resolve_config` | Yes | Yes |

## Preconditions
- The incident is resolved; the user has not asked for a milestone/sprint review (that is `/retrospective`)

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `production/incidents/postmortem-[date]-[slug].md` | all template sections; UTC timeline with a basis per row; factors by safeguard; error-budget arithmetic with sources; actions with type/owner/due/story/factor; blameless scan terms; Not Known list | after approval |
| `docs/runbooks/<name>.md` (edits or new) | the exact steps added; `Last verified` unchanged | only with approval |
| incident record header | `Status: Post-Mortem Complete` and a link | only with approval and a non-NOT ASSESSED verdict |
| action list | rows for `/create-stories` | returned in conversation |

## Output Guarantees
- No person is named as a cause; the blameless scan terms and result are printed
- Every number has a source or is `NOT KNOWN`; every action has an owner and date or is listed as a gap
- No secrets, PII, customer data or internal hostnames appear
- Owners and dates are the user's; the skill never invents either

## Immutability Rules
- Never edits code, config, alert rules, dashboards or other incident records
- Never accepts a risk, never publishes anything, never commits

## Hard Constraints (Never Violate)
- Never fills a missing evidence field from memory or inference without labelling it INFERRED
- Never upgrades root-cause confidence beyond the evidence
- Never bumps a runbook's `Last verified` for an edit

## Downstream Skill Expects
- `/create-stories`: the action table with type, owner role, due date and the factor each closes
- `SRE-OPERABILITY`: a postmortem within the window for each SEV1/SEV2, actions tracked
