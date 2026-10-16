---
paths:
  - "**/*_test.go"
  - "**/src/test/**"
  - "**/src/integrationTest/**"
  - "**/src/commonTest/**"
  - "**/src/androidTest/**"
  - "**/*.test.ts"
  - "**/*.test.tsx"
  - "**/e2e/**"
  - "**/*Tests.swift"
---

# Test Code Rules

Standard: `.claude/docs/testing-standards.md`.

- Names state the behaviour: `Test<Subject>_<Action>_<Expectation>` (Go), backtick sentences (Kotlin), `it('...')` (TS), `@Test("...")` (Swift).
- Arrange / Act / Assert visible; one behaviour per test; factories/builders for data — a test states only the fields that matter to it.
- No real clock, randomness, network or sleeps in unit tests; inject `Clock`/`IDGenerator`; poll with deadlines in integration tests.
- Integration tests use Testcontainers — never a mocked DB or cache client. Each test owns its tenant and data.
- Every use case has authz-denied and wrong-tenant tests; every cache adapter has a cache-down test; every webhook handler has duplicate and bad-signature tests.
- No skipped tests without a linked issue and owner; never weaken an assertion to make a test pass.
- Snapshot/screenshot tests store baselines in the repo and are reviewed like code.
