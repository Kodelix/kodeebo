# SwiftUI — Deprecated APIs and Replacements

Verified 2026-10-11 against Apple's per-symbol DocC JSON (`developer.apple.com/tutorials/data/documentation/...json`) fetched in this run.

**Read this first:**
- Apple's metadata marks several symbols with a reference-level `deprecated: true` and `deprecatedAt: 27.2`, while each per-platform `deprecated` flag reads `false`. The dates below use the `deprecatedAt` field. Treat them as deprecated, but re-check in Xcode 27 before relying on warnings-as-errors.
- `ObservableObject` is NOT deprecated per Apple's metadata (`deprecated: false`, introduced iOS 13). Apple's migration guide recommends the `@Observable` macro. This is a recommendation, not a deprecation.

## Deprecated

| Deprecated API | Status | Since (deprecatedAt) | Replacement | Source |
|---|---|---|---|---|
| `NavigationView`, `NavigationView.init(content:)`, `View.navigationViewStyle(_:)`, `NavigationViewStyle` | Deprecated | 27.2 | `NavigationStack`, `NavigationSplitView` | https://developer.apple.com/tutorials/data/documentation/swiftui/navigationview.json |
| `PreviewProvider` (and `previews`, `Previews`, `platform`, `PreviewPlatform`, `View.previewDisplayName(_:)`) | Deprecated | 27.0 | `#Preview` macro, `Preview(_:body:)` | https://developer.apple.com/tutorials/data/documentation/swiftui/previewprovider.json |
| `View.foregroundColor(_:)` | Deprecated | 27.2 | `foregroundStyle(_:)` | https://developer.apple.com/tutorials/data/documentation/swiftui/view/foregroundcolor(_:).json |
| `PresentationMode`, `EnvironmentValues.presentationMode`, `isPresented`, `dismiss()` (on PresentationMode) | Deprecated | 27.2 | `EnvironmentValues.isPresented`, `EnvironmentValues.dismiss` | https://developer.apple.com/tutorials/data/documentation/swiftui/presentationmode.json |
| `View.navigationBarItems(leading:trailing:)` | Deprecated | 27.2 | `toolbar(content:)` with `ToolbarItem` | https://developer.apple.com/tutorials/data/documentation/swiftui/view/navigationbaritems(leading:trailing:).json |
| `ToolbarItemPlacement.navigationBarLeading`, `.navigationBarTrailing` | Deprecated | 27.2 | Toolbar placements (replacement not named on the page; the page's own example uses them under `NavigationView`) | same as above |
| `View.navigationBarTitle(_:)` (all overloads, including `displayMode:`) | Deprecated | 27.2 | `View.navigationTitle(_:)` | https://developer.apple.com/tutorials/data/documentation/swiftui/view/navigationbartitle(_:).json |
| `View.cornerRadius(_:antialiased:)` | Deprecated | 27.2 | `View.clipShape(_:style:)` or `Shape.fill(style:)` | https://developer.apple.com/tutorials/data/documentation/swiftui/view/cornerradius(_:antialiased:).json |
| `View.onChange(of:perform:)` (one-parameter closure) | Deprecated | iOS 17.0, iPadOS 17.0, Mac Catalyst 17.0, tvOS 17.0, macOS 14.0, watchOS 10.0 (visionOS entry reads 1.0 and is unreliable) | `onChange(of:initial:_:)` with a zero-parameter or two-parameter (old, new) closure | https://developer.apple.com/tutorials/data/documentation/swiftui/view/onchange(of:perform:).json |
| On Demand Resources, `NSBundleResourceRequest` | Deprecated (Xcode 27 release notes) | Xcode 27 | Background Assets | https://developer.apple.com/tutorials/data/documentation/xcode-release-notes/xcode-27-release-notes.json |
| `devicectl` JSON v5 fields `hardwareProperties`, `deviceProperties`, `connectionProperties` | Deprecated (Xcode 27 release notes, tooling) | Xcode 27 | `properties` dictionary | same as above |

## Not deprecated (verified), with migration guidance

| API | Status | Guidance | Source |
|---|---|---|---|
| `ObservableObject` | NOT deprecated (`deprecated: false`, introduced iOS 13) | Apple recommends `@Observable` (iOS 17+, macOS 14+). Migration guide maps `@Published` to plain `var`, `@StateObject` to `@State`, `@EnvironmentObject` to `@Environment(Type.self)`. | https://developer.apple.com/tutorials/data/documentation/combine/observableobject.json ; https://developer.apple.com/tutorials/data/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro.json |
| `ViewBuilder` (closure type) | NOT deprecated (`deprecated: false`) | Xcode 27: closures are type-agnostic. Mark with `ContentBuilder`. | https://developer.apple.com/tutorials/data/documentation/swiftui/viewbuilder.json |

## Not verified (no fetched source)

| Item | Status |
|---|---|
| `NavigationLink(destination:isActive:label:)` | NOT SOURCEABLE. The NavigationLink page returned only the struct and non-`isActive` initializers. The deprecated-symbols page it links to was not fetched. Replacement pattern `navigationDestination(isPresented:destination:)` is documented on the NavigationStack page. |
| `ObservableObject` (formal deprecation date) | NOT SOURCEABLE; the metadata says it is not deprecated. |
| `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `.environmentObject(_:)` deprecation flags | NOT CHECKED individually. Replacements come from the Apple migration guide. |
| `ContentSizeCategory` → `DynamicTypeSize` | NOT SOURCEABLE from Apple. A third-party post claims deprecation in iOS 15; not verified. The `DynamicTypeSize` page documents `init?(_: UIContentSizeCategory)` only. |
| TN3211 (State and ContentBuilder source incompatibilities) | NOT SOURCEABLE. The TN3211 page returned title only. |

## Sources

- https://developer.apple.com/tutorials/data/documentation/swiftui/navigationview.json
- https://developer.apple.com/tutorials/data/documentation/swiftui/previewprovider.json
- https://developer.apple.com/tutorials/data/documentation/swiftui/view/foregroundcolor(_:).json
- https://developer.apple.com/tutorials/data/documentation/swiftui/presentationmode.json
- https://developer.apple.com/tutorials/data/documentation/swiftui/view/navigationbaritems(leading:trailing:).json
- https://developer.apple.com/tutorials/data/documentation/swiftui/view/navigationbartitle(_:).json
- https://developer.apple.com/tutorials/data/documentation/swiftui/view/cornerradius(_:antialiased:).json
- https://developer.apple.com/tutorials/data/documentation/swiftui/view/onchange(of:perform:).json
- https://developer.apple.com/tutorials/data/documentation/swiftui/viewbuilder.json
- https://developer.apple.com/tutorials/data/documentation/combine/observableobject.json
- https://developer.apple.com/tutorials/data/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro.json
- https://developer.apple.com/tutorials/data/documentation/xcode-release-notes/xcode-27-release-notes.json
