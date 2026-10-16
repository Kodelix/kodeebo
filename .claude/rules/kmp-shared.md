---
paths:
  - "mobile/shared/**"
---

# Kotlin Multiplatform Shared Module Rules

- `commonMain` holds domain, use cases, repository ports, the Ktor client and serialization. Platform code (`androidMain`, `iosMain`) holds only platform adapters.
- `expect`/`actual` only for genuinely platform-specific capabilities (secure storage, crypto RNG, connectivity); prefer interfaces injected from the platform.
- No Android or Apple types in `commonMain`.
- The API client is generated from `contracts/` or hand-mapped behind a port — DTOs never leak into domain.
- Coroutines: expose `Flow`/`suspend` APIs; provide Swift-friendly wrappers (or the chosen interop tool, per ADR) so iOS does not leak coroutine scopes.
- Local persistence (SQLDelight or the ADR-chosen store) with migrations versioned and tested.
- Offline-first features define sync, conflict resolution and retry in the spec; the shared module owns that logic once.
- Binary size and public API surface exported to iOS are kept minimal (`internal` by default).
- Tests in `commonTest` run on both JVM and iOS targets in CI.
