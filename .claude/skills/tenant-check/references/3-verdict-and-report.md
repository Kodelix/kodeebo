# /tenant-check - Severity, Verdict and Report

> Phases 4-6 of `SKILL.md`.

## Severity

| Level | Meaning | Fix window (from triage, `security-lead` policy) |
|---|---|---|
| CRITICAL | A confirmed path by which one tenant reads, changes or deletes another's data (a failing negative test, an unscoped query reachable by an authenticated user, a cache/storage key without tenant, a job that crosses tenants) | 48 h |
| HIGH | A defence layer is missing but no path is confirmed: tenant table without `ENABLE`+`FORCE` or policy, the app role is owner/superuser/`BYPASSRLS`, session-level tenant setting behind a pooler, view without `security_invoker`, tenant taken from a request field, negative tests absent for tenant-touching code | 7 d |
| MEDIUM | Convention or control gap: `tenant_id` not leading an index, metric label on unbounded tenants, missing noisy-neighbour control, soft-delete as tenant deletion | 30 d |
| LOW | Hygiene | 90 d |

CVSS-style scoring is not used. Reachability first, then data class.

## Verdict (first match wins)

1. **REJECT** - any CRITICAL; any HIGH of: RLS/FORCE missing on a tenant table in
   `shared-schema-rls`, app role bypasses RLS, negative tests absent or failing for
   tenant-touching code, or no passing run output (the gate's own rule).
2. **NOT ASSESSED** - `tenancy.model` unset; code, migrations or tests unreadable;
   catalogue query not run (T2) or errored; app role unknown (T1); tests present but
   not runnable here; a layer with no source; a table that cannot be classified;
   a stack-reference fact `NOT SOURCEABLE` that a check needs. Name each cause and
   what closes it.
3. **CONCERNS** - every check assessed, no REJECT cause, but HIGH/MEDIUM/LOW
   findings or `not met` checks remain; list each with an owner.
4. **APPROVE** - every in-scope check `met` or `not applicable (reason)` with
   evidence on disk, and no open finding.

A narrowed scope cannot give `APPROVE` for the product. With `review_mode: full`
the report also carries the director's SL-TENANT-ISOLATION verdict; the worse of
the two is the verdict. `lean`/`solo`: `SL-TENANT-ISOLATION skipped - [mode] mode`.

Accepted risk is the user's decision with an owner and an expiry; this skill never
accepts one and never downgrades a finding.

## Report template (`production/qa/tenant-check-[date]-[scope].md`)

```markdown
# Tenant Check - [date] - [scope]
Verdict: [APPROVE | CONCERNS | REJECT | NOT ASSESSED]  (mechanical) / director: [verdict | skipped - mode]
Causes: [every cause; for NOT ASSESSED what closes each]
tenancy.model: [value]   Code roots: [list]   Database checked: [name, migration head | none]
Audited by: [multitenancy-specialist | this session - reason]

## Checks
| ID | Check | Result | Evidence |
(T1-T14; not applicable with the config value or reason; not run with the reason)

## Query / path table
| Location (file:line) | Mechanism | Tenant-scoped? | Negative test |

## Catalogue results   (raw output in the evidence folder)
A (tables lacking RLS/policy): [N rows]   B (tables without tenant_id): [N, classified M]
C (views without security_invoker): [N]    D (app role attributes/owners): [summary]

## Negative tests
| Test | Layer | Role used | Result | Command / exit |

## Findings
TEN-NNN | check | severity | file:line | how another tenant could reach the data | remediation | proving test | fix window

## Not run / not checked
[each item and why; skipped phases by name]

## Follow-ups
[routed owner per finding]
```
