# SwiftUI / iOS — Version Reference

Layer: `swiftui` (iOS app development). Last verified: **2026-10-11**.

## Knowledge gap warning

The LLM's training data predates this stack. Swift 6.4, Xcode 27, iOS 27 and the WWDC26 SwiftUI changes
(`@State` as a macro, `@ContentBuilder`, new Document APIs, SwiftData observers) are NOT in model memory.
Every claim below comes from a source fetched on 2026-10-11. Gaps are marked `NOT SOURCEABLE`.
Apple's DocC pages (`developer.apple.com/documentation/...`) are JS-rendered and only partly fetchable; where a
fact came from a search-engine summary or a third party it is labelled **[secondary]**. Re-verify before pinning CI.

## Versions (current as of 2026-10-11)

| Item | Value | Date | Source |
|---|---|---|---|
| Swift (current, ships in Xcode 27) | **6.4** | 2026-09-15 (swift.org post) | https://www.swift.org/blog/swift-6.4-released/ |
| Swift previous | 6.3 (point releases 6.3.1 2026-04-17, 6.3.2 2026-05-13, 6.3.3 2026-06-30 [secondary: Swift Forums via search]) ; 6.3 released 2026-03-24 | 2026-03-24 | https://www.swift.org/blog/whats-new-in-swift-march-2026/ |
| Swift 6.2 (introduced approachable concurrency) | 6.2 | 2025-09-15 | https://www.swift.org/blog/swift-6.2-released/ |
| Xcode (current stable) | **27** (27A266a) | 2026-09-14 | https://developer.apple.com/news/releases/ |
| Xcode 27.1 | RC 27A9275 on 2026-10-05 (not yet final as of fetch); 27.1 beta 2026-09-18 | 2026-10-05 | https://developer.apple.com/news/releases/ |
| Xcode 27.2 | beta 2 (27B5028f), 2026-09-28 | — | https://developer.apple.com/news/releases/ |
| Xcode 26.x last | **26.6** (17F113), Swift 6.3, iOS 26.5 SDK | 2026-06-25 | https://developer.apple.com/news/releases/?id=06252026a ; Swift/SDK content [secondary: search summary of 26.6 RC notes] |
| iOS SDK | **iOS 27.0 SDK** in Xcode 27 (iOS 27.1 SDK in Xcode 27.1 RC) | 2026-09-14 | https://developer.apple.com/help/app-store-connect/release-notes/ |
| iOS (current public) | **iOS 27.0.1** (24A446) 2026-09-28; iOS 27 public release 2026-09-14; announced WWDC 2026-06-08 [secondary] ; iOS 26.6.2 (23G90) 2026-09-08 | 2026-09-14 | https://www.apple.com/newsroom/2026/09/major-updates-for-apples-software-platforms-are-now-available/ ; https://developer.apple.com/news/releases/ |
| Xcode 27 host requirement | macOS Tahoe **26.6** or later; **Apple silicon only** (Intel Macs unsupported) | — | Xcode 27 release notes (fetched via `developer.apple.com/tutorials/data/documentation/xcode-release-notes/xcode-27-release-notes.json`) |
| Xcode 27 on-device debugging | iOS 17+, tvOS 17+, watchOS 10+, visionOS | — | same |
| SwiftLint | **0.65.1** (Swift Package Index lists compat Swift 6.1-6.4; release date NOT SOURCEABLE — index says "about 2 months ago"; 0.65.0 dated 2026-06-27 [secondary]) | — | https://swiftpackageindex.com/realm/SwiftLint |
| Swift Testing | Ships with the toolchain (Swift 6.4 adds XCTest interop ST-0021, per-test repetitions ST-0024, etc.) | 2026-09-15 | https://www.swift.org/blog/swift-6.4-released/ |

Not final yet at fetch time: Xcode 27.1 (RC only), iOS 27.1/27.2 (27.2 beta 3 on 2026-10-05). Check
https://developer.apple.com/news/releases/ before pinning a patch version.

## App Store submission requirements (Apple)

Source: https://developer.apple.com/news/upcoming-requirements/ (fetched 2026-10-11)

- **Since 2026-04-28**: apps uploaded to App Store Connect must be built with **Xcode 26 or later** using an SDK for iOS 26 / iPadOS 26 / tvOS 26 / visionOS 26 / watchOS 26. (Previous minimum, Xcode 16/iOS 18 SDK, applied from 2025-04-24 [secondary].)
- **Since 2026-09-09**: iOS and iPadOS apps uploaded must **target iOS 13 or later** (this is the minimum *deployment target* App Store Connect accepts, not a recommendation).
- Xcode 27 builds (iOS 27.0 SDK) are accepted for App Store and TestFlight since 2026-09-14; Xcode 27 RC from 2026-09-09; Xcode 27.1 RC (iOS 27.1 SDK) from 2026-10-05. Source: https://developer.apple.com/help/app-store-connect/release-notes/
- **Next SDK minimum**: Apple has historically moved the minimum each April. For April 2027 the only requirement found on the release-notes page is screenshots for "iPhone Duo" (new device class) for submissions starting April 2027. A new Xcode 27 minimum-SDK date is `NOT SOURCEABLE` (searched upcoming-requirements page and App Store Connect release notes; a third-party summary claims an April 2027 SDK deadline, unconfirmed by Apple).
- **Privacy manifest**: since 2024-05-01 you must declare approved reasons for required-reason APIs (including from third-party SDKs) to upload new or updated apps. Source: upcoming-requirements page above.

## Support policy / deployment target

- Apple publishes no LTS or formal OS support policy for Swift/Xcode: `NOT SOURCEABLE` (searched developer.apple.com support and releases pages). Practical rule: Xcode N supports the last SDK year; each April the upload minimum moves to the previous year's Xcode.
- Device adoption (Apple, as of 2026-06-07): iOS 26 on 86% of iPhones introduced in last 4 years and 79% of all iPhones; iPadOS 26 on 79%/68%. Source: https://developer.apple.com/support/app-store/ . Adoption of iOS 27 not yet published at fetch time (`NOT SOURCEABLE`).
- **Recommended deployment target (this framework's recommendation, derived from the sources above)**: **iOS 17.0 minimum for new apps** — `@Observable`/Observation, SwiftData and the `@State` lazy-initialisation back-port all reach iOS 17; Xcode 27 debugs devices down to iOS 17; iOS 26 is at ~79-86% adoption so iOS 17 covers >95% [the >95% figure is an inference, not an Apple number]. Raise to iOS 18 or 26 if you need those APIs without `#available`. Do not use iOS 13 (the App Store floor) as a target for new code.
- Build with the newest GA Xcode (27) and SDK; keep the deployment target low. Liquid Glass/2026 and 2027 look adopts automatically when linked against the new SDK.

## Concurrency defaults (Swift 6.2+ / Xcode 26+)

- Build settings: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES` (enables `NonisolatedNonsendingByDefault`), strict concurrency `Complete`. New Xcode 26 app targets enable default MainActor isolation; one write-up says Xcode 27 templates keep both defaults [secondary: blakecrosley.com via search]. Verify in your own project's build settings. Package equivalent: `.defaultIsolation(MainActor.self)` in `swiftSettings` (SE-0466). Sources: https://www.swift.org/blog/swift-6.2-released/ (feature existence); build-setting names [secondary] https://forums.swift.org/t/swift-6-2-approachable-concurrency-default-actor-isolation-with-core-data-transformable-type/82323
- Swift 6.4 introduced no new default-isolation mode; changes are diagnostics/ergonomics (see breaking-changes.md).

## Installed locally

Machine is Linux (`/home/kiko`, CachyOS). `swift --version` -> `swift: command not found` => **NOT INSTALLED**.
iOS/SwiftUI builds, simulators, `xcodebuild` and App Store signing require **macOS with Xcode 27** (Apple silicon, macOS Tahoe 26.6+).
CI must use macOS runners (see best-practices.md). Swift 6.4 toolchains exist for Linux (swift.org, Swiftly) for server-side/package unit tests only; SwiftUI/UIKit/SwiftData do not build on Linux.

## Verified sources

- https://www.swift.org/blog/swift-6.4-released/
- https://www.swift.org/blog/swift-6.2-released/
- https://www.swift.org/blog/whats-new-in-swift-march-2026/
- https://www.swift.org/blog/whats-new-in-swift-september-2026/
- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/news/releases/
- https://developer.apple.com/help/app-store-connect/release-notes/
- https://developer.apple.com/support/app-store/
- https://developer.apple.com/videos/play/wwdc2026/262/ (What's new in Swift)
- https://developer.apple.com/videos/play/wwdc2026/269/ (What's new in SwiftUI)
- https://developer.apple.com/videos/play/wwdc2026/274/ (What's new in SwiftData)
- https://developer.apple.com/wwdc26/guides/swiftui/
- https://developer.apple.com/documentation/Technotes/tn3211-resolving-swiftUI-source-incompatibilities-for-state-and-contentbuilder (via tutorials/data JSON)
- Xcode 27 release notes via `https://developer.apple.com/tutorials/data/documentation/xcode-release-notes/xcode-27-release-notes.json`
- https://www.apple.com/newsroom/2026/09/major-updates-for-apples-software-platforms-are-now-available/
- https://swiftpackageindex.com/realm/SwiftLint
