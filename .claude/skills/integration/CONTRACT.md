# /integration - Handoff Contract

## Role in Pipeline
Takes one external provider from need to a researched, specified,
threat-modelled, tested adapter behind a port (`.claude/rules/integrations.md`).
Called by `/team-integration`, `/team-billing` (billing provider), `/dev-story`
and `/story-readiness` (presence of the research note and spec for an
integration story), `/create-architecture` (routing). Read by `/story-done`,
`/security-audit`, `/tenant-check`, `/release-checklist` (per-release sandbox
smoke), `/observability-plan` (provider SLIs and alerts).

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Provider slug and capability class | Yes | - |
| `design/specs/<feature>.md` | At `standard`/`full` (absent at `minimal` recorded) | Yes |
| `docs/stack-reference/pins.yaml` and the backend layer's reference | Yes (absent layer = `NOT SOURCEABLE`) | Yes |
| `saas-core-<track>` module list | For the core-first check (unreachable = NOT ASSESSED) | Yes |
| `project.yaml` via `resolve_config` (`stack`, `distribution`, `tenancy`, `review_mode`, `automation`) | Yes (unset = asked) | Yes |
| Existing note, spec, threat model | For `--update` | No - section numbers kept |

## Preconditions
- The provider is chosen by the user, or the skill is in the options-comparison step
- No live credential is available to or used by the skill

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. `SL-THREAT-MODEL`:
REJECT -> BLOCKED, CONCERNS -> COMPLETE WITH GAPS at best, NOT ASSESSED -> NOT
ASSESSED. A sandbox smoke that was not run keeps the verdict at best NOT ASSESSED.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `docs/research/<provider>.md` | nine sections; API version with official URL and fetch date or `NOT SOURCEABLE` | written by `researcher` to the user-approved path |
| `docs/architecture/integrations/<provider>.md` | the 13 template sections; port named; Status Draft until the user approves | after approval |
| `docs/architecture/threat-models/<provider>.md` | via `/threat-model` | not written here |
| code under the backend root: port, adapter, webhook handler, outbox hook, reconciliation job, tests | only on "implement now"; listed file by file | by `integrations-engineer`, approved paths only |
| `production/qa/evidence/integration-<provider>/` | contract-test output (T1-T18 by name), gitleaks result, smoke record, PAN-scan result | after approval |
| `production/qa/integration-<provider>-[date].md` | checks I1-I16 with evidence, verdict and causes, Not run list | after approval |

## Output Guarantees
- Every provider fact in the spec cites the research note; every gap is `NOT SOURCEABLE`, never filled
- The report lists each check as met / not met / not applicable (reason) / not run (reason)
- Secrets, payloads, PII and card-like data never appear in any output
- A skipped phase is named in the report

## Immutability Rules
- Never edits `saas-core-*`, ADRs, specs, contracts, migrations, CI or deploy files
- Never writes outside the listed paths; adapter code only on "implement now" and only the listed files
- Never commits; never sets a spec to Approved or an ADR to Accepted

## Hard Constraints (Never Violate)
- Never asks for, reads, prints or stores a credential; never calls a live provider
- Never recalls an API version, header, signature scheme, error code or limit
- Never chooses the provider, plans or prices
- Never counts a test file's existence as a pass

## Downstream Skill Expects
- `/story-readiness`: research note and spec paths for integration stories; threat model path
- `/release-checklist`: the dated sandbox-smoke record or an explicit `NOT RUN`
- `/security-audit` category 7 (webhooks, payments) reads the spec and evidence

## Known Fragile Points
- A provider whose docs state no sandbox/live key marker makes the live-key guard unsourceable
- Sandbox cannot always deliver webhooks to a local stack; the gap is stated, T8-T12 cover the handler
- Reconciliation depends on the provider's reporting API being sourced; absent -> NOT ASSESSED for I12
