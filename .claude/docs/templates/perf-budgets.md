# Performance Budgets: [Product]

> **Path**: `docs/architecture/perf-budgets.md` · **Status**: Draft | Active · **Owner**: performance-engineer · **Last reviewed**: [YYYY-MM-DD]
> **Enforcement**: `performance.enforce` in `project.yaml` — `warn` or `block` (a missed budget warns or blocks the Performance gate; DoD gate 6)

<!-- The "Default" column is the starting point from performance-standard.md.
     Tighten (or, with a written reason, loosen) per product in the "Product budget" column — that column is what stories are checked against.
     Percentile is p95 unless stated. Evidence: load-test results saved to production/qa/evidence/<story-id>/ with environment, data volume and the budget checked. -->

## 1. Budgets

| Surface | Default (p95 unless stated) | Product budget | Basis for change | How measured |
|---------|----------------------------|----------------|------------------|--------------|
| Read API endpoint | ≤ 150 ms server time | [ ] | | k6, RED histograms |
| Write API endpoint | ≤ 300 ms server time | [ ] | | k6, RED histograms |
| Auth / token refresh | ≤ 200 ms | [ ] | | k6 |
| DB queries per request | ≤ 5 on reads; **no N+1 ever** | [ ] | | query-count assertion in integration test |
| Single SQL query | ≤ 20 ms; any query > 100 ms is logged with plan | [ ] | | `pg_stat_statements`, `EXPLAIN (ANALYZE, BUFFERS)` |
| Background job | defined per job, with a max runtime and a timeout | see section 3 | | job metrics |
| API payload | list pages ≤ 100 items; responses ≤ 200 KB uncompressed | [ ] | | response size histogram |
| Web — LCP / INP / CLS | ≤ 2.5 s / ≤ 200 ms / ≤ 0.1 (p75, field data) | [ ] | | Lighthouse CI + web-vitals RUM |
| Web — initial JS | ≤ 170 KB gzipped for the authenticated shell; routes code-split | [ ] | | bundle analyzer in CI |
| Android — cold start | ≤ 1.5 s on a mid-range device; baseline profiles shipped | [ ] | | Macrobenchmark |
| iOS — cold start | ≤ 1.0 s to first frame | [ ] | | Instruments / XCTest metrics |
| Mobile frame rendering | no janky frames on main journeys | [ ] | | Macrobenchmark / Instruments |
| Service memory | steady-state RSS within the container limit with 30 % headroom | [ ] | | container metrics, pprof/JFR |

## 2. Per-Endpoint / Per-Screen Budgets

<!-- Hot paths get explicit rows: listing, search, dashboards, auth, webhooks. Link the spec/story that owns each. -->

| Endpoint / screen | Type | p95 budget | Queries | Payload | Throughput target | Index / query plan | Owner story | Status |
|-------------------|------|-----------|---------|---------|-------------------|-------------------|-------------|--------|
| `GET /v1/...` | Read | | | | [req/s at p95] | [index name] | | |

## 3. Background Jobs

| Job | Trigger | Max runtime | Timeout | Concurrency bound | Retry policy | Data volume assumption |
|-----|---------|-------------|---------|-------------------|--------------|-----------------------|

## 4. Capacity Assumptions

- Tenants: [N now / N at 12 months] · Largest-tenant size: [rows / users]
- Peak request rate: [req/s] · Concurrency: [connections]
- Data growth: [GB/month] · Retention: [policy]
- Load-test data volume must reflect these assumptions

## 5. Resource Limits

| Resource | Limit | Alert | Notes |
|----------|-------|-------|-------|
| DB connection pool | [size, wait timeout] | pool wait p95 | sized deliberately |
| Redis/Dragonfly memory | `maxmemory` [x], eviction [policy] | hit ratio, evictions | |
| HTTP client pools / timeouts | [sizes, timeouts] | | every outbound call has a timeout |
| Request body size | [limit] | | |

## 6. Load-Test Protocol

- Tool: k6; scenarios per hot endpoint: **ramp, steady, spike**; thresholds = the budgets above
- Environment: [production-like]; data volume: [per section 4]; auth and tenancy included
- Pass criteria: all thresholds met, error rate < [x]%, no resource saturation
- Evidence location: `production/qa/evidence/<story-id>/` (script, raw results, environment, budget checked)
- Cadence: per story for hot paths; before each release for the top journeys (`/load-test`)

## 7. Waivers

<!-- A missed budget needs a written waiver (named approver, expiry) or a fix. -->

| Surface | Budget | Actual | Reason | Approved by | Expires |
|---------|--------|--------|--------|-------------|---------|

## 8. Change Log

| Date | Change | Reason | Approved by |
|------|--------|--------|-------------|
