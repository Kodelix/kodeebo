# /integration - Phase 6: Adapter Behind a Port

> Phase 6 of `SKILL.md`. Applies only on "implement now"; otherwise the same
> requirements become acceptance criteria for the stories. These are the
> requirements of `.claude/rules/integrations.md` and the `integrations-engineer`
> Senior Bar. They are rules, not provider facts: every provider-specific value
> comes from the spec.

## 1. Destination paths (derive, do not assume)

| Backend | Port | Adapter | Webhook route | Tests |
|---|---|---|---|---|
| Go (`backend/`) | `internal/<context>/app/ports.go` | `internal/<context>/adapters/providers/<provider>/` | `internal/<context>/adapters/http/webhooks/` | `*_test.go` beside code; integration tests behind the `integration` build tag |
| Ktor (`backend/`) | `src/main/kotlin/<pkg>/<context>/app/` | `src/main/kotlin/<pkg>/<context>/adapters/providers/<provider>/` | `.../adapters/http/webhooks/` | `src/test/kotlin/`, `src/integrationTest/kotlin/` |

The adapter is wired **only** in the composition root. Confirm the actual layout
from the code roots; if it differs, ask, do not move files.

## 2. Port

A small, provider-neutral interface per capability (`PaymentGateway`,
`SmsSender`, `EmailSender`, `BlobStore`, `PushSender`, `OAuthClient`). No
provider type, error code or field name appears in `domain` or `app`. Swapping
providers changes only the adapter and composition root; show it with a second
adapter or a fake that passes the same **port-conformance suite**.

## 3. Outbound calls (every call)

| Requirement | Detail |
|---|---|
| Timeout | explicit connect and total timeout from config |
| Retry | exponential backoff with jitter, **idempotent operations only**, bounded attempts, honour `Retry-After` |
| Circuit breaker | where failure cascades; separate pool/bulkhead so a provider outage does not starve the API; state exposed as a gauge |
| Idempotency key | wherever the provider supports one, derived from our operation ID |
| Ambiguous outcome | a timeout after send on a non-idempotent call becomes a **pending** state resolved by lookup or webhook, never a second attempt (no double charge) |
| Context | `traceparent` propagated; span per call (`app.provider`, operation) |

## 4. Errors, credentials, egress

- Provider errors map to the closed domain set (`Declined`, `RateLimited`,
  `Unavailable`, `Invalid`, plus `NotFound`/`Conflict`); the raw code is kept in
  the wrapped cause and logs, never returned to clients.
- Credentials from the secret store; sandbox and live are separate secret names;
  **startup refuses a live key in a non-production environment**; live keys are
  absent from dev, CI and fixtures. The marker that distinguishes a live key
  comes from the research note, not from memory; if it is `NOT SOURCEABLE`, the
  startup guard cannot be written and I8 is `NOT ASSESSED`.
- Per-tenant provider config (tenant brings its own account): stored encrypted,
  scoped to the tenant, covered by a cross-tenant negative test.
- Outbound requests to user-supplied URLs only through the allowlisting egress
  client (private, link-local and metadata ranges blocked).
- Card data never touches our servers: hosted checkout or tokenisation only;
  a real run's logs are scanned for PAN-like patterns.

## 5. Inbound webhooks (handler order is fixed)

1. read the **raw body** with a size limit;
2. verify signature and timestamp tolerance, constant-time compare, **before any parsing**;
3. reject replays (stale timestamp);
4. dedupe on the provider event ID with a **unique constraint** (not a timestamp, not an in-memory set);
5. persist the event;
6. enqueue for asynchronous processing;
7. return 2xx quickly.

Business processing happens in a worker, safe for duplicate and out-of-order
delivery; for critical state, re-fetch the object from the provider API rather
than trusting the payload. Unknown and invalid events get identical responses;
the endpoint is rate-limited; webhook secrets and signature headers never appear
in logs; the tenant is derived from the verified event's mapped account, never
from an unverified field. Trusting the redirect/return URL as proof of payment is
rejected: use a verified webhook or a server-side fetch.

## 6. Outbox

State changes that trigger provider calls or e-mails write an outbox row **in the
same transaction** as the state change. The dispatcher is idempotent and bounded
with a dead-letter path, an alert and a runbook link. Delivery semantics belong
to `messaging-specialist`; the table and its migration to `data-lead` (route
through `/db-migration`). The outbox and event rows carry `tenant_id`; the
dispatcher re-establishes tenant context.

## 7. Money

Amounts are `{amount_minor, currency}`; prices, plans and entitlements are read
from the server-side catalogue; a test proves a tampered client amount is
ignored. A scheduled **reconciliation job** compares provider records with ours
per period, reports missing/duplicate/mismatched items as a metric and a
ticket-level alert, and never auto-corrects money without audit entries.

## 8. Self-hosted

Every adapter works without our hosted infrastructure; provider choice is
configuration; nothing phones home (`deploy.md`). Any cache used for idempotency
stays inside the Valkey-portable command subset (`redis/best-practices.md` §10).
A new SDK dependency is a follow-up for `/dependency-audit` (CVEs and licence).

## 9. Fixed brief for `integrations-engineer`

Spawn only after the user said "implement now" and the research note and spec are
on disk. Fill only the `{...}` slots.

```text
Implement the {provider} adapter for /integration.

Read first: .claude/rules/integrations.md, docs/research/{provider}.md,
docs/architecture/integrations/{provider}.md, docs/architecture/threat-models/{provider}.md,
the stack reference files listed here: {list with Last verified dates}.
Never write a provider API, version, header, signature scheme or limit from memory;
use the research note and spec, or stop and report NOT SOURCEABLE.

Backend: {go | ktor}   Code root: {resolve_code_root output}
Port: {name and path}   Adapter: {path}   Webhook route: {path | not applicable}
Capability class: {money | webhooks | PII | outbox | per-tenant credentials | user-supplied URL | file transfer}
Stories / acceptance criteria this serves: {ids | none}
Write only these files: {list of new files}. Existing files you must edit
(composition root, config): {list}; show each diff for approval before editing.

Deliver: the port, the adapter, the closed error mapping, resilience config, the
live-key startup guard, the webhook handler in the fixed order, the outbox write
and dispatcher hook, the reconciliation job (money class), spans/metrics/log
events per observability-standard.md, and the tests listed in
.claude/skills/integration/references/5-tests-and-sandbox.md with their output
saved under production/qa/evidence/integration-{provider}/.
No live credentials, keys, tokens, payloads or PII in any file. No commit.

Return (text, under 200 words): files written; checks you ran with exit codes; what
you could not do and why. A reply without the files is a failed phase.
```

Verify with `Glob`/`Read` that every named file exists before reading the reply.
Schema changes (webhook-event table, outbox, reconciliation tables) are not made
here: route through `/db-migration`. Changes to `contracts/` go through
`/api-contract`.
