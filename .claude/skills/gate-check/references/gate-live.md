> Gate definition, loaded by `/gate-check` for the TARGET PHASE ONLY.
> Never load the other six — one gate applies per invocation.


# Gate: Release → Live


This gate checks that the release **actually shipped and is operable in
production** — the readiness of the candidate was judged at Hardening →
Release. Nothing here is run against production by this skill: it asks for the
retained record of what the team did, and a missing record is NOT ASSESSED
(Section 4: never ask for a production action, a secret, or a real payment).

**Required Artifacts:**
- [ ] A release record exists for the shipped version: `production/releases/[product]-[version].md` (`/release-checklist`), signed off, naming every edition shipped — hosted deploy done, self-hosted bundle published and signed, Android / iOS builds submitted or released — with the commit or tag
- [ ] The release's commit range matches the commit range the Hardening → Release gate judged (SL-RELEASE-SECURITY, SRE-OPERABILITY): scans and audit are not stale against what shipped. A later change to the code roots with no re-run security audit or scan is a finding (cite both dates)
- [ ] For a first launch: the launch checklist is complete — `production/releases/launch-checklist-[date].md` (`/launch-checklist`): legal, privacy, billing, support, status page
- [ ] A post-deploy smoke result exists for the production environment, dated after the deploy (`production/qa/smoke-[date].md` or the release record's post-deploy section), recorded by the team — **this skill does not run it**
- [ ] Mobile editions (when `stack.mobile` is set): store review outcome recorded (approved / released / rejected with reason); rejected means not Live for that edition
- [ ] Observability is live in production: dashboards in use, the retained trace of a real production request on the core journey, alert rules loaded, a test alert delivered to the on-call channel — recorded under `production/qa/evidence/`
- [ ] Backups are running in production and the latest restore drill record is on file (carried from the Release gate or newer)
- [ ] Runbooks exist in `docs/runbooks/` for every alert in production; the incident path (`/incident`), paging and customer-communication channel are documented (`.claude/docs/templates/incident-response.md`)
- [ ] Status page and customer support channel are live; `customer-success` owns triage
- [ ] Billing is live: the pricing model's plans exist in the billing provider's live mode and match the configuration; a recorded live-mode transaction check by the user (this skill never makes a payment); tax/VAT handling stated
- [ ] Analytics: the tracking plan's activation events are flowing (`docs/analytics/tracking-plan.md`; one retained sample, no PII), so the success metric can be measured
- [ ] Release notes published (`/release-notes`); changelog updated
- [ ] A hotfix path is ready: `/hotfix` known to the on-call, previous release artifact retained for rollback, the rollback plan from the Release gate still valid for this version
- [ ] SLOs (`workflow: full`): `docs/architecture/slos.md` is Active and the burn-rate alerts are loaded in production; the error-budget policy names who decides on a freeze
- [ ] Self-hosted (when shipped): the signed bundle and its update channel are published; the first-install and upgrade procedures were exercised from the published artifact, not the build tree; the licence signing key is outside the repository

**Quality Checks:**
- [ ] No open S1 Critical bug and no open cross-tenant exposure in production or in the bug register
- [ ] The post-deploy smoke covers the core journey and the paid path (signup → core action; checkout / licence activation where they exist) — spot-read the report against the repository, as for any smoke report (Section 3)
- [ ] Rollback was reasoned for this version: migrations compatible with the previous app version, previous image digests retained
- [ ] Customer-facing statements match the product: pricing page, release notes and in-app copy agree with the entitlements actually enforced
- [ ] `bash .claude/scripts/project-coherence.sh` on the shipped state shows no `LICENCE` line for the self-hosted bundle (Section 3; `SKIPPED` is NOT ASSESSED)
- [ ] Open items carried from the Release gate's accepted CONCERNS are listed with an owner and a date

## Floors at every tier

- The release record with the shipped version and editions.
- A post-deploy smoke by the team, dated after the deploy.
- Backups running and a rollback path.
- No open S1 Critical bug.
- A documented incident path and who is paged.

## Workflow tier reductions

The checklist above is the **`full` baseline**. At lower tiers apply the
reduction for the resolved tier; items not named keep their status above.
Reductions only ever *relax* a requirement — `workflow_overrides` is the
only thing that adds one.

- **`full`** — everything above required: release record, launch checklist (first launch), post-deploy smoke, observability live, SLOs Active, runbooks, status page, billing live check, analytics flowing, hotfix path
- **`standard`** — SLOs Active + analytics flowing + billing live check beyond "plans exist" + commit-range freshness check → recommended; **release record + post-deploy smoke + observability live + backups + incident path + runbooks + no open S1** required
- **`minimal`** — only the **floors above** required; everything else **drops**

## Director gates at this transition

The PHASE-GATE panel (Section 4b) at the width `workflow` sets. The
release-readiness gates (SL-RELEASE-SECURITY, SRE-OPERABILITY, SRE-SLO) are
**not re-spawned** here: they ran at Hardening → Release against the
candidate. Their recorded verdicts are read (Section 3, "Recorded director
verdicts"); a verdict recorded against a different commit range than what shipped
is a finding, and `/release-checklist` / `/launch-checklist` re-run them for the
shipped version under the ordinary per-skill rule. PR-MILESTONE is recorded
per milestone.
