# Dragonfly — Deprecated / Removed APIs, Flags and Commands

Last verified: 2026-10-11. "Deprecated" = still works, documented as deprecated, may be removed. "Removed/retired" = gone. Sources are the official docs and GitHub release pages fetched 2026-10-11.

| Deprecated / removed | Replacement | Since | Source |
|---|---|---|---|
| `--rename_command` flag (rename or hide commands) | ACL rules: `ACL SETUSER <user> ... -flushall -config ...`. ACL is the documented way to restrict commands ([ACL](https://www.dragonflydb.io/docs/managing-dragonfly/acl)). | Retired in v1.40.0 | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0) |
| `--oom_deny_commands` flag | No replacement named on the release page. The flags page documents `--rss_oom_deny_ratio` (default `1.25`: DENYOOM commands fail above this maxmemory-to-RSS ratio; negative disables). Mapping is ours, not stated by Dragonfly. | Retired in v1.40.0 | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0), [flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags) |
| v1 replication path and `experimental_replicaof_v2` flag | Use the default replication path (the release page does not name the replacement flag). Replication supports Redis OSS protocol up to 6.2 per docs. | Retired in v1.40.0 | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0), [replication](https://www.dragonflydb.io/docs/managing-dragonfly/replication) |
| `squash_stats_latency_lower_limit` flag | None stated | Retired in v1.40.0 | [v1.40.0](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0) |
| `--save_schedule` (HH:MM snapshot schedule) | `--snapshot_cron` (cron expression; Dragonfly 1.7.1+). The backups page says `save_schedule` "will be removed". | Deprecated (version not stated on page) | [flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags), [backups](https://www.dragonflydb.io/docs/managing-dragonfly/backups) |
| `--shard_round_robin_prefix` flag | None stated; flags page says "slated for removal" | Deprecated (version not stated) | [flags](https://www.dragonflydb.io/docs/managing-dragonfly/flags) |
| `--huffman_table` flag | None stated | Deprecated in v2.0.0 (#8205) | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| `DEBUG COMPRESSION` command | None stated | Removed in v2.0.0 (#8205) | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| Fixed-length option for the replication backlog | Age and memory-budget retention: `--shard_repl_backlog_time_ms` (default `5000`, `0` disables the age limit) and `--shard_repl_backlog_max_bytes`. Legacy `--shard_repl_backlog_len` is still accepted; a nonzero value limits by entry count. | Deprecated in v2.0.0 (#8039) | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0), [replication](https://www.dragonflydb.io/docs/managing-dragonfly/replication) |
| Redis Functions (`FUNCTION LOAD`, `FCALL`) | Use `EVAL` scripts with `--!df flags=...` header flags where needed (scripting page). Maintainer said Dragonfly "doesn't support Redis functions at all, only EVAL scripts" (May 2024). | Not supported (statement dated 2024-05-01) | [discussion #2981](https://github.com/dragonflydb/dragonfly/discussions/2981) |
| `COMMAND DOCS` | None. Docs: "Not implemented. The server returns an error." | Not implemented | [COMMAND](https://www.dragonflydb.io/docs/command-reference/server-management/command) |
| Memcached keys longer than 250 bytes | Rejected (protocol limit). Not our protocol. | v1.40.2 (#8213) | [v1.40.2](https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.2) |
| Unbounded memcached keys; inline requests above 64 KB | Rejected | v2.0.0 (#8213, #8215) | [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0) |
| Redis 8.x-only commands (`HOTKEYS`, `XADD ... IDMP/IDMPAUTO`, `DELEX`, `DIGEST`, `MSETEX`, `INCREX`, `FT.HYBRID`, `TS.NRANGE`, `BACKUP`, compact hashes, `HIMPORT`, `LMOVEM`, `SUNIONCARD`, `SDIFFCARD`, `volatile-lrm`/`allkeys-lrm`) | Not in Dragonfly docs or release notes that we read. Presence/absence per command: **check with `COMMAND INFO <name>` on the Dragonfly version you run.** | n/a | Redis side: [8.4](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.4-release-notes/), [8.6](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.6-release-notes/), [8.8](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.8-release-notes/), [8.10](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.10-release-notes/) |

## Things that are NOT deprecated (do not remove)

- `--snapshot_cron` replaces `--save_schedule`, not the other way round.
- `COMMAND COUNT`, `COMMAND INFO`, `COMMAND HELP` are supported ([COMMAND](https://www.dragonflydb.io/docs/command-reference/server-management/command)).
- Emulated cluster mode (`--cluster_mode=emulated`, the default when omitted) is current ([cluster-mode](https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode)).

## Not found in this pass (NOT SOURCEABLE)

- Protected mode: the flags page does not document it. Whether Dragonfly has an equivalent to Redis `protected-mode`: NOT SOURCEABLE.
- Dragonfly slowlog defaults (`slowlog-log-slower-than`, `slowlog-max-len` equivalents) and LATENCY monitor: the SLOWLOG page documents the container command only; defaults and LATENCY support: NOT FOUND.
- `maxmemory-policy` equivalent: no eviction-policy flag is listed on the flags page (only `--cache_mode` and heartbeat eviction flags). The victim-selection rule for `cache_mode`: NOT SOURCEABLE.
