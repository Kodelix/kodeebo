# Readiness Checks (Phase 2b)

Each dimension reports READY, GAPS, `NOT ASSESSED — [reason]` or `N/A — [reason]`.
A check that could not run is reported as `not checked`, never counted as met.
Read artifacts; do not run scans, deploys or audits from this skill — if a scan
is missing, that is a finding and a next step (`/security-audit`, `/load-test`).

## Which dimensions apply

| Dimension | Applies when | N/A reason to write |
|---|---|---|
| Open security findings | Always | — |
| SLO readiness | `project.stage` is Hardening, Release or Live, **or** the milestone Type is Public Beta / GA / Post-Launch — and the product has a hosted edition | `Pre-Hardening stage` or `self-hosted only — customers own their SLOs` |
| Self-hosted upgrade path | `distribution.model` is `self-hosted` or `hybrid` | `hosted only` |
| Store-review readiness | `stack.mobile` is set and the milestone ships a mobile build to users | `no mobile in stack` / `milestone ships no mobile build` |

## 1. Open security findings

| Check | Source | Met when |
|---|---|---|
| Audit exists and is current | Latest `/security-audit` report (Glob `production/qa/**/*security*`, `docs/architecture/**/*security-audit*`; none → NOT ASSESSED) | Dated after the last security-relevant change in the milestone |
| Open findings by severity | Same report; story files with security verdicts | Count of open Critical / High / Medium listed with IDs. Critical or High open → GAPS (blocker per the Go/No-Go rules) |
| Threat models current | `docs/architecture/threat-models/<feature>.md` for each sensitive feature shipped | Exists; residual risks have an owner and an unexpired date, accepted by the user |
| Tenant isolation | SL-TENANT-ISOLATION verdicts recorded on stories touching tenant data; cross-tenant negative tests in CI | No story touching tenant data lacks the evidence |
| Security stories' evidence | Stories of type Security: ASVS/MASVS IDs, negative tests present | Missing evidence on a security-sensitive story is BLOCKING (`security-baseline.md`) |
| Dependency and secrets scans | CI results or release-candidate scan output | Clean, with the date; absent → not checked |

## 2. SLO readiness (Hardening and later)

| Check | Source | Met when |
|---|---|---|
| SLOs defined | `docs/architecture/slos.md` | Availability + latency SLO per critical journey (login, core action, payment, licence activation where they exist). Required at `workflow: full`; below `full`, report "SLO document not required at workflow: [tier]" and judge the next three checks on what exists |
| SLIs emitted | Instrumentation / dashboards named by the SLOs | The metric names appear in code and on a dashboard |
| Alerts and runbooks | Alert rule files under `deploy/hosted/`; `docs/runbooks/` | Burn-rate alert per SLO; every alert links an existing, non-empty runbook |
| Performance vs budget | `docs/architecture/perf-budgets.md`; load-test evidence in `production/qa/evidence/` | p95, queries per request and payload within budget, with the measured numbers. `performance.enforce: block` makes a miss BLOCKING |
| Backups and restore | Runbook log | A restore drill date within the milestone definition's window; absent → not checked |
| Error budget | SLO dashboards or notes | Budget remaining for affected SLOs stated, or `not checked` |

## 3. Self-hosted upgrade-path readiness

| Check | Source | Met when |
|---|---|---|
| Bundle versioned and signed | `deploy/self-hosted/`, release artifacts | Installer verifies signatures before applying (`.claude/rules/deploy.md`) |
| Fresh install | Evidence in `production/qa/evidence/` | Clean-host install recorded for this milestone's build |
| Upgrade from every supported prior version | Evidence; migration tests | Each supported version listed with a result; none listed → not checked, not "none supported" |
| Migrations | `backend/` migrations; `.claude/rules/migrations.md` | Expand → migrate → contract respected; backward compatible with the previous app version; duration measured on production-sized data |
| Rollback | Installer / runbook | Backup-before-upgrade and rollback tested |
| Licence rules | `deploy/self-hosted/` against `.claude/rules/deploy.md` | No hardcoded keys, offline grace works, telemetry off by default |
| Air-gapped path | Docs and evidence | Tested or documented mirror (if the audience includes it) |

## 4. Store-review readiness (mobile)

| Check | Source | Met when |
|---|---|---|
| Store requirements | `docs/stack-reference/` entries for the platform; current Play / App Store policy pages (cite the page and date; do not recall them from memory — unsourceable → `NOT SOURCEABLE`) | Target API level / SDK requirement, signing and privacy requirements checked against the build |
| Privacy declarations | Data safety form (Play) / privacy nutrition labels and manifest (App Store) | Match the data the app collects (cross-check `docs/analytics/` and the privacy specialist's data inventory) |
| Listing assets | Screenshots, descriptions, localisations (Arabic + English), support URL, privacy policy URL | Present and current |
| Reviewer access | Test account, demo tenant, notes for reviewers; sign-in with Apple / account-deletion flow where required | Documented, working, no production data |
| Billing compliance | Store billing rules for in-app purchase vs external checkout | Reviewed with `pricing-billing-designer` where the app sells anything |
| Lead time | Target date minus review duration | The submission date fits before the target; a first submission or a sensitive category allows for rejection and resubmission. The duration comes from the current store documentation or the previous release's record, not from memory |
| Staged rollout | Release checklist | Plan and halt criteria written (`/release-checklist`) |
