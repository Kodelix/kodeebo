# KMP stack — Deprecated and superseded items (as of 2026-10-11)

Layer: `kmp`. Verified 2026-10-11. `NOT SOURCEABLE` = no fetched page states the replacement or status.

| Item | Status | Replacement / note | Source |
|---|---|---|---|
| Ktor JVM **Apache** client engine (older) | **Deprecated** | `Apache5` for new Apache-based projects | [Ktor client engines](https://ktor.io/docs/client-engines.html) |
| Ktor client engine auto-selection | Not deprecated; **CIO** is lowest priority when Ktor auto-selects | Declare engines explicitly, or use `ktor-client-engine-defaults` in `commonMain` | same |
| Room 2.x Kotlin-only `kapt` processing | **Not supported** in Room 3.0 (KSP only) | `ksp("androidx.room3:room3-compiler:…")` | [Room 3 release page](https://developer.android.com/jetpack/androidx/releases/room3) |
| `androidx.room` (Room 2.x) for new KMP work | Superseded for new work by `androidx.room3` (3.0.0, 2026-07-01). Room 2.x support status: NOT SOURCEABLE. | `androidx.room3` | [Room 3 release page](https://developer.android.com/jetpack/androidx/releases/room3), [Room 2.x page](https://developer.android.com/jetpack/androidx/releases/room) |
| `androidTarget {}` in shared modules (AGP 9+ path) | Replaced by `androidLibrary {}` with `com.android.kotlin.multiplatform.library` | Use `androidLibrary {}` in shared modules | [recommended structure](https://kotlinlang.org/docs/multiplatform/multiplatform-project-recommended-structure.html) |
| Single `composeApp` Gradle module containing both shared library and app | "Older structure" per the recommended-structure page | Split into `shared` (or `sharedLogic` + `sharedUI`) and app modules | same; [JetBrains blog, 2026-05](https://blog.jetbrains.com/kotlin/2026/05/new-kmp-default-structure/) |
| KMM evolution page Alpha labels (overall KMM "Alpha") | **Outdated**: KMP has been Stable since Kotlin 1.9.20 | Use the components-stability table | [KMM evolution page](https://kotlinlang.org/docs/mobile/kmm-evolution.html) (flagged as stale by search summary); [components stability](https://kotlinlang.org/docs/components-stability.html) |
| Swift Export "on by default" (Kotlin 2.2.20 notes) | Current Swift export page does **not** repeat that claim; status is **Alpha** | Check build file for explicit config | [Kotlin 2.2.20 notes](https://kotlinlang.org/docs/whatsnew2220.html) (search summary), [Swift export](https://kotlinlang.org/docs/native-swift-export.html) |
| Compose Multiplatform for iOS "Alpha" (2023 blog) | **Outdated**: Stable since CMP 1.8.0 | none | [JetBrains blog, 2025-05](https://blog.jetbrains.com/kotlin/2025/05/kodees-kotlin-roundup-compose-multiplatform-for-ios-is-stable/) |
| `Stabilize Navigation3` roadmap item | Completed (KT-84571) | none | [roadmap](https://kotlinlang.org/docs/roadmap.html) |
| Old `kotlinOptions {}` / K1 compiler references in KMP builds | Covered in `../kotlin/deprecated-apis.md`, not repeated here | see Kotlin layer | `../kotlin/VERSION.md` |

## Unverified or pending

- SKIE: whether any SKIE feature is deprecated: NOT SOURCEABLE.
- SQLDelight: no deprecation found in release notes fetched.
- Swift Export roadmap item "Alpha to Beta" (KT-86791): no date; not a deprecation.
- Ktor `Apache` engine removal date: NOT SOURCEABLE (page says deprecated, no removal date).
