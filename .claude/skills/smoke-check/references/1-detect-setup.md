# /smoke-check — Phase 1: Detect Test Setup

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Detect Test Setup

Before running anything, understand the environment:

0. **Config coherence**: run `bash .claude/scripts/project-coherence.sh`.

   It compares what the product declares (`go.mod`, Gradle version catalogs,
   `package.json`, compose image tags, `project.yaml`) against
   `docs/stack-reference/pins.yaml`. This runs first because it is about *this
   skill's own inputs*: a floating image tag (`FLOATING`) or a toolchain far
   behind its pin will fail later and read as a broken build rather than as a
   broken setup.

   Report any `BEHIND`, `FLOATING`, `LICENCE` or `SKIPPED` lines in the report's
   Environment section. They do not by themselves decide the verdict — but a
   smoke check run on images that are not the pinned ones is worth saying out loud.
   A `SKIPPED` line means the comparison did not run; say so, never "coherent".

1. **Layers in scope and test files per layer.** Resolve the code roots with
   `resolve_code_root` (`layout.code_roots`, else the conventional `backend/`,
   `web/`, `site/`, `mobile/`, `contracts/` that exist on disk —
   `.claude/docs/directory-structure.md` → Code roots; **an empty list means
   the scan did not run** — say so and treat the run as NOT ASSESSED, never as
   "nothing to test"). Cross-check with the `stack` line of the resolved config.

   For each layer, verify that **real test files** exist — not merely that a
   directory does. Use the test location from the table:

   | Layer | A test file is… |
   |---|---|
   | Go backend | `*_test.go` beside the code; integration tests carry the `integration` build tag |
   | Ktor backend | a class under `src/test/kotlin/` (unit) or `src/integrationTest/kotlin/` (Testcontainers) |
   | Web app / marketing site | `*.test.ts(x)` beside the code; Playwright specs in `web/e2e/` or `site/e2e/` |
   | KMP shared | a file under `mobile/shared/src/commonTest/kotlin/` |
   | Android | `app/src/test/` (unit) or `app/src/androidTest/` (instrumented) |
   | iOS | a Swift Testing / XCTest target with at least one `@Test` or `test…` method |
   | Contracts | a contract test in a consumer that reads `contracts/` |

   Markdown checklists do not count. A `.gitkeep`, a placeholder test that
   asserts `true`, or a file `/test-setup` scaffolded and nobody filled in is not
   a test.

   If none are found **at any `qa.level`** — tests exist at every tier, so
   `minimal` is not an exception — **deliver a NOT ASSESSED verdict — do not
   merely stop.** "Smoke check: **NOT ASSESSED — no tests found** under [the
   layer test locations]. Run `/test-setup` to scaffold the testing
   infrastructure, or point me at where tests live." Then stop.

   > A bare halt is the wrong shape here. This is the state with the **least**
   > information about build health, so it is the last one that should exit
   > without a verdict: the caller gets no machine-readable outcome, and "the
   > skill said nothing" is easy to read as "nothing was wrong".

   > **Do not gate on `tests/` or a test directory existing.** `/test-setup`
   > creates the directories and a placeholder per layer, so the tree is present
   > on any product that ran setup — whether or not a single test was ever
   > written. Count actual test files instead.

   When only some layers have tests, continue: a layer in scope with no tests is
   reported by name as `NO TESTS` in Phase 2 and holds the verdict at NOT
   ASSESSED at every `qa.level` (Phase 5).

2. **CI check**: check whether `.github/workflows/` contains a workflow that runs
   tests. Note in the report whether CI is configured, and whether its action
   references are pinned by commit SHA (`security-baseline.md`) — an unpinned
   third-party action is a warning, not a verdict input.

3. **Toolchain and runner availability, per layer in scope.** Probe, do not
   assume — `command -v` / `--version` for what the layer needs:

   | Needs | Probe | Unavailable means |
   |---|---|---|
   | Docker + Compose | `docker info` and `docker compose version` | Part A and every Testcontainers suite cannot run → `NOT RUN — Docker unavailable` |
   | Go | `go version` | Go suites `NOT RUN` |
   | JDK + Gradle wrapper | `java -version`; `./gradlew -p <gradle root> --version` | Kotlin/Android/KMP suites `NOT RUN` |
   | Node + pnpm | `node --version`; `pnpm --version` | web suites `NOT RUN` |
   | Android emulator or device | `adb devices` | instrumented tests and Android surface checks `NOT RUN` |
   | macOS + Xcode | `uname -s` is `Darwin`; `xcodebuild -version` | iOS suites and iOS surface checks `NOT RUN — iOS needs a macOS runner` |

   Compare the Go, Node and Xcode versions found against `pins.yaml`; a version
   below the pin is a warning in the report, a missing toolchain is `NOT RUN`.

4. **The compose file.** Locate the stack definition: `deploy/compose.dev.yaml`
   (`run-and-observe.md`), or the product's equivalent named in its README or
   `CLAUDE.md`. Check it exists and that `docker compose -f <file> config -q`
   parses it. Record whether the stack is **already running**
   (`docker compose -f <file> ps`) — Phase 4 leaves a stack it did not start
   running. Missing file → Part A is `NOT RUN — no compose file`; the verdict
   follows Phase 5.

5. **Smoke test list**: check whether `production/qa/smoke-tests.md` exists. If a
   smoke test list is found, load it for use in Phase 4. If it does not exist,
   smoke checks are drawn from the current QA plan (Phase 4 fallback).

6. **QA plan check**: glob `production/qa/plan-*.md` (`/qa-plan` writes
   `plan-[slug]-[date].md`) and take the most recently modified file. If found, note the path — it will be used in Phase 3 and
   Phase 4. If not found, note: "No QA plan found. Run `/qa-plan sprint` before
   smoke-checking for best results." (At `workflow: minimal`, which has no
   sprints, a QA plan is optional — say so rather than recommend one.)

Report findings before proceeding: "Layers: [list, with code root]. Test files:
[per layer: found / none]. Toolchains: [per layer: available / missing].
Compose file: [path / not found]; stack already running: [yes / no]. CI
configured: [yes / no]. QA plan: [path / not found]."

---
