---
paths:
  - "mobile/ios/**/*.swift"
  - "mobile/ios/**/Package.swift"
---

# iOS (SwiftUI) Rules

Read `docs/stack-reference/swiftui/` before using SwiftUI/Swift APIs you are not certain of at the pinned SDK.

- **Design**: screens follow the design system and pass `/impeccable` review using its iOS references; native controls and HIG behaviour, not web-looking UI.
- Swift 6 strict concurrency: no data races; UI types and view models are `@MainActor`; shared mutable state behind actors; `Sendable` conformance correct, not silenced.
- View models use `@Observable`; views stay small and composable; dependencies injected, not reached through singletons.
- Async work via `async/await` and `Task` tied to view lifecycle (`.task {}`); no detached tasks without a cancellation story.
- Networking through the shared KMP client or a generated client; no ad-hoc `URLSession` calls scattered in views.
- Security (MASVS): tokens in Keychain with appropriate accessibility class; ATS on; no secrets in the bundle; sensitive screens hidden in the app switcher; privacy manifest maintained.
- Accessibility: VoiceOver labels and order, Dynamic Type to accessibility sizes, sufficient contrast, reduced motion respected.
- RTL and Arabic verified; leading/trailing, never left/right.
- Lint: SwiftLint clean; warnings treated as errors in CI.
- Tests: Swift Testing for logic and view models; XCUITest for critical journeys; screenshots retained as evidence.
