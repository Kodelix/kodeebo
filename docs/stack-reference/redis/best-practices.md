# Redis Open Source 8.x — Best Practices for Our Products

Last verified: 2026-10-11. Target: Redis Open Source 8.2 (Extended, per [VERSION.md](VERSION.md)) with patch releases. Our code must also run on Dragonfly, so every rule below is checked against the portability section at the end.

Uses: cache, rate limiting, sessions, idempotency keys. Deployed with Docker Compose and self-hosted by customers.

Conventions: each rule ends with its source. "Design guidance" marks our recommendations that no Redis page states as fact.

## 1. Key design and TTL

- Every cache key gets a TTL. Use `SET key value EX seconds` or `PX milliseconds`. Use `KEEPTTL` only when the TTL must survive an update ([SET](https://redis.io/docs/latest/commands/set/)).
- Add jitter to TTLs. Example from Redis: for a one-hour target, use a random TTL between 55 and 65 minutes so keys do not expire together ([Redis blog, 2026-05-13](https://redis.io/blog/how-to-tame-the-thundering-herd-problem/)).
- Co-locate keys that a multi-key command or script touches with hash tags: `{user1000}.following` and `{user1000}.followers` hash to the same slot because only the text between the first `{` and `}` is hashed ([cluster spec, hash tags](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/)).
- Key-name prefixes per product and purpose (for example `cache:{entity}:{id}`) are the pattern Redis documents for cache-aside ([cache-aside](https://redis.io/docs/latest/develop/use-cases/cache-aside/)). The separator convention itself is design guidance.
- Keep small aggregates small. Hashes, sorted sets and sets stay in compact encodings below the thresholds: `hash-max-listpack-entries 512` and `hash-max-listpack-value 64` by default; `set-max-listpack-entries 128` and `set-max-listpack-value 64` (7.2+) ([memory optimization](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/memory-optimization/)).
- Setting an expire costs memory. An eviction policy that does not need TTLs (for example `allkeys-lru`) is more memory-efficient ([eviction](https://redis.io/docs/latest/develop/reference/eviction/)).

## 2. Eviction policy

- Default: `maxmemory-policy noeviction` and `maxmemory` unset (unlimited on 64-bit) in the 8.10 `redis.conf` and the eviction docs ([redis.conf 8.10](https://raw.githubusercontent.com/redis/redis/8.10/redis.conf), [eviction](https://redis.io/docs/latest/develop/reference/eviction/)).
- Cache-only instances: `maxmemory <size>` and `maxmemory-policy allkeys-lru`. Redis documents this as "acts in a similar way to memcached" ([configuration](https://redis.io/docs/latest/operate/oss_and_stack/management/config/)).
- Choose by access pattern (Redis rule of thumb):
  - `allkeys-lru`: general cache, a hot subset (good default).
  - `allkeys-lrm` (8.6+): keep frequently read data, evict data not recently written.
  - `allkeys-random`: all keys read at similar rates.
  - `volatile-ttl`: you can predict good eviction candidates and give them short TTLs.
  - `volatile-*`: behave like `noeviction` when no key has a TTL ([eviction](https://redis.io/docs/latest/develop/reference/eviction/)).
- Do not mix cache and durable data (sessions, idempotency records) in one instance with a `volatile-*` policy. Redis suggests two instances when this is needed ([eviction](https://redis.io/docs/latest/develop/reference/eviction/)).
- LRU is approximate. `maxmemory-samples` defaults to 5; raise it to 10 for closer LRU at more CPU ([redis.conf 8.10](https://raw.githubusercontent.com/redis/redis/8.10/redis.conf), [eviction](https://redis.io/docs/latest/develop/reference/eviction/)).
- Check it at runtime: `keyspace_hits / (keyspace_hits + keyspace_misses)`, `evicted_keys`, `expired_keys`, `current_eviction_exceeded_time` (`INFO stats`/`memory`) ([eviction](https://redis.io/docs/latest/develop/reference/eviction/)).

## 3. Memory sizing

- Provision for peak, not average. Freed memory is not always returned to the OS, so RSS can stay high after keys are deleted ([memory optimization](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/memory-optimization/)).
- Do not trust `mem_fragmentation_ratio` after a large peak: RSS reflects the peak, so the ratio is inflated when the current use is low ([memory optimization](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/memory-optimization/)).
- With replication or persistence on, set `maxmemory` a little below the RAM you can afford. Buffers for replication and AOF are not counted toward `maxmemory`; `INFO memory` reports them as `mem_not_counted_for_evict` ([eviction](https://redis.io/docs/latest/develop/reference/eviction/)).
- Set `maxmemory` below the container memory limit in Compose. Without a limit Redis keeps allocating until the host is starved (design guidance; the memory page says a limit is generally advisable ([memory optimization](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/memory-optimization/))).
- `lazyfree-lazy-eviction`, `lazyfree-lazy-expire`, `lazyfree-lazy-user-del` default to `no` in 8.10 `redis.conf`. Test with large values before changing ([redis.conf 8.10](https://raw.githubusercontent.com/redis/redis/8.10/redis.conf)).
- Compact hashes (8.10+) store field names once for keys sharing a schema. Whether they are on by default was not verified in this pass. Measure with `MEMORY USAGE` and `INFO STATS` `hash_templates` before relying on them ([8.10 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/)). Redis-only.

## 4. Stampede protection

- Pattern set from Redis docs and the 2026 Redis blog:
  - TTL jitter (section 1).
  - Request coalescing: one caller takes a lock and loads, the rest wait and read the cache ([thundering-herd blog](https://redis.io/blog/how-to-tame-the-thundering-herd-problem/)).
  - Mutex lock or probabilistic early refresh, run inside Lua so they are atomic ([cache-aside](https://redis.io/docs/latest/develop/use-cases/cache-aside/)).
  - Event-driven refresh with Pub/Sub or Streams when the source changes ([thundering-herd blog](https://redis.io/blog/how-to-tame-the-thundering-herd-problem/)).
- Lock acquire: `SET lock:<name> <token> NX PX <ms>` ([SET patterns](https://redis.io/docs/latest/commands/set/)).
- Lock release only if the token matches. Use a Lua script that compares the token, or `DELEX ... IFEQ` on Redis 8.4+ (Redis-only; see portability). Plain `DEL` can remove another client's lock ([distributed locks](https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/)).
- Single instance locks are not safe under failover. Redis says the replica race can give two holders. Use fencing tokens for work that can exceed the lock TTL. Redis does not use a monotonic clock for TTL, so wall-clock changes can affect locks ([distributed locks](https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/)).
- Rate limiting does not solve a stampede by itself (thundering-herd blog).
- Cache-aside on writes: update the primary, then invalidate the key ([cache-aside](https://redis.io/docs/latest/develop/use-cases/cache-aside/)).

## 5. Atomic rate limiting

- Naive `INCR` then `EXPIRE` in two calls leaks the key if the second call never runs. Redis documents `MULTI` with `INCR` and `EXPIRE` for the simple window counter, or a Lua script ([INCR](https://redis.io/docs/latest/commands/incr/)).
- Preferred for portability: one Lua script with one declared key:

  ```lua
  local current = redis.call('INCR', KEYS[1])
  if current == 1 then redis.call('EXPIRE', KEYS[1], ARGV[1]) end
  return current
  ```

  Call with `EVAL script 1 <key> <window_seconds>`. Keys must be in `KEYS`. Redis's cluster and scripting rules are in section 10 ([INCR](https://redis.io/docs/latest/commands/incr/), [Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)).
- Key includes the window: `rl:{<tenant>}:<route>:<unix_window>` (design guidance).
- Redis 8.8 added `INCREX`, a window counter with bounds and expiry. It is Redis-only: do not use it in shared code ([8.8 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/)).
- The GCRA limiter was removed before 8.8 GA ([8.8 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/)).

## 6. Idempotency keys and sessions

- Idempotency: `SET idem:<scope>:<key> <status> NX PX <ttl_ms>`. If it returns OK, run the operation. Store the result under the same key, or a sibling key, before returning. Use the same TTL for both. (Pattern from the SET locking section; design guidance for the store-result step.)
- Redis 8.6 `XADD ... IDMP` gives at-most-once stream writes. Redis-only ([8.6 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/)).
- Sessions: random token. The distributed-locks page uses 20 bytes from `/dev/urandom` for lock values; we reuse that size for session tokens ([distributed locks](https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/)). `SET session:<token> <payload> EX <ttl>`; refresh with `EXPIRE` on activity (design guidance).
- Sessions and idempotency records are durable state: put them in an instance with `noeviction` and persistence, not in the cache instance (section 2).

## 7. Security

### ACL and default user
- A fresh instance has `user default on nopass ~* &* +@all`. Every connection is authenticated as default and can run every command ([ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)).
- `requirepass` still works and sets the default user's password ([ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)). Prefer named users.
- New users are created with no permissions ([ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)).
- One user per service, minimum permissions. Example:

  ```
  ACL SETUSER app on >PASSWORD_FROM_ACL_GENPASS ~cache:* %R~ro:* +@read +@write -@dangerous -@admin
  ```

  Rule syntax: `+@category`, `-@category`, `~pattern`, `%R~`/`%W~` for read or write only ([ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)). Generate the password with `ACL GENPASS`, which the ACL page documents as a 256-bit string (design guidance for the placeholder).
- Dangerous commands: `-@dangerous` removes FLUSHALL, MIGRATE, RESTORE, SORT, KEYS, CLIENT, DEBUG, INFO, CONFIG, SAVE and REPLICAOF ([ACL categories](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)). **Trap:** it also removes `INFO` and `CLIENT`, which metrics scrapers need. Give the monitoring user `+info` and `+client|list` explicitly (design guidance on the fix; the category list is from the ACL page).
- Key-scoped users still can run `FLUSHALL`/`FLUSHDB`/`SWAPDB` unless removed. Add `-flushall -flushdb -swapdb` explicitly ([ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)).
- `rename-command` is deprecated: "may be removed in future versions" ([security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)). Use ACL instead.
- Store ACL users in an external file, `aclfile`, loaded with `ACL LOAD` and written with `ACL SAVE`. Inline users and `aclfile` cannot be combined ([ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)).
- Since 8.8, `ACL LOAD` accepts `#` comment lines; comments are not kept on `ACL SAVE` ([ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/)).
- `CONFIG` can change the dump file path and working directory, so it lets a client write files. Remove `CONFIG` for every non-admin user ([security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)).

### Network, protected mode, TLS
- Redis is meant for trusted clients in a trusted network. Do not expose the port to the internet ([security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)).
- `bind 127.0.0.1 -::1` and `protected-mode yes` are the 8.10 defaults. Protected mode applies when Redis binds all interfaces without a password: it then answers only loopback clients and returns an error to others ([redis.conf 8.10](https://raw.githubusercontent.com/redis/redis/8.10/redis.conf), [security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)).
- In Compose, do not publish 6379. Use an internal network and set an ACL password.
- TLS: build with `make BUILD_TLS=yes`, which needs OpenSSL dev libraries. Set `tls-port`, `tls-cert-file`, `tls-key-file`, `tls-ca-cert-file`, and `port 0` to disable plaintext. `tls-replication yes` and `tls-cluster yes` for replication and the cluster bus ([TLS](https://redis.io/docs/latest/operate/oss_and_stack/management/security/encryption/)).
- The TLS page says mutual TLS is the default; `tls-auth-clients no` turns it off ([TLS](https://redis.io/docs/latest/operate/oss_and_stack/management/security/encryption/)). Check this against the `redis.conf` of your exact version: our reading of the 8.10 default-line check was inconclusive.
- TLS client certificates can map to an ACL user via `tls-auth-clients-user` (8.6+) ([8.6 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/)).
- TLS adds CPU cost, lowering per-instance throughput ([TLS](https://redis.io/docs/latest/operate/oss_and_stack/management/security/encryption/)).

### Patch level
- Every 2026 patch in the 8.x line was a security or high-urgency release. Track the latest patch of the pinned minor. The list of fixes is in [breaking-changes.md](breaking-changes.md).
- Do not build Lua scripts from untrusted strings ([security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)).
- Run as an unprivileged user ([security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)).

## 8. Observability

### INFO
- Watch `INFO stats` for `keyspace_hits`, `keyspace_misses`, `evicted_keys`, `expired_keys`; `INFO memory` for `used_memory`, `used_memory_dataset`, `mem_not_counted_for_evict` ([eviction](https://redis.io/docs/latest/develop/reference/eviction/)).
- `commandstats` shows `rejected` calls: use it to find commands blocked by `maxmemory` under `noeviction` or `volatile-*` ([eviction](https://redis.io/docs/latest/develop/reference/eviction/)).

### Slow log
- `slowlog-log-slower-than 10000` and `slowlog-max-len 128` in 8.10 `redis.conf` (the unit of the threshold was not captured in this pass) ([redis.conf 8.10](https://raw.githubusercontent.com/redis/redis/8.10/redis.conf)). Commands over the threshold go to `SLOWLOG GET` ([SLOWLOG](https://redis.io/docs/latest/commands/slowlog/)).
- 8.8+: `slowlog-entry-max-argc` and `slowlog-entry-max-string-len` truncate logged arguments. Set them so secrets in arguments are not logged in full ([8.8 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/)).
- 8.10 added a total-argument-count field to `SLOWLOG GET` replies. Parsers must not assume a fixed count ([8.10 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/)).

### Latency monitor
- Off by default (`latency-monitor-threshold 0`). Enable with `CONFIG SET latency-monitor-threshold <ms>` ([latency monitoring](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/latency-monitor/)).
- Commands: `LATENCY LATEST`, `LATENCY HISTORY <event>`, `LATENCY RESET`, `LATENCY GRAPH <event>`, `LATENCY DOCTOR` ([latency monitoring](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/latency-monitor/)).
- Events include `command`, `fast-command`, `fork`, `aof-write`, `expire-cycle`, `eviction-cycle` ([latency monitoring](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/latency-monitor/)).
- 8.6+: `HOTKEYS` reports hot keys (Redis-only) ([8.6 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/)).
- Alerts (design guidance): hit ratio, evictions per minute, `rejected_calls`, p99 of `fast-command`, memory versus `maxmemory`, replication lag, connection count.

## 9. Backups and durability

- Copy RDB files while the server runs: Redis writes a temporary file and renames it atomically when it is complete ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)).
- Retention (Redis suggestion): hourly snapshots for 48 hours, daily snapshots for one to two months, and one copy per day off the host. Verify the transferred file's size and SHA1 ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)).
- Persistence choice:
  - `appendonly no` by default. `appendfsync everysec` is the default when AOF is on; `aof-use-rdb-preamble yes` by default ([redis.conf 8.10](https://raw.githubusercontent.com/redis/redis/8.10/redis.conf)).
  - RDB alone: point-in-time snapshots; the latest minutes of writes can be lost ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)).
  - RDB + AOF: Redis recommends both if you need stronger safety than RDB alone ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)).
  - AOF alone: Redis discourages it; keep periodic RDB snapshots ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)).
- Cache instances: persistence can be disabled (no save points, `appendonly no`). Redis lists "no persistence" as an option and says it is sometimes used for caching ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)). Durable-state instances (sessions, idempotency) need RDB and/or AOF.
- 8.10 `BACKUP` family: `BACKUP START`, `BACKUP LIST`, `BACKUP SEAL`, `BACKUP CLEANUP`, `BACKUP STATUS`, `BACKUP ABORT`. Output goes to `backupdirname` (default `backupdir`) under `dir`. `backup-sealed-ttl` 0 (default) keeps sealed backups until `BACKUP CLEANUP`. Restore: `preload-file aof:<manifest>` at startup ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/), [8.10 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/)). Redis-only.
- AOF backups before 7.0: copy the file. From 7.0 copy the `appenddirname` directory; disable rewrites during the copy (`CONFIG SET auto-aof-rewrite-percentage 0`) and re-enable afterwards ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)).
- Before enabling AOF on a live server with RDB, enable it with `CONFIG SET`, not by restarting with a new file: restarting first can lose data ([persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/)).

## 10. Writing code portable across Redis and Dragonfly

Sources for the Dragonfly side are in [../dragonfly/best-practices.md](../dragonfly/best-practices.md) and the Dragonfly docs cited there.

### Lua scripts: declared keys and flags
- Redis: the script must access only keys named in `KEYS`, for standalone and cluster correctness. Scripts must not build key names at runtime ([Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)).
- Dragonfly: scripts that access undeclared keys fail with "script tried accessing undeclared key" by default. Dragonfly's docs say the opt-out, `allow-undeclared-keys`, makes Dragonfly "stop all other operations" while the script runs, so do not use it in normal code ([Dragonfly scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)).
- **Rule:** every script declares every key in `KEYS`. Keys in `ARGV`, never built from data inside Redis. This is safe on both.
- Redis shebang flags (`#!lua flags=...` or the EVAL equivalent) change behaviour: `no-writes`, `allow-oom`, `allow-stale`, `no-cluster`, `allow-cross-slot-keys`. Default for EVAL: the script may read and write, runs in cluster mode, is denied on stale replicas and under OOM ([Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)). Dragonfly uses its own `--!df flags=` header and supports `allow-undeclared-keys`, `disable-atomicity`, `legacy-float` ([Dragonfly flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags), [Dragonfly scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)). **Do not put Redis-specific flags in shared scripts.** Keep flags out of portable scripts; test flag handling on both.
- Lua version: Redis embeds Lua 5.1 ([Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)); Dragonfly uses Lua 5.4 ([Dragonfly scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)). Standard-library differences were NOT enumerated in this pass: run the script test suite on both.
- Globals: Redis's sandbox blocks global variable declarations; declare everything `local` ([Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)). Dragonfly's handling of this rule was NOT verified in this pass.

### Functions
- Redis 7+ also has Redis Functions (`FUNCTION LOAD`, `FCALL`). Dragonfly: the maintainer said in May 2024 that it "doesn't support Redis functions at all, only EVAL scripts" ([discussion #2981](https://github.com/dragonflydb/dragonfly/discussions/2981)). **Use EVAL only.**

### Cluster mode
- Redis Cluster: multi-key commands must hash to one slot (hash tags) ([cluster spec](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/), [Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)).
- Dragonfly: default `--cluster_mode=emulated` is one node that speaks the Redis Cluster protocol, so cluster clients connect without change. Native multi-shard needs `--cluster_mode=yes`, an admin port, and a manually supplied topology ([Dragonfly cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)).
- **Rule:** our code uses hash tags everywhere it needs multi-key atomicity, and does not depend on emulated cluster behaviour for failover. Dragonfly docs say it provides only a data plane: health monitoring, failover and slot migration are not built in ([Dragonfly cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)).

### Unsupported or different commands
- Dragonfly: `COMMAND DOCS` returns an error ([Dragonfly COMMAND](https://www.dragonflydb.io/docs/command-reference/server-management/command)).
- Redis 8.x commands we must not use in shared code: `DELEX`, `DIGEST`, `MSETEX`, `INCREX`, `HOTKEYS`, `BACKUP*`, `XADD ... IDMP/IDMPAUTO`, `FT.*`, `TS.*`, `JSON.*`. Dragonfly's support for each was NOT verified in this pass, so treat them as Redis-only. Sources: the 8.x release notes linked in [deprecated-apis.md](deprecated-apis.md). `CL.THROTTLE` appears in the Dragonfly 2.0.0 notes, so it is not Redis-only, but its arguments were not compared.
- Dragonfly v2.0.0 changed behaviour for `SORT ... STORE`, `EXPIRE` multi-flag, `SET` with past expiry, blocking commands in RESP3, and empty pop results. Our code must not depend on the old behaviour: see [../dragonfly/breaking-changes.md](../dragonfly/breaking-changes.md).
- Deprecated Redis commands to avoid in new code: `GETSET`, `RPOPLPUSH`, `BRPOPLPUSH`, `HMSET`, `ZRANGEBYSCORE`, `GEORADIUS`, `GEORADIUSBYMEMBER`, `SLAVEOF` ([deprecated-apis.md](deprecated-apis.md)). Replacements are in the same file.

### Modules
- Redis 8.0 bundles RediSearch, RedisJSON, RedisTimeSeries and RedisBloom functionality into the core ([8.0 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/)).
- Dragonfly's docs do not list these modules. Its release notes mention an `FT.CREATE` (v2.0.0) and Cuckoo filter `CF.*` commands from v1.40.0 ([v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0), [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0)). Argument-level parity was not verified.
- **Rule:** no module commands in shared code. If a feature needs search or JSON, it is Redis-only and must sit behind a flag that Dragonfly builds do not enable.

### Test rule
- Run the same integration suite against Redis 8.2 and Dragonfly (the version in VERSION.md) in CI. Check `COMMAND INFO <name>` for each command at startup (design guidance).

## Sources index (Redis)

- Commands: [SET](https://redis.io/docs/latest/commands/set/), [INCR](https://redis.io/docs/latest/commands/incr/), [SLOWLOG](https://redis.io/docs/latest/commands/slowlog/)
- Develop: [eviction](https://redis.io/docs/latest/develop/reference/eviction/), [cache-aside](https://redis.io/docs/latest/develop/use-cases/cache-aside/), [distributed locks](https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/), [Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)
- Operate: [config](https://redis.io/docs/latest/operate/oss_and_stack/management/config/), [memory optimization](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/memory-optimization/), [latency monitoring](https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/latency-monitor/), [ACL](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/), [security](https://redis.io/docs/latest/operate/oss_and_stack/management/security/), [TLS](https://redis.io/docs/latest/operate/oss_and_stack/management/security/encryption/), [persistence](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/), [cluster spec](https://redis.io/docs/latest/operate/oss_and_stack/reference/cluster-spec/)
- Defaults: [redis.conf 8.10](https://raw.githubusercontent.com/redis/redis/8.10/redis.conf)
- Blog: [How to tame the thundering herd problem](https://redis.io/blog/how-to-tame-the-thundering-herd-problem/) (2026-05-13)
