# SwiftUI / Swift 6.4 / Xcode 27 — Breaking and Behaviour Changes

Verified 2026-10-11. Every line cites a page fetched in this run. Items marked `[secondary]` come from a search summary or third-party page. `NOT SOURCEABLE` means the search or fetch failed or did not return the content.

## Toolchain and host requirements (Xcode 27)

- Xcode 27 ships Swift 6.4 and SDKs for iOS 27, iPadOS 27, tvOS 27, watchOS 27, macOS 27, visionOS 27. Xcode 27 requires macOS Tahoe 26.6 or later. Source: https://developer.apple.com/tutorials/data/documentation/xcode-release-notes/xcode-27-release-notes.json
- Xcode 27 installs and runs only on Apple silicon Macs. Source: same.
- Targets with macOS 27.0 or DriverKit 27.0 deployment target no longer build Universal by default. `ARCHS_STANDARD` drops x86_64 when `MACOSX_DEPLOYMENT_TARGET` or `DRIVERKIT_DEPLOYMENT_TARGET` is 27.0 or higher. Add x86_64 to `ARCHS` if needed. Source: same.
- The ld64 linker is removed. `-ld_classic` is no longer supported. Source: same.
- On Demand Resources and `NSBundleResourceRequest` are deprecated. Use Background Assets instead. Source: same.
- Instruments: target iOS, watchOS and tvOS devices must run at least iOS 17, watchOS 10 or tvOS 17. Source: same.
- `devicectl` JSON version 5: `hardwareProperties`, `deviceProperties`, `connectionProperties` are deprecated. Use the `properties` dictionary. Source: same.
- Swift Build becomes the default build system in Swift Package Manager. Source: https://www.swift.org/blog/swift-6.4-released/
- Swift dependency scanner: every Clang module reachable from one scan action must have a unique name. Duplicate names across module maps may now error. Common causes: the same module vended from several header search paths, and vendored `module.modulemap` files that redeclare an SDK module. Source: xcode-27-release-notes.json (Swift Compiler, New Features).
- Known source break (SE-0508): a computed property with both an `init` accessor and an array/dictionary literal initial value no longer compiles if the getter is declared before the `init` accessor. Workaround: declare the `init` accessor first. Source: xcode-27-release-notes.json (Swift Compiler, Known Issues).

## Swift 6.4 language and runtime

- SE-0493: async calls are allowed inside `defer`. The defer is awaited before scope exit. Source: https://www.swift.org/blog/swift-6.4-released/ ; https://developer.apple.com/videos/play/wwdc2026/262/
- SE-0504: `withTaskCancellationShield` runs a closure shielded from the enclosing task's cancellation. Source: swift-6.4-released.
- SE-0522: `@diagnose` attribute controls warnings at source level, including suppression or promotion to errors. Source: swift-6.4-released.
- SE-0491: module selectors `::` disambiguate same-named types from different modules. Source: swift-6.4-released.
- SE-0521: optional `some`/`any` no longer needs parentheses. Syntax relaxation, not a break. Source: swift-6.4-released.
- SE-0532: optionals of non-copyable types can be inspected or updated without consuming them. Source: swift-6.4-released.
- New diagnostic: Swift warns when an error thrown inside a `Task` is silently ignored. This can fail builds that treat warnings as errors. Source: https://developer.apple.com/videos/play/wwdc2026/262/
- `for` loops prefer `Sequence` and fall back to the new `Iterable` protocol. Loops over `Iterable` forbid mutating the collection during iteration (exclusivity). Source: wwdc2026/262.
- `Sendable`: `weak let` lets a class conform to `Sendable` without `@unchecked`. `~Sendable` explicitly opts a type out. Source: wwdc2026/262.
- Strict concurrency defaults, default-isolation build setting names, and Swift 6.4 strict-concurrency changes: NOT SOURCEABLE. The Swift 6.4 post does not cover them. The Swift 6 concurrency adoption page returned HTTP 404. (Searched: developer.apple.com/documentation/xcode/adopting-strict-concurrency-in-swift-6-apps.)

## Swift Testing and XCTest interop (Swift 6.4 / Xcode 27)

- ST-0021: `XCTAssert` works inside Swift Testing tests. `#expect` works inside XCTest tests. Source: https://www.swift.org/blog/swift-6.4-released/
- A failed XCTest assertion inside a Swift Testing test (or the reverse) is reported as a runtime issue with warning severity by default. A test plan setting, "Swift Testing and XCTest Interoperability", controls this. Source: xcode-27-release-notes.json (Testing, New Features). Also wwdc2026/262: assertion warnings can be promoted to failures in Xcode build settings.
- ST-0024: per-test-case repetitions via `swift test`. The `--maximum-repetitions` and `--repeat-until [pass|fail]` flags are new. Source: xcode-27-release-notes.json (Swift Package Manager).
- Test Repetition Mode repeats individual Swift Testing test cases, not the whole test plan. Source: xcode-27-release-notes.json.
- ST-0029 (recently accepted): extra issue metadata in the event stream. Source: https://www.swift.org/blog/whats-new-in-swift-september-2026/
- New `XCUIVoiceOverService` API drives and verifies VoiceOver in UI tests. Source: xcode-27-release-notes.json (Testing, adjacent).

## Concurrency and Foundation (Swift 6.4)

- `ProgressManager` gains async/await support (SF-0023). Source: swift-6.4-released.
- SE-0506: `@Observable` gives fine-grained, continuous change notifications. Source: swift-6.4-released (Foundation list). The page does not state whether existing code changes behaviour.
- `Subprocess` 1.0 is a cross-platform process API built on Swift concurrency. Source: swift-6.4-released.

## Default actor isolation and approachable concurrency (Swift 6.2 baseline)

- Swift 6.2 adds an option to isolate code to the main actor without explicit `@MainActor` annotations. Flag shown as `-default-isolation MainActor`. Source: https://www.swift.org/blog/swift-6.2-released/
- `NonisolatedNonsendingByDefault` (upcoming feature): async functions run in the caller's context, including the main actor. Before, `nonisolated async` always hopped to the global concurrent executor. Source: swift-6.2-released.
- `@concurrent` marks code that runs on the concurrent thread pool. Source: swift-6.2-released.
- Swift 6.2 migration tooling warns about patterns that will no longer compile or will change behaviour under the upcoming feature. Source: swift-6.2-released.
- Xcode build setting name `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and SwiftPM `.defaultIsolation(MainActor.self)`: `[secondary]` search summary (https://forums.swift.org/t/default-actor-isolation-mainactor-conflicts-with-sendable/87819 and https://www.massicotte.org/blog/what-settings/). Not verified on Apple pages.
- SE-0466 (control default actor isolation inference) full text: NOT SOURCEABLE. The swift-evolution GitHub pages returned HTTP 503 and 403 in this run. A search returned forum discussion of an amendment that disables `@MainActor` inference for types conforming to protocols inheriting `SendableMetatype`. Amendment status: NOT SOURCEABLE.
- Known friction `[secondary]`: default MainActor can conflict with `Sendable` conformances and class overrides; a compiler crash under `-O` with approachable concurrency was reported for Swift 6.2 / Xcode 26. Source: https://forums.swift.org/t/swift-6-2-approachable-concurrency-default-actor-isolation-with-core-data-transformable-type/82323

## SwiftUI (iOS 27 SDK, Xcode 27)

Source-breaking:
- `@State` is now a macro. Classes stored in `@State` are initialized lazily, once per view lifetime. Before, a new instance was created on every parent-driven re-init and discarded. Backported to iOS 17, macOS 14 and aligned releases. Source: https://developer.apple.com/videos/play/wwdc2026/269/
- Source break: a default value on `@State` plus assignment in `init` produces "Variable 'self.x' used before being initialized". Fix: remove the default value and assign in `init`. Source: wwdc2026/269 (cites TN3211). TN3211 page content NOT SOURCEABLE in this run (page returned title only).
- `ViewBuilder` closures are type-agnostic in Xcode 27 and later. Mark closures with `ContentBuilder` where your code expects this. Source: https://developer.apple.com/tutorials/data/documentation/swiftui/viewbuilder.json (deprecation flag: false; not deprecated).
- Deprecations (see deprecated-apis.md): `NavigationView`, `foregroundColor(_:)`, `presentationMode`, `navigationBarItems(leading:trailing:)`, `navigationBarTitle(_:)`, `cornerRadius(_:antialiased:)`, `PreviewProvider`.

Behaviour changes (no code change required):
- `AsyncImage` caches by default, respecting server cache headers. Custom control: `asyncImageURLSession(_:)` and `AsyncImage(request:)`. Source: wwdc2026/269.
- Confirmation dialogs and alerts accept item binding like sheets: `.confirmationDialog(_:item:)`, `.alert(_:item:)`. Source: wwdc2026/269.
- Liquid Glass is adopted automatically when linking the new SDK. Source: wwdc2026/269.
- iPad inactive-window icons and text dim automatically. Source: wwdc2026/269.
- iPhone apps become resizable on iOS 27. Source: wwdc2026/269.
- Menu bars on iPad and Mac show a minimal icon set by default. Opt in with `.labelStyle(.titleAndIcon)`. Source: wwdc2026/269.
- `ForEach` supports `.reorderable()` in any container, including `LazyVGrid` and watchOS. Source: wwdc2026/269.
- `.swipeActions` works on any view; `swipeActionsContainer()` coordinates swipes on a scroll container. Source: wwdc2026/269.
- Document APIs: `WritableDocument`, `ReadableDocument`, `DocumentWriter`, `DocumentCreationSource`, `NewDocumentButton`. Writes only changed parts by diffing `snapshot` against `previous`. Source: wwdc2026/269.
- `Tab(role: .prominent)` and toolbar APIs (`visibilityPriority`, `toolbarOverflowMenu`, `topBarPinnedTrailing`, `toolbarMinimizeBehavior`). Source: wwdc2026/269 and https://developer.apple.com/wwdc26/guides/swiftui/.
- `Previews`: code inside `#Preview` runs on the main actor. Canvas grids via `#Preview(arguments:)`. Source: xcode-27-release-notes.json (Previews).

## Observation and concurrency in SwiftUI code

- `WritableDocument.snapshot(contentType:)` is `@MainActor async throws` and returns `sending PageSnapshot`. `DocumentWriter.write` is `nonisolated async`, so disk I/O runs off the main actor. Source: wwdc2026/269.
- `@Observable` (Observation): availability iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1. Source: https://developer.apple.com/tutorials/data/documentation/observation/observable().json
- `@Observable` updates a view only when a property read in its `body` changes. `ObservableObject` updates on any `@Published` change. Source: https://developer.apple.com/tutorials/data/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro.json

## Apple platform policy (carried from VERSION.md, not re-fetched in this run)

- Since 2026-04-28, App Store Connect uploads must use Xcode 26 or later with the iOS 26 SDK. Since 2026-09-09, iOS apps must target iOS 13 or later. Source: VERSION.md (developer.apple.com/news/upcoming-requirements/). Not re-verified here.
- Privacy manifests: since 2024-05-01, App Store Connect rejects uploads that omit required-reason API declarations. Source: https://developer.apple.com/tutorials/data/documentation/bundleresources/describing-use-of-required-reason-api.json

## Sources

- https://www.swift.org/blog/swift-6.4-released/
- https://www.swift.org/blog/swift-6.2-released/
- https://www.swift.org/blog/whats-new-in-swift-september-2026/
- https://developer.apple.com/tutorials/data/documentation/xcode-release-notes/xcode-27-release-notes.json
- https://developer.apple.com/videos/play/wwdc2026/262/ (What's new in Swift)
- https://developer.apple.com/videos/play/wwdc2026/269/ (What's new in SwiftUI)
- https://developer.apple.com/wwdc26/guides/swiftui/
- https://developer.apple.com/tutorials/data/documentation/swiftui/viewbuilder.json
- https://developer.apple.com/tutorials/data/documentation/observation/observable().json
- https://developer.apple.com/tutorials/data/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro.json
- https://developer.apple.com/tutorials/data/documentation/bundleresources/describing-use-of-required-reason-api.json
- [secondary] https://www.massicotte.org/blog/what-settings/ ; https://forums.swift.org/t/default-actor-isolation-mainactor-conflicts-with-sendable/87819
