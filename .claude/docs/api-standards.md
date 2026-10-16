# API Standards

The API is the product's contract with its own clients (web, Android, iOS,
self-hosted integrations, customer automations). **Contract first**: the
change lands in `contracts/` and is reviewed before handlers are written.

## Contract

- REST over HTTPS described in **OpenAPI** (`contracts/openapi/<service>.yaml`); gRPC/protobuf only for internal service-to-service with an ADR.
- Client SDKs (TypeScript, KMP, Swift) are **generated** from the contract; hand-written clients are a review failure.
- Breaking-change detection runs in CI against the last released contract.

## Resource design

- Plural nouns, kebab-case paths: `/v1/invoices/{invoice_id}/line-items`.
- JSON fields `snake_case` (or `camelCase` — one convention per product, fixed by ADR, never mixed).
- IDs are opaque strings (UUIDv7 or ULID); never sequential integers exposed to clients.
- Timestamps RFC 3339 in UTC; money as `{ "amount_minor": 1999, "currency": "EGP" }` — never floats.
- Enums are strings; unknown values must be tolerated by clients.

## Methods and status codes

| Situation | Code |
|---|---|
| Read OK / Created / Accepted for async / No content | 200 / 201 + `Location` / 202 + status URL / 204 |
| Validation failed | 422 |
| Malformed request | 400 |
| Not authenticated / Not allowed | 401 / 403 |
| Not found **or** exists in another tenant | 404 (never reveal cross-tenant existence) |
| Conflict / precondition failed | 409 / 412 |
| Rate limited / quota exceeded | 429 + `Retry-After` |
| Dependency down | 503 + `Retry-After` |

## Errors — RFC 9457 Problem Details

```json
{
  "type": "https://errors.<product>.com/plan-limit-reached",
  "title": "Plan limit reached",
  "status": 422,
  "detail": "Your plan allows 5 projects.",
  "instance": "/v1/projects",
  "code": "plan_limit_reached",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "errors": [{ "field": "name", "code": "too_long" }]
}
```
`code` is stable and machine-readable; `detail` is human text and may be localized; no internals.

## Pagination, filtering, sorting

- Cursor pagination: `?limit=50&cursor=<opaque>` → `{ "data": [...], "next_cursor": "..." }`. Server caps `limit`.
- Filters are explicit query params validated against an allowlist; sort fields allowlisted.

## Idempotency and concurrency

- `POST` that creates or charges accepts `Idempotency-Key`; the stored response is replayed for the key's TTL.
- Optimistic concurrency via `ETag` / `If-Match` on updates to contended resources.
- Webhooks **out**: signed (HMAC with timestamp), retried with backoff, idempotent event IDs, replayable from the dashboard.
- Webhooks **in**: verify signature and timestamp first, dedupe by event ID, process asynchronously, return 2xx fast.

## Versioning and lifecycle

- URI major version (`/v1`). Additive changes do not bump it.
- Deprecation: `Deprecation` and `Sunset` headers, changelog entry, and a minimum support window stated in the product's API policy (self-hosted customers may lag several versions).

## Security (see security-baseline.md)

AuthN on every route except explicit public ones; object-level authz in the use
case; rate limits per tenant/actor/route; request size limits; no secrets in URLs.

## Observability

Route templates (not raw paths) as span names and metric labels; `trace_id`
returned in error bodies and the `traceparent` response header for support.
