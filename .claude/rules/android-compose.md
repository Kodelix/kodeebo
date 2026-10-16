---
paths:
  - "mobile/android/**/*.kt"
  - "mobile/android/**/*.kts"
  - "mobile/android/**/AndroidManifest.xml"
---

# Android (Jetpack Compose) Rules

Read `docs/stack-reference/compose/` before using Compose or AndroidX APIs you are not certain of at the pinned BOM.

- **Design**: screens follow the product design system and pass `/impeccable` review using its native/Android references; Material components themed, not default-looking.
- Unidirectional data flow: `ViewModel` exposes `StateFlow<UiState>` (immutable), receives events; composables are stateless and previewable; state hoisted.
- Collect flows with `collectAsStateWithLifecycle`; no work in composition; side effects only in `LaunchedEffect`/`DisposableEffect` with correct keys.
- Lists: `LazyColumn` with stable `key`s; mark UI models `@Immutable`/`@Stable` where it prevents recomposition; check with the compiler metrics when a screen is hot.
- Navigation: type-safe routes; deep links validated before acting.
- Background work: WorkManager with constraints; no long work in `Service`s without a foreground justification.
- Security (MASVS): tokens encrypted with a non-exportable Android Keystore key (no `androidx.security:security-crypto` — deprecated, see `docs/stack-reference/compose/deprecated-apis.md`); no secrets in `BuildConfig`; `android:allowBackup` decided explicitly; `FLAG_SECURE` on sensitive screens; exported components minimized.
- Accessibility: content descriptions, touch targets ≥ 48 dp, TalkBack order verified, font scaling to 200 %.
- RTL and Arabic verified; `start`/`end`, never `left`/`right`.
- Performance: baseline profiles, R8 full mode, startup measured with Macrobenchmark.
- Tests: unit tests for ViewModels with fake repositories and a test dispatcher; Compose UI tests for critical screens; screenshots retained as evidence.
