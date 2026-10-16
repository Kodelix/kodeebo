# SLOs: [Product / Service]

> **Path**: `docs/architecture/slos.md` · **Status**: Draft | Active · **Owner**: sre-lead · **Reviewed**: [YYYY-MM-DD]
> **Window**: [rolling 28 days unless stated] · **Review cadence**: [monthly; after every S1/S2 incident]
> **Standards**: `observability-standard.md` — alerts are **burn-rate alerts on SLOs** plus a short list of cause alerts that always need a human; **every alert links a runbook** (`docs/runbooks/`); an alert without a runbook is not merged.

## 1. Critical Journeys

<!-- One row per user-visible journey that matters commercially. Typical: login/token refresh, core action, payment/checkout, licence activation, data export, webhook delivery. -->

| ID | Journey | Why it is critical | User-visible failure | Owner |
|----|---------|-------------------|----------------------|-------|
| J1 | [Sign in] | | | |
| J2 | [Core action: create/save] | | | |
| J3 | [Payment / plan change] | | | |
| J4 | [Licence activation (self-hosted)] | | | |

## 2. SLIs & SLOs

<!-- SLI = good events / valid events, measured at the edge (proxy/load balancer or the API server span) or by synthetic probes. Latency thresholds come from perf-budgets.md. -->

| Journey | SLI type | SLI definition (good / valid) | Measurement source | SLO target | Window |
|---------|----------|-------------------------------|-------------------|-----------|--------|
| J1 | Availability | requests to `POST /v1/auth/token` with status < 500 / all valid requests | RED metrics `http.server.request.duration` (OTel semconv HTTP, stable) + `http.response.status_code` | [99.9%] | 28 d |
| J1 | Latency | requests under [200 ms] p95 threshold / valid requests | histogram buckets | [99%] | 28 d |
| J2 | Availability | [...] | | [99.9%] | 28 d |
| J2 | Latency | [...] | | [99%] | 28 d |
| J3 | Correctness | payments reconciled with provider within [10 min] / payments attempted | reconciliation job metric | [99.9%] | 28 d |
| J4 | Availability | activation requests succeeded / valid | | [99.5%] | 28 d |
| Web | Experience | page views meeting LCP/INP/CLS thresholds / all (field data) | RUM | [75% at p75 targets] | 28 d |
| Mobile | Stability | crash-free sessions / sessions | crash reporting | [99.5%] | 28 d |

**Excluded from "valid"**: client-caused 4xx, planned maintenance (announced), load-test traffic, [others with reason].

## 3. Error Budget

| SLO | Target | Budget (bad events / minutes per window) | Current burn | Remaining |
|-----|--------|------------------------------------------|-------------|-----------|
| J1 availability | 99.9% | [≈ 40 min per 28 d] | | |

**Error budget policy**:
- Budget > [50]% remaining: normal feature work
- Budget < [25]% remaining or exhausted: freeze risky releases; reliability work takes priority until recovered; exception requires `cto` approval
- A single incident consuming > [20]% of a window's budget requires a post-mortem (`post-mortem.md`)

## 4. Alerts (burn-rate)

<!-- Multi-window, multi-burn-rate alerts: page on fast burn, ticket on slow burn. The numbers below are common starting defaults — tune them against traffic and verify against the SRE workbook at the pinned guidance version. -->

| Alert | Burn rate | Long window | Short window | Budget consumed if it persists | Severity | Action | Runbook |
|-------|----------|-------------|--------------|--------------------------------|----------|--------|---------|
| Fast burn | 14.4x | 1 h | 5 min | 2% in 1 h | Page | On-call responds immediately | [`docs/runbooks/....md`] |
| Medium burn | 6x | 6 h | 30 min | 5% in 6 h | Page | On-call responds | [...] |
| Slow burn | 1x | 3 d | 6 h | 10% in 3 d | Ticket | Next working day | [...] |

**Cause alerts that always need a human** (not SLO-based):

| Alert | Condition | Severity | Runbook |
|-------|-----------|----------|---------|
| Database down | readiness fails / connections 0 | Page | |
| Disk usage | > 85 % | Page | |
| Certificate expiring | < [14] days | Ticket -> Page at < 3 d | |
| Backup failed / restore drill overdue | last success > [26] h | Page | |
| Queue lag / dead-letter growth | lag > [N] / DLQ > 0 | Page / Ticket | |

## 5. Dashboards & Reporting

- SLO dashboard: [link] — shows SLI, budget remaining, burn rate per journey
- Monthly SLO report: [owner, where published]; customer-facing status page: [link]
- Self-hosted: SLOs are advisory; the bundle ships dashboards and alert rules the operator can import; no telemetry leaves the customer environment without opt-in

## 6. Change Log

| Date | Change | Reason | Approved by |
|------|--------|--------|-------------|
