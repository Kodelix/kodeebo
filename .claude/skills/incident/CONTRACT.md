# /incident - Handoff Contract

## Role in Pipeline
Incident command for a live production problem: declare, mitigate, communicate,
diagnose, resolve, hand off. Called by the user only (`disable-model-invocation`);
referenced by `/hotfix` (redirect when a rollback fully resolves it), `/team-release`
and `/launch-checklist` (the documented incident path, `SRE-OPERABILITY` check 8),
and runbooks. Hands off to `/postmortem` and `/hotfix`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| The user's account of symptom, start (UTC), scope, data exposure, recent changes | Yes (`NOT KNOWN` accepted and recorded) | - |
| `docs/runbooks/` | When one matches (absence recorded as an action) | Yes |
| `docs/architecture/slos.md` | For journey IDs, budgets, cadence policy (absence recorded) | Yes |
| `project.yaml` via `resolve_config` (`stack`) | For `distribution`, `deploy`, `tenancy` | Yes |
| `production/session-state/active.md`, existing `incident-*.md` | For resume | Appended / updated |

## Preconditions
- Typed by the user; always collaborative in every `modes.automation`
- The skill runs nothing against production; the user (or named operator) does

## Verdicts Emitted
No pass/fail verdict. Status words from the template: `Active` -> `Mitigated` ->
`Resolved` -> `Post-Mortem Complete`. Unknowns are written `NOT KNOWN`; data
exposure stays `Suspected` until ruled out with named evidence.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `production/incidents/incident-[date]-[slug].md` | template sections filled as known, UTC timeline kept as it happens, mitigation log with verification, customer messages as sent, open items, postmortem decision | created and appended with one approval at declaration |
| `production/incidents/incident-[date]-[slug]-comms-[n].md`, `-diagnosis.md` | drafts by `customer-success` and `debugger` | the skill named the paths; new files only |
| `production/session-state/active.md` | one `Active incident:` line | append |

## Output Guarantees
- Every timeline row has a UTC time and says whether it was reported or evidenced; times are never reconstructed from memory
- No secret, token, PII, customer data or other tenant's details; tenants by internal ID
- Customer messages are drafts; the user sends them and the sent time is recorded
- The incident is never marked Resolved without the resolution evidence, and never closed without a recorded postmortem decision

## Immutability Rules
- Executes no command against production; runs no destructive operation; edits no code, config, alert rules or runbook content
- Never publishes, never commits

## Hard Constraints (Never Violate)
- Mitigation is never held for a proven root cause
- A suspected cross-tenant or credential exposure hands command to `security-lead` and follows containment -> evidence -> rotate -> scope -> notify
- Cadence numbers and notification deadlines are not invented: they come from the project's policy, `sre-lead`, or `privacy-compliance-specialist` and counsel via the user

## Downstream Skill Expects
- `/postmortem`: the incident file with timeline rows, mitigation log, diagnosis path, comms sent, impact fields (or `NOT KNOWN`) and the postmortem decision
