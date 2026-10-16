# /create-architecture — Phase 3: Data Flow, Messaging, Caching and Observability

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Data Flow, Messaging, Caching and Observability

Define how data moves between contexts, clients and providers during key
scenarios. Cover at minimum:

1. **Request path**: client → reverse proxy → API adapter → use case → ports → store, with tenant context, authn/authz point and the span/metric points marked
2. **Sign-in and token path**: who issues, validates and refreshes tokens; the `saas-core` identity module's role
3. **Async path**: jobs, schedules and domain events; transactional outbox, delivery semantics (at-least-once + idempotent consumers), retries, dead-letter, ordering
4. **Webhook paths** (in and out): signature verification, dedupe by event ID, async processing; signing and replay for out
5. **External provider path** (payments, SMS/OTP, email, storage, push): adapter behind a port, timeout, retry (idempotent calls only), circuit breaker or bulkhead, idempotency key, reconciliation
6. **Tenant data export / delete path** (PII)
7. **Start-up and migration order**: which services, migrations and seeds run before which (one-shot migration job before the new version starts)

Use Mermaid sequence diagrams. For each flow:
- Name the data transferred and its tenancy scope
- Identify producer and consumer
- State whether it is a synchronous call, an event/message, or shared state
- Flag any flow that crosses a trust boundary (needs a threat-model path) or a transaction boundary

### 3a. Messaging

Read `stack.messaging`. If it is empty, decide whether any flow above needs a
broker at all — an outbox table plus a polling worker in PostgreSQL often
suffices at first. If a broker is chosen it is a critical ADR, must be in the
stack reference (or marked `NOT SOURCEABLE`), and must have a self-hosted answer
(extra service in the bundle, licence, memory). Specify delivery guarantees,
idempotent consumers, DLQ and the lag metric.

### 3b. Caching tiers

Produce the cache map following `.claude/docs/caching-standard.md`:

| Tier | What | Pattern | Store | TTL / invalidation | Tenant isolation | Edition notes |
|------|------|---------|-------|--------------------|------------------|---------------|
| Client (TanStack Query / mobile repositories) | | staleTime + invalidate-on-mutate | memory | | | |
| HTTP/edge | static SPA assets, public responses | `Cache-Control`/`ETag`; `private, no-store` for tenant data | proxy | | | |
| Application (shared) | | cache-aside / read-through | Redis / Valkey / Dragonfly | | tenant ID in key | **Valkey in the bundle** |
| In-process | | singleflight / small bounded LRU | memory | | | |
| Database | read replicas, materialised views if any | | postgres | | | |

Every cached item gets a one-line cache decision (what, why, pattern, key schema,
TTL, invalidation, stampede protection, failure mode). "No cache" is a valid entry
with its reason. The per-feature decision is still written in the spec or research
note; this table is the architecture-level map and names the owning ADR.

### 3c. Observability pipeline

Specify (OTel, per `.claude/docs/observability-standard.md`): SDK per layer →
OTLP → collector → backend; the backend choice is an ADR (hosted) and, for the
self-hosted bundle, **only the OTel Collector** with exporters disabled by
default (licence decision L4). State: trace propagation across HTTP, messages
and jobs; the log pipeline; metrics (RED/USE) and cardinality budget; SLO and
alert sources (`docs/architecture/slos.md`), health endpoints, client
crash/telemetry, and how a self-hosted customer points the collector at their
own backend.

### 3d. Performance budget location

State that `docs/architecture/perf-budgets.md` is the single source of budgets,
list the hot paths this architecture creates (listing, search, dashboards, auth,
webhooks, exports) and the per-path budget owner. If the file does not exist,
record "perf-budgets.md missing — created by `/perf-profile` or on first
Performance story" in Open Questions; do not invent numbers here.

Get user approval on each scenario and on the cache map and observability
pipeline, then record them in `production/session-state/active.md`; they are
written at Phase 8.

---
