> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# SRE-SLO — SLOs, Burn-Rate Alerts and Runbooks

Agent: `sre-lead` | Model tier: session (inherit) | Domain: SLOs, alerting, incident response, capacity, reliability

**Trigger**: At `/gate-check` for the Hardening → Release transition when
`modes.workflow` is `full` (the SLO document is not required below `full` —
`workflow-modes.md`; below `full` the skill records `SRE-SLO skipped — not
required at workflow: [tier]`). Also from `/observability-plan` and
`/release-checklist`. Skipped for a product with `distribution.model:
self-hosted` and no hosted edition (customers own their SLOs).
PHASE-GATE-class when spawned by `/gate-check` (`director-gates.md`).

**Context to pass**:
- `docs/architecture/slos.md`
- Critical journeys of the product (from `design/product-brief.md` and the specs): at minimum login, the core action, payment, licence activation where they exist
- Alert rule files and dashboards (paths from `observability-engineer`; the deploy directories `deploy/hosted/`, `deploy/self-hosted/`)
- `docs/runbooks/`
- Budgets (`docs/architecture/perf-budgets.md`) and load-test results (`production/qa/evidence/`)
- `observability-standard.md` (section "SLOs and alerts")

**Checks**:
1. `docs/architecture/slos.md` exists and defines an availability SLO and a latency SLO for each critical journey; list journeys with none.
2. Each SLO states its SLI (the good-events and total-events definition and the metric name), target, and window.
3. Each SLI is actually emitted: the metric name appears in the instrumentation and on a dashboard (RED metrics per endpoint, `observability-standard.md`); cite `file:line`. An SLI with no emitting code is not an SLO.
4. Latency SLO thresholds are consistent with the budgets in `perf-budgets.md` and with the measured load-test p95; cite both numbers.
5. A burn-rate alert exists for each SLO, with its window and threshold stated and its source cited (the research note or SRE reference); cause alerts that always need a human exist for DB down, disk > 85 %, certificate expiring and backup failed.
6. Every alert links a runbook in `docs/runbooks/` and the file exists and is non-empty; an alert without a runbook is a blocker (`observability-standard.md`).
7. Each runbook has, at minimum: the symptom and the alert it answers, customer impact, diagnosis steps with the dashboard or query, mitigation, rollback or escalation, and an owner.
8. An error-budget policy is written: what happens when a budget is exhausted (for example release freeze, reliability work first) and who decides.
9. Alerts carry no PII, and alert routing (who is paged, who is notified) is documented.

**Prompt**:
> "Review the SLOs, alerts and runbooks for release readiness. Does every
> critical journey have an availability and a latency SLO with a defined SLI
> that is actually emitted? Are the targets consistent with the performance
> budgets and measured latency? Is there a burn-rate alert for every SLO and a
> runbook for every alert? Is there an error-budget policy? Return READY,
> CONCERNS [list], or NOT READY [blockers that must exist before release]."

**Verdicts**: READY / CONCERNS / NOT READY

**NOT ASSESSED when**: `slos.md` is listed as present but cannot be read, or the
alert rule files cannot be read, or the list of critical journeys was not
passed. An `slos.md` the skill reports as absent at `workflow: full` is a
finding (NOT READY).

**Output**: the standard block, with an SLO table (journey — SLI metric — target — window — burn-rate alert — runbook path).
