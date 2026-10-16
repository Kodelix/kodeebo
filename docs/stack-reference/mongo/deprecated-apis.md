# MongoDB — Deprecated / removed APIs and options (verified 2026-10-11)

| Deprecated / removed | Replacement | Since | Source |
|---|---|---|---|
| `net.wireObjectCheck` config option (deprecated) | Remove from config; no replacement named | 9.0 | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| `--objcheck` / `--noobjcheck` CLI arguments (deprecated) | Remove; BSON is validated on ingest by default in 9.0 | 9.0 | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| `mongocryptd` (deprecated) | Automatic Encryption Shared Library | 9.0 | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| `ShardCatalogCacheCollectionMetadataMismatch` (removed from `checkMetadataConsistency`) | No direct replacement named | 9.0 | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| `shardingStatistics.databaseVersionUpdateCounters` (renamed) | `shardingStatistics.databaseShardingMetadataStatistics` (fields replaced) | 9.0 | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| `metrics.changeStreams.showExpandedEvents` (renamed) | `metrics.changeStreams.option.showExpandedEvents` | 9.0 | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| Time-series collection as non-materialized writable view | Writes to time-series collections are no longer allowed on non-materialized views; use materialized collections | 9.0 | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |

## Status changes (not removed)

| Item | Status | Source |
|---|---|---|
| `$accumulator`, `$function`, `$where` | **No longer deprecated** in 9.0; run on a WebAssembly-based engine (not on `ppc64le`) | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| `validationAction: errorAndLog` | Added in 8.1 (not deprecated). Blocks downgrade while in use. | [handle-invalid-documents](https://www.mongodb.com/docs/manual/core/schema-validation/handle-invalid-documents/) |
| `validationLevel: constraint` | New in 9.0 | [specify-validation-level](https://www.mongodb.com/docs/manual/core/schema-validation/specify-validation-level/) |
| `$queryStats` | On by default in 9.0 (sampling 1% of reads and writes) | [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| `TTL` `expireAfterSeconds` change via `createIndex` | Not allowed; use `collMod` | [index TTL](https://www.mongodb.com/docs/manual/core/index-ttl/) |

## Not verified

- Full deprecation list for 8.x and 7.x: NOT SOURCEABLE (EOL-series release notes are in legacy docs; not fetched).
- MongoDB's exact removal list for the Docker/`mongosh` CLIs: NOT SOURCEABLE.
