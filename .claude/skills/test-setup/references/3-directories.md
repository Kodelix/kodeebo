# /test-setup — Phase 3: Create Directory Structure and Layer Scaffolds

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Create Directory Structure and Layer Scaffolds

**In this file:**

- The sourcing rule
- `production/qa/README.md`
- `production/qa/evidence/.gitkeep` and `production/qa/cases/.gitkeep`
- Per layer: Go, Ktor/Kotlin, web, marketing site, Android, KMP shared, iOS, contracts

After approval, create the following files.

**The sourcing rule.** Every version below is read from `docs/stack-reference/pins.yaml`
at run time — the `<pins …>` markers name the key. A version, API or config key
that `pins.yaml`, the layer's `best-practices.md` and
`docs/research/test-infrastructure.md` all lack is **not written**: record it as
`PENDING — NOT SOURCEABLE — <what> is not covered by <path>` for the summary and
the README's "Pending" section. A file that cannot be written correctly without
the missing item is not created; a file that can is created without the
unsourced line. Never fill a gap from training data.

### `production/qa/README.md`

````markdown
# Test Infrastructure

**Stack**: [`stack` line — backend / web / site / mobile; data stores]
**Test frameworks**: [per layer — see the table]
**CI**: `.github/workflows/tests.yml`
**Setup date**: [date]

## Test locations (from `.claude/docs/directory-structure.md`)

| Layer | Code root | Test location |
|---|---|---|
| Go backend | `backend/` | `*_test.go` beside the code; integration tests behind the `integration` build tag |
| Ktor backend | `backend/` | `src/test/kotlin/` (unit), `src/integrationTest/kotlin/` (Testcontainers) |
| Web app | `web/` | `*.test.ts(x)` beside the code; Playwright in `web/e2e/` |
| Marketing site | `site/` | Playwright smoke in `site/e2e/` |
| KMP shared | `mobile/shared/` | `src/commonTest/kotlin/` |
| Android | `mobile/android/` | `app/src/test/` (unit), `app/src/androidTest/` (instrumented) |
| iOS | `mobile/ios/` | Swift Testing / XCTest targets |
| Desktop client | `desktop/` | as the desktop ADR states (`PENDING — NOT SOURCEABLE` until it does) |
| Contracts | `contracts/` | contract tests run from each consumer |

[Keep only the rows for configured layers; list the others under "Not configured".]

```
production/qa/
  README.md        # this file
  smoke-tests.md   # critical-path list for /smoke-check
  evidence/        # run-and-observe records, screenshots, load-test results, per story
  cases/           # test cases per story (qa-tester)
```

## Running Tests

[Per layer, the command the product uses — filled in as each layer lands. Sourced
starting points: Go `go test -race ./...` and, for the Testcontainers suite,
`go test -race -tags integration ./...`; web `pnpm exec playwright install --with-deps`
once, then the `package.json` scripts. A layer whose command is NOT SOURCEABLE is
listed under Pending.]

## Test Naming (`.claude/rules/test-standards.md`)

- Go: `TestInvoice_Pay_RejectsAlreadyPaid` — `Test<Subject>_<Action>_<Expectation>`
- Kotlin: backtick names — `` `pay rejects an already paid invoice` ``
- TypeScript: `describe('Invoice') / it('rejects paying an already paid invoice')`
- Swift Testing: `@Test("Pay rejects an already paid invoice")`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location | Default gate |
|---|---|---|---|
| Logic | Unit tests, must pass | beside the code | BLOCKING |
| Integration | Testcontainers integration test | per layer | BLOCKING |
| Contract | Contract test against `contracts/` | per consumer | BLOCKING |
| Security | Negative tests + ASVS/MASVS mapping | per layer + `production/qa/evidence/` | BLOCKING |
| Performance | Load-test result vs budget | `production/qa/evidence/` | ADVISORY (BLOCKING when `performance.enforce: block`) |
| UI | Retained screenshot of every screen touched + `/impeccable audit` | `production/qa/evidence/` | BLOCKING |
| Config | Smoke check pass | `production/qa/smoke-[date].md` | ADVISORY |

## Flaky Tests

A test that fails then passes on rerun is quarantined within one day with an
issue and an owner, runs in a separate non-blocking job, and is fixed or deleted
within 14 days. Rerun-until-green is never configured. Register:
`production/qa/flaky-register.md` (`/test-flakiness`).

## CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging. A job that executes zero tests fails.

## Pending (NOT SOURCEABLE)

[Every item Phase 3 and 4 could not write, with the file that would cover it.
"None" is stated explicitly when true.]
````

The README and this skill's completion summary name the same evidence path —
`production/qa/evidence/` is where `/smoke-check`, `/test-evidence-review`,
`/qa-plan` and the evidence table in `.claude/docs/coding-standards.md` read.

### `production/qa/evidence/.gitkeep` and `production/qa/cases/.gitkeep`

Create both empty. Git does not keep an empty directory, and these are where
`/story-done`, `/smoke-check` and `/test-evidence-review` look for screenshots,
transcripts and sign-off records, and where `qa-tester` stores cases — the
completion summary lists them, so they must exist.

### Go backend (`stack.backend` is `go` or `go+ktor`)

Stack reference: `docs/stack-reference/go/best-practices.md` → Testing;
`postgres/best-practices.md` §7.

No test directory to create — Go tests sit beside the code. Create nothing under
`backend/` except as follows, and say so in the summary ("Go: nothing to
scaffold; conventions documented").

- **Unit**: `go test -race ./...` (race detector sourced). Table-driven tests with
  a `name` field and `t.Run`, `t.Parallel()` inside subtests; failure messages
  include input, got, want. No `testify` unless an ADR accepts it.
- **Integration**: files start with `//go:build integration`; run with
  `-tags integration`. Testcontainers-go with the Postgres module (`modules/postgres`;
  `WithDatabase`, `WithUsername`, `WithPassword`), image from `pins.yaml`
  `postgres.image` — the exact tag, never `latest`. Connect as the non-owner,
  NOBYPASSRLS application role, never the container superuser (the RLS test
  passes vacuously otherwise). One container per suite, a fresh database or
  schema per test. The harness itself is `/test-helpers`' output.
- **Deterministic time and randomness**: inject `Clock` and `IDGenerator`;
  `testing/synctest` for concurrency (GA since Go 1.25), `cryptotest.SetGlobalRandom`
  for crypto-dependent tests (Go 1.26).
- **Adding the dependency**: `testcontainers-go` and its Postgres module are not
  in `pins.yaml`. If `docs/research/test-infrastructure.md` records the version,
  show the `go get` line for that exact version and let the user run it — it is
  not pre-approved, and `go.mod` is the Go lead's file. Otherwise: `PENDING — NOT SOURCEABLE —
  testcontainers-go version is not covered by pins.yaml or go/best-practices.md`.
- **Lint for tests**: `testifylint` only if testify is in use
  (`tooling/best-practices.md`).

### Ktor / Kotlin backend (`stack.backend` is `ktor` or `go+ktor`)

Stack reference: `ktor/best-practices.md` (`testApplication`),
`kotlin/best-practices.md` → Testing (`runTest`).

Create `backend/src/test/kotlin/.gitkeep` and
`backend/src/integrationTest/kotlin/.gitkeep` (directory locations per
`directory-structure.md`).

Sourced additions (versions from `pins.yaml`, as catalog entries — show the exact
lines and ask before editing the Gradle files):

| Dependency | Version | Source |
|---|---|---|
| `ktor-server-test-host` (group `io.ktor`) | `<pins ktor.ktor>` | `ktor/best-practices.md` — Testing: testApplication |
| `kotlinx-coroutines-test` (group `org.jetbrains.kotlinx`) | `<pins kotlin.coroutines>` | `kotlin/best-practices.md` — Testing |
| `kotlin.test` | the Kotlin version, `<pins kotlin.kotlin>` | `kotlin/best-practices.md` — Testing |

Route tests use `testApplication { application { module() } … }` — modules are
**not** auto-loaded from config; never `withTestApplication`. Coroutine tests use
`runTest` (virtual time); never `sleep`.

`PENDING — NOT SOURCEABLE` unless `test-infrastructure.md` covers them:
- JUnit 5 and the Testcontainers Java artifacts (`org.testcontainers:testcontainers-postgresql`
  is the sourced coordinate; the versions are not in `pins.yaml`)
- the Gradle configuration that makes `src/integrationTest/kotlin` a source set with its
  own task, and the exact `./gradlew` tasks CI runs (`kmp/best-practices.md` §8 marks
  Kotlin/Gradle test commands NOT SOURCEABLE)
- an assertion library (`kotlin/best-practices.md`: no first-party recommendation)

### Web app (`stack.web` is `vite-react`)

Stack reference: `vite-react/best-practices.md` §8, §10, §11.

Create `web/e2e/.gitkeep`. Versions from `pins.yaml`: Node `<vite-react.node>`
(Vitest 5 needs Node 22+), pnpm `<vite-react.pnpm>`, Vitest `<vite-react.vitest>`,
Playwright `<vite-react.playwright>` — **pinned exactly** (browsers ship with the
Playwright version, so visual baselines stay stable).

Propose, and apply only after approval, the `web/package.json` changes: the
devDependencies above at those exact versions and two scripts (`test` for Vitest,
`test:e2e` for Playwright — the names are the product's choice; keep them in the
README). Do not weaken the `pnpm-workspace.yaml` supply-chain settings
(`web-react.md`): new dependencies go through `pnpm add` with a reason, honouring
`minimumReleaseAge` — the command is printed for the user to run, never run here.
Sourced setup step (also the user's to run): `pnpm exec playwright install --with-deps`.

Create `web/playwright.config.ts` only if its keys are verified (Playwright docs
at the pinned version, via the research note). It must express:

- `retries: 0` — retry-until-green is never configured
- one project per viewport × locale: **1440 px and 390 px**, **English and Arabic (RTL)**
- `baseURL` pointing at the dev compose stack (`docker compose -f deploy/compose.dev.yaml up -d --wait`),
  never mocks of our own backend; only third-party HTTP is faked
- role/label selectors by convention (no CSS chains) — a README line, not config
- screenshots written under `production/qa/evidence/<story-id>/` by the specs themselves

Unverified keys are omitted and listed as `PENDING`. Likewise the Vitest config
(`environment`, setup file) and Testing Library: **Testing Library versions are not
in `pins.yaml`** (`web-react.md` names Vitest + Testing Library for components and
hooks) → `PENDING — NOT SOURCEABLE` until the research note records them.
Vitest 5: use `concurrent`, not the removed `sequential`.

### Marketing site (`stack.site` is `astro`)

Create `site/e2e/.gitkeep`. A Playwright smoke suite with the same pinned Playwright
version as the web app; the site's own `package.json` is changed only after approval.
Lighthouse CI belongs to `/perf-profile`, not here.

### Android (`stack.mobile` includes `compose` or `kmp`)

Stack reference: `compose/best-practices.md` §8.

Create `mobile/android/app/src/test/.gitkeep` and
`mobile/android/app/src/androidTest/.gitkeep`. Sourced dependencies (versions via
the Compose BOM `<pins compose.bom>`):
`androidTestImplementation("androidx.compose.ui:ui-test-junit4")` and
`debugImplementation("androidx.compose.ui:ui-test-manifest")` (the latter when
using `createComposeRule()`; `createAndroidComposeRule<YourActivity>()` does not
need it). Compose 1.11+ coroutine tests use the v2 APIs (`StandardTestDispatcher`).
Show the lines and ask before editing the Gradle files.

`PENDING — NOT SOURCEABLE`: test tags and semantics finders beyond `onNodeWithText`,
Robolectric guidance, the instrumentation-runner configuration, JUnit versions, and an
emulator job for CI (`compose/best-practices.md` §8; Espresso is not covered at all).

### KMP shared module (`stack.mobile` includes `kmp`)

Create `mobile/shared/src/commonTest/kotlin/.gitkeep`. `PENDING — NOT SOURCEABLE`:
the Kotlin/Gradle test commands for KMP and Compose UI tests on iOS
(`kmp/best-practices.md` §8) — ask for `/research kmp-testing`; do not write a
`commonTest` build configuration from memory.

### iOS (`stack.mobile` includes `swiftui` or `kmp+swiftui`)

Stack reference: `swiftui/best-practices.md` §7–§8.

Xcode project and test-target membership are not scaffolded by writing files:
create nothing under `mobile/ios/` and put the following in the README: Swift
Testing (`@Test`, `@Suite`, `#expect`, `#require`) for new unit tests; XCUITest for
UI tests (Swift Testing does not replace it); both run on a macOS runner whose
Xcode matches `swiftui/VERSION.md`; `swift test --maximum-repetitions N` and
`--repeat-until pass|fail` for flake detection. Ask the user to add the targets in
Xcode (or a Swift package) and list this as a manual step in the summary.

### Contracts (`contracts/` exists, or `stack.backend` is set)

Contract tests validate **real handler responses** against `contracts/openapi/*.yaml`
(including every `application/problem+json` error status), and run from each
consumer. Create nothing under `contracts/`; document in the README which
consumer suites carry them. `PENDING — NOT SOURCEABLE`: the OpenAPI response-validation
library per consumer — it is a dependency choice, so it needs an ADR
(`architecture-decision`) after a `/research` note; say so rather than naming a tool.

---
