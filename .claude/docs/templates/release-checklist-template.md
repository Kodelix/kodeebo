# Release Checklist: [Version] -- [Targets]

**Release Date**: [Target Date]
**Release Manager**: [Name]
**Targets in this release**: [ ] Hosted  [ ] Self-hosted bundle  [ ] Android (Play)  [ ] iOS (App Store)  [ ] Web  [ ] Marketing site
**Status**: [ ] GO / [ ] NO-GO

<!-- Delete the target sections that do not apply; do not leave them unticked. -->

---

## Build & Artifact Verification

- [ ] Clean build succeeds for every layer in this release (backend, web, mobile)
- [ ] CI green on the release commit; no skipped or quarantined tests added for this release
- [ ] Version number set correctly everywhere: `[version]` (backend, web, mobile, bundle, contract)
- [ ] Artifacts built reproducibly from the tagged commit: `[commit hash]`
- [ ] Container images tagged by digest and scanned: no High/Critical findings
- [ ] SBOM (CycloneDX) generated and stored
- [ ] No debug features, test endpoints, sample credentials or verbose logging enabled in release config
- [ ] Web bundle size within budget: [actual] / [budget] KB gz

---

## Quality Gates

### Critical Bugs
- [ ] Zero S1 (Critical) bugs open
- [ ] Zero S2 (High) bugs -- or documented exceptions below (no exceptions at `workflow: full`)
- [ ] Zero S3 (Medium) bugs open -- required at `workflow: full`

> The release gate blocks any open S1 at every tier. An open S2 blocks unless it has
> a written exception approved by `qa-lead` and `producer` (no exceptions at
> `workflow: full`). Open S3 blocks at `full`; below `full` it is a risk recorded
> here. Security or cross-tenant bugs are S1 by definition (`/bug-report`).

| Bug ID | Description | Exception Rationale | Approved By |
| ---- | ---- | ---- | ---- |
| | | | |

### Definition of Done
- [ ] Every story in the release has the eight DoD gates met or waived in writing (`/story-done`)
- [ ] Run-and-observe evidence exists in `production/qa/evidence/` for every user-visible story

### Test Coverage
- [ ] Critical journeys signed off (`/smoke-check` on the release candidate)
- [ ] Full regression suite passed: [pass rate]%
- [ ] Contract tests pass against the released `contracts/` version; breaking-change check clean
- [ ] Migrations tested on a production-sized copy: duration [X], locks [none / planned]
- [ ] Upgrade tested from the oldest supported version and from previous release

### Security
- [ ] `/security-audit` run; no open High/Critical findings
- [ ] Cross-tenant and authz negative tests green
- [ ] Dependency scan clean (`govulncheck`, OSV-Scanner, image scan); lockfiles committed
- [ ] Secrets scan clean (gitleaks); no secrets in images, bundles or app binaries
- [ ] Threat models current for sensitive features changed in this release

### Performance & Reliability
- [ ] Load test vs `perf-budgets.md`: p95 [actual] / [budget] on hot endpoints
- [ ] Error budget remaining for affected SLOs: [X]% (freeze if exhausted)
- [ ] Alerts and runbooks exist for every new failure mode
- [ ] Backups verified; last restore drill: [date]

### Content & Localization
- [ ] All user-facing strings externalised; Arabic and English complete; RTL layouts checked
- [ ] Emails / notifications / error messages proofread in both locales
- [ ] Accessibility target met for touched screens (`accessibility-requirements.md`)
- [ ] Legal notices, third-party attributions and licence texts current

---

## Target: Hosted Deploy

- [ ] Release notes and changelog final
- [ ] Config and secrets for the target environment set in the secret store (not in the repo)
- [ ] Migrations ordered: expand → deploy → contract; backward-compatible with the previous app version
- [ ] Feature flags default-off for incomplete or risky features
- [ ] Deploy to staging, smoke check passed, then production via the documented procedure
- [ ] Rollout strategy: [rolling / blue-green / canary %] with abort criteria: [error rate, latency]
- [ ] Rollback plan documented and rehearsed (app + data); rollback owner: [name]
- [ ] Post-deploy verification: `/livez` `/readyz`, smoke check, key dashboards, error tracker clean
- [ ] Status page updated if maintenance window is needed; on-call schedule set for 72 hours

## Target: Self-Hosted Bundle

- [ ] Bundle built from the tagged commit; compose files, images and installer versions match `[version]`
- [ ] Bundle and installer signed; signature verified by the installer on a clean machine
- [ ] Fresh install tested on a clean host (documented minimum spec)
- [ ] Upgrade tested from every supported prior version, including data migration and rollback
- [ ] Offline / air-gapped install path tested (images included or documented mirror)
- [ ] Licence verification tested: valid, expired-within-grace, expired, revoked, tampered, clock skew
- [ ] Telemetry off by default; collector config shipped; no phone-home without opt-in
- [ ] Default credentials absent; secrets generated at install; TLS configured
- [ ] Customer-facing upgrade notes, minimum upgrade-from version and deprecation notices published
- [ ] Release published to the release channel; checksums and signatures attached

## Target: Android (Google Play)

- [ ] `versionCode` incremented; `versionName` = `[version]`; signed with the release key via Play App Signing
- [ ] Release build (R8/minify) tested on a physical device; baseline profile included
- [ ] Target API level meets current Play requirement; permissions minimal and justified
- [ ] Data safety form and privacy policy URL current; account deletion path in-app and on web
- [ ] Crash reporting mapping files uploaded
- [ ] Store listing: Arabic and English text, screenshots, feature graphic current
- [ ] Billing flows verified in the Play testing track (if in-app billing is used)
- [ ] Staged rollout configured: [% steps]; halt criteria: [crash-free rate, ANR]
- [ ] Review status: [submitted / in review / approved]

## Target: iOS (App Store)

- [ ] Build number incremented; version = `[version]`; signed with the distribution profile
- [ ] Release build tested on a physical device; dSYMs uploaded
- [ ] Privacy nutrition labels and privacy manifest current; account deletion in-app
- [ ] ATS/network config reviewed; entitlements minimal
- [ ] Store listing: Arabic and English text, screenshots, review notes and demo account for reviewers
- [ ] In-app purchase / subscription products verified in sandbox (if used; check guideline compliance for external payments)
- [ ] TestFlight external group verified before submission
- [ ] Phased release configured; submission status: [submitted / in review / approved]

## Target: Web & Marketing Site

- [ ] Static bundle built with pinned toolchain; CSP and security headers verified on the deployed origin
- [ ] Cache headers correct (hashed assets immutable, HTML revalidated); CDN purge planned
- [ ] Lighthouse CI within budget; web-vitals RUM monitored after release
- [ ] Source maps uploaded to the error tracker and not served publicly

---

## Billing & Account Impact

- [ ] Pricing/plan/entitlement changes match `pricing-model.md`; migration of existing subscribers defined
- [ ] Provider products/prices created in live mode; webhook endpoints and secrets configured
- [ ] Customer communication sent for any price, limit or terms change within the required notice period

---

## Launch Readiness

- [ ] Analytics events match `tracking-plan.md` and are receiving data; consent respected
- [ ] Support team briefed on changes and known issues; help-centre articles updated
- [ ] Announcements drafted (customers, in-app, status page)
- [ ] On-call team schedule set; escalation contacts verified

---

## Sign-offs

| Role | Name | Status | Date |
| ---- | ---- | ---- | ---- |
| qa-lead | | [ ] Approved | |
| cto | | [ ] Approved | |
| security-lead | | [ ] Approved | |
| sre-lead / platform-lead | | [ ] Approved | |
| producer | | [ ] Approved | |
| product-director | | [ ] Approved | |

---

## Final Decision

**GO / NO-GO**: ____________

**Rationale**: [Summary of readiness. If NO-GO, list specific blocking items and estimated time to resolve.]

**Notes**: [Known risks accepted (with the named acceptor), or conditions on the release.]
