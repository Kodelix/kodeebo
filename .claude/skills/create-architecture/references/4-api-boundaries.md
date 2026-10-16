# /create-architecture — Phase 4: API Style and Contract Boundaries

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: API Style and Contract Boundaries

Define the public contracts between contexts, and between the backend and every
client, following `.claude/docs/api-standards.md` (contract first).

- **API style**: REST + OpenAPI by default; gRPC/protobuf only service-to-service
  with an ADR. Field naming convention (`snake_case` or `camelCase`, one per
  product), ID format (UUIDv7/ULID), money shape, pagination and error format
  (RFC 9457) — each fixed here and recorded as one critical ADR ("API style").
- **Contract files**: for each context that exposes HTTP, name its
  `contracts/openapi/<service>.yaml` (or `contracts/proto/...`); client SDKs
  (TypeScript, KMP, Swift) are generated, never hand-written.
- **Boundary table**, one row per exposed capability:

  | Boundary | Producer context | Consumers (web / Android / iOS / public API / other context) | Contract file | Auth + tenant rule | Idempotency | Versioning |
  |---|---|---|---|---|---|---|

- **Context-to-context boundaries inside the backend**: the `app` API (interface)
  or event each context offers the others, written in pseudocode or the stack's
  language — the contracts engineers implement against. State invariants callers
  must respect and what the context guarantees.
- **Public/self-hosted API lifecycle**: deprecation window long enough for
  self-hosted customers who lag several versions (`Deprecation`/`Sunset` headers),
  breaking-change detection in CI.
- **Webhooks and integrations**: signed, retried, replayable (out); verified,
  deduped, async (in).
- **Cross-tenant rule at every boundary**: a resource in another tenant is 404,
  never 403.

**Stack awareness check**: If any interface uses stack-specific types or
generated-client behaviour (OpenAPI generator version, KMP Ktor client, Swift
generator), flag the version and verify it against `docs/stack-reference/` and
`pins.yaml`. Consult `api-designer` via `Agent` to review the boundary table
when more than five endpoint groups are exposed; the user decides.

Which boundaries need a contract **story first** is recorded here: every
boundary with a client consumer produces a `contracts/` story ahead of its
backend and client stories (`/create-stories` enforces the ordering).

Get user approval on the API boundaries, then record them in
`production/session-state/active.md`; they are written at Phase 8.

---
