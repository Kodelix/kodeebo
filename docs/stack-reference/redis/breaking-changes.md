# Redis Open Source 8.x — Breaking and Behaviour-Changing Changes

Last verified: 2026-10-11. Scope: Redis Open Source 7.2 (BSD line, for reference) and 8.0–8.10 (the lines we run). Pin and version facts live in [VERSION.md](VERSION.md).

Sources: release notes under `https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/` (`redisos-8.0-release-notes/`, `redisos-8.2-…`, `8.4-…`, `8.6-…`, `8.8-…`, `8.10-…`), fetched 2026-10-11. Note: the redis.io release-notes pages at fetch time did not list 8.10.2 (or the 8.2.10 / 8.4.7 / 8.6.7 / 8.8.3 patch releases); those versions were confirmed only from the GitHub releases list (`https://github.com/redis/redis/releases`, 8.10.2 marked Latest, 17 Sep 2026). Their changelog content is NOT SOURCEABLE from redis.io at fetch time.

Redis Open Source 7.x note: 7.4+ is RSALv2/SSPLv1; see VERSION.md licence section.

## Summary: what breaks code that talks to Redis (and Dragonfly)

| # | Change | Since | Impact on our code | Source |
|---|---|---|---|---|
| 1 | ACL categories `@read`/`@write`/`@dangerous`/… now include Search, JSON, time series, Bloom, Cuckoo, Top-k, CMS, t-digest commands | 8.0.0 | `+@read +@write` grants more; `+@all -@write` grants fewer (e.g. `JSON.SET` denied). Re-audit every ACL user. | [8.0 notes, "Potentially breaking changes to ACLs"](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/) |
| 2 | Standalone RediSearch/RedisJSON/RedisTimeSeries/RedisBloom are "no longer needed" (built in) | 8.0.0 | Modules are bundled; do not depend on separate module images. Redis Stack 7.2/7.4 upgrade path listed. | [8.0 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/) |
| 3 | Licence is now a choice of RSALv2, SSPLv1 or AGPLv3 | 8.0.0 | Licence obligations depend on which one the deployment uses. See VERSION.md. | [8.0 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/) |
| 4 | LeanVec/LVQ proprietary Intel optimisations removed from Redis Open Source | 8.2.1 | Do not create indexes with LeanVec/LVQ parameters on OSS builds. | [8.2 notes, 8.2.1 "Performance and resource utilization"](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.2-release-notes/) |
| 5 | `SCAN` filter order changed in 8.2, then reverted | 8.2 change, reverted in 8.4.4 and 8.6-RC1 | Do not rely on the 8.2 filter ordering. | [8.4 notes, 8.4.4 bug fixes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.4-release-notes/) |
| 6 | `SET` now enforces that `NX`/`XX` and `IF*` options are mutually exclusive | 8.10-RC1 (bug fix) | Clients sending e.g. `NX` plus `IFEQ` now get an error. Send only one condition. | [8.10 notes, 8.10-RC1 bug fixes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/) and [SET](https://redis.io/docs/latest/commands/set/) (states the options are mutually exclusive) |
| 7 | `SLOWLOG GET` reply has an extra argument (total argument count) | 8.10-RC1 | Log/metrics parsers that index by position break. | [8.10 notes, New Features](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/) |
| 8 | `SLOWLOG` truncation controls `slowlog-entry-max-argc`, `slowlog-entry-max-string-len` | 8.8.0 | Slow-log entries may be truncated; do not log secrets via slowlog expecting full args. | [8.8 notes, Configuration parameters](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/) |
| 9 | GCRA rate limiter removed; `INCREX` added as a window counter rate limiter | GCRA removed in 8.8-RC1 (`#15191`); `INCREX` in 8.8.0 | Any GCRA-based rate limiter must move to `INCREX` or to a Lua script. Redis-only: not portable. | [8.8 notes, Removed Features](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/) and [8.8.0 major changes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/) |
| 10 | `ACL LOAD` accepts `#` comment lines; comments are not persisted | 8.8.0 | ACL files with comments now load; `ACL SAVE` drops them. | [ACL page](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/) |
| 11 | Error replies sanitised: `\r\n` injection into error replies fixed | 8.0.6, 8.2.5, 8.4.2, 8.6.1 (SECURITY) | Error text can no longer carry injected lines. Clients that parse error payloads by line must not assume attacker-free text. | [8.0 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/) (8.0.6), [8.2 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.2-release-notes/) (8.2.5) |
| 12 | Hash-field expiration and `HSETEX`/`HGETEX` validation tightened (`FIELDS` only once) | 8.6.2 | Malformed `HSETEX`/`HGETEX` now rejected. Fix callers. | [8.6 notes, 8.6.2](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/) |
| 13 | `XADD` idempotency options `IDMP`/`IDMPAUTO`; `volatile-lrm`/`allkeys-lrm` eviction | 8.6.0 | New Redis-only options. Do not use in code that must run on Dragonfly (compatibility of these with Dragonfly not verified). | [8.6 notes, Major changes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/) |
| 14 | Known limitation: `XADD ... IDMP/IDMPAUTO` not allowed with `appendonly yes` + `aof-use-rdb-preamble no` | 8.6.0 | Avoid that AOF combination if using IDMP. | [8.6 notes, Known bugs](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/) |
| 15 | TLS certificate-based automatic client auth (`tls-auth-clients-user`) | 8.6.0 | Client cert CN can map to an ACL user. CN NUL-byte truncation bypass (authenticates as another ACL user) fixed in 8.6.6, 8.8.2, 8.10.1. | [8.6 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/), [8.6.6](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/) |
| 16 | `search-on-timeout` default and options changed (`RETURN` default; `RETURN_STRICT` added); `search-on-oom` values | 8.10.0 / 8.4.0 | Search-module timeout semantics change. Only relevant if using `FT.*` (not portable). | [8.10 notes, New Features](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/), [8.4 notes, Configuration](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.4-release-notes/) |
| 17 | `FT.CREATE`/`FT.ALTER` reject empty field names; `FT.CREATE` rejects invalid option combinations | 8.10.0 / 8.4.x / 8.6.x | Search-module only. | [8.10 notes, bug fixes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/) |
| 18 | `SET` no longer leaves the previous TTL in place in one case (bug fix: "TTL was not removed by the `SET` command") | 8.2.0 (bug fix) | Do not rely on an old TTL surviving a `SET` without `KEEPTTL`. | [8.2 notes, bug fixes (compared to 8.2-RC1)](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.2-release-notes/) |

## Security fixes that change behaviour (pin to a patched patch version)

Each line names the earliest fetched patch release with the fix. Upgrade your line to at least these.

| Advisory / item | Affected lines | Fixed in | Source |
|---|---|---|---|
| Lua use-after-free and RCE family (CVE-2025-49844, CVE-2025-46817/46818/46819) | 8.0, 8.2 | 8.0.4 / 8.2.2 (Oct 2025) | [8.0 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/), [8.2 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.2-release-notes/) |
| Lua use-after-free (CVE-2026-23631), RESTORE memory corruption (CVE-2026-25243, -25588, -25589), unblock UAF (CVE-2026-23479) | 8.2, 8.4, 8.6, 8.8 | 8.2.6 / 8.4.3 / 8.6.3 (May 2026) | [8.2 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.2-release-notes/), [8.4 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.4-release-notes/) |
| ACL key-permission bypass in `SORT`, `GEORADIUS(BYMEMBER)`, `XREAD`/`XREADGROUP` (#15478) | 8.2–8.10 | 8.2.9 / 8.4.6 / 8.6.6 / 8.8.2 (Aug 2026); 8.10.0 GA includes the fix (listed in 8.10-RC1 bug fixes) | [8.2 notes, 8.2.9](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.2-release-notes/), [8.6 notes, 8.6.6](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/), [8.10 notes, RC1](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/) |
| `MSETEX` ACL key-pattern bypass (#14659) | 8.4, 8.6 | 8.4.4 (Jun 2026 bug fix list) / 8.6.0 RC1 | [8.4 notes, 8.4.4](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.4-release-notes/) |
| CMSketch RDB heap OOB write (CVE-2026-62356) | 8.2, 8.4, 8.6, 8.8, 8.10 | 8.2.9 / 8.4.6 / 8.6.6 / 8.8.2 / 8.10.1 | [8.10 notes, 8.10.1](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/) |
| Crafted `RESTORE` stream consumer-group UAF (RCE) | 8.2.8, 8.4.5, 8.6.5 | 8.2.8 / 8.4.5 / 8.6.5 (Jul 2026) | [8.2 notes, 8.2.8](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.2-release-notes/) |
| Malicious RDB `SLOT_INFO` slot id memory corruption (possible RCE) | 8.2.9+, 8.4.6+, 8.6.6+, 8.8.2+, 8.10.1+ | Listed as fixed in the Aug 2026 patch set | [8.10 notes, 8.10.1](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/) |

Stay on the latest patch of your minor line; every 2026 patch in the notes above was a SECURITY or HIGH release.

## Removals and renames (already in effect)

| Change | Since | Source |
|---|---|---|
| GCRA rate limiter removed ("Remove GCRA rate limiter") | 8.8-RC1 (before 8.8 GA) | [8.8 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/) |
| Redis Stack standalone modules superseded by Redis 8 built-ins | 8.0.0 | [8.0 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/) |

## Known open limitations at GA (do not build on them)

- 8.4.0: `FT.SEARCH`, `FT.AGGREGATE`, `TS.MGET`, `TS.MRANGE` and similar may return partial or duplicate results during atomic slot migration ([8.4 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.4-release-notes/)).
- 8.6.0: `XADD` `IDMP` with AOF limitation (item 14 above).
- 8.6.0: Redis Search cursors may miss results during slot rebalancing ([8.6 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/)).

## Dragonfly-relevant items

Items 9 (GCRA/INCREX), 13 (IDMP, LRM eviction) and 17 (FT.*) are Redis-only: do not use them in code that must also run on Dragonfly. Dragonfly-side differences are in [../dragonfly/breaking-changes.md](../dragonfly/breaking-changes.md).
