# /debug — Reproduce and Observe

> Part of `/debug`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its headings still apply here.

## 1. Reproduce — the smallest deterministic failure

Reduce the report to a script, a test or a request sequence that fails **on
demand**, and write down:

| Field | Content |
|---|---|
| Commit / version | the git hash, or the hosted release / self-hosted version number |
| Environment | compose dev stack (`deploy/compose.dev.yaml`), staging named by the user, device model + OS, or the customer bundle version |
| Data shape | what must be true of the data (rows, sizes, locale, clock/time-zone) |
| Tenant / role / plan | the seeded test tenant, the role, the plan and entitlements — a cross-tenant or plan-gated bug needs both sides |
| Steps | numbered, with the request/response pairs (secrets redacted) |
| Expected vs actual | one line each |
| Failure rate | n of m runs, **m stated** |

- `debugger` (not this skill, which has no compose or test grants) brings the stack up as `run-and-observe.md` §1 says: `docker compose -f
  deploy/compose.dev.yaml up -d --wait`, the seeded tenant from `tools/seed/`.
  A service that never becomes healthy **is** the finding. Never `down -v`.
- Pin the commit, the image digests and the config that failed. "Works on my
  machine" is not closure.
- **Intermittent failures are characterised before diagnosis:** failure rate
  over N runs, correlation with load, time, tenant, data size or ordering. A race
  is confirmed with the Go race detector (`go test -race`, per
  `docs/stack-reference/go/best-practices.md`: it only finds races on executed
  paths) or a stress loop — never assumed.
- "Cannot reproduce" is reported with **what was tried** (environments,
  versions, data, N runs), not as closure.
- Minimise: remove steps until the failure disappears, put the last one back.
  Confirm the minimal repro fails on a **clean seeded tenant**.

## 2. Observe — read what the system already emits

Read before touching code (`.claude/docs/observability-standard.md` defines the
signals that exist to be queried):

| Source | How | Notes |
|---|---|---|
| Trace | by `trace_id` in the local collector UI (dev) or the trace backend the project uses | handler → use case → DB/cache spans; record the span that errored or ran long |
| Logs | structured logs filtered by `trace_id` / tenant / request id | timestamps in **UTC** |
| Metrics | RED per route/job, USE per resource, pool-wait, queue depth | the panel and window read |
| Query plans | `EXPLAIN (ANALYZE, BUFFERS)` taken as the non-owner application role | a slow-query log entry carries the plan |
| Cache | key inspection and command stats | the key schema is in the cache design record |
| Crash reports | symbolicated stack (mobile/web) | mapping files from CI |
| Browser | devtools Network/Performance/Memory panels, source maps | |
| Android | `adb logcat`, Layout Inspector, Perfetto/Profiler | needs a device or emulator |
| iOS | Xcode Instruments and `lldb` | **macOS host only** — on Linux, `NOT EXAMINED — macOS only` |

- Cite every signal read: the trace ID, the log query, the panel and window, the
  plan. A source that exists but could not be read (no access, rotated, not
  collected) is named — it caps the verdict at `LIKELY`.
- **No debug logging is added to production code** until the existing signals
  are shown insufficient. When added, it goes on a branch and is removed or kept
  only through a normal story.
- **Never put secrets, tokens, OTPs or customer PII into the record.** Identifiers
  are masked or hashed; evidence is referenced by location. Grep what you are
  about to save.
- Production or a customer's live tenant is read only inside an approved scope
  (Phase 1 of `SKILL.md`).
