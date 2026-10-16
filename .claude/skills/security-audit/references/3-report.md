# /security-audit — Report Template and Recommendation Rules

> Phases 5–7 of `SKILL.md`.

## Severity

| Level | Definition | Fix window |
|-------|-----------|------------|
| **CRITICAL** | Cross-tenant data access, authentication bypass, remote code execution, or billing/licence forgery | 48 h (fix or mitigate) |
| **HIGH** | Privilege escalation within a tenant, or sensitive data exposure (credentials, PII, secrets) | 7 days |
| **MEDIUM** | Weakness with limited reachability or impact: information disclosure, missing control where a compensating control exists | 30 days |
| **LOW** | Defence-in-depth hardening; no direct exploit | 90 days |

Severity weighs reachability, exposure and data class, not the CVSS base score
alone; a cross-tenant read is never below HIGH. **Product type never lowers a
rating**: a single-tenant or internal product is rated on the same table. The
only upward adjustment: while a scope fact is unconfirmed (`tenancy.model` unset
and unanswered), rate cross-tenant findings as for a multi-tenant product and
say so.

Status: Open / Accepted Risk / Out of Scope. **Accepted Risk** is recorded only
when the user accepts it, with an **owner** and an **expiry date**; this skill,
`appsec-engineer` and `security-lead` do not accept risk on the company's behalf.

## Report

```markdown
# Security Audit Report

**Date**: [date]
**Scope**: [full | backend | web | mobile | selfhosted | deps | quick]
**Commit**: [hash] · **Release range audited**: [range or "working tree"]
**Stack**: [stack line from the resolved config] · **Tenancy**: [tenancy.model or unset] · **Distribution**: [model or unset]
**Audited by**: [appsec-engineer via /security-audit | this session — appsec-engineer not spawned: reason]
**Standards**: ASVS 5.0.0 (L2; L3 for auth, billing, licensing, tenancy, admin) · API Security Top 10 2023 · Top 10:2025 · MASVS 2.1.0 (mobile)
**Files scanned**: [N source files, N config files] across [roots]

---

## Executive Summary

| Severity | Count | Must fix before release |
|----------|-------|------------------------|
| CRITICAL | [N] | Yes — all |
| HIGH | [N] | Yes — all (or accepted by the user with owner and expiry) |
| MEDIUM | [N] | Within 30 days / recommended |
| LOW | [N] | Optional |

**Release recommendation**: [DO NOT SHIP / FIX BEFORE SHIPPING / NOT ASSESSED / CLEAR TO SHIP]

**Categories**: run [list] · skipped [category — reason, with the config value that
justifies it] · NOT ASSESSED [category — reason]

---

## Scans

| Scanner | Version (pinned / found) | Command | Scope | Result | Unscanned |
|---------|--------------------------|---------|-------|--------|-----------|
| gitleaks | 8.30.1 / [found] | [command] | [range/tree] | [N findings / clean / not run: reason] | |
| govulncheck | 1.8.0 / [found] | | | | |
| OSV-Scanner | 2.6.0 / [found] | | | | `pnpm-lock.yaml`, `Package.resolved`, [Gradle w/o lockfile] |
| Image scan | | | [images] | | |
| SBOM (CycloneDX) | | | | [present / not generated] | |

---

## Tenant Isolation (category 3)

| Location (`file:line` / migration) | Mechanism | Scoped at app layer? | RLS enabled+forced? | Cross-tenant negative test | Result |
|---|---|---|---|---|---|

SL-TENANT-ISOLATION: [APPROVE / CONCERNS / REJECT / NOT ASSESSED — reason / skipped — [mode] mode]

---

## Control Mapping

| Finding / check | Standard + version | Requirement ID | Official source (URL fetched) | Story | Test | Evidence path | Status |
|---|---|---|---|---|---|---|---|

Status: Met (evidence) / Partially met / Gap (finding) / Not applicable (reason) /
**NOT SOURCEABLE** (ID could not be looked up — the finding stands unmapped).

---

## CRITICAL Findings

### SEC-001: [Title]
**Category**: [Authn / Authz / Tenancy / Injection / SSRF / Upload / Webhook / Secrets / Dependency / Web hardening / Mobile / Licence / Logging-PII]
**File**: `[path]` line [N]
**Requirement**: [standard version ID — from the Control Mapping, or "unmapped: not sourceable"]
**Description**: [What the weakness is and the root cause]
**Attack scenario**: [How a hostile tenant, anonymous user or network attacker exploits it — no working exploit code]
**Impact**: [tenants / data / money affected]
**Remediation**: [Specific change or pattern]
**Regression test**: [negative test to add or the existing one]
**Effort**: [Low / Medium / High] · **Fix window**: [48 h / 7 d / 30 d / 90 d]
**Siblings**: [other instances of the same pattern found by grep, or "searched: none"]

[repeat per finding]

---

## HIGH Findings
[same format]

## MEDIUM Findings
[same format]

## LOW Findings
[same format]

---

## Accepted Risk

| Finding | Accepted by (user) | Owner | Expires | Rationale |
|---|---|---|---|---|

---

## Dependency Inventory

| Library | Version | Ecosystem | Source | Advisories | Reachable? |
|---------|---------|-----------|--------|------------|-----------|

Unscanned lockfiles: [list]

---

## Not Assessed

| Item | Reason | Input that closes it |
|---|---|---|

---

## Remediation Priority Order

1. [SEC-NNN] — [1-line description] — Est. effort: [Low/Medium/High] — due [date]

---

## Re-Audit Trigger and Dynamic Testing

Run `/security-audit quick` after remediating any CRITICAL or HIGH finding.
This audit reads code, configuration and scanner output; it is **not a
penetration test**. For authorised dynamic testing of the running product run
`/pentest` (`penetration-tester`, written scope required).
```

## Recommendation (first match wins)

- **DO NOT SHIP** — any open CRITICAL finding.
- **FIX BEFORE SHIPPING** — open HIGH findings and no CRITICAL, none accepted by the user with owner and expiry.
- **NOT ASSESSED** — the audit could not cover the surface (rules below). It
  ranks below both failure values — a known finding is more actionable than an
  unscanned category and still has to be fixed — and above CLEAR TO SHIP.
- **CLEAR TO SHIP** — no open CRITICAL or HIGH in what was assessed (MEDIUM and
  LOW may remain). It is **not a security sign-off**: `SL-RELEASE-SECURITY`
  still decides release readiness.

**NOT ASSESSED is required, in place of CLEAR TO SHIP (never of a failure value), when any of these holds:**
- a scanner did not run (`not run`), or a lockfile was unscanned and no other tool covered it;
- a category in scope has no readable source, or `resolve_code_root` was empty;
- category 3 ran with `tenancy.model` unset, or `distribution.model`/`stack.*` is unset so a category could not be scoped;
- requirement IDs could not be looked up (control mapping `NOT SOURCEABLE`);
- an item from the known-gaps table in `references/1-categories.md` is in scope for the product;
- the scope given (`quick`, a single category) did not include a category that a release needs — note which, and that `full` has not been run.

Name each cause in the Executive Summary. A zero-finding scan over no files, or
over a tool that did not run, is never a clean result.
