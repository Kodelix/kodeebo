# KMP stack — Best practices (fetched 2026-10-11)

Layer: `kmp`. Each item cites the page it came from. `NOT SOURCEABLE` items were not stated on a fetched page.

## 1. Stability and target selection

- **Ship production on Stable targets**: Android, iOS, Desktop (JVM), Web (Kotlin/JS). Treat Web (Kotlin/Wasm), watchOS, and tvOS as Beta. Source: [supported platforms](https://kotlinlang.org/docs/multiplatform/supported-platforms.html).
- **Pre-stable features emit warnings** when used; check the Kotlin stability table before adopting an experimental API. Source: [components stability](https://kotlinlang.org/docs/components-stability.html) (search summary for the warning behavior).
- **Kotlin/Native runtime, klib binaries, CocoaPods integration: Stable.** C/ObjC interop and cinterop klibs: Beta. Source: components stability.

## 2. Project structure

- **Split entry points from shared code.** Entry-point modules (`androidApp`, `desktopApp`, `webApp`, iOS entry) depend on shared modules. Entry-point code such as `MainActivity.kt` stays in the app module. Source: [recommended structure](https://kotlinlang.org/docs/multiplatform/multiplatform-project-recommended-structure.html).
- **Keep UI and logic apart when a target uses native UI.** Use `sharedLogic` (no Compose dependency, used by all apps) and `sharedUI` (Compose only). A single `shared` module is sufficient if every app shares UI and logic. Source: same.
- **Keep `expect`/`actual` in common modules** so every platform can use the declarations. Source: same.
- **Server projects:** `server` module, client modules under `app/`, and a `core` module for models and validation shared with the server. Source: same.
- **AGP 9+:** shared modules use `com.android.kotlin.multiplatform.library` with `androidLibrary {}`; Android entry points are separate from common code. Source: same.
- **Root build:** declare every plugin used by subprojects with `apply false` in the root build file. Source: same (Gradle statements section).

## 3. Networking (Ktor client)

- **Engines per platform**: Android (Android, OkHttp, CIO), iOS/Apple (Darwin, CIO), JVM (Apache5 for new Apache-based projects, Java, Jetty, OkHttp, CIO), JS (Js, CIO), WasmJs (CIO only). Source: [client engines](https://ktor.io/docs/client-engines.html).
- **Let KMP pick engines** with `ktor-client-engine-defaults` in `commonMain`; add engine dependencies per source set, or use `expect`/`actual` factory functions for explicit control. Source: same.
- **Configure via the client block**: `expectSuccess`, engine config, plugins such as Logging. Source: [create and configure](https://ktor.io/docs/client-create-and-configure.html).
- **Ktor 3.6.0 change to review**: `principal` is nullable (KTOR-8594). Source: [Ktor releases](https://github.com/ktorio/ktor/releases).
- **Ktor version used in this repo**: see `../ktor/VERSION.md` (not re-verified here).

## 4. Persistence

- **Room KMP (`androidx.room3`, 3.0.3)** is the KMP-first Room line. Use KSP, not kapt. Targets: Android, JavaScript, WasmJs (added in 3.0); native targets not listed on the fetched page. Source: [Room 3 release page](https://developer.android.com/jetpack/androidx/releases/room3).
- **Room 2.x (`androidx.room`, 2.8.5)** supports iOS, JVM, native Mac/Linux, watchOS, tvOS per its release notes. Choose 2.x only when you need its existing setup or a target not covered by 3.x. Source: [Room release page](https://developer.android.com/jetpack/androidx/releases/room).
- **Suspending queries after close**: 2.8.5 throws `IllegalStateException`; handle closed-database cases in coroutine code. Source: same.
- **SQLDelight 2.4.1** (latest) is the alternative KMP option. Source: [SQLDelight releases](https://github.com/cashapp/sqldelight/releases). Feature comparison Room 3 vs SQLDelight: NOT SOURCEABLE (no head-to-head page fetched).

## 5. Swift interop and iOS

- **Swift Export is Alpha**: do not depend on its output shape for production; pin Kotlin if you trial it. Source: [Swift export](https://kotlinlang.org/docs/native-swift-export.html).
- **Suspend and Flow interop with Swift Export**: `async` functions and `AsyncSequence` (`asAsyncSequence()`); exported suspend code runs on `Dispatchers.Default` unless you `withContext()`. Source: same.
- **SKIE** (Touchlab) describes itself as a Swift-friendly API generator for KMP. Latest 0.10.15 supports Kotlin 2.4.20 per its release notes. Feature set, Swift Export comparison, and Xcode minimums: NOT SOURCEABLE (SKIE docs not fetched; skie.touchlab.co page returned no version info).
- **Roadmap items to track**: "Make Native Text Input default for iOS" (CMP-10598, in focus), Xcode integration for the Kotlin/Native debugger (KMT-2910, in focus). Source: [roadmap](https://kotlinlang.org/docs/roadmap.html).

## 6. Compose Multiplatform for iOS

- **Stable since CMP 1.8.0** ([JetBrains blog, 2025-05](https://blog.jetbrains.com/kotlin/2025/05/kodees-kotlin-roundup-compose-multiplatform-for-ios-is-stable/)).
- **1.12.0 iOS accessibility**: LiveRegion semantics; VoiceOver handling for `VerbatimTtsAnnotation` and `LocaleList` attributes. Source: [GitHub release v1.12.0](https://github.com/JetBrains/compose-multiplatform/releases/tag/v1.12.0).
- **Locale bridging**: `NSLocale.toComposeLocale()` (1.12.0). Source: same.
- **Interop lifecycle**: `ViewModel.onCleared` fires when the Compose container is deallocated (1.12.0). Source: same.
- **Test the back gesture** against horizontal pagers and RTL (1.12.0 fixed swipe-back conflicts there). Source: same.
- **Compose Compiler and compileSdk**: CMP 1.12 needs compileSdk 37 chain (see `../compose/`). Source: search summary of third-party upgrade notes.
- **Navigation 3 in CMP**: "Stabilize Navigation3" is marked Completed on the roadmap. Official CMP Navigation 3 stability statement: NOT SOURCEABLE beyond the roadmap entry. Source: [roadmap](https://kotlinlang.org/docs/roadmap.html).

## 7. Structure of shared code

- **Put platform-independent logic in `sharedLogic` or `shared`** and only UI code in `sharedUI` when you use Compose Multiplatform. Source: recommended structure page.
- **Keep Compose out of native-UI targets**: a pure-Swift iOS app should not pull in Compose dependencies. Source: same.
- **Migrate `composeApp`** to the new default layout when convenient; the recommended-structure page calls the single-module layout the older structure. Source: same.

## 8. Testing and CI

- **Kotlin test and Gradle commands**: NOT SOURCEABLE in this session (no KMP testing page fetched).
- **Compose UI tests on iOS**: NOT SOURCEABLE in this session.
