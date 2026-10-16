# Performance Standard

DoD gate 6. Performance is designed, budgeted and measured — not hoped for.
`performance.enforce` in `project.yaml` sets whether a missed budget warns or
blocks.

## Budgets

Each product keeps `docs/architecture/perf-budgets.md`. Starting defaults,
tightened per product:

| Surface | Budget (p95 unless stated) |
|---|---|
| Read API endpoint | ≤ 150 ms server time |
| Write API endpoint | ≤ 300 ms server time |
| Auth / token refresh | ≤ 200 ms |
| DB queries per request | ≤ 5 on reads, no N+1 ever |
| Single SQL query | ≤ 20 ms; any query > 100 ms is logged with plan |
| Background job | defined per job, with a max runtime and a timeout |
| API payload | list pages ≤ 100 items; responses ≤ 200 KB uncompressed |
| Web — LCP / INP / CLS | ≤ 2.5 s / ≤ 200 ms / ≤ 0.1 (p75, field data) |
| Web — initial JS | ≤ 170 KB gzipped for the authenticated shell; routes code-split |
| Android — cold start | ≤ 1.5 s mid-range device; baseline profiles shipped |
| iOS — cold start | ≤ 1.0 s to first frame |
| Mobile frame rendering | no janky frames on main journeys (Macrobenchmark / Instruments) |
| Service memory | steady-state RSS within the container limit with 30 % headroom |

## Design rules

- **Measure before optimizing**, but **design for the known hot paths up front**: listing, search, dashboards, auth, webhooks.
- **Indexes are part of the feature.** Every new query names the index it uses; `EXPLAIN (ANALYZE, BUFFERS)` output for hot queries goes into the PR.
- **Keyset (cursor) pagination** for anything that can grow; offset pagination only for small bounded sets.
- **Batch and pipeline**: no per-row queries or cache calls in loops; use joins, `IN`/`ANY` with bounds, `MGET`, bulk writes.
- **Connection pools sized deliberately** (DB, Redis, HTTP clients) with timeouts; pool wait time is a metric.
- **Async for slow work**: email, PDF, exports, webhooks out → queue/outbox, not the request path.
- **Backpressure**: bounded queues and worker pools; reject early with 429/503 rather than collapse.
- **Allocation-aware Go / coroutine-aware Kotlin**: no goroutine/coroutine per item without a bound; reuse buffers on hot paths only when profiling justifies it.
- **Payloads**: field selection or purpose-built DTOs; compression (gzip/br) at the proxy; images resized and served in modern formats.
- **Mobile**: lazy lists with stable keys, no work on the main thread, images downsampled, network calls coalesced.

## Measurement

| Tool | Use |
|---|---|
| Go `pprof` (CPU, heap, goroutine, mutex), `go test -bench` | backend hot paths |
| JFR / async-profiler | Ktor hot paths |
| `pg_stat_statements`, `EXPLAIN ANALYZE`, slow query log | database |
| k6 | load tests per hot endpoint: ramp, steady, spike; thresholds = budgets |
| Lighthouse CI + web-vitals RUM | web |
| Macrobenchmark, baseline profiles, Android Studio profiler | Android |
| Instruments (Time Profiler, Allocations, Hangs) | iOS |

Load-test results are saved in `production/qa/evidence/<story-id>/` with the
environment, data volume, and the budget they were checked against.

## Review checklist

- [ ] Hot queries have an index and a plan in the PR.
- [ ] No N+1 (verified by query-count assertion in an integration test).
- [ ] Pagination is bounded and keyset-based where the set can grow.
- [ ] Every outbound call has a timeout; pools are bounded.
- [ ] Caching decision recorded (see `caching-standard.md`).
- [ ] Budget for the surface is met, with evidence, or a waiver is written.
