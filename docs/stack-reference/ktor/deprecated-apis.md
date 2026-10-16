# Ktor — Deprecated / removed APIs (verified 2026-10-11)

| Deprecated / removed | Replacement | Since | Source |
|---|---|---|---|
| `Locations` plugin (removed) | `Resources` (needs kotlinx.serialization) | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `withTestApplication`, `withApplication` (removed) | `testApplication { }` | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `commandLineEnvironment()` (removed) | `CommandLineConfig` in a `configure` block | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `applicationEngineEnvironment` / builder | `applicationEnvironment` / `ApplicationEnvironmentBuilder` | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `ApplicationProperties` | `ServerConfig` (argument `applicationProperties` → `rootConfig`) | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `embeddedServer()` returning `ApplicationEngine` | returns `EmbeddedServer`; `start()`/`stop()` live on `ApplicationEngine` | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `ktor-server-host-common` artifact | merged into `ktor-server-core`; remove dependency | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `io.ktor:ktor` empty artifact (removed) | depend on specific `ktor-server-*` artifacts | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `HttpResponse.content` | `rawContent` | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `callloging` package | `calllogging` | 3.0 | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `PartData.FileItem.streamProvider()` | `provider()` (returns `ByteReadChannel`) | 3.0 (deprecated) | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `io.ktor.utils.io` classes (several) | kotlinx-io types; deprecated until Ktor 4.0 | 3.0 (deprecated) | [migrating-3](https://ktor.io/docs/migrating-3.html) |
| `ApplicationCall.receiveNullable()` | `receive()` with a nullable type | 3.6.0 (deprecated) | [GitHub 3.6.0](https://github.com/ktorio/ktor/releases/tag/3.6.0), [What's new 3.6.0](https://ktor.io/docs/whats-new-360.html) |
| `ApplicationCall.respondHtmlFragment()` | `respondHtmlPartial()` | 3.6.0 (deprecated) | [What's new 3.6.0](https://ktor.io/docs/whats-new-360.html) |

## Not deprecated, but check before adopting

| Item | Status | Source |
|---|---|---|
| Ktor built-in DI (`ktor-server-di`) | Introduced in 3.2.0. Stable/experimental status NOT SOURCEABLE — the DI pages do not say. | [server DI](https://ktor.io/docs/server-dependency-injection.html), [What's new 3.2.0](https://ktor.io/docs/whats-new-320.html) |
| Typed authentication DSL (`jwt<User>`, `authenticateWith()`) | Marked experimental (`@ExperimentalKtorApi`); needs Kotlin 2.4.0 or `-Xcontext-parameters` | [JWT](https://ktor.io/docs/server-jwt.html), [What's new 3.6.0](https://ktor.io/docs/whats-new-360.html) |
| Netty HTTP/3 over QUIC | Experimental; requires an SSL connector | [Ktor 3.6.0 blog](https://blog.jetbrains.com/ktor/2026/09/18/ktor-3-6-0-is-now-available/) |
| Koin for Ktor (third-party) | Not verified here; scope support differs per Koin's own comparison table (unverified) | [Koin for Ktor](https://insert-koin.io/docs/reference/koin-ktor/ktor/) |
| WebSockets `pingPeriod` / `timeout` typed as `java.time.Duration` | Now `kotlin.time.Duration` (a 3.0 change, not a deprecation) | [migrating-3](https://ktor.io/docs/migrating-3.html) |
