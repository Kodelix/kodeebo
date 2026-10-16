# Ktor — Breaking / Behaviour Changes

Last verified: 2026-10-11. Every row cites a fetched page. The "Impact" column is analysis, not sourced.

## 2.x → 3.0 — [Migrating from 2.2.x to 3.0.x](https://ktor.io/docs/migrating-3.html)

| Area | Change | Impact for us |
|---|---|---|
| Server engine API | `applicationEngineEnvironment` and its builder renamed to `applicationEnvironment` / `ApplicationEnvironmentBuilder`. `start()`/`stop()` moved from the environment to `ApplicationEngine`. | Any custom engine bootstrap code breaks at compile time. |
| Server engine API | `commandLineEnvironment()` removed; use `CommandLineConfig` in a `configure` block. | Replace in `main()`. |
| Server config | `ApplicationProperties` replaced by `ServerConfig`; the `applicationProperties` argument renamed `rootConfig`. | Update any config plumbing. |
| Server engine API | `embeddedServer()` returns `EmbeddedServer`, not `ApplicationEngine`. | Type annotations change. |
| Modules | `ktor-server-host-common` merged into `ktor-server-core`. | Remove the dependency; usually no code change. |
| Client | `HttpResponse.content` renamed `rawContent`. | Compile-time break for client code. |
| Client | `SocketTimeoutException` is now a typealias for `java.net.SocketTimeoutException`. | Update `catch` / exception checks. |
| Plugins | `Locations` removed; use `Resources` (requires kotlinx.serialization). | Route definitions must be rewritten. |
| Plugins | `CallLogging` package renamed `callloging` → `calllogging`. | Update imports. |
| Plugins | WebSockets `pingPeriod` and `timeout` now `kotlin.time.Duration` (was `java.time.Duration`). | Update config values. |
| Plugins | Sessions: MAC computed from the encrypted value. `backwardCompatibleRead = true` keeps old sessions readable. | Existing session cookies are invalidated unless this flag is set during rollout. |
| Multipart | Default 50 MiB limit for binary/file items in `receiveMultipart()`; larger items throw `IOException` unless `formFieldLimit` is passed. | Upload endpoints fail above 50 MiB until configured. |
| Multipart | `PartData.FileItem.streamProvider()` deprecated; use `provider()` (returns `ByteReadChannel`). | Deprecation warning. |
| Testing | `withTestApplication` and `withApplication` removed; use `testApplication`. | Rewrite tests. |
| Testing | `TestApplication` no longer auto-loads modules from config; load them with `application { }` or config with `environment { }`. | Tests silently run with no routes if not migrated. |
| I/O | Moved to `kotlinx-io`; `readRemaining()` returns `Source`; several `io.ktor.utils.io` classes deprecated until Ktor 4.0. | Affects any raw channel code. |
| Attributes | `AttributeKey` compared by identity; get/put need exact type match. | Custom attribute lookups can return null. |
| Sockets | `TCPSocketBuilder` / `UDPSocketBuilder` `.bind()` is now suspending. | Call sites must be in a coroutine. |
| Artifacts | Empty `io.ktor:ktor` artifact removed. | Build failure if still referenced. |
| Serialization / DI | Not covered on the migration page. | NOT SOURCEABLE from this page. |

## Minor releases 3.4 → 3.6 (no breaking labels on release pages)

| Version | Change | Impact | Source |
|---|---|---|---|
| 3.6.0 | Auth principals are nullable; `ApplicationCall.receive` accepts nullable types; `ApplicationPhase.Validators` made public. | Code that assumed non-null principals can change behaviour. The 3.6.0 page labels none as breaking. | [GitHub 3.6.0](https://github.com/ktorio/ktor/releases/tag/3.6.0), [What's new 3.6.0](https://ktor.io/docs/whats-new-360.html) |
| 3.6.0 | Netty: experimental HTTP/3 over QUIC (requires an SSL connector); h2c and HTTP/2-over-TLS on separate connectors. | Opt-in only; experimental. | [Ktor 3.6.0 blog](https://blog.jetbrains.com/ktor/2026/09/18/ktor-3-6-0-is-now-available/) |
| 3.6.0 | Type-safe authentication DSL (experimental) uses Kotlin context parameters, which require Kotlin 2.4.0 or `-Xcontext-parameters`. | Do not enable on Kotlin < 2.4. | [What's new 3.6.0](https://ktor.io/docs/whats-new-360.html) |
| 3.6.0 | Route parameter conversion covers `Uuid`, `Byte`, unsigned numerics. | Additive. | [Blog](https://blog.jetbrains.com/ktor/2026/09/18/ktor-3-6-0-is-now-available/) |
| 3.5.2 | Rate limiting based on authentication results; stability and performance patch. | Rate-limit keys may change behaviour after upgrade. | [releases table](https://ktor.io/docs/releases.html) |
| 3.5.1 | Kotlin 2.4 compiler compatibility fixes. | Upgrade to 3.5.1+ before moving to Kotlin 2.4. | [releases table](https://ktor.io/docs/releases.html) |
| 3.5.0 | RFC 7616 Digest authentication; custom DNS resolvers for OkHttp and Apache5. | Additive. | [releases table](https://ktor.io/docs/releases.html) |
| 3.4.0 | Runtime-generated OpenAPI specs; Zstd and Jackson 3 support; duplex streaming for OkHttp. | Additive. | [releases table](https://ktor.io/docs/releases.html) |

## Ktor 3.2.0 — DI introduced

- Ktor 3.2.0 introduces the Dependency Injection plugin (`ktor-server-di`). Introduction only; no breaking change was stated. Source: [What's new in 3.2.0](https://ktor.io/docs/whats-new-320.html).

## Ktor 4.0 — NOT SOURCEABLE

- Ktor 4.0 date and breaking list: NOT SOURCEABLE. Only forward reference is that deprecated `io.ktor.utils.io` classes stay until Ktor 4.0 ([migration 3.0](https://ktor.io/docs/migrating-3.html)).
