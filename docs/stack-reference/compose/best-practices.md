# Compose stack — Best practices (fetched 2026-10-11)

Layer: `compose`. Each item cites the official page it comes from. Items marked `NOT SOURCEABLE` were not stated on a fetched page; do not treat them as guidance.

## 1. Recomposition and stability

- **Try strong skipping first.** Enabled by default in Kotlin 2.0.20+; before that set `composeCompiler { enableStrongSkippingMode = true }`. Source: [strong skipping](https://developer.android.com/develop/ui/compose/performance/stability/strongskipping).
- **Make classes stable by construction.** All properties `val`, every property type immutable (primitives, `String` are). Mutable state goes behind `mutableStateOf(...)`. Source: [stability fix](https://developer.android.com/develop/ui/compose/performance/stability/fix).
- **Collections are unstable.** `List`, `Map`, `Set` parameters block skipping. Fix one of three ways: `kotlinx.collections.immutable` (`ImmutableList`, `persistentSetOf`; library still alpha per the page), a wrapper `@Immutable data class`, or a stability config file (`kotlin.collections.*`, only if your code follows the contract). Source: same.
- **`@Stable` / `@Immutable` are contracts, not fixes.** Breaking the contract silently breaks recomposition. Prefer inferred stability; annotate only when you can guarantee it. Source: same.
- **Stability config file** (Compose compiler 1.5.5+): `composeCompiler { stabilityConfigurationFile = ... }`. Supports `*` and `**` wildcards, not partial names. Source: same.
- **Multi-module:** the compiler infers stability only if every referenced non-primitive type is stable or built with the Compose compiler. Enable the compiler in data modules, annotate, or wrap in UI-module types. Source: same.
- **Do not force skippability everywhere.** Use `@NonRestartableComposable` where restart overhead is not worth it. Source: same.

## 2. State collection and UDF

- **Unidirectional data flow.** ViewModel owns data logic and exposes `StateFlow`; UI observes and reports user actions back. Keep UI controllers lean. Source: [lifecycle architecture](https://developer.android.com/topic/libraries/architecture/lifecycle).
- **`collectAsStateWithLifecycle`** for Flows in composables: the page recommends it so collection pauses in the background and saves battery. The page names no module and shows no code; the artifact (`androidx.lifecycle:lifecycle-runtime-compose`) is NOT SOURCEABLE from the fetched pages.
- **Start/stop logic in the composable that needs it** so it is removed when the element leaves composition. Source: lifecycle architecture page.
- **Use coroutines** for long-running and async work in the ViewModel, not the UI. Source: same.

## 3. Navigation

- **Navigation 3 (1.2.0)** is stable: the back stack is app-owned state. Use `NavEntry` and `EntryProvider` keys; make `Scene` implementations data classes (lint since 1.2.0). Source: [navigation3 releases](https://developer.android.com/jetpack/androidx/releases/navigation3).
- **Predictive back:** use `NavigationBackHandler` and `rememberNavigationEventState` (1.2.0) rather than manual back-stack math. Source: same.
- **Results between entries:** `ResultEventBus`, `ResultEffect`, `rememberResultEventBus` (1.2.0). Source: same.
- **Navigation Compose 2.10.2** type-safe-route usage details: NOT SOURCEABLE this session.

## 4. Security (MASVS-relevant platform APIs)

The official pages below cover platform guidance; the MASVS control IDs themselves were not fetched: mapping to MASVS controls is NOT SOURCEABLE.

- **Keys:** use the Android Keystore for keys that must persist. Keys are non-exportable; cryptographic operations run in a system process; request hardware backing (TEE or StrongBox). Check `KeyInfo.getSecurityLevel()` on API 29+. Use `KeyGenParameterSpec.Builder` to restrict purposes, digests, and padding. Source: [Keystore page](https://developer.android.com/privacy-and-security/keystore).
- **Keystore is not for arbitrary secrets.** The page is about cryptographic keys, not passwords or tokens. Keystore hardware binding also requires algorithm support on the device.
- **Keystore on background threads** (the page advises against the main thread). Source: same.
- **Biometric-bound keys:** `setUserAuthenticationParameters()` with `BiometricPrompt`; `setInvalidatedByBiometricEnrollment(false)` keeps keys valid across new enrollments. Source: same.
- **Do not store passwords on the device.** Authenticate once; use short-lived service-specific tokens; prefer Credential Manager and passkeys. Source: [security checklist](https://developer.android.com/privacy-and-security/security-tips).
- **Avoid `EncryptedSharedPreferences` for new code.** `androidx.security:security-crypto` is deprecated (latest 1.1.0, 2025-07-30). Replacement library named by Google: NOT SOURCEABLE on fetched pages. Source: [security releases](https://developer.android.com/jetpack/androidx/releases/security).
- **Secrets:** never commit API keys; inject at build time (checklist mentions `secrets-gradle-plugin` as an example). Use separate dev/test/prod keys and restrict server-side. Source: security checklist.
- **Exported components:** set `android:exported` explicitly; protect with signature permissions; use explicit intents; validate input inside receivers. Source: security checklist.
- **Internal storage** is private by default; avoid `MODE_WORLD_READABLE` / `MODE_WORLD_WRITEABLE`. External storage: non-sensitive data only. Source: security checklist.
- **Parameterized queries** for content providers (no string concatenation into `selection`). Source: same.
- **WebView:** JavaScript off by default; enable only when required. `addJavaScriptInterface` only for fully trusted content. Source: same.
- **Network:** HTTPS everywhere; `SSLSocket` does not verify hostnames (check manually). Source: same.
- **Backup rules:** the security checklist does not cover `allowBackup` or data-extraction rules; the linked backup page was not fetched. Backup configuration: NOT SOURCEABLE this session.

## 5. Credentials and passkeys

- **Credential Manager** (`androidx.credentials` 1.6.0 stable): use for passkeys and sign-in. Restore Credentials requires androidx.credentials 1.5.0+, Play services core 24220000+, Android 9+. Source: [credentials releases](https://developer.android.com/jetpack/androidx/releases/credentials), search summary of [Restore Credentials guide](https://developer.android.com/identity/sign-in/restore-credentials-implementation).
- **Compose text fields** expose a `credentialRequest` semantics property (`CredentialRequestData`) for Credential Manager integration; works on API 34+ through Autofill, and through androidx.credentials below API 34. Source: [August '26 post](https://developer.android.com/blog/posts/what-s-new-in-the-jetpack-compose-august-26-release).

## 6. Edge-to-edge

- Apps targeting **API 35+** draw under system bars and cutouts by default. Source: [insets page](https://developer.android.com/develop/ui/compose/layouts/insets).
- Use `Modifier.windowInsetsPadding(WindowInsets.safeDrawing)` as the default; `safeGestures` for bottom sheets, carousels, and games; `safeContent` for both. Material 3 `Scaffold` reduces work. Source: same.

## 7. Accessibility

- **Content descriptions:** meaningful images get a `contentDescription`; decorative images get `contentDescription = null`. Source: [Compose accessibility](https://developer.android.com/develop/ui/compose/accessibility) overview (topic list only; the overview does not state the rule explicitly).
- **Merge or clear semantics** deliberately (the overview names "merging and clearing" as a topic). Specific API names (`mergeDescendants`, `clearAndSetSemantics`, `heading()`) appeared only in an illustrative snippet from the fetch tool and were not confirmed on the subpages: verify before use.
- **Headings:** the overview names headings/roles as a topic; the API name is unverified (see above).
- **Touch target minimum size:** NOT SOURCEABLE — the fetched overview page gives no minimum; the Material touch-target page was not fetched.
- **Color contrast and text scaling:** overview points to "Support user-scalable content" subpage; contents not fetched. Use the subpage before finalizing.
- **Verify with screenshots and the Compose accessibility checks** (overview lists inspect/debug and testing tools).

## 8. Testing

- **Setup:** `androidTestImplementation("androidx.compose.ui:ui-test-junit4")`; `debugImplementation` for `ui-test-manifest` when using `createComposeRule()`. `createAndroidComposeRule<YourActivity>()` does not need the manifest artifact. Source: [Compose testing](https://developer.android.com/develop/ui/compose/testing).
- **Finders:** `onNodeWithText(...).performClick()` / `.assertIsDisplayed()`. Test tags and semantics finders beyond the example: NOT SOURCEABLE on the fetched page.
- **Coroutine tests:** the v2 testing APIs are the default from Compose 1.11.0; they use `StandardTestDispatcher`. Migrate v1 tests (`UnconfinedTestDispatcher`). Source: [April '26 post](https://developer.android.com/blog/posts/whats-new-in-the-jetpack-compose-april-26-release).
- **Robolectric vs on-device:** the testing page covers instrumented tests and recommends running them in addition to local tests. Robolectric guidance: NOT SOURCEABLE this session.

## 9. Performance: baseline profiles and R8

- **Baseline profiles** target startup, navigation, and scrolling. Generate with the Baseline Profile Gradle plugin (1.2.3 named as the library-profile minimum; AGP 8.3+). Macrobenchmark `1.5.0`; `profileinstaller` `1.4.1` minimum. Binary profile under 1.5 MB to be used on device. Source: [baseline profiles](https://developer.android.com/topic/performance/baselineprofiles/overview).
- **Startup Profiles** (AGP 8.2): cited ~15% extra startup gain; R8 rule rewriting ~15% app performance gain. Both from the baseline profile page.
- **R8 for release:** always enable code and resource shrinking in release (`isMinifyEnabled` and `isShrinkResources` on AGP < 9.3; `optimization { enable = true }` on 9.3+). Source: [R8 page](https://developer.android.com/topic/performance/app-optimization/enable-app-optimization).
- **Do not enable R8 for tests or libraries.** Same source.

## 10. Build hygiene

- **Use the BOM** for all Compose libraries; the Compose compiler is not in the BOM and follows the Kotlin version. Source: [BOM guide](https://developer.android.com/develop/ui/compose/bom).
- **Compose compiler:** apply `org.jetbrains.kotlin.plugin.compose` at the Kotlin version in each Compose module. Source: [compiler page](https://developer.android.com/develop/ui/compose/compiler).
- **Target API 36** (Play, from 2026-08-31); compile against 37 with AGP 9.4.x. Source: [Play target API page](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).
