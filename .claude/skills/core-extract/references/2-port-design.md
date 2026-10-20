# /core-extract — Phase 3: Port Design

> Part of `/core-extract`. Read again if the conversation was compacted.

## 1. Who designs, who reviews

`principal-engineer` owns module design (port list, composition root, the
core-vs-product split); the backend lead of the **product's track** supplies
idiom and structure (`go-lead` for `core.track: go`, `ktor-lead` for
`kotlin`; `stack.backend` unset is a STOP — `/setup-stack`). Resolve the
specialist reviewers by what the capability is (parallel, independent):

| Capability concerns | Reviewer |
|---|---|
| authentication, sessions, tokens, MFA, SSO, RBAC | `auth-identity-specialist` |
| tenant model, isolation, tenant-context propagation | `multitenancy-specialist` |
| signed licences, activation, entitlement enforcement | `licensing-specialist` |
| plans, entitlements, metering, subscriptions (the engine is core; the catalogue is the product's) | `pricing-billing-designer` |
| a provider behind a port (SMS/OTP, email, storage, push, payments, webhooks) | `integrations-engineer` |
| spans, metrics, logs, SLO instrumentation | `observability-engineer` |
| PII, audit trail, retention, export/delete | `privacy-compliance-specialist` and `security-lead` |
| rate limiting, key schemas, TTL, portability across Redis/Valkey/Dragonfly | `cache-specialist` |
| outbox, queues, delivery semantics | `messaging-specialist` |
| a network-exposed surface (HTTP/proto) | `api-designer` |
| client pieces in the core's `clients/` (KMP, Swift, TypeScript) | `kmp-specialist`, `ios-lead`, `web-lead` |

State the active reviewers and any the capability would normally add but that are
not spawned (with why) before spawning. Spawn the lead design first (it is the
input to the rest), then **all reviewers in one message, in parallel**
(`coordination-rules.md`, Parallel Task Protocol).

**Briefing — paths and decisions, not pasted documents.** Each agent reads the
evidence file, the capability's code, the relevant `docs/stack-reference/<layer>/`
and `pins.yaml`, `clean-architecture.md`, `testing-standards.md`,
`observability-standard.md`, `security-baseline.md`, and (when readable) the core
repo's module layout and policy docs.

**Return contract (end every prompt with it):** "Write your full output to
`[path]` — that named path is your write authorisation under the bounded
exception below, so write it without a separate approval prompt. Return **only**
(1) the path written, (2) a ≤5-bullet summary of decisions, (3) any
BLOCKED/CONCERNS items, one line each. Do not restate the documents you read."
Paths: `production/core/proposals/<module>/design.md` (lead),
`production/core/proposals/<module>/review-<agent>.md` (each reviewer).

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires
> "May I write …?" before Write/Edit; a spawned agent here writes without asking
> as a bounded exception that holds only when (1) the path is one **you** named,
> (2) it is a **new** artifact under `production/` or `docs/`, never an edit to
> existing source or config, and (3) the phase is gated by an `AskUserQuestion`
> before the pipeline advances. Outside those, the agent asks. Do not turn this
> into a prompt per agent.

## 2. What `design.md` must settle

Each item is a section; an item not settled is listed as an open question with an
owner, never skipped.

1. **Module name, purpose, non-goals** — what it will not do.
2. **Ports** — each as a language-neutral contract (operations, inputs, outputs,
   error cases, idempotency, timeouts the caller must set) plus an *illustrative*
   signature in the track's language, marked "to be finalised in the core repo".
   Ports are declared by the consumer; no provider type, error code or field name
   appears in a port (`integrations-engineer.md`). Network-exposed parts also get
   an OpenAPI/proto sketch via `api-designer`, kept out of `contracts/` of the
   product (the contract lives in the core repo).
3. **Adapters** — each real adapter and its infrastructure, checked against the
   customer-bundle rules (Valkey for cache, the official Mongo image only,
   OTel Collector only; Dragonfly hosted-only — `.claude/docs/standing-decisions.md` L1–L4,
   `.claude/rules/deploy.md`). Plus a shipped **in-memory/fake adapter** for
   consumers' unit tests.
4. **Conformance suite** — the named behaviours **every** adapter (including the
   fake) must pass: happy path, each documented error, idempotent repeat,
   timeout/unavailable behaviour, tenant isolation (tenant A's data is invisible
   to tenant B), and ordering/pagination boundaries where relevant. Integration
   runs use real dependencies via Testcontainers (`testing-standards.md`); engine
   images come from `pins.yaml`. The port is not accepted without this list.
5. **Configuration** — typed keys with defaults, which are secrets, which differ
   between hosted and bundle. No business value inline.
6. **Tenancy contract** — how the tenant is supplied (from the authenticated
   context, never a request field) and where scoping is enforced.
7. **Observability contract** — span names and attributes, RED metrics, log
   fields (`trace_id`), what is never logged (PII, secrets).
8. **Error model** — the typed domain errors; how they map to RFC 9457 at a
   product's HTTP edge (the module returns errors, it does not render problem
   details).
9. **Persistence** — tables/collections the module owns, migration approach
   (expand → migrate → contract, `.claude/rules/migrations.md`), and how a
   product with an existing local table migrates onto it (`/db-migration`).
10. **Versioning and deprecation stance** — proposed first version and the
    rules the core's `/core-release` will apply. The core repo's policy document
    wins if it exists; if it does not, the proposal says `core deprecation
    policy: NOT SOURCEABLE` and lists the decision as an open question for `cto`
    — a module is not released without one.
11. **Other-track parity** — the core has a Go track and a Kotlin track. State:
    needed in the other track (when, who) / not needed (why) / undecided (owner:
    `cto`). Language-neutral parts (contracts, conformance case list, config
    schema) are written once and shared.
12. **Threat model need** — security-baseline triggers hit? If so, `/threat-model`
    is a prerequisite for the proposal being `COMPLETE`; the design records the
    hit and the owner.
13. **Self-hosted impact** — extra services, config, upgrade path.

## 3. Review the results

Read every returned file (verify each path exists — Trigger 0). Present, per
`automation-modes.md`: the design summary, each reviewer's CONCERNS/BLOCKED lines
verbatim, and the open questions. A reviewer that could not run or was skipped is
a named gap in the final report. Ask `AskUserQuestion`: approve the design ·
revise (name the section; the same agent re-drafts) · stop.
