# /observability-plan - Mode `slos`

> SLOs, error budgets, burn-rate and cause alerts per critical journey, in
> `docs/architecture/slos.md` from `.claude/docs/templates/slos.md`. Feeds
> **SRE-SLO**. Owner: `sre-lead`.

## 1. Applicability

- `distribution.model: self-hosted` with no hosted edition: customers own their
  SLOs; the skill records `SRE-SLO not applicable - self-hosted only` and writes
  at most advisory SLOs and the dashboards and alert rules the bundle ships for
  the operator to import.
- `hosted` or `hybrid`: SLOs describe the hosted edition; self-hosted SLOs are
  advisory (template section 5).
- `workflow` below `full`: the SLO document is not required for the gate; the
  skill still writes it on request.
- `distribution.model` unset: ask; unanswered = treat as hybrid and say it is
  assumed.

## 2. Critical journeys (the user confirms)

Read `design/product-brief.md` and the specs. Propose the journeys that matter
commercially; the template's typical set is login/token refresh, the core action,
payment/plan change, licence activation (self-hosted), data export, webhook
delivery. `AskUserQuestion` to confirm, add and remove; **an unconfirmed list
makes the document `NOT ASSESSED`**. Every journey gets an availability SLO
and a latency SLO (SRE-SLO check 1); the template adds correctness for payments,
experience for web (LCP/INP/CLS field data) and stability for mobile (crash-free
sessions) as applicable to the stack.

## 3. SLIs

Per SLO: good events / valid events, the **measurement source** (the edge proxy,
the API server span, or a synthetic probe), the metric name, and what is
excluded from "valid" (client-caused 4xx, announced maintenance, load-test
traffic, others with a reason). The metric name is the semconv-stable name at the
pinned version (`opentelemetry/best-practices.md` section 2), **not** the older
name some examples use; the exported backend name is `NOT SOURCEABLE`. For each
SLI cite where it will be (or is) emitted: a `/observability-plan plan` item or a
`file:line`. **An SLI with no emitting code is not an SLO** (SRE-SLO check 3): it
is listed as `no emitter planned` and blocks.

## 4. Targets and windows (the user decides)

- Present the template's example targets as a starting point only, and show the
  consequence in minutes: error budget = (1 - target) x window. Compute it (28
  days = 40,320 minutes; 99.9 % -> about 40 minutes; 99.5 % -> about 3.4 hours;
  99 % -> about 6.7 hours) and show the arithmetic.
- Justify each target from product need, not by copying the example. Reality
  check: a single-host Compose deployment (`deploy.target: compose-vps`) has no
  redundancy beyond what the product builds; say plainly when a proposed target
  is not credible for the topology (a judgement, labelled as one).
- **Latency thresholds come from `docs/architecture/perf-budgets.md` and the
  measured load-test p95** (SRE-SLO check 4): cite both numbers. A budget row
  or a measurement that does not exist makes that threshold `NOT ASSESSED`; offer
  `/perf-profile` / `/load-test`. Starting defaults are in `performance-standard.md`.
- Window: the template's rolling 28 days unless the user states another.

## 5. Error budget policy (the user decides)

What happens when the budget is low or exhausted, and who decides: the template
suggests freeze of risky releases below a remaining-budget threshold, reliability
work first, exceptions approved by `cto`, and a post-mortem when one incident
consumes more than a stated share. The bracketed percentages in the template are
placeholders: the user sets them. An absent policy is a gap (SRE-SLO check 8).

## 6. Alerts

Alerts are **burn-rate alerts on SLOs** plus a short fixed list of cause alerts
that always need a human (`observability-standard.md`; `sre-lead` Senior Bar):
DB down, disk > 85 %, certificate expiring, backup failed or stale, replication or
WAL-archive lag, queue depth or dead-letter growth.

- **Burn-rate windows and multipliers:** the template lists common starting
  defaults (fast burn 14.4x over 1 h confirmed by 5 min; medium 6x over 6 h
  confirmed by 30 min; slow 1x over 3 days confirmed by 6 h) and says to verify
  them against the SRE workbook. That workbook is **not in the stack reference**:
  until a research note cites it, the thresholds are `NOT SOURCEABLE` and the
  alert-threshold section is `NOT ASSESSED` (SRE-SLO check 5 requires the source
  cited). Route to `/research burn-rate-alerting`.
- **Alert rule syntax** depends on the telemetry backend, which is an ADR
  (`observability-standard.md`). With no backend ADR the alerts are specified
  abstractly (SLI expression in terms of the OTel metric, windows, severity,
  runbook path) and the rule files are `not written - backend undecided`.
- **Every alert links a runbook** in `docs/runbooks/`; the file must exist and be
  non-empty (check 6). Alerts carry no PII; routing (who is paged, who is
  notified) is documented (check 9).
- Severity ladder and page vs ticket come from `sre-lead`; incident handling is
  `/incident` and `incident-response.md`.

## 7. Dashboards and reporting

SLO dashboard (SLI, budget remaining, burn rate per journey), the monthly SLO
report owner and where it is published, the customer-facing status page, and for
self-hosted editions the dashboards and alert rules the bundle ships. Dashboards
are code where the backend allows; the format is backend-specific and
`NOT SOURCEABLE` until the ADR.

## 8. Agents

Spawn **in parallel**: `sre-lead` (drafts the document: journeys, SLO table,
budget, policy, alert table) and `observability-engineer` (checks each SLI is
emittable with the planned instrumentation and drafts the dashboard and rule
list), plus `performance-engineer` for the latency evidence. Brief each with: the
mode, the confirmed journeys, the user's targets and window, the inputs with
FOUND/ABSENT, the NOT SOURCEABLE list above, and "return text only, write no
file; never write a threshold, metric export name or rule syntax from memory".
You assemble the document; the targets stay the user's.

## 9. Retained in the document

Fill `.claude/docs/templates/slos.md` section by section with the template's
headings. Mark examples replaced by user decisions; leave no bracketed example
value in the written file unless it is labelled as an unconfirmed placeholder.
Add a Change Log row with today's date (`date +%F`) and who approved. Continue to
`4-checks-gate-and-write.md`.
