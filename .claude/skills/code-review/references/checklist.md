# /code-review — Checklists

> Lookup for Phases 4–8c of `/code-review`. Each unchecked item that fails becomes
> a finding with `path:line`, a severity and the rule cited. An item that cannot
> be judged from the inputs is `not checked — [reason]`, never counted as met.
> Standards: `.claude/docs/coding-standards.md`, `clean-architecture.md`,
> `api-standards.md`, `security-baseline.md`, `testing-standards.md`; layer rules
> in `.claude/rules/`.

## Severity

| Level | Meaning | Examples |
|---|---|---|
| **BLOCKER** | A BLOCKING DoD gate is unmet by the code, or an ADR/rule is violated in a way that must not merge | domain imports a framework/DB/HTTP package; a query can return another tenant's row; tenant read from the request body; a client-computed price, total or other derived value accepted as authoritative; missing authorization before a side effect; secret in code/log/URL; pattern the ADR rejected; non-idempotent repeatable write on money/state; stack trace or SQL in a client response; migration locking a hot table with no plan; re-implementing `saas-core` identity/OTP/billing/licensing |
| **MAJOR** | Real defect or standards breach that should be fixed before merge; an ADVISORY gate gap with real consequence | ADR drift; external call with no timeout; retry on a non-idempotent call; hardcoded business value (price, limit, quota, TTL, flag); exported API with no doc comment; use case not constructible with fakes; span/RED metrics/trace-carrying log missing on a new endpoint; N+1 on a list path; unbounded pagination; no cache decision on a hot read; cache failure fails the request |
| **MINOR** | Improves quality, no behavioural risk | naming, small duplication, function slightly over 40 lines with clear reason, missing optional comment |

## A. Standards compliance (Phase 4)

- [ ] Every exported/public API has a doc comment stating **contract and failure modes** (not restating the name) — name the method or type when missing.
- [ ] Cyclomatic complexity ≤ 10 per function; no function over ~40 lines (excluding data declarations) unless a comment justifies it.
- [ ] Dependencies are injected: no package-level mutable state, singletons or service locators; every use case constructible in a test with fakes (`Clock`, `IDGenerator`, repositories as ports).
- [ ] No hardcoded business values — prices, limits, quotas, TTLs, timeouts, feature flags come from config or the database with typed defaults.
- [ ] Errors are values with context: wrapped with cause (`%w`, `cause`), compared with `errors.Is/As` / sealed types, mapped to RFC 9457 at the HTTP edge **only**; no string matching on errors; no `panic` / `!!` / `any` shortcuts in business code.
- [ ] Naming and layout follow `project.yaml` `naming.*` (if set) and the layer rules.
- [ ] Commit-ready: no `fmt.Println`/`console.log`/`println` left in production code; no commented-out code; no TODO without a story/issue ID.

## B. Clean architecture (Phase 5, DoD gate 2)

Run the import greps below — by tool, not by eye — and list each violating import with `path:line`.

- [ ] `domain` imports nothing outside the standard library and other domain packages: no framework, DB driver/ORM, HTTP library, logger or telemetry.
- [ ] Dependencies point inward: `domain` ← `app` ← `adapters`; no `domain`/`app` import of an `adapters` package; no adapter type (DB row, DTO, SDK type) crosses into `app` or `domain`.
- [ ] Every external dependency of a use case is a **port declared by the consumer** (`app`), small (1–3 methods), injected; adapters implement them.
- [ ] Wiring only in the composition root (`cmd/<binary>/main.go`, `Application.module`, the DI graph on mobile, `src/app/` on web); nothing else constructs adapters.
- [ ] Transactions are owned by the use case (unit-of-work port), not by handlers.
- [ ] No context reaches into another context's `domain` or tables; cross-context calls go through the other context's `app` API or events.
- [ ] Request validation of *shape* is at the edge; validation of *meaning* (plan allows it, quota not exceeded) in `domain`/`app`; the authorization decision is in `app` (policy port) before any side effect; caching sits in an adapter decorator, not in the use case; telemetry at adapter edges and use cases, never in `domain`.
- [ ] Anti-patterns absent: anaemic domain + fat handlers; generic `Repository<T>`; shared `utils`/`common` package every context imports; framework annotations on domain types; microservice split without an ADR.

**Import greps** (Grep tool; adjust roots from `resolve_code_root`):

| Layer | Grep (domain package) | Violation if matched |
|---|---|---|
| Go | pattern `"(net/http\|database/sql\|github\.com/(jackc\|redis\|go-redis)\|go\.opentelemetry\.io\|log/slog\|encoding/json)` in `backend/internal/*/domain/**/*.go` | any match (stdlib `errors`, `fmt`, `time`, `context` are fine; `encoding/json` tags on domain types are a smell — flag MAJOR) |
| Go | pattern `/adapters` in `backend/internal/*/domain/**` and `backend/internal/*/app/**` | any match |
| Ktor/Kotlin | pattern `import (io\.ktor\|org\.jetbrains\.exposed\|java\.sql\|javax\.sql\|kotlinx\.serialization\|org\.slf4j)` in `*/domain/**/*.kt`; `@Serializable` anywhere in `domain` | any match |
| Web | pattern `fetch\(` or `axios` in `web/src/features/*/ui/**`; imports of `features/<other>/` internals; `shared/` importing `features/` | any match |
| KMP | `import android\.\|import platform\.` in `mobile/shared/src/commonMain/**` | any match |
| Swift | `import SwiftUI` in domain/use-case targets | any match |

## C. SOLID (Phase 5)

- [ ] Single Responsibility — each type has one reason to change.
- [ ] Open/Closed — extendable without modifying (new provider = new adapter, not a new `if`).
- [ ] Liskov — subtypes/fakes honour the port's contract (including error behaviour).
- [ ] Interface Segregation — no fat interfaces; consumers depend on what they use.
- [ ] Dependency Inversion — depends on ports, not concrete adapters.

## D. SaaS rules (Phase 6)

**Tenancy (DoD gate 7; `SL-TENANT-ISOLATION` judges it at `/story-done`)**
- [ ] Every query in the changed code is tenant-scoped — through a repository that adds the predicate or an explicit `tenant_id` filter; list each query with `path:line` and its scope. RLS (per `tenancy.model`) is defence in depth, **not** a substitute for the app-layer predicate.
- [ ] The tenant comes from the authenticated context (token/session → middleware → use case), never from the request body, path parameter, or a client header.
- [ ] Object-level authorization on every resource access: load → check tenant + ownership/role → act. A cross-tenant resource returns 404 (never reveals existence).
- [ ] Mongo queries filtered by `tenant_id` in the repository, no `$where`/operator injection from user input.
- [ ] Non-DB paths carry the tenant: cache keys (`…:{tenant_id}:…`), queue messages and outbox events, background jobs (tenant context restored), object/file keys (tenant-prefixed, signed URLs scoped), search/export filters.
- [ ] Tenant ID is not a high-cardinality metric label.

**Authorization and abuse**
- [ ] Every new endpoint declares a policy; deny by default; a route with no policy fails.
- [ ] Mass assignment blocked: explicit request DTOs, never bound into domain/DB models.
- [ ] Server authority (`security-baseline.md` § Server authority): no client-sent derived value (price, discount, tax, total, time amount, stock effect, entitlement) is stored or acted on as authoritative; the server recomputes it from its own versioned data; an offline client's result is kept only as a claim and a difference is flagged; a negative test sends a tampered value. A violation is a BLOCKER.
- [ ] Rate limit / quota per tenant+actor+route on new endpoints; body size and pagination limits server-side; timeouts on every handler.
- [ ] Outbound requests to user-supplied URLs only through the allow-listing egress client (SSRF).

**API and errors (RFC 9457 — `api-standards.md`)**
- [ ] Error responses are `application/problem+json` with `type`, `title`, `status`, `code`, `trace_id`; `detail` carries no internals, SQL, stack traces or hostnames.
- [ ] Status codes follow the table (422 validation, 404 for not-found-or-other-tenant, 409/412 conflicts, 429 + `Retry-After`).
- [ ] Contract matches `contracts/` (operation, schema, errors); generated clients regenerated, not hand-edited; list operations cursor-paginated with a server-capped `limit`; creating/charging operations accept `Idempotency-Key`.
- [ ] Money is `amount_minor` + currency, never a float; IDs are opaque; timestamps RFC 3339 UTC.

**External calls and idempotency**
- [ ] Every external call has a timeout, a retry policy (idempotent operations only, backoff + jitter) and a circuit breaker or bulkhead where failure can cascade; never `http.DefaultClient`.
- [ ] Every write a client or webhook can repeat is idempotent (idempotency key or natural key); inbound webhooks verify signature + timestamp first, dedupe by event ID, process asynchronously; side effects after commit go through an outbox.
- [ ] Provider code sits behind a port as an adapter; provider errors mapped to a small domain error set.

**Secrets and data**
- [ ] No secrets in code, logs, URLs, test fixtures or client bundles (`VITE_*` is public). Read from environment / secret store.
- [ ] No passwords, tokens, OTP codes, API keys, card data, national IDs, full bodies, or clear phone/email in logs/spans/metrics.
- [ ] Parameterized queries only; no string-built SQL/Mongo from input; output encoded by the framework; `dangerouslySetInnerHTML` only with a vetted sanitizer.
- [ ] Shared capability (identity, OTP, notifications, storage, billing, licensing, observability) consumed from `saas-core`, not re-implemented in the product.

**Migrations (`.claude/rules/migrations.md`)**
- [ ] One logical change per migration; down for development; expand→migrate→contract for anything a running version depends on; no `ALTER COLUMN TYPE`, `NOT NULL` without default, non-concurrent index, or unvalidated FK on a hot table in one step; `lock_timeout`/`statement_timeout` set; destructive statements flagged for explicit approval.
- [ ] Every tenant-owned table: `tenant_id NOT NULL`, an index leading with `tenant_id`, an RLS policy.
- [ ] `bash .claude/scripts/migration-lint.sh <files>` observations read and each DANGER/WARN/MISSING answered (the skill may run nothing — ask the author for the output, or mark `not checked`).

**Caching (DoD gate 5)**
- [ ] A written cache decision exists for the touched read path (pattern, key schema with tenant ID, TTL with jitter, invalidation on write, stampede protection, cache-down behaviour) or a written "no cache" reason.
- [ ] Cache adapters: decorator around a repository port; key-builder function; every key has a TTL; no `KEYS`/`FLUSH*`/unbounded `SMEMBERS`/`HGETALL`; `MGET`/pipelines for multi-key; cache failure degrades to source, never fails the request.

**Observability (DoD gate 4)**
- [ ] Every new endpoint/consumer/job has a span (low-cardinality name = route template or use-case name), RED metrics and a structured outcome log carrying `trace_id`, `span_id`, `tenant_id` when known; outbound calls propagate `traceparent`.
- [ ] Errors recorded on the span; client-caused 4xx are not span errors; `/livez` and `/readyz` on a new service.
- [ ] No high-cardinality labels; no PII in any signal; failure modes visible on a dashboard or an alert with a runbook.

**Performance (DoD gate 6)**
- [ ] Hot queries name their index; no query in a loop (N+1) — expect a query-count assertion in a test; keyset pagination where the set can grow; bounded pools and worker counts; slow work (email, PDF, export, webhook out) off the request path.
- [ ] Payloads sized to the budget (list ≤ 100 items, response ≤ 200 KB uncompressed); pools and goroutines/coroutines bounded.
- [ ] The surface's budget row in `docs/architecture/perf-budgets.md` is cited; a missing row is `budget not yet set`, not assumed met.

## E. Stack idioms (Phase 8c, delegated to the stack lead and verified)

Source of truth for each point: `.claude/rules/<layer>.md` and `docs/stack-reference/<layer>/` — never memory. A claim about an API that is not in the stack reference is `UNVERIFIED — not in stack reference`.

| Layer | Look for (rule file) |
|---|---|
| Go | `context.Context` first param on I/O, not stored in structs; small consumer-declared interfaces, concrete returns; `%w` wrapping; every goroutine owned/bounded/cancellable (`errgroup.SetLimit`); server timeouts + `MaxBytesReader` + graceful shutdown; no globals; `slog` JSON with `trace_id`; pgx pool sized, `rows.Err()` checked; table tests with `t.Parallel()`, `integration` tag (`backend-go.md`) |
| Ktor/Kotlin | no `GlobalScope`/`runBlocking` in request paths; `CancellationException` never swallowed; blocking I/O on bounded dispatcher; sealed error types + `StatusPages` → RFC 9457; explicit DTOs; Hikari sizing; immutability (`backend-ktor.md`) |
| Web | feature-sliced; no `fetch` in components; typed query keys + `staleTime`; strict TS, no `any`/unexplained `!`; no tokens in storage; logical CSS properties for RTL; no hardcoded strings (AR/EN); route code-splitting; added dependencies justified; no `react-server-dom-*` (`web-react.md`) |
| Android | state hoisting, immutable `UiState` via `StateFlow`, stability, no work on main thread, Keystore for secrets (`android-compose.md`) |
| iOS | `@Observable` on main actor, Swift 6 strict concurrency, Keychain for tokens (`ios-swift.md`) |
| KMP | domain/use cases/ports in `commonMain`, platform code only for UI and platform adapters (`kmp-shared.md`) |
| Contracts | `additionalProperties: false`, bounds on every field, all error statuses as `problem+json`, breaking-change handling (`contracts.md`) |
| Deploy | healthchecks on every service, no secrets in compose files, licence rules for `deploy/self-hosted/` (`deploy.md`) |

## F. The eight DoD gates judgeable from the change (Phase 7 table)

Fill every row; for gates not judgeable from code write `see PE-DOD`
(`.claude/docs/director-gates/pe-code-review.md`). Gate levels from the resolved
`testing.strict.*` / `performance.enforce`.

| # | Gate | Judge from the code and the diff |
|---|---|---|
| 1 | Research first | not judgeable from code — `see PE-DOD` (but note if the diff contradicts the research note's decision) |
| 2 | Clean architecture | Section B result |
| 3 | Tests | the story-type evidence exists at the declared paths; the cases `testing-standards.md` requires per change are present (use case: happy/each domain error/authz denied/tenant mismatch; repository: round trip/not-found/constraint/tenant isolation/pagination; cache: hit/miss/invalidation/TTL/cache-down; provider: success/4xx/5xx/duplicate webhook/bad signature; endpoint: contract + anonymous/wrong role/wrong tenant); deterministic (no real clock, sleeps, unseeded randomness); real dependencies for integration; no skipped/weakened tests. **Whether they pass is not known from reading — report `not run` unless output was supplied** |
| 4 | Observability | Section D → Observability |
| 5 | Caching | Section D → Caching |
| 6 | Performance | Section D → Performance |
| 7 | Security | Section D → Tenancy, Authorization, Secrets; ASVS/MASVS IDs cited in the story/threat model; negative tests present |
| 8 | Decision record | an architectural decision visible in the diff (new store, broker, framework, engine-specific cache feature, tenancy deviation, new context) has an ADR — or a decision-log line at `workflow: minimal` |
