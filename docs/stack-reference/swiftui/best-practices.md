# SwiftUI / iOS 27 / Swift 6.4 — Best Practices

Verified 2026-10-11. Each rule cites a page fetched in this run. `NOT SOURCEABLE` marks rules whose source did not return content. Do not treat an unsourced rule as Apple guidance.

## 1. Concurrency correctness

- Turn on strict concurrency and Swift 6 language mode for new code. Build setting names and migration steps: NOT SOURCEABLE (the Apple adoption page returned HTTP 404; searched `developer.apple.com/documentation/xcode/adopting-strict-concurrency-in-swift-6-apps`).
- `Sendable`: value types qualify if all stored properties are `Sendable`. Reference types need to be `final`, have only immutable `Sendable` stored properties, and no superclass. Otherwise declare conformance explicitly or use `@unchecked Sendable` after manual verification. Source: https://developer.apple.com/tutorials/data/documentation/swift/sendable.json
- `@unchecked Sendable` disables compile-time checks. The developer owns correctness (lock or queue). Source: same.
- `@MainActor` classes are implicitly `Sendable` and may hold mutable non-`Sendable` properties. Source: same.
- Closures passed to a `Sendable` closure parameter conform implicitly. Captured values must be `Sendable` and captured by value. Source: same.
- `MainActor` is a singleton global actor whose executor equals the main dispatch queue. `MainActor.run(resultType:body:)` executes a body on the main actor. `assumeIsolated(_:file:line:)` asserts the current task is on the main actor, else stops execution. Source: https://developer.apple.com/tutorials/data/documentation/swift/mainactor.json
- Mark heavy CPU work (decoding, image processing) `@concurrent` when default MainActor isolation is on. Source: https://www.swift.org/blog/swift-6.2-released/
- Swift 6.4: `defer` may await async calls. Source: https://www.swift.org/blog/swift-6.4-released/
- Swift 6.4 warns when an error thrown inside a `Task` is ignored. Handle it inside the task or keep the `Task` value and inspect it later. Source: https://developer.apple.com/videos/play/wwdc2026/262/
- Use `withTaskCancellationShield` only for short regions where started work must finish or roll back. Source: https://developer.apple.com/videos/play/wwdc2026/262/
- Use `CheckedContinuation`-style APIs: Swift 6.4 `Continuation` checks at compile time that it resumes exactly once. Source: wwdc2026/262.
- `@MainActor` on the whole UI layer and default MainActor isolation: see breaking-changes.md (`[secondary]` build-setting names). Default-isolation interaction with `Sendable` and overrides is an open issue `[secondary]`.

## 2. View models with @Observable

- Use the `@Observable` macro on a class. Remove `ObservableObject` conformance, `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`. Source: https://developer.apple.com/tutorials/data/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro.json
- Replacement map (Apple migration guide): `@StateObject` becomes `@State`; `@ObservedObject` is removed when the view only reads, or becomes `@Bindable` when it needs bindings; `@EnvironmentObject` becomes `@Environment(Type.self)`; `.environmentObject(_:)` becomes `.environment(_:)`. Source: same.
- Use `@ObservationIgnored` to exclude a property from tracking. Source: same (the Observable macro page does not cover `@ObservationIgnored`).
- Migration can be incremental: `ObservableObject` and `@Observable` types can coexist. Source: same.
- `@Observable` availability: iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1. Source: https://developer.apple.com/tutorials/data/documentation/observation/observable().json
- `@Observable` updates a view only when properties read in `body` change. Plan view models so each view reads only what it displays. Source: migration guide.
- Make view models dependency-injected and `@MainActor` when they drive UI. The "dependency injection over singletons" rule comes from the project CLAUDE.md coding standards, not from Apple.

## 3. View identity and list performance

- `ForEach` identity: use `Identifiable` elements, or pass `id:` as a key path with a `Hashable` ID. IDs must be unique and stable across updates. Source: https://developer.apple.com/tutorials/data/documentation/swiftui/foreach.json
- Containers (`List`, `LazyVStack`) evaluate elements lazily. Each element should yield a constant number of views. Wrap a conditional in `VStack`, `HStack` or `ZStack` so each element yields exactly one view. Source: same.
- Diagnose non-constant elements with launch argument `-LogForEachSlowPath YES`. Source: same.
- Reordering: `ForEach { }.reorderable()` plus `.reorderContainer(for:)` work in any container. Source: wwdc2026/269.
- `AsyncImage` now caches by default, respecting server cache headers. Source: wwdc2026/269.
- `ContentBuilder` (Xcode 27) replaces overloaded builders and reduces type-check timeouts for deeply nested views. Source: wwdc2026/269.

## 4. NavigationStack

- Use `NavigationStack` for stack navigation. Available iOS 16, iPadOS 16, macOS 13, tvOS 16, visionOS 1, watchOS 9. Source: https://developer.apple.com/tutorials/data/documentation/swiftui/navigationstack.json
- Drive navigation with a path: `NavigationStack(path:root:)` takes a binding to a typed array or a `NavigationPath` (heterogeneous). Pushing appends; popping removes. Source: same.
- Attach `.navigationDestination(for:destination:)` inside the stack's view hierarchy, one modifier per data type. Source: same.
- Related modifiers: `navigationDestination(isPresented:destination:)` and `navigationDestination(item:destination:)`. Source: same.
- Use path-based navigation for deep links and state restoration. Source: same (the page recommends paths for deep links and state restoration).
- `NavigationView` is deprecated (see deprecated-apis.md). Migration guidance: use `NavigationStack` and `NavigationSplitView`. Source: https://developer.apple.com/tutorials/data/documentation/swiftui/navigationview.json
- `NavigationStack` placement rules (single outermost stack, avoid nesting): NOT SOURCEABLE in this run.

## 5. Security

### Keychain
- Keychain Services stores small secrets in an encrypted database. The overview also covers keys and certificates. Source: https://developer.apple.com/tutorials/data/documentation/security/keychain-services.json
- SecItem functions, `kSecClass`, accessibility attributes, access-control flags and their defaults: NOT SOURCEABLE in this run. The overview page links to these topics but its content was not returned. Searched: Keychain Services overview JSON. Do not write Keychain code from memory; fetch the linked Keychain items article first.

### App Transport Security (ATS)
- ATS requires HTTPS for all HTTP connections made with the URL loading system (`URLSession`). Extended server trust checks apply. Source: https://developer.apple.com/tutorials/data/documentation/bundleresources/information-property-list/nsapptransportsecurity.json
- ATS is on by default only for apps linked against the iOS 9 or macOS 10.11 SDK or later. All keys in the `NSAppTransportSecurity` dictionary are optional. Source: same.
- Global exception keys: `NSAllowsArbitraryLoads`, `NSAllowsArbitraryLoadsForMedia`, `NSAllowsArbitraryLoadsInWebContent`, `NSAllowsLocalNetworking`, `NSRequiresCertificateTransparency` (obsolete), `NSPinnedDomains`. Per-domain exceptions go under `NSExceptionDomains`. Source: same.
- Per-domain subkeys (`NSExceptionAllowsInsecureHTTPLoads`, `NSExceptionMinimumTLSVersion`, `NSIncludesSubdomains`): NOT SOURCEABLE in this run; the fetched page listed only `NSExceptionRequiresNIAPTLSPackageVersion`.
- Version behaviour: on iOS 10 and later, `NSAllowsArbitraryLoads` is ignored and the other global keys are honoured. On iOS 9 the reverse applies. Source: same.
- Prefer HTTPS fixes on the server over ATS exceptions. Guidance wording on App Review scrutiny: NOT SOURCEABLE in this run.

### Passkeys (AuthenticationServices)
- Setup: create `ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier:)`, call `createCredentialRegistrationRequest(challenge:name:userID:)` or `createCredentialAssertionRequest(challenge:)`, wrap in `ASAuthorizationController(authorizationRequests:)`, set `delegate` and `presentationContextProvider`, then `performRequests()`. Source: https://developer.apple.com/tutorials/data/documentation/authenticationservices/supporting-passkeys.json
- Associated domains are required for registration and assertion requests. Without them the request returns an error. Source: same.
- Handle results in `authorizationController(controller:didCompleteWithAuthorization:)`. Check for `ASAuthorizationPlatformPublicKeyCredentialRegistration` or `ASAuthorizationPlatformPublicKeyCredentialAssertion`. Handle failures in `didCompleteWithError`. Source: same.
- AutoFill: set `textContentType` to username, then call `performAutoFillAssistedRequests()`. Source: same.
- Change or reset: `ASAuthorizationSecurityKeyPublicKeyCredentialProvider.createCredentialRegistrationRequest(challenge:displayName:name:userID:)`. Re-registering an existing `userID` overwrites the passkey on the user's devices. Source: same.
- Web views: check `isUserVerifyingPlatformAuthenticatorAvailable()` and `isConditionalMediationAvailable()` (iOS 16.4+ / macOS 13.3+). Source: same.
- Entitlement string format (`webcredentials:<domain>`) and `apple-app-site-association` file format: NOT SOURCEABLE in this run. The fetched page did not include them.

### Privacy manifests
- Filename `PrivacyInfo.xcprivacy`. Create via File > New File > App Privacy File and add it to the target's bundle resources. Source: https://developer.apple.com/tutorials/data/documentation/bundleresources/privacy-manifest-files.json
- Top-level keys: `NSPrivacyTracking` (Boolean), `NSPrivacyTrackingDomains` (array), `NSPrivacyCollectedDataTypes` (array, required on all platforms), `NSPrivacyAccessedAPITypes` (required-reason APIs, required on iOS, iPadOS, tvOS, visionOS, watchOS). Source: same.
- Set `NSPrivacyTracking` to true when declaring tracking domains. Requests to those domains fail without tracking permission. Source: same.
- Third-party SDKs must ship a manifest if they are on Apple's required list, use a required-reason API, collect data, or contact tracking domains. Source: same.
- Since 2024-05-01, App Store Connect rejects uploads that omit required-reason declarations. Source: https://developer.apple.com/tutorials/data/documentation/bundleresources/describing-use-of-required-reason-api.json
- Required-reason category constants and approved reason codes: NOT SOURCEABLE in this run. Both pages returned only overview text. Do not copy codes from memory.

## 6. Accessibility

- VoiceOver labels: `.accessibilityLabel(_:)` (iOS 16+). The label should describe what the control does or shows. Do not repeat information the system already provides, and do not include the control type (the button trait already announces it). Source: https://developer.apple.com/tutorials/data/documentation/swiftui/view/accessibilitylabel(_:).json
- Dynamic Type: `DynamicTypeSize` (iOS 15+) is an environment value. Read it with `@Environment(\.dynamicTypeSize)`. Limit the range with `dynamicTypeSize(_:)`. Accessibility sizes are `accessibility1` to `accessibility5`; `isAccessibilitySize` is true for them. Source: https://developer.apple.com/tutorials/data/documentation/swiftui/dynamictypesize.json
- Switch layout (for example HStack to VStack) at accessibility sizes instead of truncating. Source: DynamicTypeSize page example.
- Text-style scaling, `@ScaledMetric`, and Large Content Viewer guidance: `[secondary]` (WWDC24 10074 summary via search; https://developer.apple.com/videos/play/wwdc2024/10074/). Not fetched.
- VoiceOver UI tests: `XCUIVoiceOverService` (Xcode 27). Source: xcode-27-release-notes.json.
- Touch-target minimum sizes, contrast ratios, VoiceOver traits and hints: NOT SOURCEABLE in this run. The HIG accessibility page returned title only.

## 7. Testing: Swift Testing vs XCTest

- Swift Testing: `@Test` declares a test; `@Suite` groups tests; `#expect` and `#require` check values. Source: https://developer.apple.com/tutorials/data/documentation/testing.json (macros `@Test` and `@Suite` on the page; `#expect` and `#require` described in the "Expectations and confirmations" article, linked).
- Availability: Swift Testing introduced in Swift 6.0 and Xcode 16. Source: testing.json.
- Parameterized tests, tags, traits and in-process parallelization are supported. Source: testing.json.
- Migration: use the "Migrating a test from XCTest" article. Source: testing.json (linked). Migration steps themselves: NOT SOURCEABLE in this run.
- Interop: `XCTAssert` works in Swift Testing tests and `#expect` works in XCTest tests (Swift 6.4, ST-0021). Source: https://www.swift.org/blog/swift-6.4-released/
- Prefer Swift Testing for new unit tests. Use XCTest for UI tests (XCUITest), which Swift Testing does not replace in the fetched sources. Source for UI test API: xcode-27-release-notes.json.
- Repetition: `swift test --maximum-repetitions N` and `--repeat-until pass|fail`. Source: xcode-27-release-notes.json.

## 8. CI on macOS runners

- Xcode 27 requires macOS Tahoe 26.6 or later on Apple silicon. Intel Macs are unsupported. Source: xcode-27-release-notes.json.
- GitHub `macos-26` runner image (fetched): default Xcode 26.6, installed 26.0.1 through 26.5. Xcode 27 is not installed on that image at fetch time. Source: https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md
- Runner Xcode 27 availability date: NOT SOURCEABLE in this run. Check the runner image README before pinning CI.
- Pin the Xcode version explicitly in CI (for example `xcode-select`) so builds stay reproducible. Recommendation is derived from the fact that the default Xcode differs by image; the pinning command syntax: NOT SOURCEABLE in this run.

## 9. SwiftLint

- Install options: Homebrew (`brew install swiftlint`), SwiftPM plugin from `SimplyDanny/SwiftLintPlugins` (pinned with `from:` or `exact:`), or Mint (`mint install realm/SwiftLint`). Source: https://github.com/realm/SwiftLint
- Build Tool plugin `SwiftLintBuildToolPlugin` works in Swift packages (`plugins:` per target) and in Xcode (Run Build Tool Plug-ins phase). Config file: the topmost config file in the package or project. Source: same.
- Command plugin: `swift package plugin swiftlint`. Source: same.
- Latest SwiftLint version and release date: NOT SOURCEABLE in this run. The GitHub releases section did not render.
- The page says Xcode 15.0 requires `ENABLE_USER_SCRIPT_SANDBOXING` set to `NO` for the target when using a Run Script phase. Current Xcode 27 behaviour: NOT SOURCEABLE in this run. Source: https://github.com/realm/SwiftLint

## 10. Navigation and iOS 27 UI changes (behaviour)

- Toolbars: `visibilityPriority`, `toolbarOverflowMenu`, `topBarPinnedTrailing`, `toolbarMinimizeBehavior`. Source: https://developer.apple.com/wwdc26/guides/swiftui/
- Document apps: `DocumentGroup`, `DocumentGroupLaunchScene`, `NewDocumentButton`, `DocumentCreationSource`, `WritableDocument`, `ReadableDocument`. Source: wwdc2026/269.

## Sources

- https://developer.apple.com/tutorials/data/documentation/swift/sendable.json
- https://developer.apple.com/tutorials/data/documentation/swift/mainactor.json
- https://www.swift.org/blog/swift-6.2-released/
- https://www.swift.org/blog/swift-6.4-released/
- https://developer.apple.com/videos/play/wwdc2026/262/
- https://developer.apple.com/videos/play/wwdc2026/269/
- https://developer.apple.com/wwdc26/guides/swiftui/
- https://developer.apple.com/tutorials/data/documentation/observation/observable().json
- https://developer.apple.com/tutorials/data/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro.json
- https://developer.apple.com/tutorials/data/documentation/swiftui/foreach.json
- https://developer.apple.com/tutorials/data/documentation/swiftui/navigationstack.json
- https://developer.apple.com/tutorials/data/documentation/swiftui/navigationview.json
- https://developer.apple.com/tutorials/data/documentation/security/keychain-services.json
- https://developer.apple.com/tutorials/data/documentation/bundleresources/information-property-list/nsapptransportsecurity.json
- https://developer.apple.com/tutorials/data/documentation/authenticationservices/supporting-passkeys.json
- https://developer.apple.com/tutorials/data/documentation/bundleresources/privacy-manifest-files.json
- https://developer.apple.com/tutorials/data/documentation/bundleresources/describing-use-of-required-reason-api.json
- https://developer.apple.com/tutorials/data/documentation/swiftui/view/accessibilitylabel(_:).json
- https://developer.apple.com/tutorials/data/documentation/swiftui/dynamictypesize.json
- https://developer.apple.com/tutorials/data/documentation/testing.json
- https://developer.apple.com/tutorials/data/documentation/bundleresources/information-property-list/nsapptransportsecurity.json
- https://developer.apple.com/tutorials/data/documentation/xcode-release-notes/xcode-27-release-notes.json
- https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md
- https://github.com/realm/SwiftLint
- [secondary] https://developer.apple.com/videos/play/wwdc2024/10074/
