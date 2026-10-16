> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# QL-TEST-COVERAGE — QA Lead Test Coverage Review

Agent: `qa-lead` | Model tier: session (inherit) | Domain: Test strategy, acceptance criteria testability, quality gates

**Trigger**: After an implementation story is complete — `/story-done` runs it
for each story before marking it Complete. Covers DoD gate 3; PE-DOD checks all
eight.

**Context to pass**:
- The story file, its story type (Logic / Integration / Contract / Security / Performance / UI / Config) and its acceptance criteria
- Test file paths (per layer, `directory-structure.md` → Code roots) and the CI run or local run output
- Evidence directory `production/qa/evidence/<story-id>/`
- Spec acceptance criteria and Edge Cases & Failure Modes section for the feature
- Gate levels resolved from `testing.strict.*` and `performance.enforce` in `project.yaml`

**Checks**:
1. Logic stories: unit tests cover happy path, each domain error, authorization denied and tenant mismatch (`testing-standards.md` → Required tests by change), and pass.
2. Integration stories: Testcontainers integration tests run against the real dependency (no mocked database or cache client); adapters have round-trip, not-found, constraint violation, tenant isolation and pagination boundary tests; cache adapters test hit, miss, invalidation, TTL and cache-down behaviour; provider integrations test success, 4xx, 5xx/timeout with retry, duplicate webhook and invalid signature.
3. Contract stories: contract tests against `contracts/` pass for every consumer touched; every endpoint has an authz test (anonymous, wrong role, wrong tenant).
4. Security stories: negative tests (authz bypass, cross-tenant, injection, rate limit) exist and pass, with the ASVS / MASVS mapping retained.
5. Performance stories: load-test results against the budget are in the evidence directory with environment and data volume; no-N+1 is asserted by a query-count test.
6. UI stories: a screenshot of every screen touched and the `/impeccable audit` result are retained in the evidence directory.
7. Each spec acceptance criterion is mapped to at least one test (list the unmapped), and each spec edge case is tested or has a written reason.
8. Tests are deterministic and isolated (injected clock and ID generator, own tenant and data per test); no test is skipped or disabled; none is flaky-quarantined without an issue and owner.
9. Domain and application packages meet the ≥ 85 % line-coverage signal, or a drop is explained.
10. Run-and-observe evidence exists for anything a user can see or call (`run-and-observe.md`).

**Prompt**:
> "Review the test coverage for this implemented story. Are all Logic criteria
> covered by passing unit tests? Are Integration criteria covered by Testcontainers
> tests against the real dependency? Are Contract, Security, Performance and UI
> stories backed by the evidence their type requires? Are the spec acceptance
> criteria each mapped to at least one test? Are there untested edge cases from
> the spec's Edge Cases & Failure Modes section? Return ADEQUATE (coverage meets
> standards), GAPS [specific missing tests], or INADEQUATE [critical logic is
> untested — do not advance]."

**Verdicts**: ADEQUATE / GAPS / INADEQUATE

**NOT ASSESSED when**: the story file, the test paths or the evidence directory
cannot be read, or test results were not produced and the skill did not state
that none exist. Tests that were not run are reported as not run, never as passing.
The gate level (BLOCKING / ADVISORY) does not change the verdict word; the
skill applies it to the verdict.

**Output**: the standard block, with an evidence matrix (criterion — test — result — evidence path).
