> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# SRE-OPERABILITY — Production Operability Readiness

Agent: `sre-lead` | Model tier: session (inherit) | Domain: SLOs, alerting, incident response, capacity, reliability

**Trigger**: At `/gate-check` for the Hardening → Release transition, at every
`modes.workflow` tier (these are engineering floors, not documents), and from
`/release-checklist`, `/team-release` and `/launch-checklist` for each release.
PHASE-GATE-class when spawned by `/gate-check` (`director-gates.md`).

**Context to pass**:
- `distribution.model` and `deploy.target` from `project.yaml`; edition(s) shipping
- Observability evidence: dashboards, one retained trace screenshot per critical journey (`run-and-observe.md`), service health endpoints, collector config
- Backup configuration in `deploy/hosted/` and `deploy/self-hosted/`, the documented RPO / RTO, and the latest restore-drill record under `production/qa/evidence/` (date, environment, restored data check, measured RTO)
- Capacity evidence: k6 results against `docs/architecture/perf-budgets.md` (environment, data volume), container resource limits, connection-pool settings
- Release/rollback plan: the release checklist section for this release, migration plan (expand → migrate → contract), previous release artifact reference
- `docs/runbooks/` and the alert rules; on-call and escalation contacts
- `.claude/rules/deploy.md`, `observability-standard.md`, `performance-standard.md`

**Checks**:
1. Observability: every service exposes `/livez` and `/readyz` (neither requires auth; neither leaks versions); each critical journey has a retained trace showing handler → use case → DB / cache spans; RED metrics and structured logs with `trace_id` exist; no PII in telemetry; mobile and web crash reporting with symbolication mapping uploaded in CI. Self-hosted: the bundle ships the OTel collector config with exporters off and telemetry opt-in.
2. Backups: automated, encrypted, off-host, with a documented RPO and RTO; PITR where the RPO requires it; a `backup failed` alert exists.
3. Restore is tested: a dated restore drill exists within the agreed interval, restoring into a non-production environment, with data verification and the measured RTO compared to the documented RTO. A backup that has never been restored is reported as untested, which is NOT READY.
4. Capacity: hot paths were load tested (ramp, steady, spike) against the budgets, with environment and data volume recorded; results are within budget or an accepted waiver is written; services have resource limits, bounded pools, and 30 % memory headroom; the capacity plan names the first resource to saturate.
5. Rollback: a written, rehearsed rollback exists — previous image digests retained, deploys are zero-downtime (start new → health → switch → stop old), migrations run as a one-shot job and are compatible with the previous app version (expand → migrate → contract; production migrations are forward-only), and no script runs `docker compose down -v` or prunes volumes.
6. Self-hosted bundle (when shipped): installer runs preflight checks (CPU / RAM / disk / ports), backs up before upgrade, verifies signatures, supports rollback, and the customer backup / restore procedure is documented.
7. Alerts and runbooks: every alert defined has a runbook in `docs/runbooks/`; cause alerts exist for DB down, disk > 85 %, certificate expiring and backup failed.
8. Incident readiness: who is paged and how, the `/incident` path, and the customer communication channel are documented; secrets rotation procedure exists.
9. Dependencies' failure modes were exercised or reasoned for each external provider (timeout, retry, circuit breaker), with the degraded behaviour documented.

**Prompt**:
> "Review the current project state for production operability. Can an on-call
> engineer answer what broke, for whom, since when and why from telemetry alone?
> Are backups automated, encrypted and off-host, and has a restore actually been
> performed and timed against the stated RTO? Was capacity load tested against
> the budgets? Is there a written, rehearsed rollback that works with the
> migrations in this release? Return READY, CONCERNS [list], or NOT READY
> [blockers that must be resolved before release]."

**Verdicts**: READY / CONCERNS / NOT READY

**NOT ASSESSED when**: the deploy directory, the observability evidence or the
release/rollback plan cannot be read. A restore drill record that the skill
reports as absent is a finding (NOT READY), not a missing input. Environments
the agent could not reach are reported as not checked, never as passing; the
agent runs no destructive operation on production data to gather evidence.

**Output**: the standard block, with a readiness table (area — evidence — date — result) covering observability, backups, restore drill, capacity, rollback, alerts / runbooks and incident readiness.
