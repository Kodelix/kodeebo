# Compose stack — Deprecated and removed APIs (as of 2026-10-11)

Layer: `compose`. Verified 2026-10-11. `NOT SOURCEABLE` = no fetched page states the replacement or status.

| API / artifact | Status | Replacement | Source |
|---|---|---|---|
| `Modifier.onFirstVisible()` | **Deprecated** in Compose 1.11.0 (fired repeatedly during lazy scroll) | `Modifier.onVisibilityChanged()` (threshold-based) | [April '26 post](https://developer.android.com/blog/posts/whats-new-in-the-jetpack-compose-april-26-release), [August '26 post](https://developer.android.com/blog/posts/what-s-new-in-the-jetpack-compose-august-26-release) |
| Compose v1 testing APIs (`UnconfinedTestDispatcher`-based) | **Deprecated** in Compose 1.11.0; v2 is default | v2 APIs with `StandardTestDispatcher`; migration guide `/develop/ui/compose/testing/migrate-v2` | [April '26 post](https://developer.android.com/blog/posts/whats-new-in-the-jetpack-compose-april-26-release) |
| `ComposeFoundationFlags.isTextFieldDpadNavigationEnabled` | **Removed** in 1.11.0 (always on) | none; behavior is always on | April '26 post |
| `androidx.compose.material:material-icons` (`material.icons` library) | **No longer recommended; no longer published; removed from latest Material 3** (1.4.0 notes) | Material Symbols | [compose-material3 release page](https://developer.android.com/jetpack/androidx/releases/compose-material3) |
| `material-icons-core` dependency | **No longer added** by Material 3 (1.4.0) | Material Symbols / explicit icon dependency | same |
| Material 3 Expressive APIs (`ExperimentalMaterial3ExpressiveApi`, `ExperimentalMaterial3ComponentOverrideApi`) | **Removed from 1.4.0** (moved to the 1.5.0-alpha line); not available on the stable line | Use Material 3 1.5.0 pre-release (beta, not production-stable) or stay on 1.4.0 without Expressive APIs | Search summary of Material 3 release notes; the 1.4.0 line on the [release page](https://developer.android.com/jetpack/androidx/releases/compose-material3) |
| `TopAppBarDefaults.enterAlwaysScrollBehavior(reverseLayout)` overload | **Deprecated** in 1.5.0-beta01 (restored for 1.4 compatibility) | Use the non-`reverseLayout` overload | [compose-material3 release page](https://developer.android.com/jetpack/androidx/releases/compose-material3) |
| `Slider` / `VerticalSlider` / `RangeSlider` nullable `onValueChange` overloads | **Hidden deprecated** (binary compatibility only) in 1.5.0-beta01 | Non-null `onValueChange` | same |
| `HorizontalCenteredHeroCarousel(maxItemWidth = ...)` | **Renamed** to `preferredItemWidth` in 1.5.0-beta01 | `preferredItemWidth` | same |
| `PolygonShape.transformed()` / `scaledToFit()` extensions | **Replaced** in 1.5.0-beta01 | `transform(...)` and `copy()`; `CornerRounding` top-level with `dp()`/`fraction()` | same |
| Compose Compiler as a standalone artifact (pre-Kotlin-2.0 setup) | **Superseded** by Gradle plugin `org.jetbrains.kotlin.plugin.compose` (Kotlin 2.0+) | Plugin id above, version = Kotlin version | [compiler page](https://developer.android.com/develop/ui/compose/compiler) |
| `androidx.security:security-crypto` (`EncryptedSharedPreferences`, `EncryptedFile`, `MasterKey`) | **Deprecated** (all APIs, since 1.1.0 pre-releases; 1.1.0 stable 2025-07-30; no further releases seen) | Platform Keystore APIs directly; replacement library named by Google: NOT SOURCEABLE | [security releases](https://developer.android.com/jetpack/androidx/releases/security), [Keystore](https://developer.android.com/privacy-and-security/keystore) |
| `getDefaultProguardFile("proguard-android.txt")` | **Not supported** from AGP 9.0 (contains `-dontoptimize`) | `proguard-android-optimize.txt` | [R8 page](https://developer.android.com/topic/performance/app-optimization/enable-app-optimization) |
| Legacy R8 DSL (`isMinifyEnabled`, `isShrinkResources`) | **Legacy**: still supported; AGP 9.3+ new DSL is `optimization { enable = true }` | New DSL on AGP 9.3+ | same. Formal deprecation status: NOT SOURCEABLE (page says "legacy DSL" without a removal date) |
| Modules still on the legacy (non-Variant-API) DSL | **Variant API mandatory from AGP 10** ("Starting with AGP 10, the new Variant API is mandatory for all projects"); opt specific modules out before then with `android.newDsl.optOut` | Variant API | [AGP 9.4.0 notes](https://developer.android.com/build/releases/agp-9-4-0-release-notes) |
| `android.enforceDynamicFeatureVariantMatching` (off by default) | **Warning in 9.4**, **fatal from AGP 10** | Match flavor dimensions 1:1 across dynamic-feature modules | same |
| `androidx.compose.ui` fake-touch trackpad input (1.11.0 change) | **Behavior change**: trackpad events are now `PointerType.Mouse`; not a removal | Update trackpad-dependent code and tests (`performTrackpadInput`) | April '26 post |
| Play targetSdk below 36 for new apps/updates | **Blocked** by Play since 2026-08-31 (extension to 2026-11-01 can be requested) | `targetSdk = 36` | [Play target API page](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en) |
| `Compose 1.12` on compileSdk below 37 | Not deprecated; **requires** compileSdk 37 for Compose 1.12+ | `compileSdk = 37` with AGP 9.4.x | [August '26 post](https://developer.android.com/blog/posts/what-s-new-in-the-jetpack-compose-august-26-release) |

## Removed or sunset packages — no evidence found this session

- `kotlinx-coroutines` and Kotlin deprecations are covered in `../kotlin/deprecated-apis.md`, not here.
- Compose `ui-test` v1 test-rule removal date: NOT SOURCEABLE.
- `androidx.lifecycle` deprecations for 2.11.0: NOT SOURCEABLE (release entry not read in full).
