---
paths:
  - "backend/**/*.kt"
  - "backend/**/*.kts"
---

# Ktor Backend Rules

Read `docs/stack-reference/ktor/` and `docs/stack-reference/kotlin/` before using any API you are not sure exists at the pinned version.

- Packages `<context>/{domain,app,adapters}`; domain is plain Kotlin — no Ktor, no Exposed/JDBC, no `@Serializable` on domain types.
- Coroutines: structured concurrency only — no `GlobalScope`, no `runBlocking` in request paths. Blocking I/O (JDBC) runs on a bounded `Dispatchers.IO.limitedParallelism(n)` matching the pool size.
- Cancellation is cooperative: never swallow `CancellationException`; `catch (e: Exception)` must rethrow it.
- Errors: sealed result/error types at the domain boundary; a `StatusPages` handler maps to RFC 9457; no stack traces to clients.
- Serialization: `kotlinx.serialization` with explicit DTOs in the HTTP adapter; `ignoreUnknownKeys` for inbound, explicit nulls policy.
- Validation at the edge (shape) and in the domain (meaning). Request size limits configured.
- DI in the composition root (`Application.module`); no service locators inside domain/app.
- Database: HikariCP with explicit pool sizing and timeouts; parameterized queries only; transactions owned by the use case.
- Plugins: CallLogging with MDC `trace_id`, OpenTelemetry instrumentation, CORS allowlist, rate limiting, compression, default headers.
- Immutability: `val` and immutable collections by default; data classes for values; no platform types leaking from Java APIs.
- Lint: the Kotlin linters the tooling ADR chose are clean (`ktlint` + `detekt` by default, but no stable release of either supports Kotlin 2.4 — read `docs/stack-reference/tooling/VERSION.md`, Kotlin part, before configuring them); with detekt 2.x CI runs the type-resolved tasks (`detektMain` / `detektTest`), not only `detekt`; compiler warnings treated as errors in CI.
- Tests: `kotlin.test`/JUnit 5, Ktor `testApplication` for routes, Testcontainers in the `integrationTest` source set.
