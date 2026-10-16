# /integration - Phase 1: Arguments, Trigger and Inputs

> Phase 1 of `SKILL.md`. Read it again if the conversation was compacted.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `<provider>` | Lowercase slug of the provider or capability (`paymob`, `sms-gateway`, `s3-storage`). Files: `docs/research/<provider>.md`, `docs/architecture/integrations/<provider>.md`, `docs/architecture/threat-models/<provider>.md` |
| `--update` | An integration exists and is being revised (API version bump, new operation, new webhook event). Existing IDs and sections are kept; changes are marked |
| no argument | Ask which provider or capability (`AskUserQuestion`). Offer the capabilities named in `design/specs/*.md` that have no integration spec; never guess |
| `--review` | Override `review_mode` for this run (gates only) |

If the user names a capability but not a provider (for example "SMS OTP"), the
provider is **not chosen**: Phase 2 compares options and the user decides. The
studio never picks a provider on its own.

## 2. Classify the capability

Record (ask when unclear) which of these apply; they select checks later:

| Class | Applies when | Adds |
|---|---|---|
| money | payments, payouts, subscriptions, refunds | reconciliation job, minor-unit amounts, server-side catalogue, no card data (I11, I12) |
| inbound webhooks | provider calls us | verify, replay, dedupe, async (I9) |
| PII | recipient phone/email, names, addresses | masking, minimisation, DPA/sub-processor, `privacy-compliance-specialist` |
| side effects after commit | emails, SMS, provider calls triggered by state change | outbox (I10) |
| per-tenant credentials | a tenant brings its own provider account | per-tenant config, isolation test |
| user-supplied URL | callbacks, redirects, avatar/fetch | egress allowlist client (SSRF) |
| file transfer | object storage | random keys, tenant prefix, presigned URLs, sniffed type |

## 3. Record every input as FOUND or ABSENT

Derive paths with `bash .claude/hooks/yaml-helper.sh resolve_code_root` and
`.claude/docs/directory-structure.md`. An empty code-root result means the
code-scanning checks are `NOT ASSESSED — no source under <root>`, never "no hits".

| Input | Path | Why |
|---|---|---|
| Feature spec(s) | `design/specs/<feature>.md` | what the integration serves; roles, quotas, failure UX |
| Existing research note | `docs/research/<provider>.md` | reuse; a note older than the provider's pinned API version is stale |
| Existing integration spec / threat model | `docs/architecture/integrations/<provider>.md`, `docs/architecture/threat-models/<provider>.md` | `--update` baseline |
| Architecture, ADRs | `docs/architecture/architecture.md`, `docs/architecture/adr-*.md` | ports already defined, messaging/outbox decision, tenancy, deployment |
| Control manifest | `docs/architecture/control-manifest.md` | forbidden patterns |
| Pricing/entitlement model | `design/specs/pricing-model.md` | catalogue the adapter must read (money class) |
| Code | code roots from `resolve_code_root` | existing ports, adapters, composition root |
| Contracts | `contracts/openapi/*.yaml` | inbound webhook route, `Idempotency-Key` on our endpoints (`api-standards.md`) |
| Deploy | `deploy/hosted/`, `deploy/self-hosted/` | secret wiring, egress, what a customer bundle may contain |
| Stack reference | `docs/stack-reference/pins.yaml` and `<layer>/` for the backend track (`go/` or `ktor/` + `kotlin/`), `postgres/best-practices.md` (outbox in the same transaction, RLS), `redis/best-practices.md` §6 (idempotency keys) and §10 (customer bundles run Valkey), `opentelemetry/best-practices.md` §2 | language idioms; record each file's Last verified date. An absent layer is `NOT SOURCEABLE — no stack reference for <layer>`, not filled |
| Config | resolved block: `stack`, `distribution`, `tenancy` | unset `distribution` is asked, not assumed: self-hosted needs configuration-driven provider choice |

Report FOUND/ABSENT in a table before continuing. An ABSENT feature spec at
`standard`/`full` is a gap, not a stop; at `minimal` the brief and the research
note carry the requirement.

## 4. Core-first check

`.claude/rules/integrations.md`: prefer `saas-core` modules for identity, OTP,
notifications, storage, billing and licensing.

1. Read `project.yaml` `core.track` / `core.version` (resolved `stack`) and look for a
   `saas-core-<track>` checkout or dependency and its module docs. If the core
   repository or its module list cannot be read: `core-first check — NOT
   ASSESSED (core not reachable)`; ask the user, do not assume absent.
2. If a module covers the capability: stop and recommend `/core-use <module>`. The
   user may override with a **written reason** (for example the module lacks the
   chosen provider's adapter); the reason goes in the spec header. A missing
   adapter in the core is a `/core-extract` candidate, not a reason to fork.
3. If no module covers it: record `no core module for <capability>` with the
   evidence searched.

Never edit `saas-core-*` from a product repo.

## 5. Provider choice

If the provider is chosen, record it and who chose it. If not, the research note
(Phase 2) compares at least two options with cost, risk, performance and
operability including the self-hosted bundle and the exit plan; the user decides
with `cto` (technology) and `pricing-billing-designer` (fees and plans). A
choice that is architectural (for example the billing provider) is an ADR through
`/architecture-decision`; it is a critical ADR when it governs billing or
identity (`workflow-modes.md`).
