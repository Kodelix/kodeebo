# ADR-0015: Backend code conventions (Ktor) — JDK, wiring, errors, gateway, runtime, plugins, types and size limits

## Status

Proposed

> **Who may move this to `Accepted`: the user, or `cto` on the user's explicit
> confirmation. No other agent, and no skill on its own.**
> Why this is stated here: stories referencing a `Proposed` ADR are set `Blocked`,
> and epics require `Accepted`, so the field needs a named owner. `cto` is the
> role `coordination-rules.md` escalates technical conflicts to, and an ADR is
> that decision made durable.
>
> This does **not** relax the rule that `Status: Accepted` is never set without
> explicit user confirmation — it narrows *which agent* may set it once that
> confirmation exists. An agent that believes an ADR is ready says so and
> escalates; it does not edit this field.

## Date

2026-10-24

## Last Verified

2026-10-24

## Decision Makers

- Kamel Mohamed, founder (user). Decided on 2026-10-23 and 2026-10-24 from `docs/research/backend-code-conventions.md` parts 1-3 (each part's section 5 holds the dated decision lines): Temurin 25; Ktor DI under six conditions with manual wiring and Koin as fallbacks; the hybrid error model; gateway B1 with the object-level `Authorizer` mandatory; the part-3 runtime and plugin set and its notes; the size limits; enums with a database CHECK; value-class ids; the `:core:foundation` building-blocks module and its closed list; snake_case JSON; 503 for our own timeouts and refusals; no `RequestValidation` plugin.
- Drafted by `/architecture-decision`; `researcher` (parts 1-3, spikes S10-S13, S20, S30, S30b) supplied the evidence.
- Founder at the write approval (2026-10-24): write this ADR with its dated amendments and notes; the statement-counting rule is recorded as a dated note in `docs/architecture/perf-budgets.md`; the proxy access-log retention default is 14 days (ADR-0005 amendment); the CGNAT residual risk of FP-IP-ONLY-BLOCK-R2 is accepted by name (review at the KMS move, the first multi-counter venue, or 2027-04-18 at the latest).
- Stack validation: `ktor-lead` — BLOCKING (2026-10-24), six issues revised in this draft; the founder confirmed on 2026-10-24 the changes that touch recorded decisions: no route-layer DI exception and pools/JobRunner outside DI; `exceptionsWithDebugInfo = false` as the one sanctioned experimental opt-in; the standard library's `kotlin.time.Clock` replaces our `Clock` if V19 confirms it is stable.
- CTO-ADR: `cto` — CONCERNS (2026-10-24), revised; narrow re-check 2026-10-24 resolved all of them; its four wording items applied. Run on the founder's instruction ("same gates as ADR-0014"); the `lean` review mode would otherwise skip it.

## Summary

Kodeebo's Ktor backend has no written code conventions yet, so the first Kotlin story would pick its JDK, wiring, error contract, request gateway, coroutine and timeout rules, plugin set and type rules on its own. This ADR fixes them for every backend module: Temurin 25; Ktor DI confined to `:app` (routes receive their module API as a parameter; pools are never DI-managed); a hybrid error model (values where the caller branches, a stack-trace-free exception tree mapped once to RFC 9457 where the request ends); the B1 gateway with `Authorizer.require` mandatory in every use case; bounded JDBC dispatchers with PostgreSQL timeouts first and semaphore admission; a fixed plugin set and install order; value-class ids, enums with a database CHECK, snake_case JSON; a `:core:foundation` module with a closed content list; and blocking size limits (function at most 40 lines, file at most 300).

## Stack Compatibility

| Field | Value |
|-------|-------|
| **Stack layer(s)** | Ktor backend |
| **Domain** | API / Core / Observability / Security |
| **Layer** | Foundation |
| **Knowledge Risk** | HIGH — Ktor 3.6.0 (2026-09-16), `ktor-server-di` 3.6.0 (introduced 3.2.0), Kotlin 2.4.21, kotlinx-coroutines 1.11.0, kotlinx.serialization 1.11.0, Konsist 0.18.1 and Temurin 25 are past the model's reliable knowledge; every API named here was verified against the stack reference or executed in the research spikes |
| **References Consulted** | `docs/stack-reference/ktor/VERSION.md`, `breaking-changes.md`, `deprecated-apis.md`, `best-practices.md`; `docs/stack-reference/kotlin/VERSION.md`, `deprecated-apis.md`, `best-practices.md`; `docs/stack-reference/pins.yaml`; `docs/research/backend-code-conventions.md` (merged note, Status Draft; parts 1-3 final; part 7 pending, which belongs to ADR-0016); `docs/registry/architecture.yaml`; `.claude/docs/api-standards.md` |
| **Pinned versions relied on** | Kotlin `2.4.21`; kotlinx-coroutines `1.11.0`; Ktor `3.6.0` (all server plugins and `ktor-server-di` at the same version); Exposed `1.5.1`; HikariCP `7.1.0`; OpenTelemetry Java agent `2.32.0`; Gradle `9.8.2` and Konsist `0.18.1` (ADR-0011; Gradle 9.8.2 is above KGP 2.4.21's documented range, see ADR-0011's caveat and S60). **Not yet in `pins.yaml`** (pin changes in Migration Plan): JDK toolchain `25` (pins say `"21"`), kotlinx.serialization `1.11.0`, pgjdbc `42.7.14` (ADR-0012), Gradle `9.8.2` (pins say `"9.7"`) |
| **Post-Cutoff APIs Used** | Ktor DI `dependencies { provide<T> { } }`, `resolve()`, `by dependencies` (F102, F129); Ktor `CSRF` route-scoped plugin with `allowOrigin`, `originMatchesHost`, `checkHeader`, `onFailure` (F313, F317); `RateLimit` `register`/`rateLimit`/`requestKey` (F302); StatusPages `exception<T>` nearest-type selection and `status(...)` (F212, F222, F226); kotlinx-coroutines `limitedParallelism(n, name)` (F301) and `kotlinx.coroutines.sync.Semaphore` (F329, F331); Exposed `suspendTransaction` (F225); kotlinx.serialization `@SerialName` (stable). Sanctioned experimental opt-in: `exceptionsWithDebugInfo = false` only (Decision 8). Deliberately **not** used: `JsonNamingStrategy` (still `@ExperimentalSerializationApi` at 1.11.0, read from the jar's class annotations 2026-10-24), the experimental typed authentication DSL, Ktor `RequestValidation`, `KtorServerTelemetry` |
| **Verification Required** | **V1** Konsist 0.18.1 can count function and file lines (else the build-logic check of Decision 10 is the enforcement path) — before acceptance. **V2** Ktor DI: a full-graph boot test at the real module count (S13 measured 5 definitions on JDK 21 only) on the JDK 25 image. **V3** a `testApplication` test asserting the install order of Decision 6 (CSRF before the session lookup; forwarded headers before the per-IP limiter; the deadline interceptor before `routing`). **V4** the forwarded-header plugin at 3.6.0: artifact, API and how it is restricted to the nginx hop (F325b: not sourced in part 3). **V5** the request-body size limit mechanism in Ktor 3.6.0 (F325a). **V6** `RateLimit` key eviction and memory (F325e). **V7** `Semaphore` FIFO and prompt-cancellation guarantees in the 1.11.0 docs (F335a; observed only). **V8** SQLSTATEs `25P04`, `57014`, and the expected `55P03`, `40P01`, `40001`, against the PostgreSQL 18 error-code appendix (F320; the last three are expected values, not yet checked). **V9** the shared `Json`'s `explicitNulls` and `encodeDefaults` behaviour at 1.11.0 (F325f), fixed by a contract test. **V10** pool sizes, dispatcher totals, admission `W` and wait budget on the 2-vCPU host (S18). **V11** nginx's rate-limit refusal answers 429 with `Retry-After` (not its default status) and its proxy timeout answers 504, checked in the deploy story. **V12** the rate-limit defaults of Decision 6a at the 10x load test. **V13** when Ktor DI closes `AutoCloseable` instances on stop and whether that can be switched off (Decision 2 condition 6). **V14** whether nested `rateLimit` scopes both apply, whether RateLimit answers or throws on refusal, and `modifyResponse` attribution. **V15** a throw from the CSRF plugin's `onFailure` reaches StatusPages. **V16** Konsist 0.18.1 can read `@SerialName` arguments (else a build-logic check). **V17** the experimental status of `exceptionsWithDebugInfo` at 1.11.0. **V18** the security headers appear on StatusPages, 429, CSRF and the engine's own error responses (F224). **V19** closed: `kotlin.time.Clock` is stable since Kotlin 2.3.0 (stack reference). **V20** `transaction_timeout` and `lock_timeout` set through `set_config(..., true)` in the combined scope statement take effect for the transaction. V4 also proves the plugin takes nginx's last hop, so a spoofed `X-Forwarded-For` prefix has no effect |

> Knowledge Risk is HIGH: re-validate this ADR whenever the Kotlin, Ktor, kotlinx, Exposed, HikariCP, Konsist or JDK pin changes, and when Ktor labels `ktor-server-di` stable, experimental or deprecated (Decision 2 revisit trigger).

Critical ADR: yes — the error contract, the gateway order and the API naming are the API style every endpoint and generated client follows.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (scope helper, `ScopedTransaction`), ADR-0003 (session lookup, branch scope), ADR-0006 (backend track, P-PLUMB, agent-only telemetry, Q8), ADR-0007 (cookie sessions, CSRF requirement, sign-in throttles), ADR-0008 (`Authorizer`), ADR-0009 (nginx in front, privileged steps) — Accepted. **ADR-0010** (Layer 1 module list; amended here with a sixteenth module) and **ADR-0011** (Gradle modules, `:arch-tests`, Konsist) — Proposed: this ADR cannot be Accepted before them. **ADR-0012, ADR-0013, ADR-0014** (Proposed): this ADR relies on ADR-0012's job outcomes, pools and stop sequence, ADR-0013's sealed notification outcomes and ADR-0014's lock order and P-TRUST flags; they are accepted with or before this ADR |
| **Enables** | ADR-0016 (data access, performance and reporting); every backend story; the dashboard real-time ADR (SSE versus WebSockets is left to it) |
| **Blocks** | The first Kotlin backend story (no epic or story exists yet) |
| **Ordering Note** | Written together with (on approval): dated amendments to ADR-0010 (sixteenth module) and ADR-0002 (scope helper), dated notes to ADR-0008, ADR-0007, ADR-0009 and ADR-0005 (Migration Plan step 1). Before acceptance: V1, and the gateway section in `staff-auth.md` by `security-lead`. After acceptance, the guide updates the studio rule `.claude/rules/backend-ktor.md` line 14 and `.claude/docs/clean-architecture.md` line 62 (error model) and the studio `pins.yaml`; the user applies the product pin changes listed under Migration Plan before the Gradle wrapper exists |

## Context

### Problem Statement

ADR-0006 chose the Ktor track and left the code conventions to a follow-up ADR, and ADR-0006 Q8 left the JDK open (21 or 25). Without one written set of conventions, each early story would choose its own wiring, error shape, check order, dispatcher and timeout handling and plugin configuration; the costs are an inconsistent API contract for the generated clients, security checks that differ by route, request paths that hold threads or connections past every budget, and modules that grow without bound. The founder asked for these rules before the first Kotlin story.

### Current State

No backend code exists. The research note `docs/research/backend-code-conventions.md` (parts 1-3 final, 2026-10-23) ran spikes S10-S13, S20, S30 and S30b on the pinned stack, including on Temurin 25 with `--cpus 2`. Accepted ADRs already fix the scope helper (ADR-0002), session lookup (ADR-0003), staff auth and CSRF requirement (ADR-0007), the `Authorizer` (ADR-0008), agent-only telemetry and P-PLUMB (ADR-0006) and nginx in front (ADR-0009). ADR-0010 and ADR-0011 (Proposed) fix the module layers and Konsist.

### Constraints

- Technical: the pins in Stack Compatibility; no code generation (kapt banned, KSP only by ADR, ADR-0011); the OpenTelemetry Java agent is the only SDK (registry `FP-SECOND-OTEL-SDK-R2`, `FP-OTEL-LIBRARY-INSTRUMENTATION-WITH-AGENT`); JDBC never on `Dispatchers.Default` (`FP-JDBC-ON-DEFAULT-DISPATCHER`); scope never from the request (`FP-SCOPE-FROM-REQUEST`, P-TRUST); no session-level advisory locks (`FP-SESSION-ADVISORY-LOCK`); a Layer 1 module never imports a kernel and a sealed hierarchy cannot span Gradle modules (ADR-0011, part-2 F201).
- Operational: hosted only (`distribution: hosted`); one backend instance on an 8 GB / 2 vCPU VPS (ADR-0006) behind nginx (ADR-0009); one developer.
- Security: sign-in and recovery: no address is blocked, banned or locked on outcomes; request-rate caps only (`FP-IP-ONLY-BLOCK-R2`, amending ADR-0007).
- Budgets: no counter action over 3 s worst case; read API at most 150 ms server time and 5 statements (`docs/architecture/perf-budgets.md`).

### Requirements

- One RFC 9457 error mapping with stable, client-translatable codes; cancellation never swallowed.
- Every route authenticates, scopes and authorizes in a fixed order; object-level authorization in every use case.
- No request path holds a thread or connection past its deadline; waiting for a database slot is bounded.
- The rules are enforced mechanically where they can be (Konsist, compiler exhaustiveness, contract tests), not by review habit.

Research note: `docs/research/backend-code-conventions.md` (Status Draft; parts 1-3 final with founder decisions; part 7 pending, which feeds ADR-0016, not this ADR).

## Decision

### 1. JDK: Eclipse Temurin 25

- Toolchain `kotlin { jvmToolchain(25) }`; runtime image the Temurin 25 JRE, pinned by digest. S12 built the spike with Gradle 9.8.2 and Kotlin 2.4.21 on Temurin 25.0.4.1 (class-file major 69) and ran the full stack (Ktor 3.6.0, HikariCP 7.1.0, pgjdbc 42.7.14, Exposed 1.5.1, Bouncy Castle 1.86, OTel agent 2.32.0) on the 25 JRE (F121-F124, F134-F137). Temurin 25 has free updates to at least Sep 2031 (F103).
- The image's Java options carry `--enable-native-access=ALL-UNNAMED` to silence Netty's restricted-method warning (F124, F136; the flag name comes from the JVM's own warning, not from the JDK documentation), and an explicit heap limit (F113; sized by S18).
- The image is rebuilt on each quarterly JDK CPU (Jan/Apr/Jul/Oct).
- **Closes ADR-0006 Q8**: JDK 25. Ktor's own documented minimum JDK remains not stated by the vendor; the observed class-file floor of the pinned libraries is Java 11 or lower (F117).

### 2. Dependency injection: Ktor DI in `:app` only, under six conditions

`ktor-server-di` at the Ktor version (3.6.0). It showed no start-up or memory difference from manual wiring or Koin at the measured size (F130, F131); it is chosen on dependency and fit.

1. Only `:app` uses it (`dependencies { provide / resolve }`, `by dependencies`). Routes in each module's `adapters/http` take their module API as a parameter (`fun Route.ordersRoutes(api: OrdersApi)`); `:app` resolves the API and passes it in. A blocking Konsist rule fails any import of `io.ktor.server.plugins.di` outside `:app`, with no exception (stack-lead review 2026-10-24: a route-layer exception would spread DI into every module and break conditions 2 and 5).
2. Each module keeps one small wiring function taking an explicit deps class (ports only) and returning its module API; `:app` registers those, so `resolve()` never spreads into modules and the plugin's reflection over constructor parameters (F114) stays at the module-API boundary.
3. No registration from configuration (`ktor.application.dependencies` or any classpath string); banned and tested (abuse case: config-driven class loading, part 1 section 6).
4. A CI test boots the full dependency graph, so a missing provider fails the PR, not production.
5. Revisit trigger: if Ktor marks the plugin experimental or deprecated, fall back to manual constructor wiring (changes `:app` and nothing else, because of condition 2); Koin 4.2.2 is the documented second fallback. Open question to the Ktor maintainers on the plugin's stability status (unlabelled, F101, F114), owner `ktor-lead`.
6. HikariCP pools, `DataSource`s and the JobRunner are **not registered in Ktor DI**: Ktor DI closes `AutoCloseable` instances on stop by default (F114), while ADR-0012 closes pools only in `ApplicationStopped`, never in `ApplicationStopping`. `:app` owns their lifecycle explicitly in the stop sequence, unless V13 shows DI's close timing can be set to match.

`ScopedTransaction` is never registered in the container (ADR-0002): it is created by `withScope` and passed as a parameter (F132, F133).

### 3. Error model: hybrid

- **Decision rule:** a value (sealed interface) when the caller branches on the outcome — external port results, job outcomes (ADR-0012 `JobOutcome`), notification outcomes including the ambiguous class (ADR-0013), authorization `Allowed`/`Denied`, multi-variant success. An exception from the founder's tree when the request must end and roll back — not found, forbidden, conflict, validation, plan limit, tenant refused, timeout. A throw inside `suspendTransaction` rolls back; a returned failure commits (F225).
- **Types** (in `:core:foundation`, Decision 10): a closed `ErrorKind` enum shared by all modules; a non-sealed `ErrorCode` interface that each context implements with its own enum (a sealed hierarchy cannot span modules, F201; an enum can implement an interface, F203); an abstract `AppException` carrying code, kind, typed field errors and an optional log-only cause (never sent to a client); expected-failure subclasses disable the writable stack trace (F229), while `Internal` keeps its trace so a 5xx bug is diagnosable.
- **Mapping:** one StatusPages `exception<AppException>` handler (the nearest registered type wins in either install order, F222), framework entries for `BadRequestException` (400), `CannotTransformContentToTypeException` (415, F228), our timeout and admission errors (503), `status(...)` rewrites to problem+json for responses that plugins answer without throwing — `Unauthorized` keeping `WWW-Authenticate` (F226), `TooManyRequests` keeping `Retry-After` (the code comes from a call attribute set by each limiter's `modifyResponse`, Decision 6a), `NotFound` and `MethodNotAllowed` for unmatched routes, `PayloadTooLarge` for the body limit — and a last-resort `Throwable` handler that rethrows `CancellationException` first.
- **`ErrorKind` → HTTP status**, one exhaustive `when` without `else` in the HTTP adapter, so adding a kind fails compilation until mapped (F231):

| `ErrorKind` | Status | Example codes |
|---|---|---|
| `Malformed` | 400 | `malformed_body` |
| `Unauthenticated` | 401 | `unauthenticated` |
| `Forbidden` | 403 | `forbidden`, `csrf_rejected` (thrown from the CSRF plugin's `onFailure`, V15) |
| `TenantRefused` | 403 | `tenant_suspended`, `licence_seat_moved` |
| `NotFound` | 404 (missing, other tenant and other branch alike) | `not_found` |
| `MethodNotAllowed` | 405 | `method_not_allowed` |
| `Conflict` | 409 | context codes |
| `PreconditionFailed` | 412 | `etag_mismatch` |
| `PayloadTooLarge` | 413 | `payload_too_large` |
| `UnsupportedMediaType` | 415 | `unsupported_media_type` |
| `Invalid` | 422 (with `errors[{field, code}]`) | context codes, `plan_limit_reached` |
| `RateLimited` | 429 + `Retry-After` | `rate_limited_ip`, `rate_limited`, `quota_exceeded` (Decision 6a) |
| `Timeout` | **503 + `Retry-After`** | `request_timeout` |
| `Overloaded` | **503 + `Retry-After`** | `overloaded` |
| `Transient` | **503 + `Retry-After`** | `transaction_retry` (deadlock, serialization failure) |
| `Internal` | 500 | `internal_error` |

- **503 for both our own timeouts and admission refusals** (founder 2026-10-24), so a **504 always means nginx timed out waiting for the backend**; the runbook and dashboards keep that distinction.
- **Problem body** per `api-standards.md` and RFC 9457 (F207): `type`, `title`, `status`, `detail`, `instance`, `code`, `trace_id`, `errors`. Codes are `snake_case`, unique across contexts (test), append-only (golden-file test), never renamed; `type` is derived from the code by one pure function so the two cannot drift. No stack trace, SQL, query or cause message ever reaches a client (ASVS 16.5.1, F213).
- **Catch discipline:** three catch-all sites only — the StatusPages `Throwable` handler, the job adapter, outbox bookkeeping — each tests for `CancellationException` first and rethrows it. Everywhere else catches a specific type. No `runCatching` around suspend calls (F208). Enforced by Konsist text rules.
- **This differs from the studio rule** (`.claude/rules/backend-ktor.md` line 14; `.claude/docs/clean-architecture.md` line 62: sealed result types at the domain boundary, exceptions only for the truly exceptional). It keeps that rule where the caller branches and departs from it for request-ending failures. Two more departures from `backend-ktor.md`: line 15 (`ignoreUnknownKeys` for inbound; this ADR rejects unknown keys, F227) and line 19 (CallLogging, OpenTelemetry instrumentation and a CORS allowlist; this ADR uses its own request-log plugin, agent-only telemetry, and no CORS on the one-origin condition). The guide updates the studio rules after acceptance.

### 4. Request gateway: B1, with the object-level `Authorizer` mandatory

| # | Step | Layer | Failure |
|---|------|-------|---------|
| 0 | Plugins (Decision 6): request log, forwarded headers, security headers, StatusPages, deadline, per-IP rate limit, body limit, content negotiation | adapters/http (`:app`) | 413, 429, 503 |
| 1 | Authentication: opaque session token or device credential, one lookup (ADR-0003) | adapters/http provider over an `app` port | 401 `unauthenticated` |
| 2 | Tenant status from the same lookup row **selects the allowed routes**, as step 3 does: for a suspended or closing tenant, device **uploads of sales already made always pass** (with a `tenant_suspended` notice in the reply) and are never refused (ADR-0001 Decision 4: money facts are never lost; research F218); the dashboard is limited to the owner's export, payment and closure routes; enrolment refuses | adapters/http over a pure `app` function | 403 `tenant_*` only on routes the status does not allow, never on a backlog upload |
| 3 | Device licence state (`active`, `retiring`, `suspended`, `seat_moved`) selects allowed device routes (F218) | adapters/http, device routes only | 403 `licence_*` |
| 4 | Scope built from the verified credential only (P-TRUST, `FP-SCOPE-FROM-REQUEST`) | adapters/http | — |
| 5 | Coarse permission from route metadata, deny by default — an **extra early gate** before the body is read | adapters/http | 403 `forbidden` |
| 6 | DTO decode and shape validation in the `toCommand()` mapper (Decision 7) | adapters/http | 400, 415, 422 |
| 7 | Transaction opens: `withScope` sets tenant and branch once (ADR-0002) | app (use case) | — |
| 8 | Target lookup inside scope; missing, other tenant and other branch are the same result | adapters/persistence behind an `app` port | 404 `not_found` |
| 9 | **Object-level `Authorizer.require(principal, key, target, amount)`** and plan entitlement — **mandatory in every use case** | app | 403, 422 |
| 10 | Domain rules; P-TRUST differences flagged, never a rejection of a money fact (ADR-0014) | domain | 409, 422 |
| 11 | Side effects in the same transaction: persist, `ActivityTrail.appendServer`, outbox (ADR-0008, ADR-0012); provider calls only through the outbox | app via ports | rollback on throw |
| 12 | Explicit `toResponse()` mapping, no reflection or generated mappers | adapters/http | — |
| 13 | StatusPages maps whatever was thrown (Decision 3) | adapters/http | per kind |

**ADR-0008 consistency:** ADR-0008 says "every route calls `Authorizer.require`". Under B1 every route reaches `Authorizer.require` through its use case (step 9), which is never optional; step 5 is an additional coarse check, not a replacement. A dated clarifying note is added to ADR-0008 with this ADR (on approval).

### 5. Coroutines, blocking, timeouts, locks and admission

1. Blocking JDBC runs only inside `withContext(dbView)`, one `Dispatchers.IO.limitedParallelism(n, "db-<role>")` per HikariCP pool with `n` = that pool's size (F306, F321); never `Dispatchers.Default`; no `runBlocking`, `Thread.sleep`, `synchronized` or blocking I/O on a request path. CPU-heavy work uses `Dispatchers.Default.limitedParallelism(k)`.
2. PostgreSQL limits first: the scope helper sets `transaction_timeout` and `lock_timeout` locally in every transaction, **in the same single scope statement** that sets the tenant and branch (`select set_config('app.tenant_id', ?, true), set_config('app.branch_ids', ?, true), set_config('transaction_timeout', ?, true), set_config('lock_timeout', ?, true)`; two `set_config` calls in one statement count as one, part-4 F417; the timeout settings through `set_config` are verified by V20) (F304, F309); HikariCP `connectionTimeout` comes from config, never the 30 s default (F303). Every request-path `Database` (`app_rt`, `device_rt`, and the others ADR-0012 does not already cover) is created with `DatabaseConfig { defaultMaxAttempts = 1 }`, with a regression test: with Exposed's default of 3 a failed block re-runs, and a 500 ms `transaction_timeout` became 1.6 s (ADR-0012, jobs-and-outbox F326); the statement guard of ADR-0016 also assumes one attempt. Order, all from config: `connectionTimeout` < `lock_timeout` < `transaction_timeout` < request deadline < budget ceiling. `withTimeout` cannot free a thread blocked in JDBC (F319); only the database ends a running statement (F320).
3. A deadline interceptor before `routing` wraps each call in one global ceiling from config (the route is not matched yet, so it cannot know the route class; F318 C3 used one fixed value); each route-class subtree applies its own budget with a subtree interceptor or `deadline()` in the handler. Both convert our own timeout into `AppException(Timeout)` before StatusPages (F318); use cases call `deadline()`, never a raw `withTimeout`. A client disconnect does not cancel a handler on Netty (F223), so the deadline is the bound on abandoned work. SQLSTATEs `25P04` (transaction timeout) and `57014` (statement cancelled) map to `Timeout` (F320); the lock-timeout SQLSTATE (expected `55P03`) maps to `Timeout`; deadlock and serialization failures (expected `40P01`, `40001`) map to `Transient` (the request path runs once, so the client retries after `Retry-After`). The expected codes are confirmed against the PostgreSQL 18 appendix by V8; any other `SQLException` is `Internal`.
4. Admission per pool (S30b, F331): a `Semaphore(n)` in front of each `dbView`; `tryAcquire()` first; when it fails, a waiter counter capped at `W` rejects the rest at once with `Overloaded`; the `W` waiters call `withTimeout(waitBudget) { acquire() }` and fail with `Timeout`; the permit is released in `finally`. The gate wraps each request-path transaction inside the scope helper (`withScope` acquires before it opens the transaction and releases after commit or rollback). It is **never nested**: a request may run two transactions one after the other (the principal read, then the use case), each with its own acquire and release, but a gated transaction never opens another gated one, because a nested entry would hold permits and time out. **The gate covers the request-path pools only** (`app_rt`, `device_rt`, and `support_rt` under its own grant rules); the job and export transactions of ADR-0012 and EXP-2 (`job_rt`, `platform_rt`, `exportSession`) keep their own timeouts and are never refused as `Overloaded`. This extends the ADR-0002 scope helper: a dated amendment to ADR-0002 and the registry entry IC-SCOPE-HELPER-R6 (new failure results `Overloaded` and `Timeout` for request-path scopes; `transaction_timeout` and `lock_timeout` set in the same one-time scope statement) are written with this ADR. The budget bounds the wait only; the running statement stays bounded by `transaction_timeout`. Not allowed as the bound: `withTimeout` around `withContext(view)` or an `async(view)` child (F327), Hikari `connectionTimeout` alone (F332). `W`, the wait budget and `n` come from S18 (V10).
5. Cancellation: `CancellationException` is never swallowed; cleanup after cancellation runs in `withContext(NonCancellable)`; `deadline()` re-checks `ensureActive()` (F318 C9).
6. Locks: row locks and two-key transaction-level `pg_advisory_xact_lock` only, in the ADR-0014 order, always with `lock_timeout`; never a session-level lock (F311). An in-JVM `Mutex`/`Semaphore` guards only in-memory state, is never held across I/O and never replaces a database lock.

### 6. Plugins and install order (in `:app`'s `Application.module()`)

Dependencies are registered with Ktor DI from each module's wiring function (Decision 2) before the plugins below.

| # | Install | Why here |
|---|---------|----------|
| 0 | OpenTelemetry Java agent (JVM flag) | server and JDBC spans; no `KtorServerTelemetry`, no second SDK (P-PLUMB) |
| 1 | **Request-log plugin** (our own; P-PLUMB's one thin plugin in `:core:observability`, ADR-0010): one structured access event per call with route template, method, status, duration, principal kind and `trace_id`; no query string, no header values | first, so refusals from later plugins are logged |
| 2 | **Forwarded headers** (`XForwardedHeaders` or `ForwardedHeaders`) trusting **only the nginx hop** (V4), so the per-IP limiter gets the real client address and a spoofed header cannot bypass it (ASVS 4.1.3, F315). The address is used in memory by the limiters only; **the request log never records it** (ADR-0007's security events keep addresses under their own rules) | before anything reads the client address |
| 3 | **Security-header plugin** (our own): CSP `default-src 'none'` and `frame-ancestors 'none'` on API responses, `X-Content-Type-Options: nosniff`, `Referrer-Policy`; removes or blanks the `Server` header. HSTS is set by nginx (ASVS 3.4.1-3.4.6, F314) | every response, including errors and 429 |
| 4 | `StatusPages` (Decision 3) | outermost catch; hooks are phase-based (F212) |
| 5 | `Compression` with `minimumSize`, event streams excluded, the BREACH `condition`, and sign-in and session routes excluded (F324) | before bodies are produced |
| 6 | Deadline interceptor (Decision 5 rule 3): one global ceiling from config | bounds all later work; the route class is not known yet here |
| 7 | Per-IP `rateLimit` scope (layer 2 of Decision 6a), wrapping every subtree **except the sign-in and recovery routes**, which keep ADR-0007's own controls in `:core:ratelimit` (`FP-IP-ONLY-BLOCK`) | before authentication |
| 8 | Request-body size limit (mechanism V5) beside nginx's limit | before decoding |
| 9 | `ContentNegotiation` with the one shared `Json` (Decision 8) | strict unknown keys (F227) |
| 10 | `Authentication` with the opaque-token provider only; no `Sessions` plugin (F310); the experimental typed auth DSL is not used | gateway steps 1-5 |
| 11 | In `routing`: cookie-session subtree = `CSRF` then `authenticate` then per-principal `rateLimit`; device subtree = `authenticate` then `rateLimit` | CSRF before the session lookup, so a forged request costs no query |

- **CSRF** (ADR-0007): Ktor's `CSRF` plugin on cookie-session routes only, with `allowOrigin(<the dashboard origin>)` only (not `originMatchesHost()`, which reads the raw `Host` header, F317) plus `checkHeader(<custom header>)`, and an `onFailure` that throws `AppException(Forbidden, csrf_rejected)` so the refusal goes through StatusPages (V15; the plugin's default status is unconfirmed, F317). A test proves the plugin refuses when unconfigured would have allowed localhost, and a route-table test proves no state change uses GET (F317, ASVS 3.5.1, 3.5.3).
- **No CORS plugin**, on the condition that the dashboard and the API are served from one origin (for example the API under `/api` on the dashboard host) — a constraint for the domain-layout decision (Q-domains, owner `cto`). A cross-origin client, if ever needed, gets Ktor `CORS` with an exact allowlist by an amendment to this ADR.
- **Not installed**: `CallId` (the OpenTelemetry `trace_id` is the request id; a client-supplied id is never trusted), Task Scheduling (ADR-0012's JobRunner is the one scheduler, P-ONCE), Static Content (nginx serves the SPA), `RequestValidation` (Decision 7), `KtorServerTelemetry`, `Sessions`.
- **SSE versus WebSockets** stays with the dashboard real-time ADR.
- **nginx's own access log** (it records the client address by default): the address is dropped or truncated (IPv4 to the /24, i.e. the last octet removed; IPv6 to the /48), with a short retention row under ADR-0005 (new category "proxy access log, truncated address"; default proposed with the write approval). Recorded here and as a note for ADR-0009's nginx configuration.

### 6a. Rate limiting, four layers (founder 2026-10-24)

| Layer | Where | Key | Scope | Refusal (status, stable code) |
|---|---|---|---|---|
| 1 | nginx (ADR-0009's proxy) | the connection's **peer address** (never a forwarded header; a CDN in front would need an amendment) | a **wide** per-IP request-rate cap on **every location, including sign-in and recovery** (amended stance FP-IP-ONLY-BLOCK-R2), with sign-in and recovery in **their own nginx zone** so a venue's counter sync traffic cannot use up the owner's sign-in budget | 429 + `Retry-After`, code `rate_limited_edge` in a static problem body; nginx's refusal status is set to 429, never its default 503, so a 503 always comes from the backend (V11) |
| 2 | Ktor `RateLimit`, before authentication: a **named `rateLimit` scope around every route subtree except sign-in and recovery** (not the `global` limiter, which has no sourced way to exclude routes) | client address from the trusted forwarded header (row 2) | **all routes except sign-in and recovery**; set wide enough for shared addresses — a whole venue behind one router, mobile-carrier CGNAT | 429 + `Retry-After`, `rate_limited_ip` |
| 3 | Ktor `rateLimit`, after authentication (Decision 6 row 11) | the principal: **per staff login** on the dashboard, **per device** on the counter's sync endpoints | every authenticated route; **the precise limit** | 429 + `Retry-After`, `rate_limited` |
| 4 | per plan and per tenant quotas | tenant and plan | product quotas | 429 + `Retry-After`, `quota_exceeded` (or 422 `plan_limit_reached` where it is a plan entitlement, not a rate); defined by the pending **Limits ADR** |

- **Sign-in and recovery keep ADR-0007's own controls** (in `:core:ratelimit`): a growing delay per identifier and per address, the 100-failure ceiling, the separate known-device count, and the recovery send limits. Layer 2 never applies to these routes.
- **Amended stance FP-IP-ONLY-BLOCK-R2** (worded by `security-lead`, founder 2026-10-24; replaces FP-IP-ONLY-BLOCK on acceptance; dated note in ADR-0007): no address is blocked, banned or locked because of failed attempts or any other outcome, and no address-keyed state outlives a short rate window. The layer-1 cap is allowed on sign-in and recovery because it counts **requests, not failures**, is sized far above a whole venue behind one router or a carrier CGNAT address, refuses only the excess within its window with 429 + `Retry-After`, never locks out, and feeds neither the 100-failure ceiling nor the M22 notices. **Conditions:** the sign-in and recovery cap is at least a stated multiple of the largest venue's shift-change peak, with a burst allowance; `security-lead` proposes it and the founder sets it in the nginx configuration, which only the founder edits (ADR-0009); no fail2ban-style tool may read nginx 429s, 401s or logs to ban an address; tests `venue peak sign-ins from one address all reach the backend`, `excess gets 429 with Retry-After and the next request after the window succeeds`, `edge-refused requests change no login_failure_state and send no notice`, `spoofed X-Forwarded-For does not change the key`; metric `rate_limited_total{limiter="edge",location}` with an alert on any edge 429 on sign-in or recovery. The nginx directives are not in the research note, so V11 proves the 429 and `Retry-After` behaviour.
- **Residual risk accepted by name** (founder, at the write approval): while a flood from a shared CGNAT address lasts, a co-located owner can be kept out of sign-in and out of M22(d)'s known-device lane (a variant of staff-auth T1.18, recorded beside R22); review at the KMS move, the first multi-counter venue, or 2027-04-18 at the latest. `security-lead` updates M2 and T1.18 in `staff-auth.md`. Mapping as printed in the staff-auth threat model: V6.1.1, V6.3.1, V2.4.1, API4:2023.
- **Every number is typed configuration with a default; nothing is hardcoded.** `security-lead` proposes the defaults with `performance-engineer`, sized so that one venue behind one address can drain a 7-day offline backlog (about 35,000 commands) within 15 minutes of online time (`perf-budgets.md` Sync table) without touching layers 1-3; they are confirmed by the load test at 10x the launch assumption (100 tenants, one counter each, about 50 bills per hour each, so about 14 bills per second sustained with peaks above it; VPS 8 GB / 2 vCPU).
- **Layers 2 and 3 are in-process today** (one backend instance; state lost on restart, as ADR-0007 accepts). They move to a shared store when a second backend instance is added — the Tier 2 revisit trigger of ADR-0016 — by an amendment to this ADR.
- RateLimit answers 429 itself rather than throwing (V14), so each limiter's `modifyResponse` sets a call attribute naming its code and the `status(TooManyRequests)` rewrite builds the problem body from it, keeping `Retry-After`. A per-principal `requestKey` never falls back to the client address when the principal is missing (principals are nullable in 3.6.0); it refuses as `Unauthenticated` instead.
- All refusals map through `ErrorKind.RateLimited` (Decision 3), carry `trace_id`, are counted in `rate_limited_total{limiter}` (limiter name only, never the key) and never log the key value.

### 7. Request validation: no plugin; validation in the mappers

Ktor `RequestValidation` returns free-text reasons only (F209). Each DTO's `toCommand()` mapper validates shape (types, lengths, enum membership, required fields) and throws `AppException(Invalid)` with field codes (422 `errors[{field, code}]`); malformed JSON stays 400 through `BadRequestException` (F227), a wrong content type 415 (F228). Meaning-level checks stay in the domain (ASVS 2.2.1, 2.2.2, F214).

### 8. JSON and serialization

- **Field names are `snake_case`** on every API (`api-standards.md`). `JsonNamingStrategy.SnakeCase` is `@ExperimentalSerializationApi` at kotlinx.serialization 1.11.0, so the ADR chooses **explicit `@SerialName("snake_case")` on every DTO property**: wire names are then a stable, explicit contract that a Kotlin rename cannot change, with no experimental opt-in. A blocking Konsist rule fails any `@Serializable` DTO property without a `snake_case` `@SerialName`, and the contract test against `contracts/openapi/` catches any drift. (Rejected: the explicit opt-in to `JsonNamingStrategy.SnakeCase` guarded by the contract test — less code, but an experimental API on the wire contract, and a property rename silently changes a wire name.)
- One shared `Json` instance; unknown keys rejected (the default, F227); `explicitNulls` and `encodeDefaults` set explicitly and asserted by a contract test (V9).
- **`exceptionsWithDebugInfo = false`** on the shared `Json`, so a decode error does not carry the input text (kotlin best-practices line 38; the decode error is the cause of `BadRequestException`, F227). It is experimental at 1.11.0 (V17), so it is the **one sanctioned experimental opt-in**, recorded here, guarded by a test, and re-checked at every kotlinx.serialization bump. Independently, the 400 handler never logs or returns `cause.message`.
- Request DTO fields are nullable; `toCommand()` checks presence and answers 422 with field code `required`, so a missing field is a field error, not a 400 (a missing non-null field raises `MissingFieldException`, which becomes 400, F227). Response DTOs use non-null types where the value always exists. kotlinx.serialization 1.11.0 has no nesting-depth limit, so the request-body size limit is the only guard against deeply nested input.
- DTOs carry plain types (`String` ids); the mapper converts to value classes, so no value class is ever serialized (part-2 F216a removed from the DTO path).

### 9. Types: value-class ids and enums for every closed choice

- Ids are `@JvmInline value class` wrappers (`TenantId`, `BranchId`, `OrderId`, ...) with `init { require(...) }` for format; boxing in `List<BranchId>` or `BranchId?` is accepted (F205).
- Every closed choice is a Kotlin `enum class`. Persisted enums are stored by an explicit `dbValue` string (never `name` or ordinal), the column carries a **named database `CHECK`** (naming and evolution rules in ADR-0016), and a Testcontainers test compares the enum's values with the constraint. Wire enums are strings; clients tolerate unknown values (`api-standards.md`).
- Mappings over closed types are exhaustive `when` expressions without `else` (F231, F232).

### 10. Building blocks and size limits

- **`:core:foundation`**, a **sixteenth Layer 1 module**, depending only on the Kotlin standard library. **Closed content list:** `ErrorKind`, `ErrorCode`, `AppException`, `FieldError`, `IdGenerator` (port), `TenantId`, `BranchId`. Time uses the standard library's `kotlin.time.Clock` and `Instant`, stable since Kotlin 2.3.0 (`kotlin/best-practices.md` line 19, `kotlin/VERSION.md` line 46), injected for deterministic tests; the module declares no `Clock` of its own. The `IdGenerator` implementation does not call the experimental UUIDv7 generation in `kotlin.uuid`.
- **ADR-0010 amendment** (dated, written with this ADR): Decision 1 gains row 16, `foundation`, package `net.kodelix.core.foundation`; Decision 6: no `-conformance` module, because it holds no adapter; Decisions 7 and 8: it is not a core category, so it is a **NOT EVIDENCED founder exception** (owner: the founder; review at the `saas-core-kotlin` repository decision) and moves to the core first, or with the first extracted module; ADR-0011's "fifteen" (lines 79 and 109) reads sixteen; registry IC-CORE-MODULE-IDENTITY-R3 replaces R2. A blocking Konsist rule fails any top-level declaration in the module outside that list; adding one needs an amendment to this ADR. There is never a growing `common`/`utils` module and never a generic `Repository<T>`.
- **Size limits:** a function at most **40 lines**, a file at most **300 lines**. They are **blocking whatever tool enforces them**. Enforcement path: a Konsist rule in `:arch-tests` if Konsist 0.18.1 can count function and file lines (V1, verified before acceptance); otherwise a small blocking build check in `build-logic` (file lines from the source text; function lines from the Kotlin PSI the compiler already provides). A line is a physical line of the declaration's text from its first to its last line, blank and comment lines included, KDoc and annotations above the declaration excluded; a file's lines are all its physical lines. Exceptions only through one listed file (`backend/gradle/size-exceptions.properties`), one entry per file or function with a written reason. detekt stays advisory and is not the enforcement path.

### Architecture

```mermaid
flowchart LR
    C[Client: dashboard SPA / counter] -->|HTTPS| N[nginx: TLS, HSTS, body limit, SPA static files]
    N -->|X-Forwarded-For from nginx only| K
    subgraph K[":app — Ktor 3.6.0 / Netty, Temurin 25"]
        P1[request log] --> P2[forwarded headers] --> P3[security headers] --> SP[StatusPages]
        SP --> DL[deadline] --> RL[per-IP RateLimit\nnot on sign-in] --> CN[ContentNegotiation]
        CN --> AU[Authentication\nsession / device lookup]
        AU --> CS[CSRF on cookie routes] --> RT[route: coarse permission\nDTO.toCommand()]
    end
    RT --> UC["use case (app)\nwithScope → Authorizer.require → domain → trail + outbox"]
    UC --> G[admission Semaphore(n) + W waiters] --> V["db view limitedParallelism(n)"] --> H[(HikariCP pool per role)] --> PG[(PostgreSQL 18.6\nFORCE RLS, transaction_timeout, lock_timeout)]
    UC -. throws AppException .-> SP
```

### Key Interfaces

```kotlin
// :core:foundation (closed list)
enum class ErrorKind { Malformed, Unauthenticated, Forbidden, TenantRefused, NotFound, MethodNotAllowed, Conflict,
    PreconditionFailed, PayloadTooLarge, UnsupportedMediaType, Invalid, RateLimited, Timeout,
    Overloaded, Transient, Internal }
interface ErrorCode { val wire: String; val kind: ErrorKind }          // each context: enum class XErrorCode : ErrorCode
data class FieldError(val field: String, val code: String)
abstract class AppException(val code: ErrorCode, val fieldErrors: List<FieldError> = emptyList(),
    safeMessage: String, logCause: Throwable? = null, withTrace: Boolean = false)
    : RuntimeException(safeMessage, logCause, false, withTrace)   // expected failures: no trace (F229); Internal: withTrace = true
interface IdGenerator { fun newId(): String }                          // UUIDv7 text
@JvmInline value class TenantId(val value: String)                     // init { require(...) }
@JvmInline value class BranchId(val value: String)

// every module: one wiring function, ports only (Decision 2)
fun ordersModule(deps: OrdersDeps): OrdersApi

// :app (Decision 2)
dependencies { provide<OrdersApi> { ordersModule(OrdersDeps(resolve(), resolve())) } }

// request path (Decision 5)
suspend fun <T> deadline(budget: Duration, block: suspend () -> T): T   // throws AppException(Timeout)
suspend fun <T> DbGate.run(block: suspend () -> T): T                   // Semaphore + W waiters + timed acquire
```

Contracts: the problem body and every DTO name live in `contracts/openapi/` (contract first, `api-standards.md`).

### Implementation Guidelines

- **Must (all modules):** domain and app code never import Ktor, Exposed, kotlinx.serialization or `io.ktor.server.plugins.di`; ports at the boundary (`clean-architecture.md`).
- **Must (app layer):** every use case calls `Authorizer.require` with target and amount where they apply; opens its own transaction through `withScope`; throws `AppException` subclasses only for request-ending failures and returns sealed values where the caller branches.
- **Must (adapters/http):** DTOs carry `@SerialName` snake_case names and plain types; `toCommand()` validates and maps to value classes; `toResponse()` maps explicitly; the `ErrorKind` mapping is one exhaustive `when` without `else`.
- **Must (adapters/persistence):** JDBC only inside `withContext(dbView)` behind the pool's `DbGate`; every transaction sets `transaction_timeout` and `lock_timeout` locally.
- **Must (`:app`):** the only place that installs plugins and registers Ktor DI providers, in the Decision 6 order, asserted by a `testApplication` test.
- **Must (adapters/http):** read the principal through one helper that throws `AppException(Unauthenticated)` when it is missing (principals are nullable in 3.6.0).
- **Must (tests):** a negative test proves that a device's backlog upload of sales already made is accepted, with the `tenant_suspended` notice, for a suspended tenant, after its lease ended, and for a tenant in `closure_requested` and `export_window` (ADR-0001 Decision 4); the same test proves a new-sale and an enrolment call are refused.
- **Must never:** `runCatching` on a request path at all (Konsist cannot tell whether a call inside is suspending); `ApplicationCall.receiveNullable` (deprecated 3.6.0); catch `Exception`/`Throwable` outside the three sites; `runBlocking`, `Thread.sleep` or `synchronized` on a request path; raw `withTimeout` in a use case; a session-level lock; registration from configuration; a tenant, branch or device id read from the request; a value class in a DTO; an enum persisted by `name` or ordinal; `JsonNamingStrategy` or any other experimental API without an ADR; a declaration in `:core:foundation` outside its list; a function over 40 or a file over 300 lines without an entry in the exceptions file.

## Alternatives Considered

### Alternative 1: Temurin 21 (or Oracle JDK)

- **Description**: keep `jvm_toolchain: "21"`; or use Oracle JDK 21/25.
- **Cost**: none now (21 is the current pin); another LTS move by 2029.
- **Risk**: 21's free updates end at least Dec 2029 against Sep 2031 for 25 (F103); Oracle's licence terms changed and its primary pages could not be read (F104, F110).
- **Performance**: no consistent difference measured (F123, F126); the agent costs 2.4-3.1 s of start-up on either.
- **Operability**: same quarterly rebuild rhythm; hosted only.
- **Rejection Reason**: 25 passed the full build and run (S12) and gives the longest free runway; Oracle adds licence tracking with no gain.

### Alternative 2: Manual constructor wiring or Koin 4.2.2 as the primary DI

- **Description**: wire every module by hand in `:app`, or install Koin.
- **Cost**: manual: more `:app` code as modules grow; Koin: a third-party dependency that still pulls `ktor-server-di` (F115, F127).
- **Risk**: manual: none technical; Koin: one vendor, a process-wide default context (F116).
- **Performance**: no consistent difference at the measured size (F125, F126, F130).
- **Operability**: both hosted only; Koin needs `ktor-server-di` pinned to 3.6.0 (F127, F131).
- **Rejection Reason**: the founder chose Ktor DI on dependency and fit; manual wiring stays the first fallback (Decision 2 condition 5) and Koin the second.

### Alternative 3: Sealed result types everywhere (the studio rule)

- **Description**: every use case returns a sealed result; exceptions only for bugs.
- **Cost**: a result type and a mapping per use case across ~30 contexts.
- **Risk**: a returned failure inside the transaction commits unless the author rolls back by hand (F225).
- **Performance**: equal.
- **Operability**: equal.
- **Rejection Reason**: the per-use-case cost and the commit-on-return hazard; its strengths are kept where the caller branches.

### Alternative 4: The exception tree everywhere

- **Description**: every failure, including provider and job outcomes, is an exception.
- **Cost**: lowest per use case.
- **Risk**: ADR-0013's ambiguous outcome and ADR-0012's retry classes would become exceptions that generic handlers treat alike; compile-time exhaustiveness lost where a wrong guess is dangerous.
- **Performance**: equal.
- **Operability**: equal.
- **Rejection Reason**: it blurs the cases where the caller must branch.

### Alternative 5: Every check inside the use case (B2)

- **Description**: the adapter forwards the raw credential; an `app`-layer gate authenticates, scopes and authorizes.
- **Cost**: higher per use case.
- **Risk**: a forgotten call is a silent security bug; `app` would parse credentials (an adapter concern).
- **Performance**: equal.
- **Operability**: heavier tests.
- **Rejection Reason**: credential-derived checks belong where the credential is read; B1 keeps the object-level check mandatory in the use case anyway.

### Alternative 6: `withTimeout`-only or HikariCP-only bounding

- **Description**: bound request time with coroutine timeouts, or the wait for a connection with `connectionTimeout`.
- **Cost**: lowest.
- **Risk**: `withTimeout` does not free a blocked JDBC call (F319) and returns late when waiting in a view (F327); Hikari alone blocks one thread per waiter (F332).
- **Performance**: breaks the 3 s and 150 ms budgets under load.
- **Operability**: hidden thread exhaustion on 2 vCPU.
- **Rejection Reason**: measured failures; Decision 5 is the only combination the spikes support.

### Alternative 7: Proxy-only headers and limits, and Ktor `CallLogging`

- **Description**: security headers, rate limits and compression only in nginx; Ktor's `CallLogging` for access logs.
- **Cost**: low.
- **Risk**: cannot be exercised by `testApplication`; no principal at the proxy for per-user limits; `CallLogging`'s default format may log URLs with query strings (F325k).
- **Performance**: off the JVM.
- **Operability**: dev and production differ.
- **Rejection Reason**: own plugins are testable and fit P-PLUMB; nginx still sets HSTS and the outer body limit.

### Alternative 8: `JsonNamingStrategy.SnakeCase` with an explicit opt-in

- **Description**: one `namingStrategy` setting on the shared `Json`, `@OptIn(ExperimentalSerializationApi::class)`, guarded by the contract test.
- **Cost**: least code.
- **Risk**: an experimental API on the wire contract; renaming a Kotlin property silently renames the wire field.
- **Performance**: equal.
- **Operability**: re-check at every kotlinx.serialization bump.
- **Rejection Reason**: explicit `@SerialName` gives a stable contract with a stable API (Decision 8).

### Alternative 9: Error types per module, or the ids in `:core:tenancy` (instead of `:core:foundation`)

- **Description**: each Layer 1 module declares its own `ErrorKind`/`AppException` copy; or `TenantId`/`BranchId` live in `:core:tenancy` and other modules depend on it.
- **Cost**: copies: one per module and a mapping per copy in the HTTP adapter; tenancy: every module depends on a large Layer 1 module.
- **Risk**: copies drift and the single exhaustive mapping of Decision 3 is lost; a tenancy dependency drags tenancy's ports and migrations into every module's graph.
- **Performance**: equal.
- **Operability**: more modules to keep consistent; extraction order tied to tenancy.
- **Rejection Reason**: one small closed module keeps one mapping and a dependency with no behaviour; the founder chose list A.

### Alternative 10: 504 for our own timeouts

- **Description**: our deadline answers 504; admission refusal 503.
- **Cost**: none.
- **Risk**: a 504 would no longer tell nginx's timeout apart from ours; clients need two retry rules.
- **Performance**: equal.
- **Operability**: dashboards and the runbook could not attribute a 504 to the proxy.
- **Rejection Reason**: with 503 for both, a 504 always means nginx timed out (founder 2026-10-24).

### Alternative 11: camelCase JSON names

- **Description**: Kotlin property names on the wire, no `@SerialName` (`api-standards.md` allows either, one per product).
- **Cost**: least code.
- **Risk**: a property rename changes the wire contract; wire names differ from the snake_case columns and error codes.
- **Performance**: equal.
- **Operability**: generated clients follow either.
- **Rejection Reason**: snake_case matches the database, the codes and the standard's first choice; explicit names keep the contract stable.

## Consequences

### Positive

- One error contract and one check order for every endpoint and generated client.
- Request paths are bounded end to end: database timeouts, a deadline, and a bounded wait for a connection.
- The conventions are enforced by the compiler, Konsist or a build check, not by memory.
- Modules stay small and the building blocks stay closed.

### Negative

- Two error mechanisms to teach; the decision rule must be applied consistently (review plus Konsist on catch sites).
- `@SerialName` on every DTO property is boilerplate.
- A sixteenth Layer 1 module and an ADR-0010 amendment.
- The error model, the unknown-keys rule and the plugin list depart from the studio rule until the guide updates it.
- Reversing the wire contract needs a versioned API (Migration Plan).
- Several values (pool sizes, `W`, budgets, timeouts) wait for S18.

### Neutral

- Ktor DI ties wiring to `:app`; modules do not change if the DI library changes.
- SSE versus WebSockets is deferred to another ADR.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Konsist 0.18.1 cannot count lines | MEDIUM | the size rule would not block | V1 before acceptance; the build-logic check is the fallback (Decision 10) |
| Ktor labels `ktor-server-di` experimental or deprecated | LOW | wiring rework | condition 2 keeps it in `:app`; manual wiring fallback; question to maintainers (`ktor-lead`) |
| The forwarded-header plugin cannot be restricted to one hop | LOW | spoofed client IP in limits and logs | V4; if not, an own small plugin reads nginx's header only |
| The per-IP limiters slow venues behind one address | MEDIUM | lost sales | layer 2 excludes sign-in and recovery; caps sized for a whole venue and the 7-day backlog drain; per-principal limits after authentication |
| A CGNAT flood keeps a co-located owner out of sign-in (staff-auth T1.18 variant) | LOW | the owner cannot sign in while it lasts | separate nginx zone, cap far above a venue, alert on any edge 429 on sign-in; residual accepted by name, review by 2027-04-18 |
| Admission or timeout values chosen badly | MEDIUM | refusals or slow paths | S18 sets them; metrics `db_admission_rejected_total`, `request_timeout_total{source}` |
| A catch-all swallows cancellation | LOW | half-done work, misclassified jobs | three sites only, Konsist rule, tests |
| A new `ErrorKind` added without mapping | LOW | 500 instead of the right status | exhaustive `when` without `else` fails the build (F231) |
| `:core:foundation` becomes a dependency of every Layer 1 module and the extraction bottleneck | MEDIUM | MEDIUM | closed list; moves first or with the first extracted module; owner `cto`, review at the `saas-core-kotlin` repository decision |
| Ktor DI closes pools in the wrong stop phase | MEDIUM | in-flight jobs lose connections at shutdown | pools never DI-managed (Decision 2 condition 6); V13 |
| A plugin refusal escapes the problem+json contract | MEDIUM | inconsistent client errors | `status(...)` rewrites, CSRF `onFailure` throws; V14, V15, V18 |
| An experimental kotlinx.serialization option changes | LOW | debug info back in decode errors | one sanctioned opt-in, test, re-check at every bump (V17) |

## Cross-Cutting Impact

| Concern | Impact |
|---------|--------|
| **Security / tenancy** | Gateway order (ASVS 2.3.1), deny-by-default coarse and object-level authorization (ADR-0008), 404 for other-tenant objects, CSRF on cookie routes (ASVS 3.5.1, 3.5.3), security headers (3.4.1-3.4.6), forwarded headers trusted from nginx only (4.1.3), no internals in errors (16.5.1), last-resort handler (16.5.4); `FP-IP-ONLY-BLOCK-R2` respected. Threat models: `docs/architecture/threat-models/staff-auth.md` and `docs/architecture/threat-models/tenant-isolation.md`; the gateway-order section (steps 0-13, Decision 6a's four layers, the forwarded-header trust) is added to `staff-auth.md` by `security-lead` **as a condition before acceptance** |
| **Observability** | Agent spans only; request log with `trace_id`; metrics `request_timeout_total{source}`, `db_admission_rejected_total{pool}`, pool pending/active, `csrf_rejected_total`, `rate_limited_total{limiter}`, error counter by route template and code; dashboards and the runbook separate our 503s from nginx's 504 |
| **Caching** | None introduced. Sessions, principals and authorization are never cached (ADR-0003, ADR-0008); rate-limit state is in-process (ADR-0007), lost on restart, shared store at a second instance |
| **Self-hosted** | None — hosted only |
| **Cost** | None beyond the JVM: the agent costs about 100 MB RSS and 2.4-3.1 s of start-up (F123). Licences: `ktor-server-di` Apache-2.0 (F107); Koin Apache-2.0 if ever used (F106); Temurin images: OpenJDK GPL v2 with Classpath Exception and Apache-2.0 Dockerfiles per the Docker Hub page (F112), Adoptium's own licence text not fetched (F103) — fetched before the first image ships (owner `infra-engineer`) |

## Performance Implications

| Metric | Before | Expected After | Budget (`perf-budgets.md`) |
|--------|--------|---------------|--------|
| Latency p95 (read endpoints) | n/a (no code) | not measured; bounded by the route-class deadline | 150 ms server time |
| Latency (counter actions) | n/a | bounded by deadline and admission | 3 s worst case |
| DB queries per request | n/a | fixed setup per read: the session lookup (1) and the principal read (1) count toward the 5 (ADR-0016 founder rule), leaving **3 business statements** for the use case; the two scope statements (one per transaction, each also setting the timeouts) are counted separately under their own cap of 2. A read that cannot fit 3 business statements does not meet the budget and is precomputed or redesigned (ADR-0016) | 5 per read |
| Memory (service RSS) | n/a | about 175 MB without the agent, about 280 MB with it, idle, on the spike (F123); heap limit from S18 | not yet set |
| Start-up | n/a | about 1.1 s without the agent, about 4.2 s with it (F123) | not yet set |

## Migration Plan

Greenfield: no code exists.

1. On approval: write this ADR; add the dated amendments to ADR-0010 (sixteenth module, Decisions 1, 6, 7, 8) and ADR-0002 (scope helper: admission and timeouts), the dated notes to ADR-0008 (Decision 4), ADR-0007 (FP-IP-ONLY-BLOCK amendment, worded by `security-lead`), ADR-0009 (nginx access log and rate-limit refusal status) and ADR-0005 (proxy access-log retention row); update the registry.
   The statement-counting rule is recorded as a dated note in `docs/architecture/perf-budgets.md` (founder 2026-10-24).
2. The user applies the product pin changes before the Gradle wrapper exists: `kotlin.jvm_toolchain` `"25"`; `kotlin.gradle` `"9.8.2"`; new `kotlin.serialization` `"1.11.0"`; new pgjdbc `42.7.14` (ADR-0012); `ktor-server-di` follows `ktor.ktor`.
3. Run V1 (Konsist line counting) before acceptance; V2-V10 in the first backend stories, each a story acceptance criterion.
4. After acceptance, the guide updates the studio rule (`backend-ktor.md` line 14, `clean-architecture.md` line 62) and the studio `pins.yaml`.

**Rollback plan**: the internal decisions are local — Ktor DI falls back to manual wiring in `:app`, a plugin can be removed in `:app`, a Konsist rule can be relaxed, and nothing persists data. **The wire contract is not local**: the problem body, the error codes, the `ErrorKind`-to-status mapping and the snake_case names are a contract with offline counter clients that may run older versions. Reversing any of them needs a versioned API (`/v2` beside `/v1`, both served until the oldest supported counter version has updated): at least the offline window (the 7-day backlog of `perf-budgets.md` plus the licence grace) plus one device update cycle, and the effort of a second mapper set for every changed DTO, a contract diff in CI and generated clients for both versions. Error codes are append-only for this reason (Decision 3).

## Validation Criteria

- [ ] V1 passes (Konsist counts lines) or the build-logic check is in place; a 41-line function and a 301-line file each fail the build in a test fixture.
- [ ] The full-graph DI boot test runs in CI and fails when a provider is removed.
- [ ] A `testApplication` test asserts the install order of Decision 6.
- [ ] Adding an `ErrorKind` constant without a mapping fails compilation (F231 reproduced in CI).
- [ ] A golden-file test fails when an error code is renamed or removed.
- [ ] Security: a cross-site POST without the custom header is refused; a spoofed `X-Forwarded-For` does not change the per-IP key; a foreign object id answers the same 404 as a missing one; an unconfigured CSRF plugin fails a test.
- [ ] Performance: under the S18 load, waiters beyond `W` are refused at once and the rest time out at the wait budget (S30b behaviour reproduced on the real stack); no thread is blocked in `getConnection`.
- [ ] A Konsist rule fails a declaration added to `:core:foundation` outside its list, and a DTO property without a snake_case `@SerialName`.

## Spec Requirements Addressed

Foundational — no spec requirement. Enables: every backend context's endpoints and jobs (the error contract, gateway order, runtime rules and plugin set), ADR-0016, the generated API clients (snake_case contract), and the dashboard real-time ADR.

## Related

- Depends on: ADR-0002 (amended: scope helper admission and timeouts, IC-SCOPE-HELPER-R6), ADR-0003, ADR-0005 (dated note: proxy access-log retention row), ADR-0006 (closes its Q8), ADR-0007 (dated note: FP-IP-ONLY-BLOCK-R2), ADR-0008 (dated note), ADR-0009 (dated note: nginx access log, rate-limit refusal status) (Accepted); ADR-0010 (amended: sixteenth module), ADR-0011, ADR-0012, ADR-0013, ADR-0014 (Proposed).
- Enables: ADR-0016 (data access, performance and reporting).
- Research note: `docs/research/backend-code-conventions.md` (parts 1-3; evidence in `docs/research/evidence/backend-code-conventions/`).
- Departs from: `.claude/rules/backend-ktor.md` line 14 and `.claude/docs/clean-architecture.md` line 62 (error model), to be updated by the guide after acceptance.
- Threat models: `docs/architecture/threat-models/staff-auth.md`, `docs/architecture/threat-models/tenant-isolation.md`; the gateway-order section in `staff-auth.md` (owner `security-lead`) is a condition before acceptance.
- Gates: CTO-ADR — CONCERNS 2026-10-24 (eight concerns and smaller fixes, all revised at the founder's instruction); narrow re-check 2026-10-24: all eight resolved, no new conflict with an Accepted ADR, four wording items applied (fit for APPROVE without another review); stack validation `ktor-lead` — BLOCKING verdict 2026-10-24, six issues revised in this draft (DI route exception removed, pools outside DI, request-path `defaultMaxAttempts = 1`, plugin refusals through `status` rewrites and CSRF `onFailure`, global deadline ceiling plus per-class budgets, `exceptionsWithDebugInfo = false`) plus minor notes.
