# /test — Phase 2: Per-Layer Commands and Preconditions

> Part of `/test`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its headings still apply here.

**Where a command comes from, in this order — and the source is recorded in the
plan table:**

1. The product's own entry points: `Makefile`/task runner targets, the `scripts`
   in `package.json`, Gradle tasks, the CI workflow's test steps. A command the
   product already defines is the one to run.
2. The stack reference under `docs/stack-reference/<layer>/` and
   `docs/stack-reference/pins.yaml` (tool versions: compare the installed
   version with the pin and report a mismatch; do not "fix" it).
3. The tool's own help output on this host (`go help testflag`, `pnpm run`,
   `pnpm exec playwright test --help`, `./gradlew tasks --all`) — quote what you
   used.

Anything found in none of the three is `NOT RUN — [command] not confirmed`.
Never write a flag, task name or script from memory.

---

## Go backend (`backend/`, a `go.mod` present)

| Suite | Command | Source |
|---|---|---|
| Unit, whole module | `go -C backend test ./...` (module root, no `cd`) | product script, else stack reference (`go/best-practices.md` Testing) |
| Race | `go -C backend test -race ./...` | `docs/stack-reference/go/best-practices.md` ("Race detector"). Only finds races on executed paths; 2–20x time — say so in the report |
| Integration | the product's target; else the `integration` build tag per `directory-structure.md` (confirm the tag flag with `go help build`/`go help testflag` and quote it) on the changed packages | `directory-structure.md` + host help |
| Benchmarks | not run here — `/perf-profile` | — |

- Run the unit suite on the **whole module** (the budget is under 30 s, so the
  cost is small and a change can break a dependent package). Run integration on
  the changed packages unless `all`, `--integration` on a migration/repository
  change, or the user widens it.
- **Precondition for integration:** a container runtime (`docker info` exits 0)
  and the Testcontainers images available per `pins.yaml`. Not available →
  `NOT RUN — container runtime unavailable`; do not pull images without asking.
- Look for `*_test.go` in the changed packages. Changed non-test Go files whose
  package has no `_test.go` are listed under "changed code without tests".
- `go test` exits 0 with "no test files" for a package without tests — that is
  **zero tests executed** for that package; count it, do not call it a pass.
  Zero tests executed across the whole suite is a `FAIL`.

## Ktor backend (`backend/`, a Gradle build)

**The Gradle task names are unverified in the stack reference** (the KMP page
marks "Kotlin test and Gradle commands" as NOT SOURCEABLE; `kotlin/best-practices.md`
only says to use the Gradle wrapper). So:

1. Confirm the wrapper exists (`./gradlew`; Glob). Tasks run as
   `./gradlew -p <gradle root> <task>`. Absent → `NOT RUN — no Gradle wrapper`.
2. List the tasks the build really defines: `./gradlew -p <gradle root> tasks --all`, and read the
   build files (`build.gradle.kts`, `settings.gradle.kts`, convention plugins) for
   the unit task and for the `src/integrationTest/kotlin` source set's task.
3. Run `check` only if it appears in that listing; run the integration-source-set
   task only if it is named in the build files or the listing. Quote both.
4. Not confirmable → `NOT RUN — Gradle task [check|integrationTest] not confirmed
   in [files and listing checked]`. The wrapper may download a Gradle
   distribution; if the host is offline and it is absent → `NOT RUN — wrapper
   cannot fetch its distribution`.
- Integration needs the container runtime, as for Go.

## Web app (`web/`) and marketing site (`site/`)

- Read `web/package.json` `scripts`. Run, in this order, those that exist:
  lint, typecheck, unit/component test. Use the **script names the product
  defines**; a missing one is `NOT RUN — no [lint|typecheck|test] script in
  web/package.json` (and `/test-setup` is the fix), never an ad-hoc substitute.
  Run with `pnpm -C web run <script>` (`-C site` for the site); compare `pnpm --version` with `pins.yaml`.
- **Dependencies not installed** (`web/node_modules` absent) → ask before
  `pnpm -C web install --frozen-lockfile`: install runs under the supply-chain settings in
  `docs/stack-reference/vite-react/best-practices.md` §11 (`strictDepBuilds`,
  allowlist). Declined → `NOT RUN — dependencies not installed`.
- **Playwright when UI is touched** (changed files under `web/src/` that render
  screens: routes, features, components, styles, i18n resources; or `site/`
  pages): needs the stack (`up --wait`), Docker, and the pinned browsers. The
  sourced install step is `pnpm exec playwright install --with-deps`
  (`vite-react/best-practices.md` §8) — not pre-approved, so the user runs it; browsers
  absent and not installed → `NOT RUN — Playwright browsers not installed`.
  Run the product's e2e script, else `pnpm -C web exec playwright test` after
  confirming it with `--help`. Report projects/viewports and locales that
  actually ran (the standard expects 1440 px and 390 px, English and Arabic
  RTL); a locale or viewport the config does not define is `not covered`, not
  assumed.
- Failing UI tests leave traces/screenshots; list their paths. They do not
  replace the retained evidence `/story-done` needs for a UI story.

## Contracts (`contracts/`)

When `contracts/` changed: (a) the backend's contract tests — tests that
validate real handler responses against `contracts/openapi/*.yaml` including
`application/problem+json` errors; (b) each consumer's contract tests (web, KMP,
Swift client). Find them by searching the test roots for references to
`contracts/`; run them with the layer's command above. None found for a changed
contract → `NOT RUN — no contract test found for [operation]` and list it as a
gap (a Contract story's evidence is BLOCKING by default). The lint and the
breaking-change diff belong to `/api-contract`: suggest it, do not substitute.

## KMP shared module (`mobile/shared/`)

Test commands for KMP are **NOT SOURCEABLE** in `docs/stack-reference/kmp/`.
Same procedure as Ktor: read the Gradle listing and build files, run only a
confirmed JVM-target test task. iOS-target tests require macOS →
`NOT RUN — macOS only`. Nothing confirmed → `NOT RUN — KMP test task not
confirmed`; suggest `/research` for the command.

## Android (`mobile/android/`)

- Unit tests (`app/src/test`): a Gradle task confirmed as above. Not confirmed →
  `NOT RUN`.
- Instrumented/Compose UI tests (`app/src/androidTest`): need an emulator or
  device. `adb devices` lists none (or `adb` is absent) → `NOT RUN — no
  device/emulator`. Do not start or install an emulator without asking.
- Android SDK/JDK absent → `NOT RUN — toolchain not installed`.

## iOS (`mobile/ios/`)

iOS builds and tests run on **macOS CI only** (`docs/stack-reference/swiftui/best-practices.md`
§8). On this host (`uname -s` is not `Darwin`): `NOT RUN — iOS suites require a
macOS runner`. If the user supplies a CI run link or output, record it as
`reported by user, not run here` with the source and date — it is not evidence
this skill produced. Never mark an iOS layer in scope as passed on a Linux host.

## Cross-cutting

- **Security-type changes** (auth, billing, licensing, tenancy, webhooks): note
  whether negative tests (anonymous, wrong role, wrong tenant) exist in the
  touched test files — presence only; their quality is `/test-evidence-review`'s.
- **Coverage:** run only if the product's script already produces it. Domain +
  app packages are expected at 85 % or higher; when not measured the report says
  `coverage: not measured` — never a number from memory.
- **Quarantined/skipped tests:** grep the touched test roots for skip markers
  and the quarantine register under `production/qa/`; list each with its owner
  if recorded, or `no owner recorded`.
