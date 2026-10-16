# /perf-profile — Per-Layer Measurement

> Phase 3 of `SKILL.md`. For each layer in scope: what to measure, the tool, the
> budget it is checked against, and what makes the layer `NOT MEASURED`.

**Rules for every row**

- **Measure on the local dev stack with seeded test tenants only**
  (`.claude/docs/run-and-observe.md`: `docker compose -f deploy/compose.dev.yaml
  up -d --wait`, `tools/seed/`). Never production, never a shared or staging
  environment, never real customer data — unless the user names the target and
  accepts the risk. Never `docker compose down -v`.
- **Production-like data volume.** A profile on an empty database proves nothing
  about a list endpoint. State rows and tenants; if the seed is smaller than
  `perf-budgets.md` §4 capacity assumptions, say so and mark the result
  `small-data (indicative only)`.
- **Three or more runs** for any before/after claim; report variance. A change
  smaller than run-to-run variance is "not significant".
- **Flags and options come from the sources.** Tools named below are those in
  `.claude/docs/performance-standard.md`. Their invocations come from
  `docs/stack-reference/` where covered (column "Sourced in"), and otherwise are
  `NOT SOURCEABLE` there — then the layer is `NOT MEASURED — invocation not
  sourced` and the next step is `/research` (via `researcher`); do **not** write
  a flag from memory. The stack reference has **no** page for k6, Lighthouse CI,
  async-profiler or JFR options.
- **Static findings are candidates, not measurements.** Reading code to find an
  N+1 or a loop-in-handler is evidence grade `STATIC`; a profile, plan or trace
  is `MEASURED`. Only `MEASURED` findings carry a quantified gain.
- A tool that is not installed, a device that is not attached, a host that is
  not macOS: `NOT MEASURED — [reason]`. Never estimate a number in its place.
- **Granted vs handed off** (see `SKILL.md`): `go test -bench`, `go tool pprof`,
  `docker stats` and local `curl` run here; `psql` (`pg_stat_statements`, `EXPLAIN`),
  cache stats, Lighthouse, Macrobenchmark, Instruments, JFR and async-profiler are
  run by the named owner or the user, or prompt with the target shown.

| Layer | What to measure | Tool | Budget row (`perf-budgets.md`) | Sourced in | `NOT MEASURED` when |
|---|---|---|---|---|---|
| **Go backend** | CPU, heap/alloc, goroutine, mutex profiles of the hot endpoint under load; `-bench -benchmem` ns/op, B/op, allocs/op on the budgeted function; `-race` on touched packages | `pprof`, `go test -bench` | per-endpoint p95, service memory | `docs/stack-reference/go/best-practices.md` (pprof endpoints, Go 1.27 goroutine-leak profile) | profiling endpoint not enabled in the dev build and the user declines enabling it; no Go toolchain |
| **Ktor / Kotlin backend** | method-level hot spots, blocking I/O on a coroutine dispatcher, allocation, GC | JFR, async-profiler | per-endpoint p95, service memory | none — options `NOT SOURCEABLE` in `docs/stack-reference/ktor/` and `kotlin/` | always, until the invocation is sourced (`/research`); static review of blocking calls on dispatchers is still `STATIC` |
| **PostgreSQL** | top statements by `total_exec_time`, `mean_exec_time`, `calls`; cache-hit ratio `shared_blks_hit/(hit+read)`; `temp_blks_written`; `EXPLAIN (ANALYZE, BUFFERS)` of each hot query **as the non-owner `app` role** (RLS cost included) naming the index used, estimated vs actual rows, no seq scan on a large tenant-scoped table; queries/request count (N+1) | `pg_stat_statements`, `EXPLAIN` | single SQL ≤ 20 ms, > 100 ms logged with plan, ≤ 5 queries/read request | `docs/stack-reference/postgres/best-practices.md` §2, §5 | extension not preloaded/created (that itself is a finding: record `pg_stat_statements not enabled`), no DB reachable |
| **Cache** | hit ratio, latency, evictions, memory vs `maxmemory`, slowlog, stampede behaviour, cache-down degradation | engine stats, slowlog | cache rows in §5 | `docs/stack-reference/redis/best-practices.md` §2–§4, §8; dragonfly/valkey per `deploy`; `.claude/docs/caching-standard.md` | no cache in the stack |
| **API contract/payload** | response size histogram, list page size ≤ 100, uncompressed ≤ 200 KB, pagination style (keyset on growing sets) | request replay + size, OpenAPI | API payload | `.claude/docs/api-standards.md` | stack not running |
| **Background jobs / webhooks** | runtime vs max runtime and timeout, concurrency bound, queue depth/lag, retry behaviour | job metrics, traces | §3 Background Jobs | `.claude/docs/observability-standard.md` | no job metrics emitted (a finding) |
| **Web app** (`web/`) | LCP / INP / CLS (p75), initial JS gzipped for the authenticated shell ≤ 170 KB with route code-splitting, throttle profile stated | Lighthouse CI, web-vitals, bundle analyzer | web rows | `docs/stack-reference/vite-react/` (bundle budget, Vite build); Lighthouse CI invocation `NOT SOURCEABLE` | Lighthouse invocation not sourced → size from the built bundle only (that part is `MEASURED`), vitals `NOT MEASURED` |
| **Marketing site** (`site/`) | Lighthouse report on changed pages | Lighthouse | web rows | `docs/stack-reference/astro/` | as above |
| **Android** | cold start ≤ 1.5 s on a mid-range device (device model and OS recorded), baseline profile present (binary profile < 1.5 MB), jank on main journeys | Macrobenchmark, baseline profiles, Android Studio profiler | Android rows | `docs/stack-reference/compose/best-practices.md` §9 and `VERSION.md` (versions) | no device/emulator attached; emulator numbers are `indicative only`, not a budget result |
| **iOS** | cold start ≤ 1.0 s to first frame, Hangs, Time Profiler, Allocations | Instruments | iOS rows | `docs/stack-reference/swiftui/` (CI on macOS runners) | host is not macOS (`swiftui/VERSION.md`: iOS builds need macOS with Xcode) → `NOT MEASURED — requires macOS` |
| **Service memory / sizing** | steady-state RSS vs container limit with 30 % headroom; self-hosted preflight minimum (CPU/RAM/disk) backed by a run at that size | container metrics, pprof/JFR | service memory | `docs/stack-reference/docker-compose/best-practices.md` §3 | no limits set in compose (a finding) |
| **Load (hot endpoints)** | ramp / steady / spike against the budget, p50/p95/p99, error rate, throughput, saturated resource | k6 — **run via `/load-test`**, not here | per-endpoint rows | `/load-test` | route to `/load-test`; this skill consumes its result |

## Static candidate checklist (grade `STATIC` until measured)

Look in the changed/in-scope code for, and list with `file:line`:

- Per-row queries or cache calls inside loops (N+1); missing `IN`/`ANY` bounds, bulk writes, `MGET`
- Offset pagination on growing sets; unbounded lists; missing page-size cap
- A query with no index named; tenant filter not leading in the index
  (`postgres/best-practices.md` §2)
- Work in the request path that belongs on a queue (email, PDF, export, webhook out)
- Missing timeouts on outbound calls; unbounded pools, queues or goroutines/coroutines
- Allocation in hot loops; large JSON built in memory; no compression at the proxy
- Cache added or proposed without a measured hit-ratio gain and an invalidation story
- Web: route not code-split, large dependency in the shell, images unsized/unmodern
- Mobile: work on the main thread, non-lazy lists or unstable keys, un-downsampled images, uncoalesced calls

## Ranking recommendations

Rank by **(budget gap closed) × (evidence strength) ÷ effort**, in this order of
evidence strength: `MEASURED` (profile/plan/trace/benchmark attached) >
`STATIC` with a reproducible query count or plan > `STATIC` code-read only.

Each recommendation states:

- **Expected gain** — for `MEASURED`: the share of the profile or the delta in
  the plan (e.g. "38 % of CPU in X; ≤ 38 % upper bound"); for `STATIC`:
  `not quantified — needs a profile`. Never a made-up percentage.
- **Evidence** — path under `production/qa/evidence/perf-profile-[scope]-[date]/`
  or `STATIC (file:line)`.
- **Risk** (Low/Med/High), **effort** (S/M/L), **owner** (the stack lead who owns
  the code — `go-lead`, `ktor-lead`, `web-lead`, `android-lead`, `ios-lead`,
  `postgres-specialist` for indexes, `cache-specialist` for cache design).
- **Re-measure plan** — which measurement proves it worked, on the same data.
