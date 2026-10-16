# Caching Standard

DoD gate 5. A cache is a second copy of the truth that can be wrong. Every
cache must say how it stays correct, how it fails, and that it is worth it.

Redis and Dragonfly are both used through the Redis protocol. Code targets
the **common command subset**; anything engine-specific (Dragonfly emulated
cluster mode, Lua script flags, Redis modules) needs an ADR and a note in the
cache adapter. Verify differences in `docs/stack-reference/{redis,dragonfly}/`.

## The cache decision (written per feature)

Recorded in the spec or research note:

| Field | Example |
|---|---|
| **What** | Plan entitlements per tenant |
| **Why** | Read on every request; source query 8 ms p95; changes a few times a month |
| **Pattern** | cache-aside / read-through / write-through / write-behind / request coalescing |
| **Key schema** | `{env}:{svc}:ent:v3:{tenant_id}` |
| **Value format** | versioned, compact (MessagePack or JSON with a `v` field) |
| **TTL** | 10 min + jitter ±10 % |
| **Invalidation** | delete on `PlanChanged` event; TTL as backstop |
| **Stampede protection** | singleflight in-process + short lock key / probabilistic early refresh |
| **Failure mode** | cache down → read from source, emit metric, do not fail the request |
| **Expected hit ratio** | > 95 % |
| **Tenant isolation** | tenant ID in every key; no cross-tenant aggregate cached under a shared key |

"No cache" is a valid decision — write the reason (e.g. data changes per request, or source is already fast enough for the budget).

## Rules

- **Key naming**: `{env}:{service}:{entity}:v{schema}:{id...}`. Bump `v` on any value-shape change instead of migrating cached data.
- **Every key has a TTL.** No eternal keys except explicit configuration stores, and those need an ADR.
- **Jitter every TTL** to avoid synchronized expiry.
- **Invalidate on write, TTL as backstop.** Prefer delete-on-write over update-on-write to avoid race-written stale values.
- **Never cache authorization decisions longer than the session/permission change latency you can accept** — and invalidate on role change.
- **Never cache secrets, OTP codes in clear, or full PII records.** OTP and rate-limit counters are stored hashed / as counters with TTL.
- **Bounded size**: configure `maxmemory` and an eviction policy per instance; separate instances (or logical DBs with an ADR) for cache vs. durable-ish data (queues, rate limits, sessions).
- **No `KEYS`, no unbounded `SMEMBERS`/`HGETALL` on large structures** in request paths — use `SCAN` / bounded structures.
- **Pipelines / `MGET`** for multi-key reads; no N round-trips in a loop.
- **Large values** (> 100 KB) are a smell: cache a projection, not the aggregate.
- **HTTP caching** for public/static responses: `Cache-Control`, `ETag`, CDN — and `private, no-store` on anything tenant-specific.
- **Client caches** (TanStack Query, mobile repositories) define `staleTime` and invalidation on mutations; they are UX, never a source of truth.

## Other Redis-protocol uses (not caching, same instance rules)

| Use | Rule |
|---|---|
| Rate limiting | sliding window or token bucket, atomic (Lua / `INCR`+`EXPIRE` in a transaction), keyed by tenant + actor + route |
| Distributed locks | short TTL, fencing token for anything that writes; prefer DB constraints when possible |
| Sessions | server-side, rotated on privilege change, revocable |
| Idempotency keys | `SET NX` with TTL ≥ client retry window; store the response to replay |
| Queues / streams | only with an ADR; consumer groups, ack, dead-letter, and lag metric |

## Observability

Every cache adapter emits: hit/miss counters, latency histogram, errors, and
evictions (instance-level). A hit ratio below the expected value is an alert.

## Tests (see testing-standards.md)

Hit, miss, invalidation on write, TTL expiry, **cache down → still correct**,
and tenant isolation.
