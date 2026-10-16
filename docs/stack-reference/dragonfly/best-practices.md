# Dragonfly — Best Practices for Our Products

Last verified: 2026-10-11. Target: Dragonfly v2.0.2 for our own deployments (see [VERSION.md](VERSION.md)); we run v1.40.0 locally today. Dragonfly speaks the Redis protocol. Our code targets the Redis subset that runs on both (see the portability section).

Uses: cache, rate limiting, sessions, idempotency keys. Deployed with Docker Compose and self-hosted by customers.

Conventions: each rule ends with its source. "Design guidance" marks our recommendations, which no Dragonfly page states as fact. Dragonfly has no official "best practices" page in the docs we could reach; the docs sidebar lists none. Several rules therefore cite the Redis docs for the pattern (where Dragonfly documents the same command or flag) and mark the Dragonfly-specific part.

## 1. Key design and TTL

- Use the same key design as Redis (see [../redis/best-practices.md](../redis/best-practices.md) section 1). Dragonfly's cluster page says key distribution and hash tags "follow the Valkey Cluster spec" ([cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)). We did not fetch that spec, so verify `{tag}` co-location on Dragonfly with a test.
- TTL jitter: design guidance; the pattern is from the Redis blog ([thundering herd](https://redis.io/blog/how-to-tame-the-thundering-herd-problem/)).
- `SET` with past expiry: since v2.0.0, `SET` with a past expiration honours `NX`/`XX`/`GET` and journals the delete ([v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0)). Do not use past-time expiry as a delete mechanism.
- `EXPIRE` with several flags: all specified flags must hold in v2.0.0 ([v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0)). Use one flag per call.

## 2. Eviction

Dragonfly has no `maxmemory-policy`. Eviction is controlled by these flags (defaults from the flags page):

| Flag | Default | Meaning ([flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags)) |
|---|---|---|
| `--maxmemory` | `0B` | Memory limit; `0` lets Dragonfly choose automatically. Set it explicitly. |
| `--cache_mode` | `false` | Evicts entries as memory nears `maxmemory`. |
| `--enable_heartbeat_eviction` | `true` | Evicts keys during heartbeat under memory pressure. |
| `--max_eviction_per_heartbeat` | `100` | Max key-value pairs deleted per heartbeat. |
| `--max_segment_to_consider` | `4` | Max dashtable segments scanned per heartbeat. |
| `--enable_heartbeat_rss_eviction` | `true` | Also evicts when RSS is under pressure. |
| `--eviction_memory_budget_threshold` | `0.1` | Eviction starts when free memory is below this fraction of the limit. |
| `--rss_oom_deny_ratio` | `1.25` | Above this maxmemory-to-RSS ratio, DENYOOM commands fail; negative disables. |

- Set `--maxmemory` explicitly (design guidance; default is automatic).
- Cache-only instances: `--cache_mode=true`. Which keys are chosen for eviction, and whether TTL matters, is **NOT SOURCEABLE** in this pass. Test with keys with and without TTLs before relying on it.
- Redis's `allkeys-lru`/`volatile-*` semantics do not carry over: Dragonfly documents no policy flag. Keep durable data (sessions, idempotency) on an instance without `cache_mode`, or check the behaviour first (design guidance).

## 3. Memory sizing

- Snapshots are forkless: Dragonfly's design doc describes a "point in time, forkless snapshotting procedure" using per-entry version counters and a write hook ([snapshotting](https://www.dragonflydb.io/docs/managing-dragonfly/snapshotting)). The doc gives no memory-overhead figure; measure it.
- Monitor `INFO memory` fields: `used_memory_peak_rss` now reports peak resident memory (v2.0.0). `table_used_memory`, `object_used_memory`, `comitted_memory`, `pipeline_cache_bytes` are listed as Dragonfly fields ([INFO](https://www.dragonflydb.io/docs/command-reference/server-management/info), [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0)).
- Field names vary by version: the INFO page says clients "should skip unknown fields and handle missing ones". Our metric parsers must do the same ([INFO](https://www.dragonflydb.io/docs/command-reference/server-management/info)).
- Set the container memory limit above `--maxmemory` plus headroom for RSS and replication (design guidance; the RSS-based deny ratio in section 2 is the Dragonfly mechanism).
- Tiered storage (v1.40.x): `tiered_max_pending_bytes` caps pending reads and writes (v1.40.2). Only if enabled ([v1.40.2](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.2)).

## 4. Stampede protection

- Same pattern as Redis: TTL jitter, single-flight lock with `SET key token NX PX ms`, token-checked release in a script, and event-driven refresh ([Redis cache-aside](https://redis.io/docs/latest/develop/use-cases/cache-aside/), [Redis blog](https://redis.io/blog/how-to-tame-the-thundering-herd-problem/)).
- Scripts used for lock release must follow the declared-keys rule (section 10). No undeclared-key flag.
- The v2.0.0 notes reference `SET` with `NX`, `XX` and `GET` ([v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0)). `PX` and full option parity were NOT verified in this pass.

## 5. Atomic rate limiting

- Use one Lua script that declares its single key, same script as the Redis side (see [../redis/best-practices.md](../redis/best-practices.md) section 5). Dragonfly rejects undeclared keys by default ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)), so this form works without flags.
- Do not rely on `MULTI`/`EXEC` for atomicity across keys without testing: transaction support was NOT verified in this pass. Single-key Lua is the portable path.
- Do not use the undeclared-key flag to make scripts easier to write: the docs say it makes Dragonfly "stop all other operations" during the script ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)).

## 6. Idempotency keys and sessions

- Same design as Redis (see [../redis/best-practices.md](../redis/best-practices.md) section 6). `SET ... NX PX` is the core command.
- Durable state (sessions, idempotency records) needs snapshots with a schedule: see section 9.

## 7. Security

### ACL
- Default user starts "ON, accepts any password, and can run all commands". Replace the default user or set a password before exposing the port ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)).
- `--requirepass` sets the password at startup. The flags page says the same value can come from the `DFLY_PASSWORD` environment variable ([flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags)). The ACL page says `--requirepass` sets the `default` user's password.
- New users other than `default` start OFF ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)).
- Syntax: `ACL SETUSER <name> ON >password +@GROUP -CMD ~pattern %R~pattern %W~pattern &channel`. Groups: `+@GROUP` / `-@GROUP`, `+@ALL`, `+ALL`. Keys: `~pattern`, `allkeys`, `resetkeys`. Read/write keys: `%R~`, `%W~` ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)).
- Persist with `--aclfile <path>`; `ACL SAVE` writes it. Put the file outside `/etc` (read-only for the service): `/var/lib/dragonfly/` is the docs' example ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)).
- Log size: `--acllog_max_len` sets the entry count per thread; total = value × threads ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)). Default not captured in this pass.
- Password changes do not disconnect authenticated clients; `ACL DELUSER` does. Permission changes apply to active connections ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)).
- P-commands (for example `PSUBSCRIBE`) need a literal channel match ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)).
- Removing dangerous commands: the `--rename_command` flag was retired in v1.40.0; use ACL: `-@ADMIN` or `-FLUSHALL -FLUSHDB` ([v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0)). Note the example in the ACL docs uses `+@ADMIN +SET` (group names upper case in Dragonfly's docs).
- v2.0.2: ACL checks source keys for read and destination keys for write on commands like `COPY` and `LMOVE`. Re-test ACL users after upgrade ([v2.0.2](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.2)).
- Caveat from the ACL page: JWT validation sends passwords or tokens in cleartext to the validation endpoint. Run it on the same host or a trusted private network ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)).

### Network, admin port, TLS
- `--bind` default is empty, which binds all interfaces; the flags page says this "is not advised" ([flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags)). Set `--bind` in Compose.
- `--admin_port` enables the admin console on HTTP and RESP. `--admin_nopass` defaults to `false` and allows open admin access when set to `true`. `--no_tls_on_admin_port` defaults to `false` ([flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags)). Do not publish the admin port.
- TLS flags: `--tls`, `--tls_cert_file`, `--tls_key_file`, `--tls_ca_cert_file`, `--tls_ca_cert_dir` (run `c_rehash` first), `--tls_ciphers` (TLS 1.2, default `DEFAULT:!MEDIUM`), `--tls_cipher_suites` (TLS 1.3), `--tls_session_caching`, `--tls_replication` ([flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags)).
- TLS for replication: the replication page says "we only support `.pem` files" ([replication](https://www.dragonflydb.io/docs/managing-dragonfly/replication)).
- Protected mode: not documented in the flags or ACL pages: **NOT SOURCEABLE** for Dragonfly. Treat as absent: bind and password explicitly.
- Dragonfly warns: "fields vary by version" for INFO (section 3). For security settings, check the release notes before each upgrade.

## 8. Observability

- `INFO` sections: `server`, `clients`, `memory`, `persistence`, `stats`, `replication`, `cpu`, `commandstats`, `latencystats`, `keyspace`, `errorstats`. `INFO all` returns every section except module-generated ones. Default output has `memory` and `latencystats`, not `commandstats` ([INFO](https://www.dragonflydb.io/docs/command-reference/server-management/info)).
- `INFO commandstats`: per command `cmdstat_<name>` with calls, CPU time, average CPU per call, rejected and failed calls ([INFO](https://www.dragonflydb.io/docs/command-reference/server-management/info)).
- Server fields: `dragonfly_version`, `multiplexing_api` (e.g. `iouring`), TLS certificate subject, issuer and validity on TLS listeners, `redis_mode` (`standalone`, `sentinel`, `cluster`) ([INFO](https://www.dragonflydb.io/docs/command-reference/server-management/info)).
- Slow log: `SLOWLOG GET|LEN|RESET|HELP` supported ([SLOWLOG](https://www.dragonflydb.io/docs/command-reference/server-management/slowlog)). The default threshold and max length: **NOT FOUND** in the docs we reached. The LATENCY command: **NOT FOUND**.
- v2.0.0: `SLOWLOG GET` returns 10 entries by default ([v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0)). Pass a count.
- v2.0.0: `expired_keys_total` and `evicted_keys_total` are always exported, even at zero ([v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0)).
- Alerts (design guidance): hit ratio, evictions, rejected commands, memory versus `--maxmemory`, replication lag, connection count.

## 9. Backups

- Snapshot location: `dir` (local path or `s3://<bucket>[/<prefix>]`). `dbfilename` defaults to `dump-{timestamp}`. `df_snapshot_format` defaults to `true` (writes Dragonfly `.dfs` format) ([backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups)).
- Schedule: `--snapshot_cron "*/5 * * * *"` (Dragonfly 1.7.1+). `save_schedule` is deprecated ([backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups)).
- Manual: `SAVE` and `BGSAVE` ([backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups)).
- Shutdown: automatic snapshot on shutdown when `dbfilename` is non-empty ([backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups)).
- Restore: on startup Dragonfly loads the snapshot found in `dir`; an empty `dbfilename` disables loading. For S3 it loads the latest snapshot under the prefix. Loading a named file from a local directory is not described ([backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups)).
- Retention: the backups page says snapshots accumulate and are not removed automatically. We need a retention script. The vendor blog advises periodic pruning ([Dragonfly blog](https://www.dragonflydb.io/blog/best-practices-for-managing-in-memory-data-stores)); we saw that advice only in a search summary, not in a full fetch.
- S3 is a preview feature. Flags: `s3_endpoint`, `s3_ec2_metadata` (off), `s3_sign_payload` (on), `s3_use_https` (on). Credentials from standard AWS variables ([backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups)).
- Redis compatibility of the file: the snapshot design doc says the RDB file "follows the Redis format spec" ([snapshotting](https://www.dragonflydb.io/docs/managing-dragonfly/snapshotting)). The default output is `.dfs`. If we need a file readable by Redis, set `df_snapshot_format=false` (inference from the flag description; not tested here). Cross-restore is NOT SOURCEABLE in this pass.
- Snapshot file format compatibility: Dragonfly v2.0.0 accepts RDB files with the `VALKEY080` header ([backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups)).

## 10. Writing code portable across Redis and Dragonfly

The Redis-side rules are in [../redis/best-practices.md](../redis/best-practices.md) section 10. The Dragonfly-side facts and sources:

### Lua scripts: undeclared keys and flags
- **Dragonfly default:** a script that accesses undeclared keys fails with "script tried accessing undeclared key" ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)).
- **Opt-out:** `allow-undeclared-keys`. Enable per script with the header `--!df flags=allow-undeclared-keys`, per server with `--default_lua_flags=allow-undeclared-keys`, or per SHA with `SCRIPT FLAGS <sha1> allow-undeclared-keys` ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting), [flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags)).
- **Cost:** with undeclared-key access, "Dragonfly has to stop all other operations when the script is running" ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)).
- **Rule:** declare every key in `KEYS`. Never enable `allow-undeclared-keys` in shared code. Redis enforces the same discipline for cluster ([Redis Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)).
- **Flags set:** Dragonfly lists `allow-undeclared-keys`, `disable-atomicity`, `legacy-float` for `--default_lua_flags` ([flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags)). Redis's flags (`no-writes`, `allow-oom`, `allow-stale`, `no-cluster`, `allow-cross-slot-keys`) are not in that list. Do not use Redis-only flags in shared scripts.
- **Lua version:** Dragonfly uses Lua 5.4 ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)). Redis uses 5.1 ([Redis Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)). Test every script on both. Standard-library differences were NOT enumerated in this pass.
- The Dragonfly scripting page also lists sandbox limits: `load()` accepts text mode only; `rawset`, `setmetatable` and `getmetatable` refuse to change the `_G` metatable; `dragonfly.randstr()` rejects oversized input ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)).

### Functions
- Dragonfly does not support Redis Functions. The maintainer said "doesn't support Redis functions at all, only EVAL scripts" (2024-05-01) ([discussion #2981](https://github.com/dragonflydb/dragonfly/discussions/2981)). Use `EVAL` only. Re-verify on each upgrade.

### Cluster mode
- Default `--cluster_mode=emulated`: a single node answers Redis Cluster protocol commands so cluster clients connect unchanged. It is "mainly for migrating from Redis Cluster" ([cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)).
- Native multi-shard: `--cluster_mode=yes`, `--admin_port`, `REPLICAOF`, `DFLYCLUSTER MYID`, `DFLYCLUSTER CONFIG <json>`. Only database 0 is supported. A node serves only the slots it owns; keys in other slots are deleted and rejected ([cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)).
- Dragonfly provides only a data plane: health monitoring, automatic failover and slot migration are not built in. Dragonfly Swarm in Dragonfly Cloud provides them ([cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)).
- The topology must be identical on all nodes and resent after restarts ([cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)).
- **Rule:** our default is emulated single-node Dragonfly. We do not rely on multi-shard Dragonfly for failover. Multi-key work uses hash tags.

### Unsupported or limited commands and features
- `COMMAND DOCS`: "Not implemented. The server returns an error." Supported: `COMMAND HELP`, `COMMAND COUNT`, `COMMAND INFO` ([COMMAND](https://www.dragonflydb.io/docs/command-reference/server-management/command)).
- Replication: the replication page says Redis-to-Dragonfly replication is supported, with a running Redis server as primary. It also says Dragonfly supports the Redis OSS data structures and replication protocol "up to version 6.2" ([replication](https://www.dragonflydb.io/docs/managing-dragonfly/replication)). Replicating from a Redis 8.x primary is therefore not documented as supported. Test it, or use snapshot-and-restore ([migrating](https://www.dragonflydb.io/docs/migrating-to-dragonfly)).
- Command count: the FAQ says "more than 200 Redis commands" ([FAQ](https://www.dragonflydb.io/docs/about/faq)). Command-by-command coverage: check `COMMAND INFO <name>` on the version we run; the command reference page was not reachable in full.
- Redis 8.x commands: presence in Dragonfly was NOT verified for `DELEX`, `DIGEST`, `MSETEX`, `INCREX`, `HOTKEYS`, `BACKUP*`, `XADD ... IDMP`, `FT.*`, `TS.*`, `JSON.*`. Treat as absent.

### Modules
- Dragonfly's docs do not list RediSearch, RedisJSON, RedisTimeSeries or RedisBloom as supported modules. Release notes mention `FT.CREATE` (v2.0.0), Cuckoo filters with `CF.*` and `BF.INFO` (v1.40.0) ([v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0), [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0)). Argument-level parity was not verified.
- **Rule:** no module commands in shared code.

### Config and flags that differ
- `--rename_command`, `--oom_deny_commands` are retired (v1.40.0). Use ACL.
- `--save_schedule` deprecated: use `--snapshot_cron`.
- `--shard_round_robin_prefix` deprecated ([flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags)).
- Redis `maxmemory-policy`, `slowlog-log-slower-than`, `latency-monitor-threshold`: no Dragonfly equivalent found in docs reached. Do not set them in shared config files; Dragonfly may reject or ignore them. Confirm on the running version.
- Full list: [deprecated-apis.md](deprecated-apis.md).

### Test rule
- Run the same integration suite against Redis 8.2 (see [../redis/VERSION.md](../redis/VERSION.md)) and Dragonfly v2.0.2 in CI. A failing Dragonfly job is a blocker for the shared code path (design guidance; the rule follows from the sections above).

## Sources index (Dragonfly)

- Docs: [flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags), [scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting), [cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode), [replication](https://www.dragonflydb.io/docs/managing-dragonfly/replication), [ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl), [snapshotting](https://www.dragonflydb.io/docs/managing-dragonfly/snapshotting), [backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups), [INFO](https://www.dragonflydb.io/docs/command-reference/server-management/info), [COMMAND](https://www.dragonflydb.io/docs/command-reference/server-management/command), [SLOWLOG](https://www.dragonflydb.io/docs/command-reference/server-management/slowlog), [FAQ](https://www.dragonflydb.io/docs/about/faq), [license](https://www.dragonflydb.io/docs/about/license), [migrating](https://www.dragonflydb.io/docs/migrating-to-dragonfly)
- Releases: https://github.com/dragonflydb/dragonfly/releases (v1.40.0, v1.40.2, v2.0.0, v2.0.2 pages)
- Discussion: https://github.com/dragonflydb/dragonfly/discussions/2981
- Blog (vendor): https://www.dragonflydb.io/blog/best-practices-for-managing-in-memory-data-stores
