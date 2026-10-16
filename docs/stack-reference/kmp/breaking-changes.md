# KMP stack — Breaking changes (2025-09 → 2026-10)

Layer: `kmp`. Verified 2026-10-11. `NOT SOURCEABLE` = not stated on any fetched page.

## Swift interop

| Item | Change | Action | Source |
|---|---|---|---|
| Swift Export | **Alpha**. Page: "still incomplete, so breaking changes are expected." Requires `swiftExport { }` config and Xcode task `embedSwiftExportForXcode`; direct integration only. | Do not ship production builds that depend on Swift Export output shape. Pin the Kotlin version if you use it. | [Swift export page](https://kotlinlang.org/docs/native-swift-export.html) |
| Swift Export default state | Kotlin 2.2.20 release notes called it experimental and "now on by default." The current page does not repeat the on-by-default claim. Current default: NOT SOURCEABLE. | Check `build.gradle.kts` for explicit enable/disable. | [Kotlin 2.2.20 notes](https://kotlinlang.org/docs/whatsnew2220.html) (search summary for current-state comparison) |
| Swift Export roadmap | "Swift Export: from Alpha to Beta" (KT-86791) is in focus. No version or date. | Re-check roadmap before each Kotlin upgrade. | [roadmap](https://kotlinlang.org/docs/roadmap.html) |

## Compose Multiplatform

| Release (date) | Change | Action | Source |
|---|---|---|---|
| CMP 1.12.0 (2026-08-25) | Pulls AndroidX Compose 1.12, which requires **compileSdk 37** (per third-party upgrade notes via search summary). Minimum AGP for that chain is stated as 9.1.1 / 9.1.2 / 9.2.0 across sources. | Use AGP 9.4.x (see `../compose/breaking-changes.md`). | [GitHub release v1.12.0](https://github.com/JetBrains/compose-multiplatform/releases/tag/v1.12.0), search summary for compileSdk note |
| CMP 1.12.0 | Experimental MCP server for AI agents in Compose Hot Reload; window/dialog API v2 (experimental). | Opt-in only; not production API. | [JetBrains blog](https://blog.jetbrains.com/kotlin/2026/08/compose-multiplatform-1-12-0/) |
| CMP 1.12.0 (iOS) | iOS selection handles restyled; "Select" added to text-field context menu; swipe-back conflict fixes; `ViewModel.onCleared` now called when Compose container is deallocated. | Re-check iOS text-field screenshots and back-gesture behavior. | [GitHub release v1.12.0](https://github.com/JetBrains/compose-multiplatform/releases/tag/v1.12.0) |
| CMP 1.12.0 (iOS) | Build fix for older Xcode 16 SDK; crash fix on iOS 14 from referencing iOS 15+ API. Minimum Xcode/iOS for 1.12: NOT SOURCEABLE. | Test on your minimum iOS target. | same |
| CMP 1.8.0 (2025-05) | Compose Multiplatform for iOS became Stable. Not a breaking change, but it is the baseline for "iOS stable" claims. | None. | [JetBrains blog, 2025-05](https://blog.jetbrains.com/kotlin/2025/05/kodees-kotlin-roundup-compose-multiplatform-for-ios-is-stable/) |

## Persistence

| Release (date) | Change | Action | Source |
|---|---|---|---|
| Room 3.0.0 (2026-07-01) | New package **`androidx.room3`** (separate from Room 2.x `androidx.room`). **KSP required**: kapt and JavaAP no longer supported. Adds JavaScript and WasmJs KMP targets. | Migrate imports and KSP config (`ksp("androidx.room3:room3-compiler:…")`). Keep Room 2.x on `androidx.room` if you cannot migrate yet. | [Room 3 release page](https://developer.android.com/jetpack/androidx/releases/room3) |
| Room 3.0.x | Migration SupportSQLite wrapper moves to `androidx.room3:room3-sqlite-wrapper`. | Update migration-helper imports. | same |
| Room 2.7.0 | Room became a KMP library (iOS, JVM, native Mac, native Linux). | Informational for 2.x users. | [Room release page](https://developer.android.com/jetpack/androidx/releases/room) |
| Room 2.8.0 | Watch OS and TV OS targets added. | Informational. | same |
| Room 2.8.5 (2026-09-09) | Suspending queries and invalidation tracker operations throw `IllegalStateException` after the database closes. | Handle closed-DB exceptions in coroutine code. | [Room release page](https://developer.android.com/jetpack/androidx/releases/room) |
| SQLDelight 2.4.0 / 2.4.1 | No breaking change stated in the fetched release notes (2.4.1: docs for Android transactions; Gradle plugin keeps parsed `.sq` in memory; IntelliJ plugin crash reports moved to JetBrains Marketplace). | Upgrade normally. | [SQLDelight releases](https://github.com/cashapp/sqldelight/releases) |

## Networking

| Release (date) | Change | Action | Source |
|---|---|---|---|
| Ktor 3.6.0 (2026-09-16) | **KTOR-8594**: non-optional `principal` is now of nullable type. Likely source-breaking for code reading `principal` as non-null (not labelled breaking). | Check auth code for `principal` usage. | [Ktor releases](https://github.com/ktorio/ktor/releases) |
| Ktor 3.6.0 | Notes truncated; no breaking-change section visible on the fetched page. Full notes: NOT SOURCEABLE. | Read the full 3.6.0 release notes before upgrading. | same |
| Ktor (JVM engines) | Older Apache engine **deprecated**; Apache5 recommended for new Apache-based projects. | Migrate from `Apache` to `Apache5`. | [client engines](https://ktor.io/docs/client-engines.html) |

## Project structure and build

| Change | Action | Source |
|---|---|---|
| Recommended structure moves from single `composeApp` module to app entry-point modules + shared modules (`shared`, or `sharedLogic` + `sharedUI`). Single-module layout is described as the "older structure" to migrate from. | Plan migration for existing projects; new projects follow the new default (May 2026). | [recommended structure](https://kotlinlang.org/docs/multiplatform/multiplatform-project-recommended-structure.html), [JetBrains blog, 2026-05](https://blog.jetbrains.com/kotlin/2026/05/new-kmp-default-structure/) |
| AGP 9+: Android entry points must be separated from common code. Shared modules use `com.android.kotlin.multiplatform.library` and `androidLibrary {}` instead of `androidTarget {}`. | Migrate shared modules when moving to AGP 9+. | recommended structure page |
| AGP 9.0 support in IntelliJ IDEA needs IDEA 2026.1.2+ and the latest Android plugin (per the May 2026 blog). | Update tooling before AGP 9 migration. | JetBrains blog, 2026-05 |
| Stability: KMP Android, iOS, JVM and JS are Stable; **Wasm, watchOS, tvOS are Beta**. | Treat Wasm/watchOS/tvOS as beta in production plans. | [supported platforms](https://kotlinlang.org/docs/multiplatform/supported-platforms.html) |
