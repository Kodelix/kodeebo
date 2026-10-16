# Coding Standards

Every line of code is written at the level of a **senior engineer in that
role**: the Go code a senior Go engineer would merge, the Compose code a senior
Android engineer would merge. "It works" is the floor, not the bar.

## Definition of Done — the eight gates

A story is not Done until each gate is met **or explicitly waived with a written
reason** in the story file. `/story-done` checks every gate. Detailed standards
live in the linked docs in `.claude/docs/`; API shape rules in `api-standards.md`.

| # | Gate | Evidence | Standard |
|---|---|---|---|
| 1 | **Research first** | `docs/research/<feature>.md` exists before code: primary sources, pinned versions, alternatives rejected and why | `research-protocol.md` |
| 2 | **Clean architecture** | Domain has no framework/DB/HTTP imports; dependencies point inward; ports at the boundary | `clean-architecture.md` |
| 3 | **Tests** | Unit tests on domain + use cases; integration tests on real PG/Mongo/Redis/Dragonfly via Testcontainers; contract tests on the API | `testing-standards.md` |
| 4 | **Observability** | Every endpoint and job emits an OTel span, RED metrics and structured logs carrying `trace_id`; no PII in telemetry | `observability-standard.md` |
| 5 | **Caching** | A written cache decision: pattern, key schema, TTL, invalidation, stampede protection — or a written reason for no cache | `caching-standard.md` |
| 6 | **Performance** | Meets the budget in `docs/architecture/perf-budgets.md` (p95 latency, queries per request, payload size); no N+1; hot paths load-tested | `performance-standard.md` |
| 7 | **Security** | Mapped to OWASP ASVS (backend/web) or MASVS (mobile) controls; tenant isolation tested; threat model for auth, billing, file upload, PII; dependency scan clean | `security-baseline.md` |
| 8 | **Decision record** | ADR for every architectural decision the story made | `docs/architecture/` |

### Gate levels — what config can and cannot change

| Gate | Level | Configurable by |
|---|---|---|
| 1 Research, 2 Clean architecture, 4 Observability, 5 Caching, 7 Security, 8 Decision record | **Always BLOCKING** at every tier | nothing — a story may only pass them by meeting them or by a written, user-approved waiver in the story file (never for security evidence on a security-sensitive story) |
| 3 Tests | **BLOCKING at every tier** for Logic, Integration, Contract and Security story types: the tests **exist and pass** | `testing.strict.*` may only make other types stricter; `qa.level` changes how much *additional* evidence is required (manual cases, coverage signal, UAT), never whether the required tests exist and pass |
| 6 Performance | ADVISORY by default | `performance.enforce: block` makes it BLOCKING; a missing budget is "not checked", never "met" |

`workflow` and `qa.level` scale **documents and extra evidence**, not these
gates (see `workflow-modes.md`). A product on the default `minimal` tier still
cannot close a story or pass the release gate with failing or missing required
tests.

Per-type evidence and defaults are in **Test evidence by story type** below.

## Code rules

- **Doc comments on every exported/public API**, stating contract and failure modes — not restating the name.
- **No hardcoded business values.** Prices, limits, quotas, TTLs, timeouts and feature flags come from config or the database, with typed defaults.
- **Dependency injection over singletons and globals.** Every use case is constructible in a test with fakes.
- **Errors are values with context.** Wrap with cause; map to RFC 9457 problem details at the HTTP edge only; never leak internals or stack traces to clients.
- **Every external call has a timeout, a retry policy (idempotent calls only) and a circuit breaker or bulkhead** where failure can cascade.
- **Every write that a client or webhook can repeat is idempotent** (idempotency key or natural key).
- **Every query is tenant-scoped.** A query that can return another tenant's row is a security bug, not a logic bug.
- **Secrets never in code, logs, URLs or client bundles.** Read from the environment or a secret store.
- **Migrations are forward-only in production and reversible in development**, and never lock a hot table without a written plan.
- **Shared capabilities come from `saas-core`.** Re-implementing identity, OTP, storage, billing, licensing or observability inside a product is a review failure — extend core instead (`/core-extract`). When the core or the module does not exist yet, a product-local adapter behind the same port, recorded in an ADR and scheduled for `/core-extract`, is the accepted path (`coordination-rules.md` § Shared core absent).
- Architecture decisions are recorded as ADRs in `docs/architecture/`. How many is set by `modes.workflow`: all at `full`, critical only at `standard`, none required at `minimal`.

## Commits

- Conventional Commits: `feat:`, `fix:`, `perf:`, `refactor:`, `test:`, `docs:`, `chore:`, `security:`.
- The body references the story or task ID (`Story: BILLING-003`).
- No commit without the user's instruction.

## Test evidence by story type

| Story type | Required evidence | Location | Default gate |
|---|---|---|---|
| **Logic** (domain rules, pricing, state machines) | Unit tests, must pass | beside the code (see `directory-structure.md`) | BLOCKING |
| **Integration** (DB, cache, queue, external provider) | Testcontainers integration test | per layer | BLOCKING |
| **Contract** (API shape between backend and clients) | Contract test against `contracts/` | per consumer | BLOCKING |
| **Security** (auth, tenancy, billing, uploads, PII) | Negative tests (authz bypass, cross-tenant, injection) + ASVS/MASVS mapping | per layer + `production/qa/evidence/` | BLOCKING |
| **Performance** (hot path, list endpoints, jobs) | Load test result vs budget | `production/qa/evidence/` | ADVISORY (BLOCKING when `performance.enforce: block`) |
| **UI** (web or mobile screens) | Retained screenshot of every screen touched + `/impeccable audit` result | `production/qa/evidence/` | BLOCKING |
| **Config** (limits, flags, prices) | Smoke check pass | `production/qa/smoke-[date].md` | ADVISORY |

**A compile is not a run.** Every story that changes something a user can see
or call is launched and observed before it closes: the endpoint is called
against a running stack, the screen is opened in a browser, emulator or
simulator, and the observation is retained in `production/qa/evidence/`.

## Automated test rules

- **Deterministic**: no real clock, no unseeded randomness, no sleeps — inject a clock and an ID generator.
- **Isolated**: each test owns its data; integration tests use a fresh schema/database/keyspace per test or per suite.
- **Real dependencies for integration**: Testcontainers, never a mocked database.
- **Unit tests make no network, disk or database calls.**
- **Never disable or skip a failing test to get green** — fix the cause or mark the story blocked.
- CI runs the full suite on every push and PR; a red suite blocks merge.
