# /automate-test — Choosing the Level and the Rules a Test Must Meet

> Part of `/automate-test`. `SKILL.md` names when to read this file; the
> settings it resolved and the rules under its headings still apply here.

Source of truth: `.claude/docs/testing-standards.md` (pyramid, required tests
by change, naming, rules) and `.claude/rules/test-standards.md`. This file
applies them to a conversion; it does not restate versions or commands.

## 1. The level decision — first match wins

| The behaviour is… | Level | Notes |
|---|---|---|
| A domain rule, formula, state transition, permission decision with fakes for ports | **Unit** | Table-driven where inputs vary. Whole unit suite stays under 30 s |
| Correct only against a real store: a repository query, RLS/tenant isolation, a migration, a cache adapter (hit, miss, invalidation, TTL, **cache down**), a provider adapter against a stub | **Integration** (Testcontainers; WireMock/httptest only for third-party HTTP you do not own) | Fresh schema/database/keyspace or tenant per test. Postgres suites connect as the non-owner, NOBYPASSRLS application role |
| The shape of a request or response, an error status, a field in `contracts/` | **Contract** | Validate real handler responses (not hand-written fixtures) against `contracts/openapi/*.yaml`, including `application/problem+json`; consumer tests per generated client |
| Who may call an endpoint | **Authz table test** with three actors — anonymous, wrong role, wrong tenant — in the same file as the endpoint's contract test | Wrong tenant expects 404/403 and **no data in the body** |
| A journey across the UI that makes money or loses data (sign-up, plan change, checkout, export, delete) | **End-to-end** — Playwright (web), Compose UI/Espresso (Android), XCUITest (iOS) | Against the compose dev stack with the seeded tenant, never mocks of our own backend. Web: 1440 px and 390 px, English and Arabic (RTL). CI retries 0 |
| A visual judgement, copy quality, "feels right", an exploratory finding | **Not automated** | Stays manual; `/manual-test` and retained screenshots |

Rules that push a case **down**: if a unit test can reach it, it is not an
integration test; if an integration test can reach it, it is not e2e. A manual
case that mixes several behaviours is **split** into one test per behaviour.

## 2. Required tests by change (copy into the rows you create)

- **Every use case:** happy path, each domain error, authorization denied, tenant mismatch.
- **Every repository adapter:** round-trip, not-found, constraint violation, tenant isolation (tenant A's row invisible to B), pagination boundaries (first, last, empty).
- **Every cache adapter:** hit, miss, invalidation on write, TTL expiry, behaviour when the cache is down (degrades to source, does not fail).
- **Every provider integration:** success, provider 4xx, provider 5xx/timeout with retry, duplicate webhook (idempotency), invalid signature.
- **Every migration:** up on empty, up on seeded, down (dev), app integration suite green after.
- **Every endpoint:** contract test + authz test (anonymous, wrong role, wrong tenant).
- **A fixed bug:** the regression test at the **lowest level that exhibits it**, red before the fix and green after.

## 3. Rules every new test meets

- **Deterministic.** No real clock, no unseeded randomness, no sleeps. Inject
  `Clock` and an ID generator; wait by polling with a deadline and a failure
  message naming the condition. Go concurrency tests use the `testing/synctest`
  package and Kotlin `runTest` virtual time (both in the stack reference);
  seeded randomness prints its seed on failure.
- **Isolated.** The test creates its own tenant and data and depends on no other
  test's rows or on order. Containers start once per suite, state is fresh per test.
- **Factories over fixtures.** Use the builders, fakes and fixtures from
  `/test-helpers`; a test states only the fields that matter to it. No magic
  numbers except in boundary tests where the number is the point (use the
  spec's limit, limit ± 1, zero, max length).
- **Named for behaviour** (`.claude/rules/test-standards.md`): Go
  `Test<Subject>_<Action>_<Expectation>`, Kotlin backtick sentences, TypeScript
  `describe`/`it`, Swift `@Test("…")`. Arrange / Act / Assert visible; one
  behaviour per test. Traceability to the case: the test's doc comment or the
  mapping file carries the `TC-<story>-NN` or `BUG-NNNN` ID.
- **Unit tests make no network, disk or database calls.**
- **Image tags and tool versions** come from `docs/stack-reference/pins.yaml`;
  never `latest`, never a floating major. Only engines the product's `deploy/`
  bundle ships are in a matrix (a cache adapter runs the same suite on every
  engine it ships on).
- **Selectors** (e2e) use roles and labels, never CSS chains. Screenshots taken
  by an e2e test are evidence only if retained under `production/qa/evidence/`.
- **No secrets, tokens or customer data** in tests, fixtures, logs or snapshots.

## 4. What is not automated here — say so in the table

- Visual fidelity, animation feel, copy tone, anything a person must judge.
- A case that needs a device, a provider's live system, or a person's phone.
- iOS tests on a Linux host: write them if asked, mark `WRITTEN, NOT RUN —
  macOS runner` (see `/test`).
- KMP test commands and Compose UI tests on iOS are `NOT SOURCEABLE` in
  `docs/stack-reference/kmp/`; Espresso is not covered by the stack reference.
  Do not write those from memory — `/research`, then convert.
- A one-off exploratory finding with no stable expected result.

Each excluded case keeps its reason in the table and in the evidence file.
