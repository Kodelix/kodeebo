# Redis Open Source 8.x — Deprecated / Removed APIs

Last verified: 2026-10-11. "Deprecated" = still works, documented as deprecated on the command or feature page, may be removed later. "Removed" = gone.

Use the replacement column in new code. All rows were checked on redis.io `latest` command pages fetched 2026-10-11, except where marked.

| Deprecated / removed | Replacement | Since | Source |
|---|---|---|---|
| `GETSET key value` | `SET key value GET` (GET option since 6.2.0). Redis docs on `SET` state that the `SET` options can replace GETSET. | Deprecated as of 6.2.0 | [GETSET](https://redis.io/docs/latest/commands/getset/), [SET](https://redis.io/docs/latest/commands/set/) |
| `RPOPLPUSH source destination` | `LMOVE source destination RIGHT LEFT` (LMOVE since 6.2.0; the LMOVE page says it "comes in place of the now deprecated RPOPLPUSH") | Deprecated as of 6.2.0 | [RPOPLPUSH](https://redis.io/docs/latest/commands/rpoplpush/), [LMOVE](https://redis.io/docs/latest/commands/lmove/) |
| `BRPOPLPUSH source destination timeout` | `BLMOVE source destination RIGHT LEFT timeout` (BLMOVE since 6.2.0) | Deprecated as of 6.2.0 | [BRPOPLPUSH](https://redis.io/docs/latest/commands/brpoplpush/), [BLMOVE](https://redis.io/docs/latest/commands/blmove/) |
| `HMSET key field value [...]` | `HSET key field value [...]` (HSET takes multiple field-value pairs). The version in which multi-pair HSET appeared is NOT SOURCEABLE in this pass (HSET page lists since 2.0.0 only). | Deprecated as of 4.0.0 (per HMSET page compatibility table) | [HMSET](https://redis.io/docs/latest/commands/hmset/), [HSET](https://redis.io/docs/latest/commands/hset/) |
| `ZRANGEBYSCORE key min max` | `ZRANGE key min max BYSCORE` (ZRANGE since 1.2.0; its page says it "can replace" ZRANGEBYSCORE from 6.2.0) | Deprecated as of 6.2.0 | [ZRANGEBYSCORE](https://redis.io/docs/latest/commands/zrangebyscore/), [ZRANGE](https://redis.io/docs/latest/commands/zrange/) |
| `ZREVRANGE`, `ZREVRANGEBYSCORE`, `ZRANGEBYLEX`, `ZREVRANGEBYLEX` | `ZRANGE` with `REV`, `BYSCORE`, `BYLEX` options (6.2.0) | 6.2.0 (per ZRANGE page). Pages of the four commands were NOT fetched; deprecation status of each: NOT SOURCEABLE in this pass. | [ZRANGE](https://redis.io/docs/latest/commands/zrange/) |
| `GEORADIUS key lon lat radius unit [...]` (and its `_RO` variant on the same page) | `GEOSEARCH` (since 6.2.0), which replaces GEORADIUS and GEORADIUSBYMEMBER and also supports BYBOX. The `STORE` replacement (`GEOSEARCHSTORE`) was NOT fetched: NOT SOURCEABLE in this pass. | Deprecated as of 6.2.0 | [GEORADIUS](https://redis.io/docs/latest/commands/georadius/), [GEOSEARCH](https://redis.io/docs/latest/commands/geosearch/) |
| `GEORADIUSBYMEMBER` | `GEOSEARCH ... FROMMEMBER` | Page not fetched: deprecation status NOT SOURCEABLE in this pass; the GEOSEARCH page names GEORADIUS and GEORADIUSBYMEMBER together as deprecated. | [GEOSEARCH](https://redis.io/docs/latest/commands/geosearch/) |
| `SLAVEOF host port` / `SLAVEOF NO ONE` | `REPLICAOF host port` / `REPLICAOF NO ONE` (REPLICAOF since 5.0.0; the SLAVEOF page says "deprecated; use REPLICAOF") | Deprecated as of 5.0.0 | [SLAVEOF](https://redis.io/docs/latest/commands/slaveof/), [REPLICAOF](https://redis.io/docs/latest/commands/replicaof/) |
| `rename-command` in `redis.conf` to hide dangerous commands | ACL rules: `ACL SETUSER <user> ... -flushall -config|set` etc. The security page says the method "is deprecated and may be removed in future versions." | Deprecated (version not stated on page) | [Redis security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/) |
| ACL first-arg rule `+<command>|first-arg` (for example `+select|0`) | Use subcommand rules (`+config|get`, `-config|set`, supported from 7.0) or restructure permissions | Deprecated since 7.0 (per ACL page) | [ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/) |
| `hash-max-ziplist-entries`, `hash-max-ziplist-value`, `zset-max-ziplist-entries`, `zset-max-ziplist-value` | `hash-max-listpack-entries`, `hash-max-listpack-value`, `zset-max-listpack-entries`, `zset-max-listpack-value` (Redis >= 7.0 names; the memory page shows the Redis <= 6.2 names next to the 7.0+ names) | Renamed in 7.0 (per memory-optimization page) | [Memory optimization](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/memory-optimization/) |
| `SETNX key value` used as a lock | `SET key value NX PX <ms>` plus a token-checked release (see distributed-locks page). SETNX is not marked deprecated on its page but the page says the pattern is discouraged in favour of Redlock. | Not deprecated; locking pattern discouraged | [SETNX](https://redis.io/docs/latest/commands/setnx/), [Distributed locks](https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/) |
| `SETEX key seconds value`, `PSETEX`, `SETNX`, `GETSET` as separate commands | `SET` with `EX`, `PX`, `NX`, `GET` options. The SET page says these commands "will be deprecated and finally removed" in future versions. Note: SETEX page shows no deprecation. | No removal date given | [SET](https://redis.io/docs/latest/commands/set/), [SETEX](https://redis.io/docs/latest/commands/setex/) |
| Standalone RediSearch / RedisJSON / RedisTimeSeries / RedisBloom and Redis Stack versions | Redis 8.x built-in modules. The 8.0 notes say they are "no longer needed" and that Redis 8.0 "deprecates previous Redis and Redis Stack versions." | 8.0.0 (May 2025) | [8.0 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/) |
| GCRA rate limiter | `INCREX` (window counter, 8.8.0) or a Lua script | Removed 8.8-RC1 | [8.8 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/) |
| `SET` with mutually-exclusive options combined (NX with XX, or NX with IFEQ) | Use one condition per call. Previously accepted silently; enforced from 8.10. | Enforced 8.10 (fix listed in 8.10-RC1) | [8.10 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/), [SET](https://redis.io/docs/latest/commands/set/) |
| Redis 8.2 `LeanVec` / `LVQ` index parameters (Intel proprietary optimisations) | Use open-source vector compression options (SVS-VAMANA compression variants listed in 8.2 notes) or non-LeanVec index types. | Removed from Redis OSS in 8.2.1 | [8.2 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.2-release-notes/) |

## Redis-only commands and options (not deprecated, but not portable)

These are not deprecated. Do not use them in code that must also run on Dragonfly (see [../dragonfly/deprecated-apis.md](../dragonfly/deprecated-apis.md) and the portability section of [best-practices.md](best-practices.md)).

| Feature | Since | Source |
|---|---|---|
| `DELEX`, `DIGEST`, `SET ... IFEQ/IFNE/IFDEQ/IFDNE` | 8.4.0 | [8.4 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.4-release-notes/), [SET](https://redis.io/docs/latest/commands/set/) |
| `MSETEX` | 8.4.0 | [8.4 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.4-release-notes/) |
| `INCREX` | 8.8.0 | [8.8 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/) |
| `XADD ... IDMP / IDMPAUTO` idempotent production | 8.6.0 | [8.6 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/) |
| `volatile-lrm`, `allkeys-lrm` eviction | 8.6.0 | [Key eviction](https://redis.io/docs/latest/develop/reference/eviction/) |
| `HOTKEYS` | 8.6.0 | [8.6 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/) |
| `BACKUP`, `BACKUP START/LIST/SEAL/CLEANUP/STATUS/ABORT` | 8.10.0 | [Persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/) |
| `LMOVEM`, `BLMOVEM`, `SUNIONCARD`, `SDIFFCARD`, `HIMPORT`, compact hashes | 8.10.0 | [8.10 release notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/) |

## Removed or deprecated Lua behaviour

No deprecation notice was found for `EVAL` or `EVALSHA` on the pages fetched. The Redis Lua API page and the EVAL intro page were NOT fetched (404 on the tried URLs); the shebang flag list is NOT SOURCEABLE in this pass.
