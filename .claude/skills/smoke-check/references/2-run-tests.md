# /smoke-check — Phase 2: Run Automated Tests

> Part of `/smoke-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Run Automated Tests

**In this file:**

- Where the commands come from
- Bring the stack up
- Per layer: Go, Ktor/Kotlin, web, Android, KMP, iOS, contract tests
- Reading the result (the outcomes that look like success and are not)
- Quarantined tests
- A layer whose runner is not available

**Where the commands come from.** The studio configures no `commands.*` keys;
the product's own scripts are the source. For each layer take, in this order,
and name which you used in the report:

1. the target or script the product documents (`Makefile`, `package.json`
   `scripts`, `tools/`, its README or `CLAUDE.md`);
2. the same step in `.github/workflows/` — CI is the command that is known to
   work;
3. the standard invocation named below, where `docs/stack-reference/` sources it.

**Never write a command from memory.** Where the product declares none and the
stack reference does not source one, the layer is `NOT RUN — command not
sourced`, the verdict follows Phase 5, and the next step is `/research` (or
`/test-setup` if the layer has no test infrastructure yet). Wrap every command in
a timeout (`timeout 900 …`): **a timeout (exit 124) is a gate FAILURE, never a
pass** — the run never completed and nothing was verified. macOS has no
`timeout`: use `gtimeout 900 …` from Homebrew's `coreutils` (same exit 124), or,
with nothing installed, `perl -e 'alarm shift; exec @ARGV' 900 …`, which exits
142 when time runs out — a FAILURE the same way. Then read the result for the
layer. On every layer one outcome looks like success and is not; each is named
below.

**Run order**: stack-less suites first (unit), then bring the stack up, then
the suites that need it (contract against real handlers, Playwright), so a
broken unit suite is reported without waiting on containers.

## Bring the stack up

Needed by contract tests that call real handlers, Playwright, and Phase 4
Part A. Skip it only when Phase 1 recorded `NOT RUN — Docker unavailable` or no
compose file — then say which, here and in the report.

```bash
timeout 900 docker compose -f deploy/compose.dev.yaml up -d --wait
```

(`deploy/compose.dev.yaml` is the default; use the file Phase 1 located.)
`--wait` blocks until every service's healthcheck passes. **If a service never
becomes healthy, that is the finding — a FAIL, not a retry:** capture
`docker compose -f <file> ps` and `docker compose -f <file> logs --no-color --tail=200 <service>`
for each unhealthy service and keep them for the report. Do not change the
compose file, the healthcheck or a timeout to get past it.

Migrations run as a one-shot service of the compose stack before the API starts
(a product that migrates with its own `make migrate` instead: the user or the
backend lead runs it — it is not pre-approved here); a migration that failed is a FAIL naming the migration. Seed
data comes from `tools/seed/` with a dedicated test tenant — never a copy of
production data. If the product documents no seed step, the sign-in checks in
Phase 4 are `NOT RUN — no seeded test tenant`.

Record whether this run started the stack or found it running (Phase 1 step 4).

## Go backend

Stack reference: `docs/stack-reference/go/best-practices.md` → Testing.

```bash
timeout 900 go -C backend test -race -json ./...
timeout 900 go -C backend test -race -json -tags integration ./...
```

`-C` runs the command from the Go module root (`backend/`) without a `cd`, so
each line is one approvable command. The second command is the Testcontainers
suite (needs Docker; test files carry the `integration` build tag per
`directory-structure.md`). `-race` is the sourced race-detector flag (it only
finds races on executed paths). Read the `-json` events:

- any `"Action":"fail"` event, or a build failure (`[build failed]` in the output) → FAIL
- count of `"Action":"pass"` events with a `Test` field = tests passed;
  `"Action":"skip"` events = skipped (see below)
- **zero tests executed** (every package `[no test files]`) → `FAIL — no tests executed`, exit code notwithstanding: the suite started and verified nothing

## Ktor / Kotlin backend

Stack reference: `docs/stack-reference/ktor/best-practices.md` (route tests use
`testApplication`) and `kotlin/best-practices.md` → Testing (`runTest`).

Run the Gradle tasks the product documents or its CI runs for `src/test/kotlin`
(unit) and `src/integrationTest/kotlin` (Testcontainers), through the wrapper:
`timeout 900 ./gradlew -p <gradle root> <task>`. **The stack reference does not source the Gradle task names**
(`kmp/best-practices.md` §8 marks the Kotlin/Gradle test commands NOT
SOURCEABLE) — take them from the product, or `NOT RUN — command not sourced`.
Read the JUnit XML the test tasks write (the directory comes from the build
configuration; do not assume it): sum `tests`, `failures`, `errors`, `skipped`.
Any failure or error → FAIL. A compile error writes no XML — which is why the result files' modified times
are recorded before the run (`stat -c '%Y %n' <file>`, one call per file found
by Glob) and compared after it: a file whose time did not change is the last
run's, and reading its pass as this run's is the failure this prevents. Nothing
is deleted. After any exit, no fresh result
files is a FAIL. **`tests="0"` in total → FAIL — no tests executed**, never a pass.

## Web app and marketing site

Stack reference: `docs/stack-reference/vite-react/best-practices.md` §8
(Vitest 5 needs Node 22+; Playwright is pinned to the `pins.yaml` version).

Run the `scripts` the product's `package.json` declares for unit tests (Vitest)
and end-to-end tests (Playwright), with `timeout 900 pnpm -C web run <script>`
(and `-C site` when in scope). The sourced Playwright setup step is
`pnpm exec playwright install --with-deps` — it installs system packages, so it
is not pre-approved: if browsers are missing, name it as the fix and ask the
user to run it, rather than skipping the suite. Playwright journeys run against the
stack brought up above and the seeded test tenant, never against mocks of our
own backend, with CI retries at 0. Read the runner output: any failed test →
FAIL; **zero tests executed → FAIL** whatever the exit code.

## Android

Unit tests (`app/src/test/`) run on the JVM with the product's documented Gradle
task. Instrumented and Compose UI tests (`app/src/androidTest/`) need an emulator
or device: with `adb devices` empty they are `NOT RUN — no emulator or device`.
Report unit and instrumented on separate lines — the unit result does not cover
the instrumented tests, so it cannot make the Android row a PASS. Gradle task
names are the product's (not sourced; same rule as above).

## KMP shared module

`mobile/shared/src/commonTest/kotlin/`. **Kotlin/Gradle test commands for KMP are
NOT SOURCEABLE in the stack reference** (`kmp/best-practices.md` §8), and so are
Compose UI tests on iOS. Run the product's documented task if it has one; if
not, `NOT RUN — command not sourced` and suggest `/research kmp-testing`.

## iOS

Swift Testing for unit tests, XCUITest for UI tests (Swift Testing does not
replace it — `swiftui/best-practices.md` §7). These run only on macOS with the
Xcode version in `swiftui/VERSION.md`. On any other host the iOS suites are
`NOT RUN — iOS needs a macOS runner`; ask the developer for the CI result
(Phase 5 rules). The sourced repetition flags are `swift test --maximum-repetitions N`
and `--repeat-until pass|fail`; the full build/test invocation is the product's
(`xcodebuild`/Xcode invocation syntax is not in the stack reference) and is run
by the user or CI, not by this skill. `timeout 900 swift test` is the one iOS
command this skill may run, on a macOS host.

## Contract tests

Contract tests validate real handler responses against `contracts/openapi/*.yaml`
and live in each consumer's suite. Identify them by path or name (`contract`) in
the layer runs above and report **Contract on its own line**. A product with a
`contracts/` directory and no contract test anywhere → `Contract: NO TESTS`,
which Phase 5 treats as a gap, not a pass.

## Reading the result

Parse runner output and extract, per suite line (`Go unit`, `Go integration`,
`Ktor`, `Web unit`, `Web e2e`, `Android unit`, `Android instrumented`, `KMP`,
`iOS`, `Contract`):

- Total tests run
- Passing count
- Failing count
- Skipped count
- Names of any failing tests (up to 10; if more, note the count)
- Any crash or error output from the runner itself

Outcomes that look like success and are not:

| Looks like | Is | Verdict contribution |
|---|---|---|
| Exit 0, zero tests executed | nothing was verified: a suite that started and ran nothing | `FAIL — no tests executed` |
| Integration suite "passes" with every Testcontainers test skipped or absent because Docker is unavailable | the real dependency was never touched | `NOT ASSESSED — Testcontainers not exercised` |
| Suite passes after an automatic retry | a flake, not a pass | report the **first** run's result; FAIL if it failed |
| A stale result file from an earlier run | not this run | FAIL if no fresh file exists |
| Skipped tests with no linked issue | a disabled test | warning, listed by name (`.claude/rules/test-standards.md`) |
| Timeout (exit 124 / 142) | the run never completed | FAIL |

**Never rerun a failed suite until it goes green.** One diagnostic rerun of a
single failed test is allowed to classify a flake; the report still carries the
first run as FAIL and names the test for `/test-flakiness`. Retry-until-green is
never configured and never simulated here.

## Quarantined tests

If `production/qa/flaky-register.md` exists, list every quarantined test in the
report as a warning, and any past its 14-day fix-or-delete deadline as a named
warning. Quarantined tests run in their own non-blocking job; a quarantined test
failing does not FAIL this gate, but an unlisted failing test is not
quarantined. If the register does not exist, say `flaky register: none found`.

## A layer whose runner is not available

If a layer's toolchain or runner is not available in this environment (Phase 1
step 3 — no Docker, no emulator, not macOS — or a command that cannot be
sourced), report clearly:

"[Layer] tests could not be executed — [reason: Docker unavailable | no emulator
or device | not a macOS host | command not sourced for this layer]. Status will
be recorded as NOT RUN. Confirm the result from your IDE or CI pipeline. Until
you do, the verdict is NOT ASSESSED — not FAIL, and not a pass either: nothing
has been observed about this layer yet."

Do not treat NOT RUN as an automatic FAIL. Record it, and let the developer's
manual confirmation in Phase 4 resolve it. Until that confirmation arrives the
verdict is **NOT ASSESSED** (see the verdict rules in Phase 5), which ranks above
both pass values and below FAIL. An unrun suite is not a healthy build; it is an
unknown one, and the two need different follow-ups.
