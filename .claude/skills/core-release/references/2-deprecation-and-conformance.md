# /core-release — Phases 3–4: Deprecation Policy and Conformance

> Part of `/core-release`. Read again if the conversation was compacted.

## 1. The deprecation policy

Read the core's policy (`docs/` in the core repo): the minimum window before
removal (in releases and/or time), the required notice (annotation in code,
CHANGELOG entry, release-note line), the replacement requirement, and whether a
removal is allowed only in a major.

- **Policy present:** applied as written; quote the clause when citing it.
- **Policy absent or unreadable:** `deprecation policy: NOT SOURCEABLE — not in
  <path>`. Consequence, wired to the verdict: **this release may add
  deprecations but may not remove anything** (a removal → `BLOCKED`), and the
  record lists "no deprecation policy" as an open decision for `cto` — write it
  with `/architecture-decision` (a module is not released without a policy:
  `cto.md`, core Senior Bar). Consumers cannot plan against a window that does
  not exist.

Consider the products' reality when a window is proposed: self-hosted customers
and old mobile app versions lag several releases (`api-standards.md`,
"Versioning and lifecycle"); the window should cover the supported
upgrade-from range the products publish. That number is not in the core repo:
ask the user for it and record it as `stated by user`.

## 2. Check each deprecation and removal in this release

| Check | Evidence | Result |
|---|---|---|
| Each **new** deprecation: marked in code (the language's deprecation annotation, as the repo already uses it), a replacement named, the earliest-removal version stated, a CHANGELOG "Deprecated" entry, a release-note line | file:line of each | ok / missing |
| Each **removal** in this release: it was deprecated, and for at least the policy's window (find the release that deprecated it, `git log -S`/tags) | the deprecating tag | ok / violates window / never deprecated |
| Each removal is in a MAJOR release | the bump table | ok / no |
| Deprecated symbols still **used inside the core** by non-deprecated code | grep | none / list |
| Products still on a deprecated symbol past its window: not knowable from the core repo | - | `NOT ASSESSED` — noted, for `/core-upgrade` in each product |

Any "violates window", "never deprecated" or "no" is `BLOCKED` — fix the
change, or deprecate now and remove in a later release.

## 3. The conformance matrix

**What it proves.** Every adapter of every module released passes the module's
**conformance suite** — the shared behaviour tests that define the port
(`directory-structure.md`: each module = ports + adapters + conformance tests) —
against **real dependencies** via Testcontainers, never a mocked database or
cache (`testing-standards.md`). The in-memory/fake adapter passes the same suite.

Build the matrix from the repo, not from memory:

1. Enumerate adapters per module from the module's directory (the layout read in
   Phase 1) and the suites that target them. An adapter with **no** conformance
   test is a finding (`adapter <x>: no conformance test`) and a `not run` cell.
2. Enumerate the **engines/images** each adapter targets and take the exact tags
   from `docs/stack-reference/pins.yaml` (Postgres, Mongo, Valkey/Redis/Dragonfly,
   MinIO, broker...). A test that defaults to a different image than the pin is
   reported (`image mismatch: test uses <x>, pin is <y>`). Customer-bundle rules
   apply to what the notes may claim: cache → Valkey, Mongo → official image
   reference, observability → OTel Collector; Dragonfly is hosted-only
   (`docs/ROADMAP.md` L1–L4) — a Dragonfly adapter is tested and the notes mark it
   hosted-only.
3. Commands: Go — the `integration`-tagged run per `layer-checks.md` (the
   `dev-story` skill folder); Kotlin — the integration source-set task **named in
   the build files** (`src/integrationTest/kotlin/`; the task name is NOT
   SOURCEABLE in the stack reference — confirm with the build, a task that does
   not exist is `not run — task not defined`). Use the repo's own wrapper
   scripts if they exist. Needs a reachable container runtime; absent → every
   such cell is `not run — no container runtime`.
4. Run **all** cells for the modules in this release; run the dependent modules
   too when a released module is a dependency of another released module.
5. Client pieces in the core's `clients/` (KMP, Swift, TypeScript): run each
   client's own tests; Swift on a Linux host is `not run — needs macOS`
   (`ios-lead.md`: honest "not run" reporting). Pieces with no tests are findings.

Spawn **in parallel, one message** (independent): `test-automation-engineer`
(runs the matrix, and writes missing conformance tests *only* if the user later
asks — here it reports gaps) and `appsec-engineer` (the scans in §4). Return
contract: write the result to a named path
(`production/releases/core-draft/conformance-<module>.md`,
`.../security-scans.md`), return the path, a ≤5-bullet summary, BLOCKED/CONCERNS
lines. **Verify both files exist** before continuing.

Matrix (printed, and copied into the release notes):

| Module | Adapter | Engine / image (pin) | Suite | Result | Evidence (command, exit, counts) |
|---|---|---|---|---|---|
| | | | | passed / FAILED / not run — reason | |

A `FAILED` cell → `BLOCKED`: nothing is tagged, not even on user override. A
`not run` cell → `NOT ASSESSED`; the user may still decide to release
(Phase 6), and the release notes then carry "unverified in this release:
<adapter>" in the matrix and the Known Issues section.

## 4. Quality scans

Alongside the matrix, per module, `not run — <reason>` where unavailable (the
tooling reference lists `govulncheck` and `osv-scanner` as possibly not
installed on the host):

| Check | Source of the command |
|---|---|
| Unit tests (+ race detector for Go) | `layer-checks.md` / repo scripts |
| Lint and static analysis | `layer-checks.md` / repo config |
| Vulnerabilities in dependencies (`govulncheck`, `osv-scanner`) | `layer-checks.md`; pins in `pins.yaml` (`tooling`) |
| Secret scan (`gitleaks`) over the release range | `docs/stack-reference/tooling/` |
| Dependency licences compatible with customer-bundle redistribution | the dependency manifests; unknown → `NOT SOURCEABLE`, `cto` decides |
| Floors: the module's toolchain/framework versions vs `pins.yaml`; changed floors listed for the notes | build files |

Print real output lines. A vulnerability with a fix available in a dependency of a
released module is a finding the user must decide on before the go/no-go; this
skill does not triage it away.
