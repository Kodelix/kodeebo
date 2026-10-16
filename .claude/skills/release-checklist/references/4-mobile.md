# /release-checklist — Track 3: Mobile Stores

> Emitted per store from `stack.mobile`: `compose` or `kmp` → Android;
> `swiftui` → iOS; `kmp+swiftui` → both; `none` → omitted with the one-line
> notice below; **unset → ask** which stores are in scope (unset is not `none`).
>
> `Mobile track: omitted — stack.mobile is 'none' (no mobile app).`

## Store requirements are re-read, dated, and never assumed

Store floors change on dated deadlines. **At release time re-read**
`docs/stack-reference/compose/VERSION.md` (Google Play) and
`docs/stack-reference/swiftui/VERSION.md` (App Store) and write into the
checklist: the requirement, the **date it applies from**, the reference's
**"Last verified" date**, and the **date checked today**.

- A requirement whose effective date is **later than the reference's last-verified
  date**, or any item the reference marks `NOT SOURCEABLE`, is written
  `NOT SOURCEABLE — not covered by <path>` and the item is `[?]`. The checklist
  does not fill it from memory, and the track verdict cannot be READY while one
  is open.
- If the reference is older than the release by more than a few weeks, say so and
  offer `/research` (`researcher`) to re-verify before submission.
- **Privacy and policy forms are not in the stack reference** (Play Data safety,
  App Store App Privacy answers / nutrition labels, content rating, App Review
  guideline compliance for external payments, required-reason API reason codes):
  these items are **flagged for `/research`** and are `[?]` until a research note
  exists. Do not draft answers to those questionnaires from memory.

## Android — Google Play

Values as recorded in `compose/VERSION.md` (verified 2026-10-11 at the time this
skill was written — re-read before use). **These quoted values are a snapshot, not
the source:** the checklist line carries the value and the verified date read from
`compose/VERSION.md` at run time, and if the two differ the reference wins and the
quoted line below is stale. A reference older than 90 days is itself a `[?]`
(`/research` first):

- [ ] `targetSdk` meets the current Play requirement: new apps and updates **API 36 or higher, effective 2026-08-31** (extension requestable to 2026-11-01); existing apps API 35 to stay discoverable. Set `targetSdk = 36`; `compileSdk = 37` only with AGP ≥ 9.1.2. Actual: `[targetSdk]`; reference date checked: `[date]`
- [ ] `versionCode` strictly increases (previous `[n]`, now `[m]`); `versionName` = `[version]`
- [ ] Release is an **app bundle (AAB)** signed via **Play App Signing**; upload key handled by the pipeline (`platform-lead`), never in the repo
- [ ] **R8 enabled** for release (setting depends on AGP: `isMinifyEnabled` + `isShrinkResources` before 9.3, `optimization { enable = true }` from 9.3); release build tested on a **physical device**; the **mapping file archived** and uploaded to the crash reporter (symbolication)
- [ ] **Baseline profile** included (binary profile < 1.5 MB); cold start ≤ 1.5 s on a mid-range device (Macrobenchmark result `[..]`, device model/OS recorded)
- [ ] Permissions minimal and each justified; `android:exported` explicit; no secrets in the binary; tokens in Keystore
- [ ] Edge-to-edge behaviour verified (enforced for API 35+); RTL (Arabic) and English checked on a small screen and with rotation/process death
- [ ] **Data safety form and privacy policy URL current** — `[?] flagged for /research` (not in the stack reference); **account deletion path in-app and on the web**
- [ ] Store listing: Arabic and English text, screenshots (RTL included), feature graphic current
- [ ] In-app billing flows verified in a Play testing track (if used)
- [ ] **Staged rollout** configured: `[% steps]`; **halt criteria** written (crash-free rate `[x]`, ANR rate `[y]`, error rate); the halt-rollout procedure is written and the owner named
- [ ] Review status: `[submitted / in review / approved]` — **submission is made by the user**; this skill never submits

## iOS — App Store

Values as recorded in `swiftui/VERSION.md` (verified 2026-10-11 — a snapshot: re-read
`swiftui/VERSION.md` at run time, write the value and its verified date into the
checklist line, and treat a reference older than 90 days as `[?]`):

- [ ] Built with **Xcode 26 or later** using an SDK for iOS 26 or later (required since 2026-04-28); Xcode 27 builds are accepted for App Store and TestFlight (since 2026-09-14). A newer minimum-SDK date is `NOT SOURCEABLE` — do not assume an April 2027 deadline either way. Build used: `[Xcode / SDK]`
- [ ] **Deployment target** is the product's chosen target (framework recommendation iOS 17.0 for new apps) and not below the App Store floor (iOS 13, enforced since 2026-09-09)
- [ ] Build number incremented; version = `[version]`; signed with the distribution profile via the macOS CI runner (`platform-lead`)
- [ ] **`PrivacyInfo.xcprivacy` complete**, including required-reason API declarations from the app **and its SDKs**; reason codes `NOT SOURCEABLE` in the reference → `[?] flagged for /research`
- [ ] **App Privacy labels (nutrition labels)** current — `[?] flagged for /research`; **account deletion in-app**
- [ ] ATS/network config reviewed (no unjustified exceptions); entitlements minimal; Keychain use reviewed
- [ ] Release build tested on a **physical device**; **dSYMs archived** and uploaded to the crash reporter
- [ ] **TestFlight** external group verified before submission
- [ ] Store listing: Arabic and English text, screenshots (RTL, Dynamic Type large), review notes and a **demo account for reviewers** (test tenant; never a real customer's)
- [ ] In-app purchase / subscription products verified in sandbox (if used); external-payment guideline compliance — `[?] flagged for /research`
- [ ] **Phased release** configured; submission status `[submitted / in review / approved]` — submission by the user
- [ ] iOS build, signing and simulator checks cannot run on a Linux host (`swiftui/VERSION.md`: macOS with Xcode 27, Apple silicon): items needing them are `[?]` until the macOS CI result or the user's confirmation is supplied

## Both stores

- [ ] API/contract compatibility window: the store build in users' hands (previous versions) is still accepted by the API after the hosted deploy; a force-upgrade rule exists if a version must be cut off
- [ ] Crash reporting configured with release + build identifiers and symbolication
- [ ] No PII in client telemetry; consent respected
