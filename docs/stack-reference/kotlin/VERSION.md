# Kotlin Stack Reference — VERSION

Layer: `kotlin` — Kotlin language + K2 compiler, kotlinx.coroutines, kotlinx.serialization, Gradle + KGP, JDK target.
Last verified: **2026-10-11**. Every claim below was fetched this session; gaps are marked `NOT SOURCEABLE`.

| Field | Value |
|---|---|
| **Current stable Kotlin** | **2.4.21** (bug-fix release), released **2026-10-08** — [releases page](https://kotlinlang.org/docs/releases.html), [GitHub tag v2.4.21](https://github.com/JetBrains/kotlin/releases/tag/v2.4.21) |
| Current language release | 2.4.0 (2026-06-03). Then 2.4.10 (2026-07-14, bug fix), 2.4.20 (2026-09-07, tooling), 2.4.21 (2026-10-08, bug fix). Dates: releases page + GitHub API `published_at` |
| In flight | 2.5.0-Beta1 published 2026-09-23 (GitHub API) — not stable, do not pin |
| Previous line | 2.3.x: 2.3.0 (2025-12-16), 2.3.10, 2.3.20 (2026-03-16), 2.3.21 (2026-04-23) |
| **Support policy** | Kotlin stdlib (JVM) has an **18-month support window per release line** starting with 2.4.0; 2.4 line: released 2026-06-03, end of support **2027-12-03** ([releases page](https://kotlinlang.org/docs/releases.html)). Language 2.x.0 and tooling 2.x.20 share a line. Support policy for the compiler/KGP beyond stdlib: NOT SOURCEABLE (not stated on releases page text fetched). |
| Compiler | **K2 only.** K2 stable/default since 2.0.0 (2024-05-21, [whatsnew20](https://kotlinlang.org/docs/whatsnew20.html)); K1 and `-language-version=1.9` **removed in 2.4** (KT-80590, [compat guide 2.4](https://kotlinlang.org/docs/compatibility-guide-24.html)) |
| **kotlinx.coroutines** | **1.11.0**, released **2026-05-08** ([GitHub release](https://github.com/Kotlin/kotlinx.coroutines/releases/tag/1.11.0)); built on Kotlin 2.2.20. Previous stable 1.10.2 (2025-04-08). No newer stable found 2026-10-11. |
| **kotlinx.serialization** | **1.11.0** stable, **2026-04-09** (Kotlin 2.3.20 base) ([release](https://github.com/Kotlin/kotlinx.serialization/releases/tag/v1.11.0)). **1.12.0-RC** published 2026-09-04 (Kotlin 2.4.10 base) — RC, not stable. 1.10.0 on 2026-01-21. |
| **Gradle** | Current **9.8.1**, buildTime 2026-10-07 (`services.gradle.org/versions/current`). 9.8.0 on 2026-09-24. 8.14.6 maintenance on 2026-10-08. |
| **KGP ↔ Gradle** | KGP 2.4.20–2.4.21: Gradle **7.6.3–9.7.0**, AGP 8.5.2–9.3.1 ([KGP compat table](https://kotlinlang.org/docs/gradle-configure-project.html)). **Gradle 9.8.x is above KGP 2.4.21's fully-supported max (9.7.0)** — doc says newer works but may show deprecations / lose features. |
| **Gradle's own Kotlin** | Gradle 9.8 embeds Kotlin 2.4.10 (Kotlin language level 2.2 for scripts); Gradle tested with Kotlin 2.0.0–2.4.20-RC2 ([Gradle compat](https://docs.gradle.org/current/userguide/compatibility.html)) |
| **JDK to run Gradle** | 17–27 ([Gradle compat](https://docs.gradle.org/current/userguide/compatibility.html)); Java 25 since Gradle 9.1.0, 26 since 9.4.0, 27 since 9.8.0 |
| **Kotlin JVM bytecode** | Kotlin 2.4.0 can emit Java 26 bytecode; 2.3.0 added Java 25; 2.2.0 Java 24; 2.1.0 Java 23 (whatsnew pages) |
| **Recommended pin** | Kotlin **2.4.21**, Gradle **9.8.1** wrapper (accept the >9.7.0 caveat) or **9.7.x** for fully-supported KGP combo — decide per project; kotlinx.coroutines **1.11.0**; kotlinx.serialization **1.11.0** (move to 1.12.0 stable when released; it targets Kotlin 2.4.10); **JDK 25 LTS toolchain** (see below). Ktor 3.6.0 is verified against its own docs in `../ktor/VERSION.md`. |
| JDK LTS facts | Java 8, 11, 17, 21, 25 are LTS; JDK 25 GA 2025-09-16, Oracle Premier Support to Sep 2030; next LTS Java 29 Sep 2027; JDK 21 updates after Sep 2026 move to OTN license ([Oracle roadmap](https://www.oracle.com/java/technologies/java-se-support-roadmap.html), via search summary) |
| **Installed locally** | `java -version`: **OpenJDK 21.0.12.1** (2026-08-18), 64-Bit Server VM. `kotlin -version`: **NOT INSTALLED**. `gradle --version`: **NOT INSTALLED** (use the Gradle wrapper per project). |
| Recommended `jvmTarget` | Set via `kotlin { jvmToolchain(25) }` (or 21 if the CI/host JDK is 21). With a toolchain configured, `jvmTarget` follows the toolchain JDK unless set explicitly; without a toolchain it uses a default (the fetched compiler-options page says `1.8`). Mismatch with `targetCompatibility` fails the build (`kotlin.jvm.target.validation.mode=error` default on Gradle 8+). ([KGP config](https://kotlinlang.org/docs/gradle-configure-project.html), [compiler options](https://kotlinlang.org/docs/gradle-compiler-options.html)) |
| Last verified | 2026-10-11 |

## Verified sources
- https://kotlinlang.org/docs/releases.html
- https://kotlinlang.org/docs/whatsnew24.html , /whatsnew2420.html , /whatsnew23.html , /whatsnew22.html , /whatsnew21.html , /whatsnew20.html
- https://kotlinlang.org/docs/compatibility-guide-24.html
- https://kotlinlang.org/docs/gradle-configure-project.html , /gradle-compiler-options.html
- https://docs.gradle.org/current/userguide/compatibility.html ; https://services.gradle.org/versions/current
- GitHub release APIs: JetBrains/kotlin, Kotlin/kotlinx.coroutines, Kotlin/kotlinx.serialization (tag dates + bodies)
- https://www.oracle.com/java/technologies/java-se-support-roadmap.html (via WebSearch summary)

## Discrepancies noticed
- A fetched summary of `whatsnew24.html` labelled 2.4.0 as "July 14, 2026"; releases page and GitHub tags give **2026-06-03** for 2.4.0 (2026-07-14 is 2.4.10). Treat 2026-06-03 as correct.
- kotlinx.coroutines README still shows "companion to Kotlin 2.2.20" — library is built on 2.2.20 but is used with Kotlin 2.4.x (Gradle tests with 2.4.x); binary-compat promises beyond that: NOT SOURCEABLE.

## Knowledge gap warning (releases after mid-2024 an LLM may not know)
| Release | Date | Why it matters |
|---|---|---|
| Kotlin 2.0.0 | 2024-05-21 | K2 compiler default; `kotlinOptions{}` deprecated for `compilerOptions{}`; lambdas via `invokedynamic` |
| Kotlin 2.1.0 | 2024-11-27 | Preview: `when` guards, non-local break/continue, `$$` interpolation; `-Wextra`; JSpecify strict |
| Kotlin 2.2.0 | 2025-06-23 | Guards/non-local break/multi-dollar **stable**; context parameters preview; `-jvm-default`; `kotlinOptions{}` = error |
| Kotlin 2.3.0 | 2025-12-16 | Nested type aliases stable; unused return value checker (exp); explicit backing fields (exp); Java 25; `kotlin.time.Clock/Instant` stable; Ant dropped |
| Kotlin 2.4.0 | 2026-06-03 | Context parameters + explicit backing fields **stable**; `@all`; UUID API stable; K1 removed; Java 26; Gradle 9.5 |
| Kotlin 2.4.20 | 2026-09-07 | Coroutine stack-trace recovery API (exp); `kotlin` runner command → `kotlinr`; `when` indy on JVM 21+ stable; Gradle 9.7 |
| kotlinx.coroutines 1.10.0 | 2024-12-19 | `Flow.any/all/none`; debug/core split-package fix |
| kotlinx.coroutines 1.11.0 | 2026-05-08 | `CoroutineDispatcher` as context key deprecated; Job-to-builder lint; JS/Wasm Promise move |
| kotlinx.serialization 1.9.0 | 2025-06-27 | `kotlin.time.Instant` serializers (kotlinx-datetime 0.7 dropped its own) |
| kotlinx.serialization 1.10.0 | 2026-01-21 | Many Json options stabilized; `subclassesOfSealed` |
| kotlinx.serialization 1.11.0 | 2026-04-09 | Public `JsonException` hierarchy; `exceptionsWithDebugInfo` |
| Gradle 9.x | 2025–2026 | Gradle 9.8.1 current; needs JVM 17+; Kotlin DSL embeds Kotlin 2.4.10 |
