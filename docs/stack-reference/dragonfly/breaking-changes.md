# Dragonfly — Breaking and Behaviour-Changing Changes

Last verified: 2026-10-11. Range covered: v1.40.0 (04 Aug) through v2.0.2 (07 Oct). We run v1.40.0 locally; anything below v1.40.0 is not covered. Version and licence facts: [VERSION.md](VERSION.md).

Sources: GitHub release pages, fetched 2026-10-11 (`https://github.com/dragonflydb/dragonfly/releases/tag/vX.Y.Z`). The release pages show day and month only; years are inferred (see VERSION.md). Release pages list PR numbers (`#NNNN`) which are kept below for lookup.

## Summary: what breaks code that talks to Dragonfly

| # | Version | Change | Impact on our code | Source |
|---|---|---|---|---|
| 1 | v1.40.0 | Retired `--rename_command` and `--oom_deny_commands` flags | Renaming or disabling commands via these flags is no longer supported. Any Compose/config using them must move to ACL rules (see deprecated-apis.md). | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0) |
| 2 | v1.40.0 | Retired the v1 replication path and `experimental_replicaof_v2`; retired `squash_stats_latency_lower_limit` | Configs setting these fail or are ignored. Remove them from Compose files. | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0) |
| 3 | v1.40.0 | Azure snapshot storage now accepts standard Azure Blob HTTPS URLs in place of the `az://` scheme | Use HTTPS form. Whether `az://` still works: **NOT SOURCEABLE** (release says "in place of", the notes do not state removal). | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0) |
| 4 | v1.40.0 | AWS support disabled by default in builds; tagged chunk serialization on by default; RDB loader skips keys with unsupported module types instead of aborting | Snapshot load behaviour changes. Test restores. | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0) |
| 5 | v1.40.0 | Full Cuckoo filter data type (`CF.RESERVE`, `CF.ADD/ADDNX`, `CF.EXISTS/MEXISTS`, `CF.INSERT/INSERTNX`, `CF.INFO/COUNT/DEL/COMPACT`) with RDB persistence; `BF.INFO`; `WAIT`, `RESET`, `HGETEX`, `HPEXPIRETIME` added | New commands. Redis 8.x has Cuckoo filters built in (8.0 notes), but argument-level parity between Dragonfly and Redis was NOT verified. Test before use. | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0) |
| 6 | v1.40.2 | Tiered storage: separate write-depth limit replaced by one `tiered_max_pending_bytes` cap | Only relevant if tiered storage is enabled. | [v1.40.2](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.2) |
| 7 | v1.40.2 | Memcached protocol: keys longer than 250 bytes are rejected | Not our protocol (we use RESP). Listed for completeness. | [v1.40.2](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.2) |
| 8 | v2.0.0 | Client input buffer maximum halved, 64 KiB to 32 KiB (#8005) | Large pipelined or big-argument clients may hit the limit. Test big writes. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 9 | v2.0.0 | `SLOWLOG GET` returns 10 entries by default (#8248) | Monitoring that expects more entries must pass a count. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 10 | v2.0.0 | `used_memory_peak_rss` now reports peak resident memory (#8143); `expired_keys_total` and `evicted_keys_total` always exported even at zero (#8052) | Dashboards and alerts on these fields change meaning or start appearing. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 11 | v2.0.0 | Empty `ZMPOP`/`BZMPOP`/`LMPOP`/`BLMPOP` results return null arrays (#8092) | Clients that expect an empty array must handle null. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 12 | v2.0.0 | RESP3 null encoding changed for blocking stream, list and sorted-set commands (#8085); blocked `XREAD` returns a RESP3 map (#8064) | RESP3 clients (we should use RESP2 unless needed) must re-test blocking calls. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 13 | v2.0.0 | `SORT ... STORE` deletes the destination and returns 0 when the source is missing (#8190) | Code that relied on the old destination surviving breaks. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 14 | v2.0.0 | `EXPIRE` with several flags: every specified flag must hold, not any one (#8189) | Redis semantics may differ for multi-flag calls. Test. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 15 | v2.0.0 | `SET` with a past expiration now honours `NX`/`XX`/`GET` and journals the delete (#8082) | Affects cache/idempotency code that sets past expiries. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 16 | v2.0.0 | Inline requests capped at 64 KB (#8215) | Long inline commands rejected. Use RESP arrays from our clients. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 17 | v2.0.0 | Stricter `RESTORE` validation: duplicate hash fields, odd-entry HASH/ZSET listpacks, zero-member SET/HASH, declared lengths beyond input rejected (#8260, #8185, #8179, #8222) | Payloads from older dumps may now fail to restore. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 18 | v2.0.0 | `FT.CREATE` rejects a missing `SCHEMA` (#8054) and `NUMERIC BLOCKSIZE 0` (#8164); `CL.THROTTLE` rounding corrected (#8289) | Only if we use these module commands (we should not). | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 19 | v2.0.0 | `SET` default stays StringSet; OAHSet was made default in #8013 and reverted for 2.0 (#8257) | No change for us. | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| 20 | v2.0.2 | ACL: commands that read and write keys (e.g. `COPY`, `LMOVE`) now check source keys for read and destination keys for write | ACL users that worked before may get `NOPERM`. Re-test every ACL user. | [v2.0.2](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.2) |
| 21 | v2.0.2 | Daily version check now also sends anonymous deployment info (architecture, I/O backend, cloud provider, thread count, kernel version, uptime, `maxmemory` bucket). No keys or data per the notes. | Outbound traffic from our customers' hosts. Opt-out flag: NOT SOURCEABLE. See VERSION.md. | [v2.0.2](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.2) |
| 22 | v2.0.2 | Emulated cluster mode: replicas advertise the master's announced address in `CLUSTER NODES`, `SLOTS`, `SHARDS` | Affects cluster-aware clients using emulated mode. | [v2.0.2](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.2) |
| 23 | v2.0.2 | Fixes: `DFLYMIGRATE` on a non-cluster server returns "Cluster is disabled"; glob matching with many `*` no longer overflows the stack; `rdb_bgsave_in_progress` resets after BGSAVE; `rdb_last_bgsave_status` updates | Operational fixes; upgrade from v2.0.0 if you use these. | [v2.0.2](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.2) |

## Replication compatibility (not a release change, but a hard limit)

Dragonfly's replication page says it supports "the data structures and replication protocol of Redis OSS up to version 6.2" ([replication](https://www.dragonflydb.io/docs/managing-dragonfly/replication)). Migrating from a Redis 8.x primary by replication is therefore not something the docs cover. Use a snapshot instead ([migrating: snapshot and restore](https://www.dragonflydb.io/docs/migrating-to-dragonfly/from-redis-instance/snapshot-and-restore), page linked from [migrating-to-dragonfly](https://www.dragonflydb.io/docs/migrating-to-dragonfly), not fetched in full in this pass).

## Behaviour that differs from Redis (see best-practices.md for portable code)

- Lua undeclared-key access is rejected by default ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting)).
- Lua 5.4 in Dragonfly; Lua 5.1 in Redis ([scripting](https://www.dragonflydb.io/docs/managing-dragonfly/scripting), [Redis Lua API](https://redis.io/docs/latest/develop/programmability/lua-api/)).
- `COMMAND DOCS` is "Not implemented. The server returns an error." ([COMMAND](https://www.dragonflydb.io/docs/command-reference/server-management/command)).
- Cluster: emulated single-node mode by default; native multi-shard mode uses `--cluster_mode=yes` and a manually supplied topology ([cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)).
- Redis Functions (`FUNCTION LOAD`, `FCALL`): maintainer statement from May 2024 that Dragonfly supports only `EVAL` scripts ([discussion #2981](https://github.com/dragonflydb/dragonfly/discussions/2981)); re-verify.
