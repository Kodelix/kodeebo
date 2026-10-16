> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other six — one gate applies per invocation.


# Gate: Hardening → Release


This is the gate where engineering floors bind hardest: **SL-RELEASE-SECURITY**
and **SRE-OPERABILITY** run at every `workflow` tier, **SRE-SLO** at `full`
(Section 4b). In `solo` they are skipped as reviewers but every mechanical check
below still runs.

**Required Artifacts:**
- [ ] All features from the milestone plan are implemented (stories Complete of total, cited; `bash .claude/scripts/story-status.sh`)
- [ ] User-facing strings are externalized — no hardcoded user-facing text in the code roots (Grep, Section 3; unresolved code roots → NOT ASSESSED)
- [ ] QA test plan exists (`/qa-plan` output in `production/qa/`)
- [ ] QA sign-off report exists (`/team-qa` output — APPROVED or APPROVED WITH CONDITIONS)
- [ ] UAT sign-off exists (`production/qa/uat/uat-signoff-[release]-[date].md`) when the release needs UAT (enterprise or self-hosted customers; `uat-coordinator`). Required-and-not-run reads **UAT: NOT RUN** and the QA sign-off cannot be APPROVED on it. Not in scope → say "UAT not in scope for this release"
- [ ] All Must Have story evidence is present: Logic / Integration / Contract tests pass; **Security** stories have negative tests and the ASVS/MASVS mapping; **UI** stories have retained screenshots of each screen touched (desktop and mobile; Arabic RTL and English) and the `/impeccable audit` result; **Performance** stories have the load-test result — all in `production/qa/evidence/`, and no `qa.level` waives the security or UI evidence
- [ ] Smoke check passes cleanly (PASS verdict) on the release candidate — report `production/qa/smoke-[date].md`, dated after the candidate's last code change (spot-read per Section 3)
- [ ] No test regressions from the previous sprint (the suites pass fully, per layer)
- [ ] Plans, entitlements and quotas reviewed (`/pricing-check` run) and the billing configuration matches the pricing model
- [ ] Release checklist completed (`/release-checklist` run): `production/releases/[product]-[version].md`, with a section per edition shipping — hosted deploy, self-hosted bundle, Android / iOS stores
- [ ] Changelog and customer-facing release notes drafted (`/changelog`, `/release-notes`)
- [ ] Store listing and review readiness (when `stack.mobile` is set): Play Console / App Store metadata, privacy declarations (data safety, privacy nutrition labels), target SDK requirement per `docs/stack-reference/` — otherwise "not applicable — no mobile edition", stated
- [ ] Legal and privacy: terms of service, privacy policy, and — for the personal data in the release — a data inventory, retention rules and DSAR export/delete (`privacy-compliance-specialist` sign-off cited; Egypt PDPL / GDPR as applicable). A missing document is a finding, never assumed to exist
- [ ] **Security audit**: a `full`-scope report exists — the newest `production/qa/security-audit-[date]-full.md` — with its release recommendation (see the quality check below)
- [ ] **Dependency, container and secrets scans ran on the release commit**: `govulncheck` (Go), OSV-Scanner across Go / Gradle / npm / SwiftPM, a container image scan, `gitleaks` over the release range, and a CycloneDX SBOM — each with tool, version, scope and result recorded (`/dependency-audit`). A scan that **did not run** is a Blocker, never clean
- [ ] **Tenant isolation**: SL-TENANT-ISOLATION full sweep (`/tenant-check`) recorded APPROVE or CONCERNS (accepted); no REJECT open
- [ ] **Load test** on the release candidate against `docs/architecture/perf-budgets.md` (`/load-test`): ramp, steady, spike on the hot paths, with environment and data volume recorded
- [ ] **Backups and restore**: automated, encrypted, off-host backups with documented RPO and RTO; a dated restore drill record in `production/qa/evidence/` (non-production environment, restored-data check, measured RTO vs documented RTO)
- [ ] **Rollback plan** written for this release: previous image digests retained, zero-downtime deploy (start new → health → switch → stop old), migrations one-shot and compatible with the previous app version (expand → migrate → contract), no script runs `docker compose down -v` or prunes volumes
- [ ] **Runbooks and alerts**: every defined alert links a runbook in `docs/runbooks/`; cause alerts exist for DB down, disk > 85 %, certificate expiring, backup failed; incident path (`/incident`), paging and customer-comms channel documented
- [ ] **SLOs** (`workflow: full`): `docs/architecture/slos.md` with an availability and a latency SLO per critical journey, burn-rate alerts, and an error-budget policy
- [ ] **Self-hosted bundle** (`distribution.model` `self-hosted` or `hybrid`): `deploy/self-hosted/` exists; versioned and **signed**; the installer runs preflight checks (CPU/RAM/disk/ports), backs up before upgrade, verifies signatures, supports rollback; telemetry off by default; the customer backup/restore procedure is documented; the licence signing key is outside the repository and CI logs
- [ ] **Stack coherence** — `bash .claude/scripts/project-coherence.sh` run on the release candidate (Section 3)

**Quality Checks:**
- [ ] Full QA pass signed off by `qa-lead`
- [ ] All tests passing (per layer; `testing.strict.*` decides Blocker vs CONCERNS)
- [ ] Performance targets met on every shipping surface: API p95, web LCP/INP/CLS and initial JS, mobile cold start — measured, not template numbers (`performance.enforce`)
- [ ] No known open S1 Critical, S2 High or S3 Medium bugs (`production/qa/bugs/`)
- [ ] **No open CRITICAL or HIGH finding in the newest security-audit report whose Scope is `full`, as updated by any later `quick` report** (the re-run `/security-audit` prescribes after remediation). A later `backend`, `web`, `mobile`, `selfhosted` or `deps` report adds its open findings but never clears a category it did not scan. Any open CRITICAL or HIGH finding means not ready (a Blocker), unless accepted in the vulnerability register with an owner and an expiry **and** accepted by the user. No `full`-scope report means the check could not run: this item is NOT ASSESSED, never passed. A report whose release recommendation is itself NOT ASSESSED makes this item NOT ASSESSED too
- [ ] Control mapping complete: ASVS 5.0.0 at Level 2 for backend and web (Level 3 for authentication, billing, licensing), MASVS 2.1.0 for shipped mobile — every row names a story, a test and an evidence path (`.claude/docs/security-baseline.md`)
- [ ] Secrets: `gitleaks` clean on the release range; no secret in images (layers, build args), logs, client bundles or the mobile app; no `.env` committed
- [ ] Supply chain: lockfiles committed; `pnpm` settings per `.claude/docs/security-baseline.md` present; third-party CI actions pinned by commit SHA; base image digests pinned
- [ ] Web hardening verified on the built release: CSP without `unsafe-inline`/`unsafe-eval`, `frame-ancestors 'none'`, `nosniff`, Referrer-Policy, Permissions-Policy, HSTS, CORS allowlist with no `*` with credentials
- [ ] Every sensitive feature in the release has an approved threat model (SL-THREAT-MODEL APPROVE or accepted CONCERNS) and every mitigation a passing negative test
- [ ] Accessibility verified against `accessibility.target` on the shipping surfaces
- [ ] Localization verified for all target languages — every translated locale being shipped has a `/localize qa` verdict of PASS or PASS WITH CONDITIONS (`production/localization/loc-qa-[locale]-[date].md`), with an RTL check for Arabic (`production/localization/rtl-check-[date].md`). A FAIL blocks that locale; the others may still ship. A locale with no QA report, or whose QA reported NOT ASSESSED, has not been verified: this item is NOT ASSESSED, never passed. The source locale needs no `/localize qa` report; a product that ships only its source locale marks this item N/A and says so
- [ ] Build compiles and packages cleanly for every shipping edition (hosted images, self-hosted bundle, Android / iOS archives)
- [ ] Migrations for the release run forward on a copy of production-shaped data and are compatible with the previous app version

**Licence rules** (for `distribution.model` `self-hosted` or `hybrid`; Section 3 "Licence rules"; `.claude/rules/deploy.md`):
- [ ] `deploy/self-hosted/` ships only allowed engines: cache **Valkey** (`valkey/valkey`); MongoDB only as an `image:` reference to the **official** image — never a Mongo binary, tarball or image we build; observability **OTel Collector** only, exporters off by default — no Grafana/Loki/Tempo/Mimir; PostgreSQL, Caddy/Traefik allowed
- [ ] No `LICENCE` line in the `project-coherence.sh` output — **any LICENCE line is a Blocker** at this gate
- [ ] Code runs on Valkey: stays within the portable command subset (`docs/stack-reference/redis/best-practices.md`, portability section); no use of a Redis ≥ 7.4 or Dragonfly-only command
- [ ] No `FLOATING` image tag (`latest`, bare major) in `deploy/self-hosted/` — a Blocker here (reproducible customer installs)
- [ ] `distribution.model: hosted` → "licence rules not applicable — hosted only", stated in the report; `distribution.model` empty → NOT ASSESSED (`/setup-stack`)

## Floors at every tier

These are engineering floors, not documents; no tier drops them and they run in
`solo` as mechanical checks (Section 2b):
- The **smoke check** PASS on the release candidate.
- **No open S1 Critical bug.**
- The **security audit** (`full` scope) with no open CRITICAL/HIGH, the scans on the release commit, and tenant isolation proven.
- **Backups with a restore drill record**, and a written **rollback plan**.
- The **licence rules** for `deploy/self-hosted/`.
- **Security and UI evidence** for the stories shipping.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — all features + externalized strings + localization verification + QA sign-off (and UAT where in scope) + smoke (PASS) + no open S1–S3 bugs + SLOs + the floors, all required; SL-RELEASE-SECURITY, SRE-OPERABILITY and SRE-SLO all run
- **`standard`** — localization verification + QA sign-off + UAT + changelog/notes + pricing check → recommended; **all features + smoke + no open S1 Critical bugs + the floors** required; open S2 High and S3 Medium bugs → recommended; SLOs not required (`SRE-SLO skipped — not required at workflow: standard`)
- **`minimal`** — only **smoke + no open S1 Critical bugs + the floors** required (security audit, scans, tenant isolation, restore drill, rollback plan, licence rules, security/UI evidence); everything else **drops**; SLOs not required (`SRE-SLO skipped — not required at workflow: minimal`)

> **Hosted-only and self-hosted-only products.** `SRE-SLO` is also recorded as
> `skipped — self-hosted only` when `distribution.model: self-hosted` and no hosted
> edition exists; SRE-OPERABILITY still runs against the customer bundle. For a
> hosted-only product the self-hosted bundle items read "not applicable — hosted
> only", stated in the report, never silently omitted.

## Director gates at this transition

The PHASE-GATE panel (Section 4b) at the width `workflow` sets, **plus**
SL-RELEASE-SECURITY (`security-lead`) and SRE-OPERABILITY (`sre-lead`) at every
tier and SRE-SLO (`sre-lead`) at `full`, all spawned in the same parallel batch
and skipped only in `solo`. Recorded, not re-spawned: SL-THREAT-MODEL (per
sensitive feature), SL-TENANT-ISOLATION (per story and the full sweep),
PD-USABILITY, PR-MILESTONE. A NOT READY from any of them is a FAIL; a NOT
ASSESSED keeps the gate from PASS.
