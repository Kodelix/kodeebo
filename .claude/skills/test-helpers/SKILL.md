---
name: test-helpers
description: "Generate test helper libraries per layer — factories and builders, fakes for ports, injected Clock and IDGenerator, Testcontainers fixtures per store (Postgres with RLS roles, Mongo, Valkey/Redis), and two-tenant fixtures for isolation tests."
argument-hint: "[context-name | layer | all | scaffold]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), AskUserQuestion, Bash(bash "*/.claude/skills/test-helpers/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Test Helpers

Tests are faster to write and easier to trust when setup, fakes and fixtures
live in one place instead of being copied into every test. This skill generates
a test-helper library tailored to the product's actual layers, ports and
stores — so each engineer writes less boilerplate and more assertions, and every
test starts from a deterministic clock, a deterministic ID generator, its own
tenant and its own data (`.claude/docs/testing-standards.md`).

**Output:** helper files in the helper locations below — the only places each
layer's test runner and compiler reach them (`.claude/docs/directory-structure.md`
→ Code roots):

| Layer | Helper location |
|---|---|
| Go backend | `backend/internal/<context>/testkit/` per bounded context (builders, fakes of that context's ports) and `backend/internal/testkit/` for cross-cutting helpers (clock, IDs, tenants); store fixtures in `backend/internal/testkit/<store>test/` behind the `integration` build tag |
| Ktor backend | `backend/src/test/kotlin/<pkg>/testkit/`; integration fixtures beside the `src/integrationTest/kotlin/` suites |
| Web app | `web/src/shared/testing/` (unit and component helpers); `web/e2e/fixtures/` (Playwright fixtures) |
| KMP shared | `mobile/shared/src/commonTest/kotlin/<pkg>/testkit/` |
| Android | `mobile/android/app/src/test/.../testkit/`; Compose rule helpers under `app/src/androidTest/` |
| iOS | a test-support target or folder inside the Swift test targets |

Helpers are **not** production code: production packages never import a
`testkit`, and a `testkit` imports inward only (domain, app ports) — never
adapters it does not fake. Say so in the generated package doc.

**When to run:**
- After `/test-setup` scaffolds the frameworks (first time, `scaffold`)
- When multiple test files repeat the same setup boilerplate
- When starting to write tests for a new bounded context
- Before `/regression-suite` asks for missing tests (gaps are cheaper with helpers)

---

## Assertions: use the layer's test framework, never a bare abort

**Generated helpers must assert through the layer's test framework** and fail
the *test*, not the process.

- Go: take `testing.TB`, call `t.Helper()`, report with `t.Errorf` (continues)
  or `t.Fatalf` (stops the subtest) — never `panic`, never `log.Fatal`
  (`go/best-practices.md` → Testing).
- Kotlin: the `kotlin.test` assertions (and `runTest` for coroutines); no
  `check()`/`require()` as an assertion — they throw outside the test framework's
  reporting and can be mistaken for production preconditions.
- TypeScript: the runner's `expect`; no `throw new Error` as an assertion.
- Swift: `#expect` (records and continues) and `#require` (stops)
  (`swiftui/best-practices.md` §7).

A helper that panics, exits, or uses an assertion the runner strips or does not
report aborts the whole run on the first failure, hiding every result after it.
**Look up the assertion form for the layer's framework at the pinned version
before generating code**; do not copy forms from other skills or from memory. If
you cannot confirm the form, say so and **generate no helper for that layer**
rather than guessing — an unconfirmed assertion reaching disk is a bug; a missing
helper is a task, and the verdict is PARTIAL.

**Helpers must not look like tests.** A Go helper file named `*_test.go` cannot be
imported by another package — shared helpers live in ordinary files of a `testkit`
package. A TypeScript helper file must not match the runner's test-file pattern
(no `.test.` or `.spec.` in the name), or the runner discovers it as a suite with
zero tests. A Kotlin or Swift helper is a plain class, struct or function, never a
test class.

---

## 1. Parse Arguments

**Modes:**
- `/test-helpers [context-name]` — generate helpers for one bounded context
  (e.g., `/test-helpers billing`), in every layer that implements it
- `/test-helpers [layer]` — `backend`, `web`, `android`, `kmp`, `ios`: the layer's
  cross-cutting helpers plus those of every context it implements
- `/test-helpers all` — helpers for every context that has test files
- `/test-helpers scaffold` — generate only the cross-cutting kit (clock, IDs,
  tenants, store fixtures, evidence helper); use this on first run
- No argument — run `scaffold` if no helpers exist, else `all`

---

## 2. Detect Stack and Test Frameworks

Read the `stack` line of the resolved config (backend, web, site, mobile, `data`
stores, `deploy`, `distribution`, `tenancy`). If no layer is configured:
"Stack not configured. Run `/setup-stack` first." (verdict **BLOCKED**).

Then read, per layer in scope, what `/test-setup` left:
- the test framework configuration and the layer's `testing` section of
  `docs/stack-reference/<layer>/best-practices.md`
- `docs/research/test-infrastructure.md` if it exists — it is the second source
  after `pins.yaml` and the stack reference for container APIs and versions
- `docs/stack-reference/pins.yaml` for image tags (`postgres.image`,
  `mongo.image`, `mongo.image_self_hosted`, `redis.image_hosted`,
  `redis.image_redistributable`, `dragonfly.image`) and tool versions

If a layer has no test framework yet: "Test framework not scaffolded for [layer].
Run `/test-setup` first." That layer is skipped and **named** as skipped in the
output.

**Which store engines to cover** comes from the product, not from this list:
`stack.data`, and for cache adapters the engines each `deploy/` bundle ships
(`deploy.md`: hosted may use Redis and Dragonfly; the customer bundle ships
Valkey, and Dragonfly is not redistributable). A fixture is generated only for an
engine the product actually uses.

---

## 3. Load Existing Test Patterns

Scan each layer's test locations for patterns already in use:

```
Glob pattern="backend/**/*_test.go"
Glob pattern="backend/src/*/kotlin/**/*Test*.kt"
Glob pattern="web/**/*.test.ts*"   and   web/e2e/**/*.ts
Glob pattern="mobile/**/src/*Test*/**/*.kt"
```

For a representative sample (up to 5 files per layer), read the test files and extract:
- Setup patterns (how fixtures, containers and parallelism are set up)
- Common assertion patterns
- How objects are created in tests (builders, literals, helpers)
- How dependencies are replaced (hand-written fakes, interfaces)

This ensures generated helpers match the project's existing style, not a
generic template. Where no test exists yet, follow `.claude/rules/test-standards.md`.

Also read, with section greps rather than full reads:
- `design/specs/domain-map.md` — which bounded contexts and features exist
- For each in-scope feature, its spec's **Data & Contracts** (entities, fields,
  constraints), **Detailed Behaviour** (roles, permissions, numbers) and **Edge
  Cases & Failure Modes**:
  `Grep pattern="^## ([0-9]+\. )?(Data & Contracts|Detailed Behaviou?r|Edge Cases)" path="design/specs/[feature].md" output_mode="content" -A 30`
- `design/registry/entities.yaml` — the plans, roles, permissions and quotas that
  tenant and user builders draw their defaults from
- `docs/architecture/tr-registry.yaml` — to map requirements to tested contexts
- The **port interfaces** the code declares where they are consumed
  (`internal/<context>/app/` in Go; the equivalent in other layers) — fakes are
  generated from the real interfaces, never from a guess at their methods
- `contracts/openapi/*.yaml` — for response builders that must match the contract

If a port, entity or plan the helper needs does not exist yet, say so and generate
only the part that does not depend on it. Never invent a method set, a plan name
or a price. If that leaves nothing to generate, the verdict is `NOT ASSESSED`
(Section 5), not PARTIAL.

---

## 4. Generate Helpers

Every helper kind below is generated per layer **only where the layer and the
sourced facts allow it**. Anything the stack reference, the research note and the
existing code do not cover is reported `PENDING — NOT SOURCEABLE — <what> is not
covered by <path>` and the helper is not written.

### 4.1 Clock and ID generator (deterministic time and identity)

`testing-standards.md`: no `time.Now()` / `Clock.System` / `Date.now()` in tested
paths; time and IDs are injected.

- **Fake clock**: holds a fixed instant, `Now()` returns it, `Advance(d)` moves it,
  `Set(t)` jumps. It implements the product's **existing Clock port** — read the
  port from the code. If the port comes from `saas-core` (`core.modules` in
  `project.yaml`, or an import of the core module), implement that interface; if
  neither exists, ask via `AskUserQuestion` which package owns the port rather
  than defining a competing one inside the testkit.
- **Sequential ID generator**: returns predictable IDs (`id-1`, `id-2`, … or
  valid UUIDs from a counter) implementing the product's IDGenerator port.
- **Seeded randomness**: any helper that needs randomness takes an explicit seed,
  and **prints the seed on failure** so the failure can be replayed. Go
  crypto-dependent tests use the `cryptotest` hook (Go 1.26,
  `go/best-practices.md`); concurrency tests use `testing/synctest` (Go 1.25+) and
  Kotlin uses `runTest` virtual time. No helper contains a `sleep`: waits are
  polls with a deadline and a failure message naming the condition.

Go shape (stdlib only — adapt the interface to the product's port):

```go
// Package testkit holds deterministic helpers for tests. Production code must
// not import it.
package testkit

import (
	"sync"
	"time"
)

// FakeClock is a manually advanced clock. Safe for concurrent use.
type FakeClock struct {
	mu  sync.Mutex
	now time.Time
}

// NewFakeClock returns a clock fixed at start.
func NewFakeClock(start time.Time) *FakeClock { return &FakeClock{now: start} }

// Now returns the current fake instant.
func (c *FakeClock) Now() time.Time {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.now
}

// Advance moves the clock forward by d.
func (c *FakeClock) Advance(d time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.now = c.now.Add(d)
}
```

The start instant is a named test constant, not `time.Now()`.

### 4.2 Factories and builders

Builder functions with sensible defaults; a test states only the fields that
matter to it (`testing-standards.md`: factories over fixtures).

- One builder per aggregate/entity the spec's **Data & Contracts** defines, with
  functional options (Go), named/default arguments (Kotlin), or an overrides
  object (TypeScript). Defaults come from the spec and `entities.yaml`; a value
  with no source gets a neutral, clearly-labelled test constant — never a price,
  limit or quota invented to look real. Boundary values (limit, limit ± 1, zero,
  max length) are exposed as named constants **traced to the spec rule**, so a
  boundary test reads `LimitPlusOne`, not `101`.
- Builders create a **valid** object by default and expose `Invalid…` variants for
  the domain errors the spec lists.
- Every builder that produces tenant-owned data takes a tenant (or uses the
  current fixture tenant); there is no builder that produces tenant-owned data
  without one.
- Response builders for contract tests are generated from `contracts/openapi/*.yaml`
  schemas, so a field the contract lacks fails the build.

TypeScript shape:

```ts
// web/src/shared/testing/builders.ts — a helper, not a test: no `.test.` in the name.
export interface Invoice { id: string; tenantId: string; status: 'open' | 'paid'; }

export function buildInvoice(overrides: Partial<Invoice> = {}): Invoice {
  return { id: 'invoice-1', tenantId: 'tenant-a', status: 'open', ...overrides };
}
```

### 4.3 Fakes for ports

For each port interface found in Step 3, a hand-written in-memory fake that
implements it faithfully: an in-memory repository enforces the same uniqueness and
**tenant scoping** as the real adapter (a fake that returns another tenant's row
hides the bug the real adapter test exists to catch); a fake provider client
records calls and can be told to return 4xx, 5xx, a timeout or a duplicate
delivery; a fake event publisher records events for assertion.

- Fakes are generated **from the interface** — method set, signatures and error
  values copied from the port; if the port changes, the fake stops compiling.
- A fake never replaces the database or cache **client** in an integration test
  (`testing-standards.md`: mock only third-party HTTP you do not own). Fakes serve
  unit tests of use cases; Testcontainers serve adapters.
- Third-party HTTP you do not own: a fake server via the layer's standard test
  server (Go `httptest`; WireMock for JVM) with scripted responses for success,
  4xx, 5xx/timeout, duplicate webhook and invalid signature.

### 4.4 Testcontainers fixtures per store

Integration fixtures live behind the `integration` build tag (Go) or in the
`integrationTest` source set (Kotlin), so unit runs never need Docker. The
container API and module versions come from `docs/research/test-infrastructure.md`;
**Testcontainers module versions are not in `pins.yaml`** → if the note does not
record them, the fixture is `PENDING — NOT SOURCEABLE` and only its specification
below is written to the helper package's README.

General rules for every store: image tag from `pins.yaml` exactly (never `latest`,
never a floating major); **one container per suite**, a fresh schema, database,
keyspace or tenant **per test**; teardown registered with the test framework's
cleanup; no fixed host ports.

**Postgres** (`stack.data` includes `postgres`; `postgres/best-practices.md` §7):
- image `<pins postgres.image>`; Go module `modules/postgres` with
  `WithDatabase`, `WithUsername`, `WithPassword`; Java artifact
  `org.testcontainers:testcontainers-postgresql`
- **Two roles**: the owner (runs migrations) and the application role — a
  non-superuser, **non-owner, NOBYPASSRLS** role the app connects as. The
  fixture hands tests a connection as the app role; a test that connects as the
  container superuser passes the RLS tests vacuously
- migrations run from scratch **and** from the previous release's schema dump
- per-test isolation by truncating or rolling back, or `CREATE DATABASE … TEMPLATE`
  per test
- tenant context set with parameterised `set_config($1,$2,true)` — never string
  concatenation
- helper `AssertRLSEnabledAndForced`: every table with a `tenant_id` column has
  `pg_class.relrowsecurity` **and** `relforcerowsecurity` set and at least one
  policy in `pg_policies`; helper for "unset GUC returns 0 rows"
- a pooled-connection-reuse test through PgBouncer in transaction mode: the
  PgBouncer image/version is not sourced → `PENDING — NOT SOURCEABLE`

**Mongo** (`stack.data` includes `mongo`): images `<pins mongo.image>` (hosted/dev)
and `<pins mongo.image_self_hosted>` (customer bundles) — the matrix includes only
the line each bundle ships. All access goes through the repository, which filters
by `tenant_id`; the fixture seeds two tenants and a helper asserts that an
unfiltered ad-hoc query is impossible through the repository API. The Testcontainers
Mongo module API: `PENDING — NOT SOURCEABLE` unless the research note covers it.

**Valkey / Redis / Dragonfly** (`stack.data` includes `redis` or `dragonfly`;
`redis/best-practices.md` §10, `dragonfly/best-practices.md` test rule): one suite
run against **every engine the product ships on** — `<pins redis.image_hosted>` and
`<pins dragonfly.image>` for hosted, `<pins redis.image_redistributable>` (Valkey)
for the customer bundle. The fixture exposes the engine list so the same test body
runs per engine; no module commands (`FT.*`, `JSON.*`, …) in shared code. A
**cache-down helper** stops the container mid-test and restores it, so a cache
adapter test proves degrade-to-source instead of failure.

### 4.5 Tenant fixtures (two tenants for isolation tests)

The fixture every Security and repository test starts from:

- `TwoTenants` creates **tenant A and tenant B**, each with an owner, a member with
  a lower role, and one resource of each tenant-owned type the context defines —
  created through the product's real tenancy/use-case path (or `tools/seed/`), IDs
  from the injected generator
- returns the principals (token or actor) for: anonymous, wrong role (member of A
  on an owner-only action), owner of A, owner of B
- helper `AssertCrossTenantDenied`: acts as tenant A on tenant B's resource ID and
  asserts **404 and no data in the body** (or the port-level not-found error), never
  403 with a body that confirms existence
- every repository adapter and every endpoint of the context gets the same
  isolation assertion from the fixture; an adapter without it is a gap
  `/regression-suite` will report
- roles, permissions and plans come from `entities.yaml`; a context with none
  gets the roles the spec names, labelled as such

### 4.6 Web and end-to-end helpers

- `web/e2e/fixtures/` — Playwright fixtures that sign in as a seeded actor from
  `tools/seed/` and expose the two-tenant principals. The Playwright fixture API
  and config keys come from the research note at the pinned version
  (`vite-react/best-practices.md` §8) — `PENDING` otherwise.
- **Evidence helper**: names screenshots `web-<screen>-<width>-<lang>.png`
  (1440 and 390 px; `en` and `ar`) and writes them to
  `production/qa/evidence/<story-id>/`; refuses to report success when the file is
  not on disk (a captured-and-discarded screenshot is an assertion, not evidence).
- **Redaction helper**: removes `Authorization` headers, cookies, tokens, OTP
  codes, passwords and personal data from request/response transcripts before they
  are saved as `api-<endpoint>.md`.
- Component helpers (`renderWithProviders`, accessible-role queries) use Testing
  Library; **Testing Library versions are not in `pins.yaml`** → `PENDING` until
  the research note records them.

### 4.7 Mobile helpers

- **Android**: a Compose rule helper built on `createComposeRule()` (or
  `createAndroidComposeRule<…>()`), with `onNodeWithText` finders and the v2
  coroutine test dispatcher (Compose 1.11+); test tags and semantics finders beyond
  that are `PENDING` (`compose/best-practices.md` §8).
- **KMP shared**: fakes of the shared ports in `commonTest`; test commands are
  `NOT SOURCEABLE` (`kmp/best-practices.md` §8), so write the fakes, not a runner
  configuration.
- **iOS**: Swift Testing helpers as plain functions and structs using `#expect` and
  `#require`; XCUITest helpers only for UI tests, which Swift Testing does not
  replace.

---

## 5. Write Output

Present a summary of what will be created:

```
## Test Helpers to Create

Layers in scope: [list]; skipped: [layer — reason]

Cross-cutting kit ([layer]):
- [path]/clock — FakeClock implementing [Clock port path]
- [path]/ids — sequential IDGenerator
- [path]/tenants — TwoTenants fixture + AssertCrossTenantDenied
- [path]/[store]test — [engine] fixture, image [pinned tag], app role NOBYPASSRLS

Context helpers ([mode]):
- [path]/[context]/testkit — builders for [entities], fakes for [ports]  ← from [spec]

Pending (NOT SOURCEABLE — not written):
- [item — what is missing — file that would cover it]  (or: "None")
```

Ask: "May I write these helper files to the paths above?"

**Never overwrite existing files.** If a file already exists, report:
"Skipping `[path]` — already exists. Remove the file manually if you want it
regenerated."

After writing, close with the verdict:
- **COMPLETE** — every requested helper written, nothing pending
- **PARTIAL** — helpers written; the listed ones skipped or pending (layers without
  a test framework, unconfirmed assertion forms, NOT SOURCEABLE container APIs)
- **NOT ASSESSED — nothing generated** — the requested context (or layer) has no
  spec, no ports and no code yet, or every helper is blocked on an unconfirmed
  form, so there was nothing to write and nothing that counts as partial; name
  which inputs were missing and the skill that produces them (`/design-spec`,
  `/dev-story`, `/test-setup`)
- **BLOCKED** — stack not configured (`BLOCKED — stack not configured`), or the user
  declined the write (`BLOCKED — write declined by user`; nothing is reported as
  written)

"Helper files created. To use them in a test:
- Go: import the `testkit` package from a `_test.go` file; fixtures behind the
  `integration` tag need `-tags integration`
- Kotlin: the helpers are on the test source set's classpath; the `integrationTest`
  source set sharing is a Gradle setting (see Pending)
- TypeScript: import from `web/src/shared/testing/` or the Playwright fixtures
- Swift: add the helper file to the test target"

---

## Collaborative Protocol

- **Never overwrite existing helpers** — they may contain hand-written
  customisations. Only generate new files that don't exist yet
- **Generated code is a starting point** — adapt it to the real types once the code
  exists; never loosen a helper's isolation (fresh data per test, app role, tenant
  scoping) to make a test pass
- **Helpers reflect the spec and the code** — bounds, constants, roles and plans trace
  to the spec's Data & Contracts / Detailed Behaviour, `entities.yaml`, or the ports
  as declared; nothing invented
- **Never write a container API, version or assertion form from memory** — the stack
  reference and `pins.yaml` win over training data; where neither covers it, write
  `PENDING — NOT SOURCEABLE` and suggest `/research test-infrastructure`
- **Test data is synthetic** — builders and fixtures never read production data;
  the seeded test tenant comes from `tools/seed/`
- **Ask before writing** — always confirm before creating files in test locations

## Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/test-helpers <context> — <verdict>`, Next step = the first item below that applies, plus Blocked on (e.g. a layer with no scaffold) / Files in progress (the helpers written) / Open questions; append the Notes line. Still updated when the write was declined (record that nothing was written).

- Run `/test-setup` if a layer's test framework has not been scaffolded yet.
- Use `/dev-story` to implement stories — helpers reduce boilerplate in new test files.
- Run `/regression-suite audit` to see which contexts still lack isolation and
  regression tests.
