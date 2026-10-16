---
paths:
  - "**/integrations/**"
  - "**/adapters/providers/**"
  - "**/webhooks/**"
---

# External Integration Rules (payments, SMS/OTP, email, storage, push, OAuth, ...)

Every provider integration is an adapter behind a port, so providers are swappable and testable.

- A research note (`docs/research/<provider>.md`) exists citing the provider's current API reference and version.
- Credentials from the secret store; separate sandbox and live credentials; live keys never in dev/CI.
- Every call: timeout, retry with exponential backoff + jitter **only for idempotent operations**, circuit breaker, and an idempotency key where the provider supports it.
- Map provider errors to a small domain error set (`Declined`, `RateLimited`, `Unavailable`, `Invalid`), never leak provider codes upward.
- **Inbound webhooks**: verify signature and timestamp before acting; reject replays; dedupe by event ID; persist then process asynchronously; respond 2xx quickly.
  - Providers that sign selected fields or send no timestamp (confirm per provider in the research note): strict typed parse **with no side effects** → verify the signature over the provider's documented fields → dedupe → **re-fetch the object from the provider's API** before changing any state. Never trust an unsigned field.
- **Outbound requests to URLs that users or tenants supply** (webhook targets, imports, avatars by URL, OAuth discovery) go through the egress client that resolves DNS once, blocks private, loopback, link-local and cloud-metadata ranges, disallows redirects to them, and enforces timeouts and size caps (SSRF — `security-baseline.md`).
- **Money**: amounts in minor units; reconcile against provider records with a scheduled job; never trust client-sent prices.
- **Outbox pattern** for side effects that must happen after a DB commit (emails, webhooks out, provider calls triggered by state changes).
- Observability: span per provider call with `app.provider`, metrics for latency/errors per provider and operation, alert on error-rate spikes.
- Tests: contract tests against a stub (WireMock/httptest) for success, 4xx, 5xx, timeout, duplicate webhook, bad signature; one sandbox smoke test per release.
- Prefer `saas-core` modules for identity, OTP, notifications, storage, billing and licensing; a product-local provider adapter needs a reason.
