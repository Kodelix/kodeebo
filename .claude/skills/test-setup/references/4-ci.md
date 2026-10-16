# /test-setup — Phase 4: Create CI/CD Workflow

> Part of `/test-setup`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Create CI/CD Workflow

**In this file:**

- Rules for the workflow
- Resolve each action to a commit SHA
- The workflow template: Go, web (Vitest and Playwright)
- Jobs that are not written, and why

Create `.github/workflows/tests.yml` if no workflow already runs the tests. If
one does, do not create a second: show the diff you would apply and ask.
(`platform-lead` owns CI configuration after this skill's first write; say so in
the summary.)

### Rules for the workflow

- Triggers: `push` to `main` and `pull_request` to `main`. Never
  `pull_request_target`.
- `permissions: contents: read` at the top level; widen per job only with a
  reason. The jobs need **no secrets**; do not add any.
- Every third-party action is pinned by **commit SHA**
  (`security-baseline.md` → Supply chain), with the release tag in a trailing
  comment. A tag or branch reference is not pinned.
- Language toolchain versions come from `pins.yaml`, never typed from memory.
- `timeout-minutes` on every job; a `concurrency` group that cancels superseded
  runs on the same ref.
- **Retries are 0.** No retry action, no `--retries`, no rerun-on-failure: a red
  test is quarantined (`/test-flakiness`), never retried into green.
- **A job that executes zero tests fails.** Each test step writes its
  machine-readable output to a file and a following step asserts that tests ran.
  A layer whose report format is not sourced gets no job until it is
  (see "Jobs that are not written").
- Test reports (machine-readable plus the human summary) are uploaded with
  `if: always()` so a red run still leaves evidence.
- Jobs are written only for layers whose **code root exists on disk**. A
  configured layer that is not scaffolded yet gets no job, and the summary says
  `deferred until the layer exists — re-run /test-setup force`. (A job over an
  empty layer would fail on the zero-test rule on the first push.)

### Resolve each action to a commit SHA

The stack reference does not list GitHub Actions or their versions
(`NOT SOURCEABLE`). Resolve them from the actions' own repositories, with the
user choosing the release. For each action the workflow needs
(`actions/checkout`, `actions/upload-artifact`, the Go setup action, the Node
setup action, the pnpm setup action, and a Java setup action only when a Kotlin
job is being written from the research note):

1. List release tags, excluding pre-releases:
   ```bash
   git ls-remote --tags --refs "https://github.com/<owner>/<repo>.git"
   ```
   Strip the `refs/tags/` prefix, sort by version and keep the newest eight in
   your own reading — no pipe is run.
2. Ask the user, once for all actions, with `AskUserQuestion`: show each action's
   newest stable tag as the recommended option, the previous major as the
   alternative. Record the choices in `docs/research/test-infrastructure.md`
   when it exists (a line per action: repo, tag, SHA, date).
3. Resolve the chosen tag to its commit (an annotated tag has a `^{}` line that
   gives the commit; use it when present):
   ```bash
   git ls-remote "https://github.com/<owner>/<repo>.git" "refs/tags/<tag>" "refs/tags/<tag>^{}"
   ```
   The SHA must be 40 hex characters. Anything else is `UNRESOLVED`.
4. Confirm the action's **inputs** instead of recalling them: fetch
   `https://raw.githubusercontent.com/<owner>/<repo>/<SHA>/action.yml` with
   `WebFetch` and read it as data — nothing is cloned, run or written to disk.
   Use only inputs that file declares (`go-version`, `node-version`,
   `version`, `name`, `path` … are what to look for, not what to assume).

If the network is unavailable, a tag does not resolve, or an input cannot be
confirmed: **do not write the workflow.** Report `CI workflow NOT CREATED —
action SHAs unresolved: [list]` in the summary and make the verdict PARTIAL. A
workflow with placeholder SHAs would be committed and fail, or worse be "fixed"
by switching to tags.

Runner label: reuse the label of an existing workflow; otherwise ask. The stack
reference does not source a Linux runner label (`ubuntu-latest` floats with the
provider's image); record the choice in the workflow comment. Docker must be
available on the chosen runner for the Testcontainers jobs.

### The workflow template

Shape, not authority: every command and input below is confirmed against the
research note, the stack reference or the action's `action.yml` before it is
written. `<SHA>` and `<tag>` are the values resolved above; `<pins …>` are read
from `docs/stack-reference/pins.yaml`.

```yaml
name: Automated Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: tests-${{ github.ref }}
  cancel-in-progress: true

jobs:
  go-unit:
    name: Go unit tests
    runs-on: <runner label>
    timeout-minutes: 15
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@<SHA> # <tag>
        with:
          persist-credentials: false
      - uses: <Go setup action>@<SHA> # <tag>
        with:
          go-version: '<pins go.toolchain>'      # input name confirmed in action.yml
      - name: Unit tests with the race detector
        run: |
          set -o pipefail
          go test -race -json ./... | tee unit.json
      - name: Fail when no test ran
        run: grep '"Action":"pass"' unit.json | grep -q '"Test":'
      - uses: actions/upload-artifact@<SHA> # <tag>
        if: always()
        with:
          name: go-unit-results
          path: backend/unit.json

  go-integration:
    name: Go integration tests (Testcontainers)
    needs: go-unit
    runs-on: <runner label>                      # Docker must be available
    timeout-minutes: 30
    defaults:
      run:
        working-directory: backend
    steps:
      - uses: actions/checkout@<SHA> # <tag>
        with:
          persist-credentials: false
      - uses: <Go setup action>@<SHA> # <tag>
        with:
          go-version: '<pins go.toolchain>'
      - name: Integration tests (build tag integration)
        run: |
          set -o pipefail
          go test -race -json -tags integration ./... | tee integration.json
      - name: Fail when no integration test ran
        run: grep '"Action":"pass"' integration.json | grep -q '"Test":'
      - uses: actions/upload-artifact@<SHA> # <tag>
        if: always()
        with:
          name: go-integration-results
          path: backend/integration.json

  web:
    name: Web unit and end-to-end tests
    runs-on: <runner label>
    timeout-minutes: 30
    defaults:
      run:
        working-directory: web
    steps:
      - uses: actions/checkout@<SHA> # <tag>
        with:
          persist-credentials: false
      - uses: <pnpm setup action>@<SHA> # <tag>
        with:
          version: '<pins vite-react.pnpm>'      # or from packageManager; confirmed in action.yml
      - uses: <Node setup action>@<SHA> # <tag>
        with:
          node-version: '<pins vite-react.node>'
      - name: Install
        run: pnpm install                        # lockfile mode confirmed in the research note
      - name: Unit tests
        run: pnpm run test                       # script names are the product's, from package.json
      - name: Install Playwright browsers
        run: pnpm exec playwright install --with-deps
      - name: Start the dev stack
        working-directory: .
        run: docker compose -f deploy/compose.dev.yaml up -d --wait
      - name: End-to-end tests
        run: pnpm run test:e2e
      - name: Fail when no test ran
        run: <asserts that tests ran, from the report format recorded in the research note>
      - name: Stack logs on failure
        if: failure()
        working-directory: .
        run: docker compose -f deploy/compose.dev.yaml logs --no-color --tail=300
      - name: Stop the stack
        if: always()
        working-directory: .
        run: docker compose -f deploy/compose.dev.yaml down
      - uses: actions/upload-artifact@<SHA> # <tag>
        if: always()
        with:
          name: web-test-results
          path: |
            web/playwright-report
            web/test-results
```

Notes on the template:

- The `web` job carries the same zero-test guard as the Go jobs (a step that
  asserts tests ran, written from the Vitest and Playwright report formats). The
  guard is never `PENDING` inside a written job: if the research note does not
  record those formats, the **`web` job is not written** — it joins the table
  under "Jobs that are not written" as `PENDING — NOT SOURCEABLE — Vitest and
  Playwright report formats`, and the summary says CI has no web job yet. Do not
  invent a grep for a format you have not seen, and do not write a web job that
  could pass with zero tests.
- The compose steps use `down`, never `down -v`. The e2e step runs against the
  seeded test tenant (`tools/seed/`); if the product documents no seed step,
  the e2e step is omitted and listed as pending.
- `web/playwright-report` and `web/test-results` are the default output
  directories of Playwright's HTML reporter and artifact folder only if the
  research note confirms them for the pinned version; otherwise use the paths
  the verified config sets.
- Jobs for `site/` (Playwright smoke) copy the `web` job's shape and are written
  only when `site/` exists.
- Quarantined tests run in a separate non-blocking job
  (`continue-on-error: true`) that `/test-flakiness` proposes when the first test
  is quarantined; it is not created here.

### Jobs that are not written

Each is listed in the summary as `PENDING — NOT SOURCEABLE`, with the file that
would cover it; none is replaced by a guess or a job that always fails:

| Job | Why |
|---|---|
| Web (Vitest, Playwright), until the report formats are recorded | a job without a zero-test guard could pass vacuously — see the notes above |
| Ktor / Kotlin, KMP shared | Gradle test tasks and the `integrationTest` source set are not sourced (`kmp/best-practices.md` §8) — written only if the research note records the tasks, the JDK distribution and the result paths |
| Android instrumented (Compose UI) | emulator-on-CI setup is not covered by `compose/best-practices.md` §8 |
| iOS (Swift Testing, XCUITest) | needs a macOS runner; Xcode 27 availability on runner images and the pinning syntax are NOT SOURCEABLE (`swiftui/best-practices.md` §8) — check the runner image README before pinning |
| Contract tests | run inside each consumer's job; the validator is an ADR choice |
| Security scans (`govulncheck`, OSV-Scanner, `gitleaks`) | owned by `/dependency-audit` and `platform-lead`; commands are in `tooling/best-practices.md` |

---
