# Integration Spec: [Provider / System]

> **Status**: Draft | In Review | Approved | Implemented
> **Owner**: [engineer] · **Reviewer**: principal-engineer, security-lead (for billing/auth/PII)
> **Date**: [YYYY-MM-DD] · **Last Verified**: [YYYY-MM-DD against provider docs at the pinned API version]
> **Feature specs using it**: [`design/specs/...`] · **Research note**: [`docs/research/<provider>.md`] · **ADR**: [ADR-NNNN] · **Threat model**: [`docs/architecture/threat-models/<provider>.md`]
> **Port in our code**: [`internal/<context>/app/ports.go: PaymentGateway`] — the domain depends on the port; the provider SDK lives in an adapter only (`clean-architecture.md`).

<!-- Verify every fact against the provider's official documentation at the pinned API version. Anything not found: write NOT SOURCEABLE — <what was searched>. -->

## 1. Provider Overview

| Field | Value |
|-------|-------|
| **Provider** | [name] |
| **Purpose** | [payments / email / SMS / storage / identity / maps / ...] |
| **API version pinned** | [e.g. dated version header or SDK version] — pinned in [`pins.yaml` / config], upgrade policy: [...] |
| **SDK or raw HTTP** | [official SDK @ version | generated client | raw] — reason |
| **Pricing / limits that matter** | [rate limits, quotas, per-call cost] |
| **Data shared** | [categories; PII?; data residency; DPA in place?] |
| **Merchant of record / compliance** | [PCI scope: hosted checkout/tokenisation only — card data never touches our servers] |
| **Fallback / vendor-exit plan** | [alternate provider or degraded mode] |

## 2. Authentication & Secrets

- **Auth method**: [API key | OAuth2 client credentials | mTLS | signed requests]
- **Credentials**: separate for sandbox and live; stored in [secret store path]; never in code, logs, URLs or client bundles
- **Scopes / permissions**: least privilege — [restricted key scopes]
- **Rotation**: [procedure and period; dual-key overlap]
- **Self-hosted**: [customer supplies own credentials? configured via env/secret file; documented in the install guide]

## 3. Endpoints / Operations Used

| Operation | Provider endpoint | Our use case | Idempotent? | Timeout | Retry? | Notes |
|-----------|-------------------|--------------|-------------|---------|--------|-------|
| [Create checkout session] | [`POST /v1/...`] | [Start subscription] | [Idempotency key supported] | [5 s] | [only with idempotency key] | |
| [Retrieve payment] | [`GET /v1/...`] | [Reconciliation] | Yes | [3 s] | Yes (backoff) | |

## 4. Webhooks (inbound)

| Event type | Meaning | Handler | Effect on our state | Ordering assumptions |
|------------|---------|---------|--------------------|---------------------|
| [`invoice.paid`] | | [`HandleInvoicePaid`] | [activate/renew entitlement] | [may arrive out of order / duplicate] |

- **Endpoint**: [`POST /webhooks/<provider>`] — public, rate-limited, body-size limited
- **Signature verification**: [algorithm, header name, signed payload format (timestamp + body), secret per endpoint]; verify **before** parsing business data; constant-time compare
- **Replay protection**: [timestamp tolerance N min; dedupe by event ID stored with TTL ≥ provider retry window]
- **Processing**: acknowledge 2xx fast, enqueue, process asynchronously, idempotent handler
- **Provider retry policy**: [schedule]; our response codes: [2xx ack, 4xx for bad signature, 5xx only for transient failure]
- **Fetch-before-trust**: [for critical state, re-fetch the object from the API rather than trusting the payload]
- **Dead-letter and replay**: [where failed events go; how to replay]

## 5. Idempotency

- **Outbound**: every create/charge call carries an idempotency key derived from [our operation ID]; keys retained [N] hours; behaviour on key reuse with different params: [...]
- **Inbound**: events deduplicated by [provider event ID]; handlers safe to run twice
- **Our API**: endpoints that trigger provider calls accept `Idempotency-Key` and replay the stored response (`api-standards.md`)

## 6. Retries, Timeouts, Circuit Breaking

| Aspect | Policy |
|--------|--------|
| **Connect / total timeout** | [e.g. 2 s / 5 s] — configurable, not hardcoded |
| **Retry** | [idempotent calls only; exponential backoff with jitter; max attempts N; honour `Retry-After`] |
| **Circuit breaker / bulkhead** | [open after N failures in M s; half-open probe; separate pool so provider failure does not starve the API] |
| **Rate-limit handling** | [client-side limiter; 429 handling; queue] |
| **Degraded mode** | [what users see and what is queued when the provider is down] |

## 7. Error Mapping

| Provider error | Meaning | Our domain error / problem `code` | HTTP status | User-facing message key | Retry? |
|----------------|---------|----------------------------------|-------------|------------------------|--------|
| [card_declined] | | [`payment_declined`] | 422 | `errors.payment_declined` | No |
| [rate_limit] | | [`provider_busy`] | 503 + `Retry-After` | `errors.try_later` | Yes |
| [api_connection_error / timeout] | | [`provider_unavailable`] | 503 | | Yes (idempotent) |
| [authentication_error] | Our credential problem | [`internal`] + alert | 500 | generic | No — page |

Provider error bodies are logged without PII or secrets; never returned to clients verbatim.

## 8. Sandbox vs Live

| Aspect | Sandbox | Live |
|--------|---------|------|
| Base URL / account | | |
| Credentials | | |
| Test data / fixtures | [published test values only] | — |
| Webhook endpoints | | |
| Differences in behaviour | [documented gaps between sandbox and live] | |
| Go-live checklist | [live products/prices created, webhooks registered, keys rotated, monitoring verified] | |

Integration tests run against [a fake provider / sandbox with recorded fixtures]; no live calls in CI.

## 9. Reconciliation

- **What is reconciled**: [payments vs. invoices vs. entitlements]
- **Schedule**: [hourly/daily job]; **source of truth**: [provider for money, us for entitlements]
- **Mismatch handling**: [auto-correct rules; alert threshold; manual review queue; audit trail]
- **Metric / alert**: [`reconciliation_mismatch_total` -> runbook]

## 10. Observability

- **Spans**: one span per provider call (`peer.service`, operation name low-cardinality), `traceparent` propagated where supported
- **Metrics**: call rate/error/latency by operation, retries, circuit state, webhook received/processed/failed/duplicate, queue lag
- **Logs**: outcome events with provider request ID; **no** card data, tokens, secrets or full payloads
- **Alerts**: error ratio, latency, webhook failure/lag, reconciliation mismatch -> runbook `[docs/runbooks/....md]`
- **SLO impact**: [journey J# in `slos.md`]

## 11. Security & Privacy

- **Threat model**: [link]; key risks: [forged webhooks, replay, SSRF via callback URLs, over-privileged keys, PII leakage in logs]
- **Egress**: outbound calls only to the provider's allowlisted hosts via the egress client
- **PII sent / stored**: [fields; minimisation; retention; deletion on tenant/user erasure; sub-processor listed in the DPA]
- **Callbacks/redirect URLs**: [validated against an allowlist]

## 12. Testing

- [ ] Contract/fixture tests of request and response shapes at the pinned API version
- [ ] Webhook: valid signature, bad signature, stale timestamp, duplicate, out-of-order
- [ ] Timeout, retry, circuit breaker, and degraded mode behaviour
- [ ] Idempotency: repeated outbound and inbound operations have a single effect
- [ ] Reconciliation catches an injected mismatch
- [ ] Sandbox end-to-end smoke test before each release

## 13. Open Questions

| Question | Owner | Due | Resolution |
|----------|-------|-----|-----------|
