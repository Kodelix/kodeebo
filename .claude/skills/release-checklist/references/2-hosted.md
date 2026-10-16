# /release-checklist — Track 1: Hosted Deploy

> Emitted when `distribution.model` is `hosted` or `hybrid` (and the web app and
> marketing site always ride with this track). Source rules:
> `.claude/rules/deploy.md`, `.claude/rules/migrations.md`,
> `docs/stack-reference/docker-compose/best-practices.md` §8 (zero-downtime),
> `docs/stack-reference/postgres/best-practices.md` §3–§4 (migrations, backup),
> `.claude/docs/observability-standard.md`.

Emit these as checkboxes under `## Target: Hosted Deploy` in the release
checklist. Unticked = work remains; `[?]` = nobody could check
(`[?] = not assessed — the input to this check was absent`).

## Migrations — expand → migrate → contract

- [ ] Every migration in this release is listed (file, what it does), with its `migration-lint.sh` observations quoted (`DANGER` / `WARN` / `MISSING`)
- [ ] Each is **backward-compatible with the previous app version** (the old version keeps working while the migration has run and the new one is not yet live); breaking steps are split across releases: expand now, contract in a later release
- [ ] No lock-heavy change on a hot table without a written plan: `ALTER COLUMN TYPE`, `NOT NULL` without default, `CREATE INDEX` without `CONCURRENTLY`, foreign key without `NOT VALID` + later `VALIDATE`; `lock_timeout` and `statement_timeout` set in the migration
- [ ] Backfills run in batches outside the migration transaction, idempotent and resumable
- [ ] Migrations run as a one-shot job before the new app version starts; production is **forward-only** — rollback is a new migration, stated in the plan
- [ ] Any `DROP` / `TRUNCATE` / data-deleting statement has the user's explicit approval **and** a backup step in this checklist (name the approval)
- [ ] Tested: up on empty, up on a seeded production-sized copy (duration `[X]`, locks `[none / planned]`), down in dev, integration suite green after

## Backup verified

- [ ] Automated, encrypted, **off-host** backups with documented RPO / RTO; a `backup failed` alert exists
- [ ] A **fresh backup taken immediately before this deploy**, identified (time, size, location) — not "backups are configured"
- [ ] Last **restore drill**: `[date]`, into a non-production environment, data verified, measured RTO `[X]` vs documented `[Y]`. Never restored = untested = blocker. Older than the agreed interval → CONCERNS
- [ ] Restore procedure is in `docs/runbooks/` and was executed from it

## Zero-downtime and rollout

- [ ] Deploy sequence: start new → health → switch → stop old (`docker-compose/best-practices.md` §8); healthchecks gate the switch
- [ ] `/livez` and `/readyz` on every service (neither needs auth, neither leaks versions); `/readyz` checks migrations applied
- [ ] Config and secrets for the target environment set in the secret store (not the repo); `.env.example` lists every new variable without values
- [ ] **Feature-flag gate**: every risky user-visible change (new or changed pricing/plan/entitlement behaviour, a changed core journey, an auth or data-visible change) ships behind a flag that is **off by default**, read from config or the database (not a deploy-time constant), with owner and removal date named, the flag-off path tested, and a way to switch it off **without a deploy**. An unflagged risky change is listed with the reason it cannot be flagged and the user's written acceptance — otherwise CONCERNS
- [ ] Deployed to staging first: `/smoke-check` passed there; evidence path `[..]`
- [ ] **Canary / staged rollout** written in `production/releases/rollout-[version].md`: the steps (`internal → 5 % → 25 % → 100 %`, or one cohort/tenant group first on a single VPS), the minimum hold time per step and the traffic needed for the signals to mean anything
- [ ] **Rollback triggers are numeric and written before the deploy**: error rate above `[x]` (or baseline + `[y]`) for `[z]` min; p95 above budget by `[y]` % or a fast-burn SLO alert firing; `/readyz` failing, a restart loop or a failed smoke journey; payment/login failure rate or any cross-tenant error above `[x]`. Thresholds from `slos.md` / `perf-budgets.md`, else `NOT SOURCEABLE — threshold not set` with the previous release's baseline as fallback. Rollback owner (name) and time-box stated
- [ ] Images pinned **by digest** and scanned; no `latest`; web bundle built with the pinned toolchain; cache headers (hashed assets immutable, HTML revalidated) and CSP verified on the deployed origin; source maps uploaded to the error tracker and not served publicly

## Rollback plan

- [ ] Written and **rehearsed** (app and data): previous image digests retained; the previous app version is still accepted by the API (contract compatibility window); migrations compatible with the previous version (expand-only until contract)
- [ ] Trigger, owner (name) and time-box stated; data-side rollback = restore-from-backup procedure with its RTO, or "forward-fix only" stated plainly
- [ ] No script runs `docker compose down -v` or prunes volumes

## SLO, alerts and observability ready

- [ ] New endpoints/jobs emit spans, RED metrics and outcome logs with `trace_id`; no PII in telemetry (grep of a real run saved to evidence)
- [ ] Alerts for every new failure mode are burn-rate on SLOs (`docs/architecture/slos.md`) or listed cause alerts (DB down, disk > 85 %, certificate expiring, backup failed); **each alert links a runbook** in `docs/runbooks/`
- [ ] Error budget remaining for affected SLOs: `[X]%` (freeze if exhausted) — or `slos.md` absent: `NOT ASSESSED` (required at `workflow: full` only)
- [ ] Dashboards for the changed journeys opened; one retained trace per critical journey
- [ ] Capacity: load test vs `perf-budgets.md` on the release candidate, p95 `[actual]/[budget]`; services have resource limits and bounded pools

## Post-deploy and communication

- [ ] **Post-deploy production verification** scripted and run after 100 %: `/livez` `/readyz`, the smoke journey against production as a synthetic tenant, one retained trace per critical journey, key dashboards, error tracker clean for the new version; error rate and latency compared with the previous release for 24 h. Result recorded in `production/releases/post-deploy-[version].md` (`PASSED` / `FAILED` / `not run — [reason]`; `not run` leaves this item `[?]`, never ticked)
- [ ] Status page updated if a maintenance window is needed (drafted by `customer-success`, **sent by the user**)
- [ ] On-call schedule set for 72 hours; escalation contacts verified; the `/incident` path and customer-communication channel known
- [ ] Release notes and changelog final (`/changelog`, `/release-notes`)
