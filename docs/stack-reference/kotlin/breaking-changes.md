# Kotlin — Breaking / behaviour changes (2.0 → 2.4.21, coroutines, serialization, Gradle)

Verified 2026-10-11. Each row has a source. Stable-only unless marked.

## Kotlin language / compiler

| Since | Change | Impact / action | Source |
|---|---|---|---|
| 2.0.0 | **K2 compiler default** on all platforms; stricter source-set separation (common code can't see platform declarations) | Smart-cast behaviour changes; with Gradle < 8.3 K2 can break `buildSrc` / included-build plugins — upgrade Gradle or set language 1.9 (1.9 no longer possible on 2.4) | [whatsnew20](https://kotlinlang.org/docs/whatsnew20.html) |
| 2.0.0 | Lambdas compiled with `invokedynamic` by default: not serializable (unless `@JvmSerializableLambda`), not visible to reflection, `toString()` less readable | Java-serialization or reflection of lambdas breaks; `-Xlambdas=class` restores | [whatsnew20](https://kotlinlang.org/docs/whatsnew20.html) |
| 2.0.0 | Data dir moved `.gradle/kotlin` → `.kotlin/` | add `.kotlin/` to `.gitignore` | [whatsnew20](https://kotlinlang.org/docs/whatsnew20.html), [KGP config](https://kotlinlang.org/docs/gradle-configure-project.html) |
| 2.1.0 | Locale-sensitive `toLowerCase()/toUpperCase()` and `appendln()` now **errors** | use `lowercase()/uppercase()`, `appendLine()` | [whatsnew21](https://kotlinlang.org/docs/whatsnew21.html) |
| 2.1.0 | JSpecify nullability mismatches are errors by default; Gradle min 7.6.3, AGP min 7.3.1 | Java-interop nullability errors appear | [whatsnew21](https://kotlinlang.org/docs/whatsnew21.html) |
| 2.2.0 | `kotlinOptions{}` Gradle block is an **error** (use `compilerOptions{}`); `-language-version` 1.6/1.7 removed; `kotlin-android-extensions` plugin removed | migrate DSL; see below | [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html) |
| 2.2.0 | `KotlinCompileTool.setSource()` now **replaces** sources (use `source()` to add) | custom Gradle tasks | [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html) |
| 2.2.0 | `-jvm-default` modes: `enable` (default), `no-compatibility`, `disable`; replaces `-Xjvm-default=all/all-compatibility` | interface default-method codegen | [whatsnew22](https://kotlinlang.org/docs/whatsnew22.html), [compiler options](https://kotlinlang.org/docs/gradle-compiler-options.html) |
| 2.3.0 | `-language-version=1.8` dropped (1.9 only JVM); Ant build unsupported; AGP 9.0+ deprecates `kotlin-android` plugin (built-in Kotlin) | | [whatsnew23](https://kotlinlang.org/docs/whatsnew23.html) |
| 2.3.0 | Min AGP 8.2.2; `macosX64/iosX64/tvosX64/watchosX64` Tier 3 | KMP only | [whatsnew23](https://kotlinlang.org/docs/whatsnew23.html) |
| **2.4.0** | **K1 compiler and `-language-version=1.9` removed** (KT-80590) | Error now | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| 2.4.0 | Default annotation use-site target now `param` AND `property` (KTLC-391); old behaviour via `-Xannotation-default-target=first-only` | **Hits Ktor/Jakarta/Jackson/validation annotations on constructor properties** | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| 2.4.0 | Warnings → errors: always-false `is` checks (KTLC-365); exposing lower-visibility types in inline fns (KTLC-283); implicit refs to inaccessible types (KTLC-384, KTLC-363); Jakarta `@Nullable/@Nonnull` enforced (KTLC-285); `::class` on reified nullable-bound type params (KTLC-370); non-exhaustive `when` on non-abstract Java sealed classes (KTLC-366); array literals outside annotations (KTLC-369); `inline` on enum entries (KTLC-361); wrong-arity `operator getValue/setValue` (KTLC-289); initialization before declaration in anonymous objects (KTLC-290); inconsistent type args vs upper bound (KTLC-373); flexible explicit nullable type args for Java types (KTLC-284) | Code that compiled with warnings on 2.2/2.3 now fails | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| 2.4.0 | Function references with different vararg conversions are now unequal (KTLC-385) | rare | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| 2.4.0 | `Random.nextDouble(from, until)` requires finite `until` (KT-84368) | | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| 2.4.0 | JVM default module name now `{group}:{project_name}` (revert: `compilerOptions.moduleName(project.name)`) | affects `internal` name mangling across modules | [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html) |
| 2.4.0 | Annotations-in-metadata enabled by default; AGP min 8.5.2; Kotlin/Native CMS GC default, LLVM 21, iOS/tvOS min 15 | | [whatsnew24](https://kotlinlang.org/docs/whatsnew24.html) |
| 2.4.20 | `when` on JVM 21+ compiles with `invokedynamic` by default (stable) | bytecode shape changes (sealed/enum `when`) | [whatsnew2420](https://kotlinlang.org/docs/whatsnew2420.html) |
| 2.4.20 | `kotlin` runner command replaced by `kotlinr` (using `kotlin` warns) | scripts/CI calling `kotlin` | [whatsnew2420](https://kotlinlang.org/docs/whatsnew2420.html) |

## Gradle / KGP
| Since | Change | Source |
|---|---|---|
| 2.4.0 | Removal of deprecated Gradle task/compilation/DSL APIs (KT-85509); legacy Kotlin/JS compiler-type selection is an error (KT-64275); `sourceSets` in Kotlin Android extension deprecated → use AGP `android { sourceSets }` (KT-74451); obsolete Compose compiler options error (KT-85343) | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| 2.4.0 | Binary-compat-validation DSL streamlined; use `abiValidation {}` directly (KT-80685) | [compat 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html) |
| 2.4.x | KGP 2.4.20–2.4.21 fully supports Gradle ≤ 9.7.0; Gradle current is 9.8.1 | [KGP compat](https://kotlinlang.org/docs/gradle-configure-project.html), [services.gradle.org](https://services.gradle.org/versions/current) |
| any | JVM target mismatch between `compileKotlin` and `compileJava` fails build on Gradle 8+ (`kotlin.jvm.target.validation.mode=error`) | [KGP config](https://kotlinlang.org/docs/gradle-configure-project.html) |

## kotlinx.coroutines
| Version | Change | Source |
|---|---|---|
| 1.10.0 (2024-12-19) | Kotlin 2.1.0 base; `kotlinx.coroutines.debug.AgentPremain` → `kotlinx.coroutines.debug.internal.AgentPremain`; byte-buddy no longer shaded in debug artifact | [release 1.10.0](https://github.com/Kotlin/kotlinx.coroutines/releases/tag/1.10.0) |
| **1.11.0 (2026-05-08)** | Using `CoroutineDispatcher` as the context **key** deprecated → `ContinuationInterceptor`; `kotlinx-coroutines-test` deprecation levels advanced; lint flags passing `Job` to coroutine builders; JS/Wasm: `Promise` functions moved to `web` target, Wasm/JS accepts only `JsAny` subtypes; unpropagatable exceptions on JS reported to runtime not logged | [release 1.11.0](https://github.com/Kotlin/kotlinx.coroutines/releases/tag/1.11.0) |
| 1.11.0 | New: `runBlocking`/`suspendCancellableCoroutine` `callsInPlace(EXACTLY_ONCE)` contracts; `SharedFlow.asFlow`, `CompletableDeferred.asDeferred`, `ReceiveChannel.consumeTo`, Flow→Map terminal ops | same |
| 1.11.0 | Fixed `flowOn` mishandling `ThreadContextElement`, `SharedFlow` invalid state on simultaneous cancel, R8 GC of `shareIn/stateIn` | same |

## kotlinx.serialization
| Version | Change | Source |
|---|---|---|
| 1.9.0 (2025-06-27) | Needs Kotlin 2.2; `kotlin.time.Instant` serializers; kotlinx-datetime 0.7.0 no longer ships Instant serializers | [v1.9.0](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.9.0) |
| 1.10.0 (2026-01-21) | Json options `decodeEnumsCaseInsensitive`, `allowTrailingComma`, `allowComments`, `prettyPrintIndent`, `@EncodeDefault` no longer experimental; class-discriminator conflict check reworked (#3105); API marked for return-value checker | [v1.10.0](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.10.0) |
| 1.11.0 (2026-04-09) | `JsonException`/`JsonDecodingException`/`JsonEncodingException` public (experimental); `exceptionsWithDebugInfo` added — **will become default-off (input hidden) once stable** | [v1.11.0](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.11.0) |
| 1.12.0-RC (2026-09-04, **RC**) | Every exception in deserialization wrapped into `JsonException`; Json nesting depth limited (proper `JsonDecodingException` not StackOverflow); `ChunkedDecoder` deprecated; `@KeepGeneratedSerializer`, `@SerialInfo`, `JsonNamingStrategy`, `ContextualSerializer` stabilized | [v1.12.0-RC](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.12.0-RC) |

## Migration snippets (sourced)
```kotlin
// 2.0+: kotlinOptions -> compilerOptions (kotlinOptions is an ERROR since 2.2.0)
kotlin { compilerOptions { jvmTarget = JvmTarget.fromTarget("17"); optIn.add("kotlin.RequiresOptIn") } }
// Source: https://kotlinlang.org/docs/gradle-compiler-options.html
```
