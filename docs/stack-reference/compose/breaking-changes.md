# Compose stack — Breaking changes (2025-09 → 2026-10)

Layer: `compose`. Verified 2026-10-11. Each row cites the page it came from. `NOT SOURCEABLE` = not stated on any fetched page.

## Compose UI / Runtime / Foundation

| Release (date) | Change | Action | Source |
|---|---|---|---|
| 1.11.0 (2026-04-22) | v2 testing APIs become the default. v1 deprecated. v2 uses `StandardTestDispatcher` (queues coroutines until virtual clock advances) instead of `UnconfinedTestDispatcher`. Tests may surface races and need changes. | Migrate tests to `runTest` / v2 APIs; expect failures in old `UnconfinedTestDispatcher` tests. | [April '26 post](https://developer.android.com/blog/posts/whats-new-in-the-jetpack-compose-april-26-release) |
| 1.11.0 | `ComposeFoundationFlags.isTextFieldDpadNavigationEnabled` removed; D-pad TextField navigation always on (cursor moves first, focus only at end of text). | Remove the flag from code. | April '26 post |
| 1.11.0 | `Modifier.onFirstVisible()` deprecated (fired repeatedly during lazy scrolling). | Use `Modifier.onVisibilityChanged()`. | April '26 post; re-stated in [August '26 post](https://developer.android.com/blog/posts/what-s-new-in-the-jetpack-compose-august-26-release) |
| 1.12.0 (2026-08-12) | `compileSdk` raised to **API 37**. Compose "will always target the latest compileSdk." | Set `compileSdk = 37`; upgrade AGP (see AGP row below). | August '26 post; [AGP table](https://developer.android.com/build/releases/about-agp) |
| 1.12.0 | **Minimum AGP for compileSdk 37 is stated three ways**: 9.1.1 (AGP API-level table), 9.1.2 (August '26 post), 9.2.0 (third-party-reported release-note text, not seen on the compose-ui 1.12.0 entry). | Pin AGP 9.4.x, which meets all three. Exact floor: NOT SOURCEABLE. | sources above |
| 1.12.0 | Compose Multiplatform 1.12 pulls AndroidX Compose 1.12, which needs compileSdk 37+. | Applies to KMP projects too. | Search summary of third-party CMP 1.12 upgrade notes (not an official page; see `kmp/VERSION.md`) |
| 1.13.0-alpha03 (2026-09-09) | Compose libraries' `compileSdk` set to 37.1. | Pre-release only; do not depend on 1.13 in production. | [compose-ui releases](https://developer.android.com/jetpack/androidx/releases/compose-ui) |

## Material 3

| Release (date) | Change | Action | Source |
|---|---|---|---|
| 1.4.0 (2025-09-24) | `androidx.compose.material:material-icons` no longer published and removed from latest release; use Material Symbols. | Replace icon imports. | [compose-material3 releases](https://developer.android.com/jetpack/androidx/releases/compose-material3) |
| 1.4.0 | Nav bar and rail item **active label color** changed from `onSurface` to `secondary`. Components use new `MotionScheme`. | Re-check theme contrast and screenshots. | same |
| 1.4.0 | Expressive APIs removed from the 1.4.0 line (moved to 1.5.0-alpha). | Do not reference `ExperimentalMaterial3ExpressiveApi` on 1.4.0. | Expressive status: [Material 3 release page](https://developer.android.com/jetpack/androidx/releases/compose-material3) (search summary for the removal note) |
| 1.5.0-alpha23 (2026-07-01) | Expressive list items and `TopAppBar`, `MediumFlexibleTopAppBar`, `LargeTopAppBar`, `LargeFlexibleTopAppBar`, `TwoRowsTopAppBar`, `FlexibleBottomAppBar` no longer need `@ExperimentalMaterial3ExpressiveApi`. | Alpha only. | same |
| 1.5.0-alpha29 (2026-09-23) | **Source-breaking**: `onValueChange` is now a required parameter of `Slider` and `RangeSlider`; its position in the parameter list changed. | Alpha only; update call sites when adopting 1.5.x. | same |
| 1.5.0-beta01 (2026-10-07) | `PolygonShape`: `CornerRounding` moved to top level (`dp()`, `fraction()` factories); `transformed()` / `scaledToFit()` replaced by `transform(...)` and `copy()`. `HorizontalCenteredHeroCarousel` param `maxItemWidth` renamed `preferredItemWidth`. `enterAlwaysScrollBehavior(reverseLayout)` deprecated. `DraggableState` restored on `SliderState`. | Beta only. | same |

## Navigation 3 / Navigation Compose

| Release (date) | Change | Action | Source |
|---|---|---|---|
| Navigation 3 1.0.0 (2025-11-19) | First stable. Pre-releases: 1.0.0-beta01 (2025-10-22), 1.0.0-rc01 (2025-11-05). | Use 1.2.0 now. | [Nav3 stable post](https://android-developers.googleblog.com/2025/11/jetpack-navigation-3-is-stable.html), [navigation3 releases](https://developer.android.com/jetpack/androidx/releases/navigation3) |
| Navigation 3 1.0.1 (2026-02-11) | Depends on NavigationEvent 1.0.2 (fixes `IllegalStateException` with `NavDisplay` in Studio previews). | none beyond bumping. | navigation3 releases |
| Navigation 3 1.2.0 (2026-09-23) | `NavEntry.contentKey` defaults to composite of key string form and class. `EntryProvider` prioritizes key instances over key types. New lint: `Scene` implementations must be data classes or implement `equals` / `hashCode`. | Check `contentKey` assumptions; make `Scene` impls data classes. | navigation3 releases (1.2.0 entry) |

## Lifecycle / ViewModel

| Release (date) | Change | Action | Source |
|---|---|---|---|
| lifecycle 2.11.0 (2026-06-17) | Stable line; 2.12.0-alpha01..04 in flight. Breaking changes for 2.11: NOT SOURCEABLE (not fetched). | Read the 2.11.0 release entry before upgrading. | [all-channel](https://developer.android.com/jetpack/androidx/versions/all-channel) |

## Android Gradle Plugin (AGP)

| Release (date) | Change | Action | Source |
|---|---|---|---|
| AGP 9.0 | `getDefaultProguardFile("proguard-android.txt")` no longer supported (it contains `-dontoptimize`). Optimized resource shrinking on by default; Kotlin null-check optimization on by default. | Use `proguard-android-optimize.txt`. | [R8 page](https://developer.android.com/topic/performance/app-optimization/enable-app-optimization) |
| AGP 9.0 | Library consumers must use same-or-higher compileSdk by default; `AarMetadata.minCompileSdk` can override. | Align compileSdk across libs. | Search summary only (not re-fetched from an official page): NOT SOURCEABLE as a primary citation |
| AGP 9.1 | Classes repackaged by default (R8). | Check keep rules for reflection. | R8 page |
| AGP 9.3 | Optimized resource shrinking always enabled. Default Android keep rules become opt-out. New DSL: `optimization { enable = true }`; keep rules in `src/<variant>/keepRules/*.keep`. Legacy DSL still supported. | Migrate DSL when on 9.3+. | R8 page |
| AGP 9.4.0 (2026-09) | Variant API becomes **mandatory in AGP 10**; opt specific modules out with `android.newDsl.optOut`. Dynamic-feature flavor parity: warning now, fatal in AGP 10. Gradle min 9.6.0. | Set `android.enforceDynamicFeatureVariantMatching=true` to test the AGP 10 behavior early. | [AGP 9.4.0 notes](https://developer.android.com/build/releases/agp-9-4-0-release-notes) |

## Google Play policy

| Effective | Change | Action | Source |
|---|---|---|---|
| 2026-08-31 | New apps and app updates **must target API 36 (Android 16)**. Extension request to 2026-11-01. | `targetSdk = 36`. | [Play target API page](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en) |
| 2026-08-31 | Existing apps: must target API 35 to remain discoverable to new users on newer Android. | Check target. | same |
| 2026-08-31 | Wear OS and Android Automotive new apps: API 35. Android XR new apps: API 34 (also 2026-08-31). Android TV new apps: API 34 (effective 2025-08-31). | Per form factor. | same |

## Security / credentials

| Release (date) | Change | Action | Source |
|---|---|---|---|
| security-crypto 1.1.0 (2025-07-30) | All security-crypto APIs deprecated in favor of platform APIs and direct Keystore use. No planned releases seen. Replacement library named: NOT SOURCEABLE on the fetched page (third-party blogs point to Tink + DataStore; not official). | Plan migration off `EncryptedSharedPreferences` / `EncryptedFile`. | [security releases](https://developer.android.com/jetpack/androidx/releases/security) |
| androidx.credentials 1.6.0 | Stable. Passkeys: Android 9 (API 28)+ per third-party summary of the Credential Manager docs. Restore Credentials: androidx.credentials 1.5.0+, Play services core 24220000+. | Pin 1.6.0. | [credentials releases](https://developer.android.com/jetpack/androidx/releases/credentials) |
