# /integration - Phase 3: Integration Spec

> Phase 3 of `SKILL.md`. The template is
> `.claude/docs/templates/integration-spec.md`; do not invent a parallel format.
> Destination: `docs/architecture/integrations/<provider>.md`.

## 1. Fill order and sources

Work through the template's 13 sections with the user, one at a time
(`AskUserQuestion` for choices; in `guided` mode only major ones). Every fact
comes from the research note (cite the finding number) or the user's decision.
Anything the note does not hold is `NOT SOURCEABLE — <what was searched>` and
stays in the spec as such. **Last Verified** is the date the research note was
verified against the provider's documentation at the pinned API version.

| Section | Source | Notes |
|---|---|---|
| Header | user, research note, ADR, threat model, port | the **port** line names the interface in `app/`; the domain depends on it, the SDK lives in the adapter only (`clean-architecture.md`) |
| 1 Provider overview | research note | API version pinned and where; PCI scope: hosted checkout/tokenisation only, card data never touches our servers (`security-baseline.md`); fallback/vendor-exit plan is mandatory |
| 2 Authentication & secrets | research note, `deploy.md` | sandbox and live are different secret names; rotation with dual-key overlap; self-hosted: the customer supplies credentials by env/secret file, documented in the install guide |
| 3 Operations | research note | per operation: idempotent?, timeout, retry? A non-idempotent call with no provider idempotency key is **never** retried automatically |
| 4 Webhooks | research note | only the sourced scheme. Handler order is fixed (see `4-adapter-and-resilience.md` §5); mark fetch-before-trust for critical state |
| 5 Idempotency | research note, `api-standards.md`, `redis/best-practices.md` §6 | outbound keys derived from our operation ID; inbound dedupe by provider event ID with TTL at least the provider retry window; where keys are stored (Postgres unique constraint, or cache with a portable command subset) |
| 6 Retries, timeouts, breaker | `rules/integrations.md`, `performance-standard.md` | connect and total timeout, backoff with jitter, `Retry-After` honoured, breaker thresholds, bulkhead; **values come from config, not constants** |
| 7 Error mapping | domain error set | closed set: `Declined`, `RateLimited`, `Unavailable`, `Invalid` (+ `NotFound`/`Conflict` if needed); RFC 9457 at the edge; provider code kept only in the wrapped cause and logs |
| 8 Sandbox vs live | research note | differences documented; published test values only; go-live checklist (live products created, webhooks registered, keys rotated, monitoring verified); no live calls in CI |
| 9 Reconciliation | user, `pricing-billing-designer` for the catalogue | mandatory for the money class: source of truth (provider for money, us for entitlements), schedule, mismatch handling that never auto-corrects money without audit entries, metric and alert with runbook |
| 10 Observability | `observability-standard.md` | span per provider call with `app.provider` and a low-cardinality operation name; RED + retries + breaker state gauge + webhook received/processed/failed/duplicate + queue lag; alert on error-rate spikes with a runbook link; no payload bodies |
| 11 Security & privacy | threat model | forged webhooks, replay, SSRF through callback URLs, over-privileged keys, PII in logs; egress allowlist; PII sent/stored/retention/erasure; sub-processor listed in the DPA via `privacy-compliance-specialist` |
| 12 Testing | `5-tests-and-sandbox.md` | the checklist is the same list as I14/I15 |
| 13 Open questions | all | each with an owner and what it blocks |

## 2. Rules while filling

- No placeholder (`[...]`) may remain in a section that applies. A section that
  does not apply (no webhooks, no money) says `Not applicable — <reason>`.
- Money class: every amount is `{amount_minor, currency}`; prices, plans and
  entitlements are read from the server-side catalogue; client input is an
  intent. State the tampered-amount test.
- Self-hosted (`distribution.model` includes self-hosted): state that the adapter
  works without our hosted infrastructure, provider choice is configuration,
  and nothing phones home. If the provider requires a callback to a public URL,
  state how an air-gapped customer operates without it.
- If the provider is a payment, SMS or e-mail vendor, check the pricing/limits row
  against the plan quotas; mismatches go to `pricing-billing-designer`, not into
  the spec as a decision.
- Spec Status is `Draft` while any load-bearing item is `NOT SOURCEABLE` or an
  open question blocks implementation. Only the user moves it to `Approved`.

## 3. Structure check

`bash .claude/scripts/spec-structure-check.sh` applies to feature specs, not to
this template; do the structure check by hand: 13 numbered sections present, header
fields filled, every table has at least one real row or an explicit
`Not applicable`. Report the result as "structure checked by reading" — it is a
read-through, not a script result.

## 4. Write

Ask: "May I write the integration spec to
`docs/architecture/integrations/<provider>.md`?" Write only after approval. With
`--update`, show the diff of changed sections first and keep the section
numbers.
