---
paths:
  - "**/adapters/redis/**"
  - "**/adapters/cache/**"
  - "**/adapters/dragonfly/**"
  - "**/*cache*.go"
  - "**/*Cache*.kt"
---

# Cache Code Rules (Redis / Dragonfly)

Standard: `.claude/docs/caching-standard.md`. The cache decision for this feature must already be written.

- Cache adapters are decorators around a repository port; use cases do not know a cache exists.
- Keys via a single key-builder function per context: `{env}:{svc}:{entity}:v{n}:{tenant_id}:{id}`. No string concatenation elsewhere.
- Every write sets a TTL with jitter. No eternal keys.
- Cache down → log once, increment a metric, fall through to the source. A cache error never fails the request.
- Stampede protection on expensive loads (singleflight / lock key / early refresh).
- No `KEYS`, `FLUSH*`, unbounded `SMEMBERS`/`HGETALL`/`LRANGE 0 -1` in application code.
- Multi-key reads via `MGET`/pipelines; Lua only for atomic multi-step logic, kept short, and checked for Dragonfly compatibility.
- Never store secrets or raw OTPs; store hashes/counters.
- Emit hit/miss/latency/error metrics per cache.
- Integration tests run against **every engine the product can ship on**: Valkey (customer bundles, decision L1) always; Redis and/or Dragonfly when the hosted edition uses them. Valkey parity is assumed only for commands verified in the test suite.
