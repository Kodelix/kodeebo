---
paths:
  - "contracts/**"
---

# API Contract Rules

Standard: `.claude/docs/api-standards.md`.

- Contract changes land **before** handler code and are reviewed by `api-designer`.
- Every operation has: `operationId`, summary, security requirement (or explicit `security: []` for public), request/response schemas, every error status as RFC 9457 `application/problem+json`, and examples.
- Schemas set `additionalProperties: false` on requests, `maxLength`/`maximum`/`maxItems` on every unbounded field, and formats (`uuid`, `date-time`, `email`).
- List operations are cursor-paginated with a server-capped `limit`.
- Creating/charging operations document the `Idempotency-Key` header.
- Breaking changes (removed/renamed fields, tightened validation, changed types, new required inputs) require a new major version or an ADR plus deprecation headers.
- Generated clients (TS, KMP, Swift) are regenerated in the same change; never hand-edit generated code.
- Lint the spec (Spectral or the ADR-chosen linter) and run breaking-change diff in CI.
