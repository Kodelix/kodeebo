# /api-contract - Phase 3: Checklist Review

> A **review** against `.claude/rules/contracts.md`, `.claude/docs/api-standards.md`
> and `.claude/docs/security-baseline.md`. It is performed by reading the
> proposal or file (with `Grep` to count and locate), and it is labelled a review
> in the report. It is not a lint and does not substitute for one.

Mark each item `met` / `not met` / `n/a - reason`, with `file:line` (or the
proposal section). Items marked **S** are security items: a `not met` on one is
`BLOCKED`. A `not met` on any other item is `COMPLETE WITH GAPS` at best, listed
with an owner.

## Operations (rules/contracts.md)

| # | Item |
|---|---|
| K1 | Every operation has a unique verb-noun `operationId` and a summary |
| K2 | **S** Every operation has a `security` requirement, or an explicit `security: []` with the reason it is public |
| K3 | Request and response schemas are declared; request and response DTOs are separate schemas |
| K4 | **S** Every error status is declared as `application/problem+json` (RFC 9457) with `type`, `title`, `status`, `detail`, `instance`, a stable machine-readable `code` and `trace_id`; the `code` catalogue is an enum |
| K5 | Every operation has examples (success and at least one error) |
| K6 | **S** Request schemas set `additionalProperties: false` (mass-assignment defence) |
| K7 | **S** Every unbounded field has `maxLength` / `maximum` / `maxItems`; formats used where one exists (`uuid`, `date-time`, `email`) |
| K8 | Every list operation: `limit` with a `maximum`, opaque `cursor`, `{data, next_cursor}`, allowlisted filter and sort parameters, documented stable sort key |
| K9 | Every create or charge `POST` documents `Idempotency-Key`: scope (tenant + key), TTL, replay behaviour, 409/422 on reuse with a different body |
| K10 | Contended updates document `ETag` / `If-Match` with `412` |

## Resource design and conventions (api-standards.md)

| # | Item |
|---|---|
| K11 | Plural nouns, kebab-case paths, no verbs in paths, URI major version `/v<n>` |
| K12 | JSON field case follows the ADR-fixed convention and is not mixed |
| K13 | IDs are opaque strings (UUIDv7 or ULID); no sequential integers exposed |
| K14 | Timestamps RFC 3339 UTC; money is `{amount_minor, currency}`, never a float |
| K15 | Enums are strings and the contract states that clients must tolerate unknown values; enums clients must handle exhaustively are marked and versioned |
| K16 | Status codes follow the table: 400 malformed, 422 validation, 401/403, 404 for missing **or other-tenant**, 409/412, 429 + `Retry-After`, 503 + `Retry-After`, 202 + status URL for async, 201 + `Location` |
| K17 | `trace_id` in error bodies and `traceparent` on responses documented (observability-standard) |

## Security and tenancy (security-baseline.md)

| # | Item |
|---|---|
| K18 | **S** A caller in another tenant gets 404; the contract and examples never distinguish "forbidden" from "missing" for cross-tenant IDs |
| K19 | **S** Response schemas expose no internal field, tenant identifier the caller does not own, secret or field the caller's role may not read (object-property-level authorization) |
| K20 | **S** No secret, token or personal data in a URL or query parameter |
| K21 | **S** Rate limits and quotas per tenant/actor/route are documented for auth, OTP and expensive operations; request size limit stated |
| K22 | **S** URL-accepting fields (webhooks, imports) are flagged for the egress allowlist client |
| K23 | Sensitive surfaces cite the threat model and the mitigations they implement (`Threat model:`) |

## Webhooks

| # | Item |
|---|---|
| K24 | Outbound: event types and versioned payload schemas, `event_id`, HMAC over timestamp + body, tolerance window, retry schedule with backoff and cap, delivery status and replay endpoints, secret rotation with overlap; minimal event plus fetch (no full resource with secrets) |
| K25 | **S** Inbound: verify signature and timestamp before parsing, dedupe by event ID, acknowledge 2xx quickly, process asynchronously |

## Evolution

| # | Item |
|---|---|
| K26 | Every change classified ADDITIVE or BREAKING against the last released contract (`3-tooling-and-diff.md` step 4) |
| K27 | A BREAKING change has a new major version, or an ADR plus `Deprecation`/`Sunset` headers, a changelog entry and the product's stated support window |
| K28 | Deprecated fields/operations carry `deprecated: true`, `Deprecation` and `Sunset` headers and a replacement |
| K29 | Generated clients (TS, KMP, Swift as per the stack) are listed as outputs of the change and no hand-edited generated code is proposed |

## How to run it

- `Grep` counts help: operations (`operationId:`), error media types
  (`application/problem+json`), `additionalProperties`, `Idempotency-Key`,
  `security:`; compare each count to the number of operations and say so.
  A count is evidence for the review, not a lint result.
- Cite what you read. An item judged from memory of the proposal rather than
  the text is `not assessed`.
- In `check` mode run it over every operation of the file; if the file is too
  large to read whole, state which operations were read and which were not, and
  mark the rest `not assessed`.

## Result

```text
Checklist (review, not a lint): K1-K29  met N / not met N / n/a N / not assessed N
Security items not met: <list>  (any = BLOCKED)
Other items not met: <list with owner>
```
