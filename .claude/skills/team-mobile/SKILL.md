---
name: team-mobile
description: "Orchestrate mobile delivery of a feature — contract first, kmp-specialist's shared module, then android-lead and ios-lead in parallel against the shared facade, accessibility, Arabic/RTL and MASVS review, Play and App Store requirements from the stack reference, retained evidence including RTL screenshots."
argument-hint: "[mobile feature] [--layers shared|android|ios|all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Bash(uname -s), Agent, AskUserQuestion, Skill, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(./gradlew tasks --all), Bash(./gradlew tasks --all *), Bash(adb devices), Bash(adb devices *), Bash(bash "*/.claude/skills/team-mobile/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Mobile

If no argument is provided, output usage guidance and exit without spawning any agents or reading any files:
> Usage: `/team-mobile [mobile feature] [--layers shared|android|ios|all] [--review full|lean|solo]` — describe the feature to deliver on mobile (e.g., `offline appointment list`, `passkey sign-in`, `plan upgrade screen`). Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate the mobile team through a structured pipeline: the contract and the shared Kotlin module come first, because the Android and iOS apps are built against them — then the two platforms proceed in parallel.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,qa.level,testing.strict,accessibility,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**Which layers.** From `stack` above work out what the feature touches: the KMP
shared module (`mobile/shared/`, when `stack.mobile` includes KMP), Android
(`mobile/android/`), iOS (`mobile/ios/`). `--layers` narrows it. If `stack` is
unset for a layer the feature needs, that layer is **not implemented by this run**
— say so and recommend `/setup-stack`; never choose a framework yourself.

`workflow` and `qa.level` do not waive the run-and-observe evidence, the UI
screenshots or any required Logic, Integration, Contract or Security test:
tests never scale down (`coding-standards.md`); `qa.level` changes only how much
extra evidence is asked for. `accessibility` (above) is the committed
default target; the committed document is `design/accessibility-requirements.md`.

`review_mode` sets director-gate depth, and this pipeline has no director gate of
its own: no phase below spawns a PD-, CTO-, PR- or DD-PHASE-GATE. A new visual
token or component family is `DD-VISUAL`/`DD-DESIGN-SYSTEM` work, owned by
`/team-ui`; per-story `PE-CODE-REVIEW`/`PE-DOD` run in `/code-review` and
`/story-done`. A skipped gate waives the director's opinion, never this evidence.

`automation` drives the Decision Points note above.

**`team.size`**: which agents are active (orthogonal to review_mode and workflow).
- **`individual`** (default): `kmp-specialist` for the shared module plus the platform lead(s) in scope, `android-lead` and/or `ios-lead`, who implement directly; their specialists are not spawned.
- **`small`**: + `api-designer` (contract), `accessibility-specialist`, `localization-lead`, `qa-tester`.
- **`studio`**: + the platform specialists the leads route to (`compose-ui-specialist`, `android-platform-specialist`, `swiftui-specialist`, `swift-concurrency-specialist`), `offline-sync-specialist` for offline-first features, `appsec-engineer` (MASVS), `release-manager` (store requirements), and an adversarial review pass: Phase 5 reviewers are told "your job is not to confirm this matches the spec — find where it fails it", and the report says the pass ran.
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists**, whatever the `automation` mode.

**Announce the active set before Phase 1 — never let the collapse be silent.**
State in one line which agents this run will spawn and which the pipeline names
but will **not** spawn at the resolved `team.size`:

> `Active set (team.size: <resolved>): <agents for that size>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

The collapse is correct; without saying so a reader cannot tell a collapsed run
from a broken one.

## Team Composition

- **api-designer** — the contract change in `contracts/` and client generation (via `/api-contract`)
- **kmp-specialist** — the shared module: `<context>/{domain,app,adapters}` in `commonMain`, use cases and ports, Ktor client over the generated client, local persistence by ADR, the Swift-friendly facade, `commonTest`
- **offline-sync-specialist** — sync engine, outbox, conflict policy (reports to `kmp-specialist`), when the feature is offline-first
- **android-lead** (→ `compose-ui-specialist`, `android-platform-specialist`) — Compose app, Play requirements, MASVS, baseline profile and startup evidence
- **ios-lead** (→ `swiftui-specialist`, `swift-concurrency-specialist`) — SwiftUI app, Swift 6 strict concurrency, App Store and privacy-manifest requirements, macOS CI
- **accessibility-specialist**, **localization-lead**, **appsec-engineer**, **qa-tester**, **release-manager** — review, evidence and store inputs

## How to Delegate

Use the `Agent` tool: `subagent_type: api-designer` · `kmp-specialist` · `offline-sync-specialist` · `android-lead` · `ios-lead` · `accessibility-specialist` · `localization-lead` · `appsec-engineer` · `qa-tester` · `release-manager`. The leads route to their specialists themselves.

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline, never a path to a document you already read. Independent agents are spawned in parallel — issue every independent `Agent` call before waiting for any result (`.claude/docs/coordination-rules.md`).

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." **Implementation files are the exception:** an agent writing code first returns the files it will create or change; its contract names them only after you asked once for the set and the user said yes (File Write Protocol).

| Phase / agent | Writes to |
|---|---|
| 3 kmp-specialist | `production/mobile/[slug]/shared-handoff.md` (ports, facade, DTOs, error model, test status); code under `mobile/shared/` per the file-set approval |
| 4 android-lead | `production/mobile/[slug]/platform-android.md`; code under `mobile/android/` per the file-set approval |
| 4 ios-lead | `production/mobile/[slug]/platform-ios.md`; code under `mobile/ios/` per the file-set approval |
| 5 accessibility-specialist, localization-lead, appsec-engineer, release-manager | `production/mobile/[slug]/review-[agent].md`, one each |
| 5 qa-tester | `production/qa/evidence/[story-id]/` and `production/qa/cases/[story-slug]-cases.md` |

`/api-contract` writes the contract and generated clients under its own protocol and asks before writing.

> **Why this does not violate the Collaboration Protocol.** A subagent spawned here writes **without** asking, a deliberate, bounded exception. It holds only when: (1) the path is one **you** named in the prompt; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is a phase gate. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent.**

## Pipeline

### Phase 1: Load Context and Host Capability

Read and report each as FOUND or ABSENT: the feature spec (`design/specs/`) with its acceptance criteria, the UX spec (`design/ux/`), `PRODUCT.md` and `DESIGN.md` at the repo root, `design/accessibility-requirements.md`, `design/localization/`, the `contracts/` operations the feature uses, the control manifest, and the ADRs this layer depends on: **local persistence choice** (SQLDelight or Room 3), **Swift interop approach**, and **Compose Multiplatform for iOS** (only by ADR). A needed ADR that is absent is a stop for that choice: route to `/architecture-decision`; the shared module does not guess.

**`PRODUCT.md` is a precondition for any UI:** absent → **BLOCKED**, route to `/impeccable init`; the UX and visual work comes from `/ux-design` and `/team-ui` — this pipeline implements it, it does not redesign it.

**Host capability — state it now, per platform, so nothing is silently skipped.** This skill itself runs only the three probes below (`./gradlew tasks --all`, `adb devices`, `uname -s`); every build, test, `adb` screenshot and `xcrun` command is run by the platform lead or `qa-tester` through `Agent` (they have Bash), or by `/test`:
- Gradle wrapper and the Gradle tasks that build and test the shared module and the Android app — **task names are unverified in the stack reference** (`docs/stack-reference/kmp/best-practices.md`: Kotlin test and Gradle commands `NOT SOURCEABLE`); confirm from the build files or `./gradlew tasks --all` as `/test` does, or report not run.
- An Android emulator or device (`adb devices`) for instrumented tests and screenshots.
- A macOS host for any iOS build, test, simulator screenshot or Instruments run (`uname -s`). On this Linux host: `iOS: not built, not tested, not screenshotted — macOS CI only`.

Report: "Mobile delivery of [feature]. Layers: [shared / android / ios]. Contract change: [yes/no]. ADRs: [present/absent each]. Can run here: [list]. Cannot run here: [list with reasons]. Ready?"

### Phase 2: Contract First

If the feature needs a new or changed operation: run `/api-contract` (`api-designer`) — contract-first OpenAPI change, lint, breaking-change diff, client generation. **The contract merges before any client code.** No contract change → record `contract unchanged` with the operations used. A generated KMP client that differs from regeneration output is drift, reported.

### Phase 3: Shared Module (kmp-specialist)

Spawn `kmp-specialist` (and `offline-sync-specialist` for sync/conflict work) to build the feature's shared part against the stack reference (`docs/stack-reference/kmp/`, `kotlin/`, `ktor/`; no API or version from memory — gaps are `NOT SOURCEABLE` → `/research`): pure-Kotlin domain rules and use cases written test-first behind ports (repository, clock, ID generator, connectivity, secure store — injected, no singletons); Ktor adapters over the generated client mapped to domain types, with auth, retry (idempotent calls only) and telemetry in one place; persistence per the ADR with versioned, tested migrations and **tenant scoping**; a minimal exported surface and the Swift-friendly facade the iOS app consumes; `commonTest` on JVM and iOS targets.

Run the shared tests with `/test kmp` — JVM-target tasks that are confirmed run; iOS-target tests are `NOT RUN — macOS only`.

**Gate (phase gate):** present `shared-handoff.md` — the ports and facade signatures, DTOs, the error model the UI maps, which tests ran and which did not. `AskUserQuestion`: freeze the hand-off and start the platforms / revise the shared module / stop. **The platforms build against the frozen hand-off**; a change to it afterwards returns here.

### Phase 4: Android and iOS in Parallel

After the freeze, spawn `android-lead` and `ios-lead` **in the same message** (issue both `Agent` calls before waiting for either). Each implements the feature against the shared facade, the UX spec and `DESIGN.md`, and the layer's stack reference (`compose/`, `swiftui/`, `pins.yaml`). Shared rules for both:

- **The UI holds no business rules and never trusts itself for authorisation**: it displays state and emits intents; the server enforces. Data comes through the shared module's generated client, never hand-built requests.
- **All user-facing text through the layer's i18n mechanism**, Arabic and English keys added together; logical start/end alignment so RTL mirrors; numbers, dates and money through locale formatters; no hardcoded strings.
- Every screen implements its states: loading, empty, error (problem-details mapped to a message, no stack traces or internal IDs), forbidden, offline/partial where the feature is offline-capable.
- Accessibility per the committed target: TalkBack semantics / VoiceOver labels, focus order in RTL, reduced motion, text scaling (Android) and Dynamic Type (iOS).
- Tokens and secrets: secrets never in the binary; tokens in Keystore / Keychain; telemetry carries no PII.

**Android** (`android-lead`): screen = `Route` + stateless `Screen`; one immutable `StateFlow<UiState>` per ViewModel; the composition root in one place; baseline profile and R8 as the Senior Bar requires. **Play requirements come from `docs/stack-reference/compose/VERSION.md`** (target API, edge-to-edge, predictive back, permission declarations, data-safety inputs for `release-manager`) — a requirement not in the file is `NOT SOURCEABLE`.
**iOS** (`ios-lead`): `@Observable @MainActor` view models over use cases, the KMP framework behind Swift-side protocols and the facade from the ADR, Swift 6 strict concurrency. **App Store requirements come from `docs/stack-reference/swiftui/`** (privacy manifest `PrivacyInfo.xcprivacy` and required-reason declarations, ATS, deployment target, entitlements) — absent items `NOT SOURCEABLE`. The lead may write code on this host but cannot build or run it: the report says `written, not built`.

Each lead returns its file set first; you ask once for both sets (a single `AskUserQuestion` naming every path); each writes after a yes. Unit/component tests per the layer's standard are part of the work.

### Phase 5: Review and Evidence (parallel)

Launch together, then collect all before Phase 6:
- **accessibility-specialist** — TalkBack and VoiceOver passes, contrast, focus, motion, text scaling, against the committed target. If `design/accessibility-requirements.md` is absent there is no criterion: report `Accessibility: NOT ASSESSED — no committed target` and do not report the gate as passed.
- **localization-lead** — Arabic RTL mirroring, directional icons, plurals, numerals and dates, mixed-direction strings, truncation, Arabic type.
- **appsec-engineer** (`studio`; at smaller sizes the platform leads own the MASVS mapping with `security-lead` consulted) — MASVS 2.1.0 mapping with negative tests: secrets absent from the binary, Keystore/Keychain storage, backups excluded for sensitive data, validated deep links/intents, locked-down WebViews, privacy manifest completeness. MASVS control IDs for Android are a known gap in the stack reference: look them up in the official document or write `NOT SOURCEABLE`.
- **qa-tester** — runs the feature on the Android emulator/device as each actor including the negative path and the Arabic pass, capturing evidence; iOS cells `NOT COVERED — macOS only` on this host.
- Performance: cold start and jank against `docs/architecture/perf-budgets.md` — Macrobenchmark on a device (Android), Instruments on a macOS host (iOS). No device or host → `NOT MEASURED — [reason]`, never met.

At `studio`, state that the adversarial pass ran.

### Phase 6: Store Requirements, Evidence and Verdict

**Store requirements table** (Play, App Store): requirement | source file in the stack reference | status `MET` / `NOT MET` / `NOT VERIFIED` (reason). `release-manager` (`studio`) takes the items into the release checklist.

**Evidence** in `production/qa/evidence/[story-id]/` (`run-and-observe.md`): **`qa-tester` (Android) and `ios-lead` or `qa-tester` on a macOS host (iOS) run these commands; this skill does not.** Android — `adb exec-out screencap -p > shot.png` for each touched screen, English and Arabic (RTL), light/dark if supported; iOS — `xcrun simctl io booted screenshot shot.png` per touched screen, RTL and Dynamic Type large (macOS only); an API request/response with the negative path; one trace of a request. Open each screenshot with `Read` and compare it to the criterion; **describe only images you opened**. Write `[story-id]-evidence.md` from `.claude/docs/templates/test-evidence.md` with real file names and the sign-off rows **unchecked**. A UI story with no retained screenshots for a platform is reported as **missing evidence** for it — the UI gate is BLOCKING by default.

**Mobile status** (per platform, then overall; first match wins): **BLOCKED** — `PRODUCT.md` absent for UI work, a needed ADR absent, an S1/S2 open, MASVS negative test failing; **NOT ASSESSED** — nothing above, but a platform in scope could not be built, tested, screenshotted or measured (iOS on Linux, no emulator, tasks unconfirmed), accessibility had no committed target, or a store requirement is `NOT SOURCEABLE`; **COMPLETE WITH GAPS** — everything ran, listed gaps accepted; **COMPLETE**. `NOT ASSESSED` outranks `COMPLETE` and ranks below `BLOCKED`.

Ask: "May I write the team mobile report to `production/mobile/[slug]/team-mobile-report.md`?" Write only after a yes; take the date from `date +%F`.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** Resume the agent
naming the unmet contract.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** If one platform lead is blocked, the other still completes and
the report states the blocked platform by name. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input missing (spec, UX spec, `PRODUCT.md`, ADR) → redirect to the skill that creates it
- Shared hand-off changed after the freeze → return to Phase 3; do not patch the platforms around it
- Dev stack or emulator will not come up → that is the finding; capture the logs and stop the execution phase
- Scope too large → split into stories via `/create-stories`

## Output

A summary covering: layers delivered, active set, contract status, shared-module hand-off and tests (run / not run), per-platform implementation status, accessibility and Arabic/RTL results, MASVS results, store-requirements table, performance (measured / not measured), evidence retained, and the mobile status per platform and overall.

Verdict: **COMPLETE** — shared module, Android and iOS delivered, reviewed and evidenced.
Verdict: **COMPLETE WITH GAPS** — everything that could run ran; accepted or listed gaps remain (a platform lead blocked while the other completed, an accepted finding), each named.
Verdict: **COMPLETE — [iOS build | emulator evidence | performance | accessibility | store checks] NOT ASSESSED ([reason])** — the named check could not run; never a plain COMPLETE.
Verdict: **BLOCKED** — a precondition or blocker halted the pipeline; partial report produced.
Verdict: **BLOCKED — write declined by user** — the user declined the file set or the report write; nothing is reported as COMPLETE.

## Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/team-mobile <slug> — <verdict>`, Next step = the first item below (`/code-review` per story), plus Blocked on (e.g. the iOS rows awaiting a macOS host) / Files in progress / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone. Still updated for BLOCKED and a declined write.

- `/code-review` per story, then `/story-done` (UI stories close on retained screenshots; iOS evidence needs the macOS step)
- `/test` for the layers, `/localize qa` for the Arabic pass, `/security-audit mobile` before release, `/team-hardening` for the pre-release pass
- `/release-checklist` and `/team-release` for the Play and App Store submission inputs
