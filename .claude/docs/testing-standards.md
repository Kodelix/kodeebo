# Testing Standards

DoD gate 3. Tests are the executable spec: a reviewer should be able to read
the test names and know what the feature guarantees.

## The pyramid per layer

| Level | What it proves | Tooling (resolve versions from stack-reference) | Speed budget |
|---|---|---|---|
| **Unit** | Domain rules and use cases with fakes | Go `testing` + table tests; Kotlin `kotlin.test`/JUnit 5 + kotest assertions; Vitest; Swift Testing | whole suite < 30 s |
| **Integration** | Adapters against the real thing | Testcontainers (Postgres, Mongo, Redis, Dragonfly, MinIO, NATS/RabbitMQ, mock SMTP); WireMock / httptest for providers | per test < 2 s after container start |
| **Contract** | Backend and clients agree on `contracts/` | OpenAPI schema validation of real responses; consumer tests generated from the spec | runs on every PR |
| **End-to-end** | Critical user journeys on a running stack | Playwright (web); Compose UI tests / Espresso (Android); XCUITest (iOS) | only the journeys that make money or lose data |
| **Load** | Budgets in `perf-budgets.md` hold | k6 | on hot paths, before release |
| **Security** | Negative paths hold | authz matrix tests, cross-tenant tests, injection payloads, rate-limit tests | runs on every PR for touched endpoints |

## Required tests by change

- **Every use case**: happy path, each domain error, authorization denied, and tenant mismatch.
- **Every repository adapter**: round-trip, not-found, constraint violation, tenant isolation (row of tenant A invisible to tenant B), and pagination boundaries.
- **Every cache adapter**: hit, miss, invalidation on write, TTL expiry, behaviour when the cache is **down** (must degrade to source, not fail).
- **Every provider integration** (payments, SMS, email, storage): success, provider 4xx, provider 5xx/timeout with retry, duplicate webhook delivery (idempotency), invalid webhook signature.
- **Every migration**: up on an empty DB, up on a seeded DB, down (dev), and the app's integration suite green after it.
- **Every endpoint**: contract test + authz test (anonymous, wrong role, wrong tenant).

## Naming

- Go: `TestInvoice_Pay_RejectsAlreadyPaid` (`Test<Subject>_<Action>_<Expectation>`), subtests named in table cases.
- Kotlin: backtick names — `` `pay rejects an already paid invoice` ``.
- TypeScript: `describe('Invoice') / it('rejects paying an already paid invoice')`.
- Swift Testing: `@Test("Pay rejects an already paid invoice")`.

## Rules

- **Deterministic**: inject `Clock` and `IDGenerator`; no `time.Now()`/`Clock.System` in domain; no sleeps — poll with a deadline.
- **Isolated**: each test creates its own tenant and data; never depends on order or on seed data another test mutates.
- **Real dependencies for integration**: never mock the database or the cache client; mock only third-party HTTP you do not own.
- **Factories over fixtures**: builder functions with sensible defaults; a test states only what matters to it.
- **No hardcoded magic numbers** except in boundary tests where the number *is* the point.
- **Coverage is a signal, not a target**: domain + app packages ≥ 85 % line coverage; a drop in a PR must be explained.
- **Flaky = broken**: quarantine with an issue and owner within a day; never retry-until-green in CI.
- **Never disable a failing test to pass CI.**

## Evidence

Integration, contract, security and load results that close a story are saved
to `production/qa/evidence/<story-id>/` (summary + raw output). Screenshots of
every UI screen touched go there too (see `run-and-observe.md`).
