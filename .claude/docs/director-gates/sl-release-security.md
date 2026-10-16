> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# SL-RELEASE-SECURITY — Release Security Readiness

Agent: `security-lead` | Model tier: session (inherit) | Domain: Security baseline, threat models, ASVS/MASVS mapping, security sign-off

**Trigger**: At `/gate-check` for the Hardening → Release transition, at every
`modes.workflow` tier (security evidence is not waived by a lower tier), and
from `/release-checklist` and `/team-release` for each release candidate. Also
fed by `/security-audit` and `/dependency-audit`. PHASE-GATE-class: runs in
`lean` and `full` when spawned by `/gate-check` (`director-gates.md`).

**Context to pass**:
- Release identifier and commit range; edition(s) shipping (hosted, self-hosted bundle, Android, iOS)
- Control mapping: the latest `/security-audit` report and the per-story security evidence (`production/qa/evidence/<story-id>/`) — requirement ID, story, test, evidence path, status
- Threat models (`docs/architecture/threat-models/`) for every sensitive feature in the release, with the SL-THREAT-MODEL verdicts recorded
- Scan results for the release commit: `govulncheck`, OSV-Scanner across Go / Gradle / npm / SwiftPM, container image scan, `gitleaks`, SBOM (CycloneDX) — tool, version, scope, result
- Open vulnerability register (findings with severity, owner, status, accepted-risk expiry)
- SL-TENANT-ISOLATION verdict for the release (full sweep)
- Standards pinned in `security-baseline.md` (ASVS 5.0.0, MASVS 2.1.0, API Top 10 2023)

**Checks**:
1. ASVS 5.0.0 mapping exists for backend and web at Level 2, and Level 3 for authentication, billing and licensing modules; MASVS 2.1.0 mapping exists for Android / iOS / KMP when shipped. Every mapped row names a story, a test and an evidence path; list requirement IDs with no evidence.
2. Every scan listed above ran on the release commit and its result is recorded with tool, version and scope. A scan that did not run is reported as not run, and counts as a failure of this check, never as clean.
3. No open Critical or High vulnerability (dependency, container, code) remains unless accepted in the register with an owner and an expiry, and accepted by the user. List every open Critical/High with its age.
4. Secrets: `gitleaks` is clean on the release range; no secret appears in images (layers, build args), logs, client bundles or the mobile app; `.env` files are not committed; any suspected exposure has a recorded rotation.
5. Every sensitive feature in the release has a threat model with SL-THREAT-MODEL APPROVE (or accepted CONCERNS), and every mitigation has a passing negative test.
6. Tenant isolation: SL-TENANT-ISOLATION is APPROVE for the release, or CONCERNS accepted; no REJECT is open.
7. Supply chain: lockfiles committed; pnpm settings per `security-baseline.md` (`strictDepBuilds`, `allowBuilds` allowlist, `minimumReleaseAge`, `trustPolicy`, `blockExoticSubdeps`) present; no `react-server-dom-*` package in the SPA lockfile; third-party CI actions pinned by commit SHA; base image digests pinned.
8. SBOM generated for the release; the self-hosted bundle is signed and the installer verifies the signature before applying an update; licence signing key is outside the repository and CI logs.
9. Web hardening verified on the built release: CSP without `unsafe-inline` / `unsafe-eval`, `frame-ancestors 'none'`, `nosniff`, Referrer-Policy, Permissions-Policy, HSTS, CORS allowlist with no `*` with credentials; mobile: no secrets in the app, tokens in Keystore / Keychain.
10. The security audit log events (login, MFA changes, role changes, API key creation, licence activation) are emitted and append-only; no sensitive data appears in the telemetry sample inspected.
11. Privacy: data inventory, retention and DSAR export/delete exist for the personal data in the release (`privacy-compliance-specialist` sign-off cited).

**Prompt**:
> "Review the current project state for release security readiness. Is the
> ASVS / MASVS control mapping complete, with a story, test and evidence for
> every row? Did every scan run on the release commit and come back clean? Is
> there any open Critical or High vulnerability that is not formally accepted?
> Were secrets checked? Do all sensitive features have an approved threat model,
> and is tenant isolation proven? Return READY, CONCERNS [list], or NOT READY
> [blockers that must be resolved before release]."

**Verdicts**: READY / CONCERNS / NOT READY

**NOT ASSESSED when**: the control mapping, the scan results or the vulnerability
register cannot be read, or the release commit range was not passed. Reports of
scans "not run" are findings (NOT READY), not missing inputs.

**Output**: the standard block with the agent's security sign-off sections: Control mapping table (requirement — story — test — evidence path — status), Threat model (path, unmitigated threats, accepted residual risk with owner and expiry), Scans (tool, version, scope, result — or "not run" with reason), Findings `[CRITICAL|HIGH|MEDIUM|LOW] path:line — problem → fix (control ID)`. Never print a secret value in the report.
