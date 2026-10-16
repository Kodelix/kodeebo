# /integration - Phase 7: Tests, Sandbox Smoke and Review

> Phase 7 of `SKILL.md`. Real output only. A test that was not run is `not run`;
> a test file's existence is not a pass. Evidence folder:
> `production/qa/evidence/<STORY-ID>/` (with no story, `integration-<provider>` is the
> folder id: `production/qa/evidence/integration-<provider>/`).

## 1. Contract tests against a stub (I14)

Stub with WireMock or `httptest` (`testing-standards.md`; the stub library and
version come from the stack reference or a `/research` note, not memory). Each
case below is a named test; the evidence lists each by name with its result.

| # | Case | Asserts |
|---|---|---|
| T1 | success | request shape at the pinned API version (headers, idempotency key, body), response mapped |
| T2 | 4xx (invalid, declined) | mapped to the closed domain error, **no retry** |
| T3 | 429 | `RateLimited`, backoff honouring `Retry-After`, bounded attempts |
| T4 | 5xx on an idempotent call | retried with backoff and jitter, then `Unavailable` |
| T5 | 5xx / timeout on a **non-idempotent** call | **not retried**; ends in pending/lookup, never a second send |
| T6 | timeout | explicit timeout fires; context cancelled |
| T7 | circuit open | calls fail fast with `Unavailable`; half-open probe recovers |
| T8 | duplicate webhook | one effect; second delivery acknowledged |
| T9 | bad signature | rejected before parsing; response identical to unknown event; secret not logged |
| T10 | stale timestamp | rejected as replay |
| T11 | out-of-order events | final state correct |
| T12 | webhook handler is async | handler returns 2xx without running business logic inline |
| T13 | outbox | state change and outbox row commit together; dispatcher idempotent; DLQ path |
| T14 | tampered client amount (money) | catalogue price used; client amount ignored |
| T15 | reconciliation (money) | an injected mismatch is detected and reported, nothing auto-corrected without an audit entry |
| T16 | tenant isolation | event for tenant A never mutates tenant B; per-tenant credentials not readable cross-tenant |
| T17 | live-key guard | startup refuses a live-marked key in a non-production config |
| T18 | port conformance | the fake/second adapter and the real adapter pass the same suite |

Not applicable cases (no webhooks, no money) are listed as `not applicable —
<reason>`, never omitted. Run through the layer's runner (Go: tests beside the
code, integration tests behind the `integration` build tag; Ktor:
`src/test` and `src/integrationTest`); the exact commands come from the CI
config or the stack reference; unsourced → ask the user, do not invent flags. This skill holds no test-runner grants:
`test-automation-engineer` (spawned via `Agent`) runs the commands and returns exit codes and
output, or the user runs them and pastes the result; no output returned = `not run`.
Save the output with exit code; Testcontainers/WireMock outputs go to the
evidence folder.

## 2. Secret and data hygiene (I8)

- `gitleaks git -v --redact --log-opts="<base>..HEAD"` and `gitleaks dir . --redact`
  with the commands in the scanners file of the `security-audit` skill (gitleaks section). Not installed →
  `not run — gitleaks not installed`; offer the install, do not install without a
  yes. `--redact` is mandatory; a finding is reported with rule ID, file and line
  only. A real live key found: capture the minimal evidence (location only, never the value; time-boxed, 15 minutes by default), **then rotate**, then remove; the report states
  `rotation: not done` as an open BLOCKED cause until it is.
- Logs of a real run (stub or sandbox) are scanned for PAN-like strings, bearer
  tokens and webhook secrets; the result is `none found in <N> lines` or the
  finding. A run that produced no logs is `not run`, not clean.

## 3. Sandbox smoke (I15) — once per release

The smoke is one end-to-end call sequence against the provider's **sandbox**, not
live. Rules:

1. The user loads sandbox credentials from the secret store into the environment.
   The skill never asks for, reads, prints or stores a key value.
2. Before running, confirm the configured credential is sandbox by the marker in
   the research note. `NOT SOURCEABLE` marker, or a live-looking key → **do not
   run**; record `not run — cannot establish sandbox credential`.
3. Only published test values are used. The base URL is the sandbox host from
   the research note.
4. Record: date (UTC), provider API version used, operations exercised, result,
   and the provider request IDs (no payloads, no PII).
5. `NOT RUN` is a valid, reported result: verdict at best `NOT ASSESSED` for I15.
   Stories mark it `DEFERRED` with an owner and the release it is due before.

Webhooks in the smoke use the provider's sandbox event tooling documented in the
research note; if the sandbox cannot deliver to a local stack, say so — the
webhook path is then covered by T8-T12 only and the gap is named.

## 4. Security review (parallel)

For webhooks, money or PII, spawn `appsec-engineer` in the same turn as the test
run (independent inputs). Brief: scope = the adapter, webhook handler, outbox
and config paths; read `integrations.md`, `security-baseline.md` (webhooks,
SSRF, secrets, logging), the threat model; return findings as SEC-NNN with
file:line, no secrets, and what was not reviewed. It reviews; it does not fix.
In `lean`/`solo` mode the review is still recommended for money; record
`appsec review skipped — [mode]` if skipped, never as passed.
