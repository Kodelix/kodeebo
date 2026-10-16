# Kotlin — Deprecated / removed APIs (verified 2026-10-11)

| Deprecated / removed | Replacement | Since | Source |
|---|---|---|---|
| `kotlinOptions { }` (Gradle) — **error** | `compilerOptions { }`; `freeCompilerArgs +=` → `.add()/.addAll()`; `-Xjvm-default=all` → `jvmDefault = NO_COMPATIBILITY` | deprecated 2.0.0, error 2.2.0 | [whatsnew20](https://kotlinlang.org/docs/whatsnew20.html), [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html), [compiler options](https://kotlinlang.org/docs/gradle-compiler-options.html) |
| K1 compiler, `-language-version=1.9` (removed) | K2 only; fix code or stay on Kotlin ≤ 2.3 | removed 2.4.0 | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| `kotlin-android-extensions` plugin (removed) | `kotlin-parcelize`, view binding | 2.2.0 | [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html) |
| `kotlin-android` plugin with AGP 9.0+ | AGP built-in Kotlin support | 2.3.0 | [whatsnew23](https://kotlinlang.org/docs/whatsnew23.html) |
| Kotlin Android extension `sourceSets` | AGP `android { sourceSets }` | 2.4.0 (warning) | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| `kotlin.io.readLine()` | `readln()` / `readlnOrNull()` | 2.4.0 (warning) | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| `AbstractCoroutineContextKey` family, `getPolymorphicElement()`, `minusPolymorphicKey()` | NOT SOURCEABLE (compat guide gives no replacement; see KT-84970) | 2.4.0 (warning) | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| Property reference to `javaClass` | NOT SOURCEABLE replacement (KTLC-375) | 2.4.0 (warning) | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| `-Xpartial-linkage` | always on; tune with `-Xpartial-linkage-loglevel` | 2.4.0 | [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html) |
| Explicit `shrunkClasspathSnapshot` (BTA) | auto-managed snapshot | 2.4.0 | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| Compose flags `StrongSkipping`, `IntrinsicRemember` (ERROR in 2.4.0, removed 2.5.0); `OptimizeNonSkippingGroups`, `PausableComposition` (deprecated, removed 2.6.0) | `featureFlags`, `stabilityConfigurationFiles` | 2.4.0 | [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html) |
| `KotlinScriptMojo` (Maven) | removed | deprecated 2.2.0, removed 2.4.0 | [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html), [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html) |
| Ant build, REPL default, JSR-223, `kotlinArtifacts` | Ant removed 2.3.0; others deprecated 2.2.0 | 2.2.0/2.3.0 | [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html), [whatsnew23](https://kotlinlang.org/docs/whatsnew23.html) |
| `watchosArm32` Native target | removal planned 2.5.0 | 2.4.20 | [whatsnew2420](https://kotlinlang.org/docs/whatsnew2420.html) |
| `toLowerCase()/toUpperCase()`, `appendln()` (errors) | `lowercase()/uppercase()`, `appendLine()` | error 2.1.0 | [whatsnew21](https://kotlinlang.org/docs/whatsnew21.html) |
| `enumValues<T>()` (in favour of) | `enumEntries<T>()` (stable, more efficient) | 2.0.0 | [whatsnew20](https://kotlinlang.org/docs/whatsnew20.html) |
| Using `CoroutineDispatcher` as a coroutine context key | `ContinuationInterceptor` key | coroutines 1.11.0 | [release 1.11.0](https://github.com/Kotlin/kotlinx.coroutines/releases/tag/1.11.0) |
| Passing `Job` to coroutine builders (lint) | use `coroutineScope`/`supervisorScope`/`withContext`, child scope | coroutines 1.11.0 | [release 1.11.0](https://github.com/Kotlin/kotlinx.coroutines/releases/tag/1.11.0) |
| `BroadcastChannel`, old test API (advanced deprecation) | `SharedFlow`/`StateFlow`; `runTest` | 1.9.0-RC.2 (from release notes fetch; dates unverified) | NOT fully SOURCEABLE — see summary fetch of releases page |
| `GlobalScope` | structured scopes (`coroutineScope`, injected `CoroutineScope`) — doc guidance, `@DelicateCoroutinesApi` | long-standing | [coroutines-basics](https://kotlinlang.org/docs/coroutines-basics.html) |
| `CoroutineDispatcher.limitedParallelism(Int)` single-arg (HIDDEN) | `limitedParallelism(parallelism, name)` | HIDDEN in source | [source](https://github.com/Kotlin/kotlinx.coroutines/blob/master/kotlinx-coroutines-core/common/src/CoroutineDispatcher.kt) |
| `ChunkedDecoder` interface (serialization) | planned removal, no replacement stated | 1.12.0-RC | [v1.12.0-RC](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.12.0-RC) |
