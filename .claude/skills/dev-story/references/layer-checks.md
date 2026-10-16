# /dev-story — Layer Checks

> Lookup table for Phase 6 (`references/6-verify.md`). Commands are run from the
> repository root with a directory flag (`go -C`, `pnpm -C`, `swift test --package-path`,
> `./gradlew -p`) — never `cd dir && cmd`, which no permission pattern can approve. Where
> a tool has no sourced directory flag (`golangci-lint`, `govulncheck`), the row says
> which agent runs it in its directory. **Every row is a check that may not run**:
> a missing toolchain, an unreachable container runtime, an unset layer or a
> script the project does not define is reported `not run — [reason]` and is
> never counted as passed.

**Where the commands come from.** Go commands: `.claude/rules/backend-go.md`,
`docs/stack-reference/go/best-practices.md`, `docs/stack-reference/tooling/best-practices.md`.
`pnpm` supply-chain and audit commands: `docs/stack-reference/vite-react/best-practices.md` §11.
Swift tests: `docs/stack-reference/swiftui/VERSION.md` (macOS with Xcode only).
Gradle task names (`ktlintCheck`, `detekt`, the integration-test task) are
**NOT SOURCEABLE** in `docs/stack-reference/` — confirm them with
`./gradlew tasks --all` in the project (or from the build files) before running;
a task that does not exist is `not run — task not defined`, never a pass. The same
holds for `package.json` script names: read `web/package.json` `scripts` first.

## Go (`backend/`, `stack.backend` = `go` or `go+ktor`)

| Check | Command | Passes when | Needs |
|---|---|---|---|
| Format | `gofmt -l backend/` | prints nothing | Go toolchain |
| Vet | `go -C backend vet ./...` | exit 0 | Go toolchain |
| Unit tests + race | `go -C backend test -race ./...` | exit 0 | Go toolchain (cgo for `-race` on some hosts) |
| Integration tests | `go -C backend test -race -tags=integration ./...` | exit 0 | Go + container runtime (Testcontainers: Docker or Podman socket reachable) |
| Lint | `golangci-lint run ./...` in `backend/` — run by `go-lead` (spawned via `Agent`; no directory flag is sourced in `docs/stack-reference/tooling/best-practices.md`) | exit 0 (config is `version: "2"`) | golangci-lint v2 (`pins.yaml`) |
| Vulnerabilities | `govulncheck ./...` in `backend/` — run by `go-lead` (spawned via `Agent`) | no reachable vulnerabilities — **exit code is 0 either way**, so read the output | `govulncheck` — **may be NOT INSTALLED** (`go install golang.org/x/vuln/cmd/govulncheck@latest`); if absent → `not run — govulncheck not installed` |
| Dependency scan (all ecosystems) | `osv-scanner scan -r .` | no findings above the project's threshold | `osv-scanner` — may be NOT INSTALLED → `not run` |
| Benchmarks (budgeted hot path) | `go -C backend test -bench=. -benchmem ./internal/<context>/...` | recorded vs the budget | Go toolchain |

## Ktor / Kotlin (`backend/`, `stack.backend` = `ktor` or `go+ktor`; `mobile/shared`, `mobile/android`)

| Check | Command | Passes when | Needs |
|---|---|---|---|
| Build + unit tests + lint | `./gradlew -p <module-root> check` (confirm the wrapper location in the build files first) | exit 0 | JDK per `pins.yaml` |
| Style | `./gradlew ktlintCheck` (task name per build config) | exit 0 | ktlint configured — else `not run — ktlint not configured` |
| Static analysis | `./gradlew detekt` (task name per build config) | exit 0 | detekt configured — else `not run — detekt not configured` |
| Integration tests | the integration source-set task defined in the build (`src/integrationTest/kotlin/`) | exit 0 | JDK + container runtime |
| Android instrumented tests | `./gradlew connectedAndroidTest` (task per build config) | exit 0 | emulator or device attached — else `not run — no emulator/device` |
| Dependency scan | `osv-scanner scan -r .` (reads Gradle lockfiles/manifests) | clean | `osv-scanner` — may be NOT INSTALLED |

## Web (`web/`, `site/`)

| Check | Command | Passes when | Needs |
|---|---|---|---|
| Install | `pnpm -C web install --frozen-lockfile` | exit 0; lockfile unchanged | pnpm at the version in `packageManager` |
| Lint | `pnpm -C web lint` | exit 0 | script defined in `package.json` (ESLint 10 flat config) |
| Typecheck | `pnpm -C web typecheck` | exit 0 | script defined |
| Unit/component tests | `pnpm -C web test` | exit 0 | script defined (Vitest) |
| Build | `pnpm -C web build` | exit 0; bundle size vs the shell budget (≤ 170 KB gzipped initial JS) | — |
| E2E / screenshots | `pnpm -C web exec playwright test` (Playwright in `web/e2e/`) | exit 0; screenshots written | browsers installed (`pnpm exec playwright install --with-deps`) |
| Supply chain | `pnpm -C web audit`; then the `Grep` tool (not shell grep) over `web/pnpm-lock.yaml` for `react-server-dom-\|plugin-rsc\|"next@\|waku\|rwsdk` | audit clean; the Grep result **empty** | pnpm |

Run `site/` checks the same way with `pnpm -C site ...`, plus `pnpm -C site build` then `pnpm -C site preview` (two commands) for run-and-observe.

## Contracts (`contracts/`)

| Check | Command | Passes when | Needs |
|---|---|---|---|
| Lint the spec | Spectral or the linter the ADR chose (`.claude/rules/contracts.md`) | exit 0 | the linter — else `not run — linter not configured` |
| Breaking-change diff | the diff tool the project chose, against the base branch | none, or an ADR + deprecation headers exist | the tool — else `not run` |
| Client regeneration | the project's codegen command (`tools/`) | generated TS / KMP / Swift clients are regenerated in the **same change**, no manual edit | — |
| Consumer contract tests | each consumer's test command above | exit 0 | — |

## iOS (`mobile/ios/`)

| Check | Command | Passes when | Needs |
|---|---|---|---|
| Swift tests | `swift test --package-path mobile/ios` (package) or `xcodebuild test -scheme <scheme> -destination '<simulator>'` | exit 0 | **macOS with Xcode** (`docs/stack-reference/swiftui/VERSION.md`) |

**On a non-macOS host these tests are `not run — requires macOS with Xcode`.** They
are then expected to run on the macOS CI runner; the summary says exactly that,
and a Done decision waits for the CI result (never inferred from reading the code).
SwiftLint, if configured: `swiftlint lint mobile/ios` — same macOS note.

## Migrations and data (`backend/**/migrations`)

| Check | Command | Passes when | Needs |
|---|---|---|---|
| Migration lint | `bash .claude/scripts/migration-lint.sh <changed .sql files>` | no DANGER; WARN/MISSING each have a written decision | — (script prints observations, exit always 0: read them) |
| Up on empty DB / up on seeded DB / down (dev) / integration suite green after | the project's migrate command (`make migrate` or the compose one-shot) against a Testcontainers or compose Postgres. Run by `test-automation-engineer` (spawned via `Agent`); a destructive step (`down`, drop) is never in this skill's grants | all succeed | container runtime |

## Secrets and repo hygiene (every story)

| Check | Command | Passes when | Needs |
|---|---|---|---|
| Secrets in the diff | `gitleaks git --pre-commit --staged` (staged) or `gitleaks dir <changed paths>` | no leaks | gitleaks (`/usr/bin/gitleaks` on the dev host) |
| Studio coherence (when stack/deploy files changed) | `bash .claude/scripts/project-coherence.sh` | observations only | — |

## Run-and-observe stack

```bash
docker compose -f deploy/compose.dev.yaml up -d --wait
```
(granted exactly in this form; `ps`, `logs` and `down` without `-v` are the other granted forms — nothing else, in particular no `down -v`.)
`--wait` blocks until every healthcheck passes; a service that never becomes
healthy **is the finding** — capture `docker compose logs <svc>`. If Docker is not
installed or the daemon is not reachable, run-and-observe is `NOT VERIFIED —
container runtime unavailable`. Tear down with `docker compose -f deploy/compose.dev.yaml down`;
never `down -v` unless the user asks for a clean slate (`run-and-observe.md` §5).
