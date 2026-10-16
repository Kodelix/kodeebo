# Kotlin — Best practices (sourced, verified 2026-10-11)

Priorities: things that changed recently or that models commonly get wrong.

## Build / toolchain
- **Use `compilerOptions {}` not `kotlinOptions {}`** (error since 2.2.0). Typed values: `jvmTarget = JvmTarget.fromTarget("17")`, `optIn.add(...)`. [compiler options](https://kotlinlang.org/docs/gradle-compiler-options.html)
- **Pin the JDK with `kotlin { jvmToolchain(N) }`** — it also sets the toolchain for Java tasks and `jvmTarget` follows it; add the `org.gradle.toolchains.foojay-resolver-convention` plugin (docs example version 1.0.0) on Gradle ≥ 8.0.2 so JDKs can be downloaded. Keep `kotlin.jvm.target.validation.mode=error` (default Gradle 8+). [KGP config](https://kotlinlang.org/docs/gradle-configure-project.html)
- Use the **Gradle wrapper**, not a global Gradle. Check KGP↔Gradle table before bumping Gradle (KGP 2.4.21 fully supports ≤ 9.7.0; Gradle 9.8.1 is current). Gradle runs on JDK 17–27. [KGP config](https://kotlinlang.org/docs/gradle-configure-project.html), [Gradle compat](https://docs.gradle.org/current/userguide/compatibility.html)
- Keep Java sources in `src/*/java`, not `src/*/kotlin`: `.java` files in the kotlin dir are not compiled. Don't commit `.kotlin/`. [KGP config](https://kotlinlang.org/docs/gradle-configure-project.html)
- Prefer `-Wextra` for extra K2 diagnostics (`REDUNDANT_NULLABLE`, `UNREACHABLE_CODE`, `CAN_BE_VAL`); fine-grained control with `-Xwarning-level=DIAG:(error|warning|disabled)` (2.2.0+). [whatsnew21](https://kotlinlang.org/docs/whatsnew21.html), [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html)
- Ignored results: enable `-Xreturn-value-checker=check|full` (experimental, 2.3.0); kotlinx.serialization ≥ 1.10 is annotated so `Json.encodeToString(...)` ignored results warn. [whatsnew23](https://kotlinlang.org/docs/whatsnew23.html), [serialization 1.10.0](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.10.0)

## Language (stable in 2.4)
- **Context parameters** (stable 2.4.0, except context arguments & callable refs) replace the removed context receivers: `context(users: UserService) fun f()`. [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html), [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html)
- **Explicit backing fields** stable in 2.4.0 (`val city: StateFlow<String>` + `field = MutableStateFlow("")`) — replaces `_city`/`city` property pairs. [whatsnew23](https://kotlinlang.org/docs/whatsnew23.html), [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html)
- Stable since 2.2: `when` guard conditions (`is Cat if !x`), non-local `break/continue` in inline lambdas, multi-dollar interpolation `$$"..."`. Nested type aliases stable in 2.3.0. [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html), [whatsnew23](https://kotlinlang.org/docs/whatsnew23.html)
- Annotation use-site defaults changed in 2.4 (`param`+`property`); verify validation/DI annotations; `-Xannotation-default-target=first-only` restores. [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html)
- Experimental in 2.4 — do not use in production code without opt-in decision: collection literals (`-Xcollection-literals`), `@IntroducedAt`, explicit context arguments, compile-time const eval. [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html)
- Time: `kotlin.time.Clock` / `Instant` are stable (2.3.0); serializable with kotlinx.serialization ≥ 1.9.0 (`InstantSerializer`). Inject `Clock` for deterministic tests. [whatsnew23](https://kotlinlang.org/docs/whatsnew23.html), [serialization 1.9.0](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.9.0)
- UUID API (`kotlin.uuid.Uuid`) stable in 2.4.0; V4/V7 *generation* still experimental. [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html)
- `readln()`/`readlnOrNull()` instead of `readLine()`. [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html)

## Structured concurrency (kotlinx.coroutines 1.11.0)
- Every coroutine lives in a `CoroutineScope`; parent waits for children, failure/cancel propagates down. **Avoid `GlobalScope`**; use `coroutineScope { }` or an injected, lifecycle-owned scope. Extracted builders: `fun CoroutineScope.launchAll()`; only mark functions `suspend` if they should suspend. [coroutines-basics](https://kotlinlang.org/docs/coroutines-basics.html)
- **Never swallow `CancellationException`**: if you catch it (or `Exception`/`Throwable`) rethrow it. Docs: catching it "can break the cancellation propagation". [coroutines-cancellation.md](https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/topics/coroutines-cancellation.md)
- Cancellation is cooperative: use `ensureActive()`, `isActive`, `yield()` in CPU loops; suspending cancellable functions throw on cancel. [coroutines-cancellation.md](https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/topics/coroutines-cancellation.md)
- Cleanup that must suspend: `withContext(NonCancellable) { ... }` only — **not** as an argument to `launch`/`async` (breaks parent-child). [coroutines-cancellation.md](https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/topics/coroutines-cancellation.md)
- **Do not pass a `Job` to coroutine builders** (1.11.0 lint) — it detaches structure. [1.11.0](https://github.com/Kotlin/kotlinx.coroutines/releases/tag/1.11.0)
- `CoroutineExceptionHandler` only fires for **uncaught** exceptions on **root** coroutines, can't recover; child failures go to the parent. Use `supervisorScope`/`SupervisorJob` deliberately for independent children. [exception-handling.md](https://github.com/Kotlin/kotlinx.coroutines/blob/master/docs/topics/exception-handling.md)

## Performance
- `Dispatchers.Default` for CPU; `Dispatchers.IO` for blocking IO — default parallelism is max(64, cores), tunable via system property `kotlinx.coroutines.io.parallelism`. **`Dispatchers.IO.limitedParallelism(n)` views are elastic and are NOT capped by the IO limit** — use them to isolate/bound pools (e.g. a DB pool of 100). [Dispatchers.kt](https://github.com/Kotlin/kotlinx.coroutines/blob/master/kotlinx-coroutines-core/jvm/src/Dispatchers.kt)
- `limitedParallelism(n, name)` accepts a name for diagnostics (stable since 1.9.0). [release notes](https://github.com/Kotlin/kotlinx.coroutines/releases)
- kotlinx.serialization 1.12.0-RC: ASCII parser speeds Okio/kotlinx-io decoding, up to 30% on large strings (RC only). [v1.12.0-RC](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.12.0-RC)
- Lambdas use `invokedynamic` since 2.0 (smaller binaries). [whatsnew20](https://kotlinlang.org/docs/whatsnew20.html)

## Security
- kotlinx.serialization JSON exception messages historically embed the input JSON; since 1.11.0 set `exceptionsWithDebugInfo = false` (experimental property on `JsonConfiguration`) to avoid logging user data; it becomes default-off when stable. [v1.11.0](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.11.0)
- Deeply nested JSON → stack overflow risk; 1.12.0-RC adds a nesting limit producing `JsonDecodingException` (RC). [v1.12.0-RC](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.12.0-RC)
- Polymorphic serialization: register sealed subclasses with `subclassesOfSealed` (1.10.0); class-discriminator conflict check reworked. [v1.10.0](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.10.0)

## Observability / debugging
- Kotlin 2.4.20 adds experimental `StackTraceRecoverable` + `copyForStackTraceRecovery()` (`@OptIn(ExperimentalStdlibCoroutineSupportApi::class)`) used by coroutines for stack-trace recovery on custom exceptions. [whatsnew2420](https://kotlinlang.org/docs/whatsnew2420.html)
- `kotlinx-coroutines-debug` (no longer shades byte-buddy since 1.10.0). [1.10.0](https://github.com/Kotlin/kotlinx.coroutines/releases/tag/1.10.0)
- Compiler diagnostics flow to Gradle Problems API (2.4.0, JVM; diagnostic IDs in 2.4.20; Gradle 8.6+). [whatsnew2420](https://kotlinlang.org/docs/whatsnew2420.html)

## Testing
- `kotlinx-coroutines-test`: use `runTest { }` (virtual time, auto-skips `delay`, 60 s default timeout; override via `timeout` param); `StandardTestDispatcher` vs `UnconfinedTestDispatcher`; `Dispatchers.setMain` for Main. On JS the result of `runTest` must be returned. [test README](https://github.com/Kotlin/kotlinx.coroutines/blob/master/kotlinx-coroutines-test/README.md)
- `kotlin.test` lazy assertion messages (lambda overloads) — experimental, `@OptIn(ExperimentalKotlinTestApi::class)` (2.4.20). [whatsnew2420](https://kotlinlang.org/docs/whatsnew2420.html)
- NOT SOURCEABLE: a first-party recommendation of a specific mocking library / assertion lib (none searched).
