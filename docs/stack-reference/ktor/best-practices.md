# Ktor — Best Practices (verified 2026-10-11)

Every factual claim cites a fetched page unless marked otherwise. Lines marked **(analysis)** are our recommendations, not sourced. Plugins are shown for Ktor 3.6.0.

## Plugin setup

| Plugin | Artifact | Verified facts | Practice for us | Source |
|---|---|---|---|---|
| StatusPages | `io.ktor:ktor-server-status-pages` | Maps `exception<T>`, `status(...)`, or `statusFile(...)` to responses. Default behaviour for unmatched errors: NOT SOURCEABLE (page silent). | Map domain errors to `exception<T>` handlers; never return stack traces. Add a catch-all `Throwable` handler that logs with a request ID. **(analysis)** | [StatusPages](https://ktor.io/docs/server-status-pages.html) |
| CallLogging | `io.ktor:ktor-server-call-logging` | SLF4J logging; level defaults to INFO; `filter` and `format` blocks; `mdc(name) { call -> }` stores values in SLF4J MDC. `callIdMdc` / CallId plugin: NOT on this page. | Use `mdc("requestId")` so every log line carries the ID. Filter out health checks. **(analysis)** | [CallLogging](https://ktor.io/docs/server-call-logging.html) |
| RateLimit | `io.ktor:ktor-server-rate-limit` | Token-bucket algorithm; returns 429 with `Retry-After`; `X-RateLimit-*` headers on success. `register(RateLimitName)`, `rateLimiter(limit, refillPeriod)`, `requestKey { }`, `requestWeight { }`. Default limit: NOT SOURCEABLE. Storage (in-memory vs shared): NOT SOURCEABLE. | Key by authenticated principal, not client-supplied headers or query params. The doc example keys on a query parameter; that is spoofable **(analysis)**. For multi-instance deployments, storage backend must be confirmed separately — NOT SOURCEABLE. Nest `rateLimit()` inside `authenticate()` to limit per user. | [RateLimit](https://ktor.io/docs/server-rate-limit.html) |
| Auth / JWT | `ktor-server-auth`, `ktor-server-auth-jwt` | `install(Authentication) { jwt("name") { realm; verifier; validate; challenge } }`. HS256 via `Algorithm.HMAC256`, RS256 via `JwkProvider`. `validate` is required (omitting it throws `IllegalArgumentException`). Docs advise against plaintext secrets in config files. `Oidc` plugin handles JWKS for OpenID Connect. | Build the verifier with `withIssuer` and `withAudience`. Load secrets from a secret store, not config files. Use RS256 + JWKS for multi-service setups. Validate the principal's claims in `validate`. | [JWT](https://ktor.io/docs/server-jwt.html) |
| ContentNegotiation | `ktor-server-content-negotiation`, `ktor-serialization-kotlinx-json` | `install(ContentNegotiation) { json() }`. Requires the Kotlin serialization plugin and `@Serializable` on DTOs. `json()` takes a kotlinx `Json` builder. | Configure one shared `Json` instance; set `ignoreUnknownKeys` only if intended **(analysis)**. | [ContentNegotiation](https://ktor.io/docs/server-serialization.html) |
| CORS | `io.ktor:ktor-server-cors` | `allowHost` (with port, subdomains, scheme), `anyHost`, `allowMethod`, `allowHeader`/`allowHeaders`/`allowHeadersPrefixed`, `exposeHeader`, `allowCredentials`, `maxAgeInSeconds`. Defaults: methods GET, POST, HEAD; headers Accept, Accept-Language, Content-Language. Non-simple content types need `allowNonSimpleContentTypes`. Route-level CORS needs `options` handlers. Page has no wildcard warning. | Allow explicit origins via `allowHost`. Avoid `anyHost` in production **(analysis)**. Set `allowCredentials` only with explicit hosts **(analysis)**. | [CORS](https://ktor.io/docs/server-cors.html) |
| Compression | `ktor-server-compression` (+ `ktor-server-compression-zstd`) | Defaults: gzip, deflate, identity. Zstd default level 3. Excludes audio, video, image, event-stream by default. `minimumSize`, `condition { }`, `matchContentType`/`excludeContentType`. Does not support SSE. Request decompression via `Mode.DecompressRequest`. HTTPS + compression is BREACH-vulnerable; page's mitigation is a `condition` disabling compression for cross-site Referrer. | Keep event-stream excluded. Apply the BREACH condition on HTTPS endpoints that reflect user input. Set a minimum size. | [Compression](https://ktor.io/docs/server-compression.html) |

## Dependency injection (built-in)

- Artifact: `ktor-server-di` (JVM coordinate `ktor-server-di-jvm` in Maven). Introduced in **3.2.0** per [What's new 3.2.0](https://ktor.io/docs/whats-new-320.html). Stability status: NOT SOURCEABLE.
- Register in code (`dependencies { provide<T> { ... } }`) or in config under `ktor.application.dependencies`. Resolve with `dependencies.resolve<T>()`, or declare module-function parameters for injection. Suspending providers are supported; `resolve()` suspends until ready. [Dependency resolution / registration](https://ktor.io/docs/server-dependency-injection.html) (sub-pages linked there)
- Caveat: the registration example above comes from search-result text, not a fetched page body; re-verify the exact syntax on `server-di-dependency-registration.html` before copying.
- Testing: register a mock inside `testApplication` before loading modules. [Testing with DI](https://ktor.io/docs/server-di-testing.html) (linked from the DI page).
- Practice **(analysis)**: prefer constructor injection of service interfaces so unit tests need no Ktor runtime (matches the project rule that public methods must be unit-testable).

## Testing: testApplication

- Import `io.ktor.server.testing.*`; add `ktor-server-test-host`. Test shape:
  ```kotlin
  @Test
  fun root() = testApplication {
      application { module() }      // modules are NOT auto-loaded from config
      val response = client.get("/")
      assertEquals(HttpStatusCode.OK, response.status)
  }
  ```
- Config: `environment { config = ApplicationConfig("application-custom.conf") }` (from `test/resources`) or `MapApplicationConfig("ktor.environment" to "dev")`.
- App starts on first client call; call `startApplication()` to test lifecycle hooks.
- Page banner: Ktor 3.6.0.

## Observability: OpenTelemetry

- Server plugin: `KtorServerTelemetry`; artifact `io.opentelemetry.instrumentation:opentelemetry-ktor-3.0:2.18.1-alpha` (alpha suffix; the page does not call it experimental). Client counterpart: `KtorClientTelemetry`. Source: [Ktor server OpenTelemetry](https://ktor.io/docs/server-opentelemetry.html).
- You must create and initialise an `OpenTelemetry` instance (OTLP gRPC exporter, tracer provider, batch span processor) before installing the plugin. Spans carry route, method, and status code; incoming W3C trace context is extracted.
- Older Ktor 2.x artifact: `opentelemetry-ktor-2.0` (per OpenTelemetry Java instrumentation README, search-result only).
- Alpha coordinate: pin the exact version and re-check on upgrade.

## Persistence pairing

| Component | Verified version | Verified requirement | Source |
|---|---|---|---|
| Exposed | **1.5.1** latest on Maven (2026-10-09); JetBrains get-started page shows 1.5.0 | JDK 8 or higher (JetBrains page). Kotlin requirement: NOT on the JetBrains page; third-party sites say Kotlin 2.2+ (unverified). | [Maven metadata](https://repo1.maven.org/maven2/org/jetbrains/exposed/exposed-core/maven-metadata.xml), [JetBrains](https://www.jetbrains.com/help/exposed/get-started-with-exposed.html) |
| HikariCP | **7.1.0** (Maven, 2026-06-14) | JDK 11+ for 7.x per Baeldung tutorial (third-party). Official JDK requirement: NOT SOURCEABLE (GitHub releases page is empty). | [Maven metadata](https://repo1.maven.org/maven2/com/zaxxer/HikariCP/maven-metadata.xml), [Baeldung](https://www.baeldung.com/hikaricp) |

- Ktor docs connect Exposed with `Database.connect(url, user=..., password=...)` and run queries in `inTopLevelSuspendTransaction` on `Dispatchers.IO`. The docs example pins `exposed = 1.3.0` (stale) and does not show HikariCP. Use 1.5.x and wire a HikariCP `DataSource` yourself **(analysis)**. Source: [Ktor database integration](https://ktor.io/docs/server-integrate-database.html).
- Exposed's own docs and its 1.5.1 source make `suspendTransaction` the supported entry point for suspend code (`newSuspendedTransaction` is `@Deprecated`); a nested block shares the outer transaction, so a second tenant context set inside it overwrites the outer one. Sources: [Exposed transactions](https://www.jetbrains.com/help/exposed/transactions.html) (fetched 2026-10-17); Exposed 1.5.1 sources jar (Kodeebo `docs/research/tenant-isolation.md` F237-F239).
- Sizing the pool, timeouts, and lifecycle: NOT SOURCEABLE from fetched pages.

## Ktor-level checklist

1. Pin `ktor = "3.6.0"` in the version catalog; upgrade by reading `breaking-changes.md`.
2. Use `testApplication` (3.x) for all route tests; never `withTestApplication`.
3. Install StatusPages, CallLogging with MDC, ContentNegotiation, and CORS explicitly in `module()`.
4. Authenticate with JWT (RS256/JWKS for multi-service), and rate limit per principal.
5. Keep event-stream excluded from Compression.
