# Cache Design: [Feature / Entity]

> **Status**: Draft | Approved | Implemented
> **Owner**: [engineer] · **Reviewer**: principal-engineer / performance-engineer
> **Date**: [YYYY-MM-DD]
> **Spec / story**: [`design/specs/<feature>.md` NFR "Caching Decision"] · **Research note**: [`docs/research/<feature>.md`]
> **Backend**: Redis protocol — Redis or Dragonfly. Use the **common command subset** only; anything server-specific (Redis vs. Dragonfly) needs an ADR and a note in the cache adapter (`docs/stack-reference/{redis,dragonfly}/`).

<!-- DoD gate 5 (caching-standard.md). A cache is a second copy of the truth that can be wrong:
     say how it stays correct, how it fails, and that it is worth it. One block per cached thing.
     "No cache" is a valid decision — fill only Section 1 and the reason. -->

## 1. Decision Summary

- **Decision**: [Cache | No cache]
- **If no cache — reason**: [e.g. data changes per request; source query already meets the budget (p95 X ms vs budget Y ms)]

## 2. Cache Entry: [Name]

| Field | Value |
|-------|-------|
| **What** | [e.g. Plan entitlements per tenant] |
| **Why** | [e.g. Read on every request; source query 8 ms p95; changes a few times a month — evidence: query plan / metric] |
| **Pattern** | [cache-aside / read-through / write-through / write-behind / request coalescing] |
| **Key schema** | [`{env}:{svc}:{entity}:v{schema}:{id...}` — e.g. `prod:api:ent:v3:{tenant_id}`] |
| **Value format** | [versioned, compact — MessagePack or JSON with a `v` field; size estimate; > 100 KB is a smell — cache a projection] |
| **TTL** | [e.g. 10 min + jitter ±10 %; every key has a TTL] |
| **Invalidation** | [delete on write / event (e.g. `PlanChanged`); TTL as backstop; list every writer] |
| **Stampede protection** | [singleflight in-process + short lock key / probabilistic early refresh] |
| **Failure mode** | [cache down -> read from source, emit metric, do not fail the request] |
| **Expected hit ratio** | [> 95 % — alert below this] |
| **Tenant isolation** | [tenant ID in every key; no cross-tenant aggregate cached under a shared key] |
| **Sensitivity** | [No secrets, no OTP in clear, no full PII records; authorization decisions cached no longer than the permission-change latency you can accept, invalidated on role change] |
| **Instance & memory** | [instance (cache vs. durable-ish data separated); `maxmemory` and eviction policy; expected key count × size] |
| **Access pattern** | [single GET / MGET / pipeline — no per-item round-trips in loops; no `KEYS`; no unbounded `SMEMBERS`/`HGETALL`] |
| **HTTP/client caching** | [`Cache-Control`/`ETag`/CDN for public; `private, no-store` for tenant-specific; client `staleTime` and mutation invalidation] |
| **Self-hosted** | [works with the bundled Redis/Dragonfly; behaves correctly if cache is absent] |

## 3. Other Redis-Protocol Uses (if any)

| Use | Rule applied | Design |
|-----|--------------|--------|
| Rate limiting | sliding window / token bucket, atomic, keyed by tenant + actor + route | |
| Distributed lock | short TTL, fencing token for writes; prefer DB constraints | |
| Sessions | server-side, rotated on privilege change, revocable | |
| Idempotency keys | `SET NX` with TTL >= client retry window; store response to replay | |
| Queues / streams | only with an ADR; consumer groups, ack, dead-letter, lag metric | |

## 4. Observability

- Hit/miss counters, latency histogram, errors per adapter; evictions per instance
- Alert: hit ratio below expected for [N] minutes -> [runbook]
- Dashboards: [link]

## 5. Tests (see `testing-standards.md`)

- [ ] Hit
- [ ] Miss (loads from source and populates)
- [ ] Invalidation on write
- [ ] TTL expiry
- [ ] **Cache down -> still correct**
- [ ] Tenant isolation (tenant A cannot read tenant B's entry)
- [ ] Stampede (concurrent misses -> one source load)
- [ ] Schema bump (`v` change) does not read old-shaped values

## 6. Review Checklist

- [ ] Every key has a TTL with jitter; no eternal keys (or ADR)
- [ ] Invalidate on write; TTL as backstop; no race-written stale values
- [ ] Bounded size; separate instance/DB from durable-ish data
- [ ] Failure of the cache never fails the request
- [ ] Decision recorded in the spec or here
