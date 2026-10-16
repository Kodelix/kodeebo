# /tenant-check - Handoff Contract

## Role in Pipeline
Audits tenant isolation against `tenancy.model` and returns the
SL-TENANT-ISOLATION verdict. Called by `/team-security`, `/team-hardening`,
`/team-data`, `/security-audit` (category 3 may cite its report), `/release-checklist`
and `/story-done` (stories touching tenant data). Read by `/gate-check` and the
`SL-RELEASE-SECURITY` gate.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| `tenancy.model` via `resolve_config` (`stack`) | Yes (unset = asked, then NOT ASSESSED) | Yes |
| Code roots from `resolve_code_root`; migrations; `deploy/` DB role and pooler config | Yes (absent = NOT ASSESSED for the dependent check) | Yes |
| Test paths and `production/qa/evidence/` | Yes for T14 | Yes |
| A named non-production database or container runtime | For T1/T2 and T14 runs (absent = NOT ASSESSED) | Read-only queries only |
| `docs/stack-reference/{postgres,mongo,redis}/best-practices.md`, `pins.yaml` | Yes | Yes |
| Threat model, spec, story | When they exist | Yes |

## Preconditions
- The database named, if any, is not production; no credential is passed to the skill
- A narrowed scope is stated and cannot approve the product

## Verdicts Emitted
`APPROVE` / `CONCERNS` / `REJECT` / `NOT ASSESSED` (the gate's words).
Precedence: REJECT, NOT ASSESSED, CONCERNS, APPROVE. With `review_mode: full`
the worse of the mechanical and the director's verdict stands; in `lean`/`solo` the
director is recorded as skipped and the mechanical verdict stands.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `production/qa/tenant-check-[date]-[scope].md` | checks T1-T14 each with a result and evidence, query/path table, catalogue results, negative-test table, findings TEN-NNN, Not run list, follow-ups | after approval |
| `production/qa/evidence/tenant-check-[date]-[scope]/` | query text + raw results (no connection details), test output with command and exit code | after approval |

## Output Guarantees
- A check that did not run is `not run (reason)`; static migration text is labelled `static only` and never counts as the catalogue
- A negative test run as owner/superuser is recorded `invalid evidence`
- Customer data, connection strings and secrets never appear in any output
- A narrowed scope is named and never yields APPROVE for the product

## Immutability Rules
- Reads code, migrations, deploy files and tests; runs read-only catalogue queries and the existing tests
- Never modifies data, schema, roles, source, tests, ADRs or specs; never runs against production

## Hard Constraints (Never Violate)
- Never marks the catalogue check `met` from migration text alone
- Never accepts a risk, downgrades a finding or treats absent tests as "no issue"
- Never prints a secret or connection string; never asks for credentials
- Announces a confirmed cross-tenant path or live leak immediately and routes it to `security-lead`

## Downstream Skill Expects
- `/security-audit`: category-3 verdict and the evidence folder path
- `/story-done`: verdict for the story's tenant-data paths, and whether negative tests passed
- `SL-RELEASE-SECURITY`: a `full`-scope report within the release range

## Known Fragile Points
- The catalogue query assumes the tenant column is named `tenant_id`; schema-per-tenant products use provisioning checks instead
- A database at an older migration head than the release gives evidence for that head only
- Testcontainers-based tests need a container runtime; without one T14 is NOT ASSESSED
