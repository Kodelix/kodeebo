# MongoDB — Breaking / Behaviour Changes

Last verified: 2026-10-11. Every row cites a fetched page unless marked otherwise. "Impact" is analysis, not sourced.

## 8.x → 9.0 (GA 2026-09-29) — [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/)

The 9.0 page has no dedicated "breaking" section; these rows are the items it lists as behaviour or action changes.

| Change | Detail | Impact for us |
|---|---|---|
| Per-operation memory limit | A single query operation is limited to 1 GB or 20% of server memory, whichever is greater. Over the limit fails with `ExceededMemoryLimit` or `QueryExceededMemoryLimitNoDiskUseAllowed`. | Large aggregations that passed on 8.x can now fail. Test with real data sizes. |
| Multi-document transaction cap | `maxConcurrentMultiDocumentTransactions` default `10000`; beyond it the server returns `TooManyOpenTransactions`. | Connection-pool sizing must respect this on very busy nodes. |
| Server-side JS un-deprecated | `$accumulator`, `$function`, `$where` no longer deprecated; they run on a WebAssembly-based engine. Not available on `ppc64le`. | Still a security surface; see injection notes in best-practices.md. |
| Query stats on by default | `$queryStats` samples 1% of reads and 1% of writes by default; now covers update, insert, delete. | Extra overhead; check profiling baselines. |
| Time series storage | Collections stored as a single namespace; no longer writable non-materialized views; renameable with `renameCollection`. `find`, `aggregate`, `listIndexes` return the user-facing namespace in `cursor.ns`. | Update any code reading time-series namespaces. |
| Queryable Encryption | Prefix, suffix, and substring queries generally available. | Additive. |
| Document validation `constraint` level | New level applies rules to all inserts and updates and guarantees every existing document satisfies them. See `constraint` rules in best-practices.md. | Additive; enabling it requires a clean collection first. |
| BSON validation | Server validates all ingested BSON by default. | Malformed client writes now rejected. |
| Removed inconsistency type | `ShardCatalogCacheCollectionMetadataMismatch` removed from `checkMetadataConsistency`. | Monitoring that alerts on it goes silent. |
| Renamed metrics | `shardingStatistics.databaseVersionUpdateCounters` → `shardingStatistics.databaseShardingMetadataStatistics` (fields replaced). `metrics.changeStreams.showExpandedEvents` → `metrics.changeStreams.option.showExpandedEvents`. | Update dashboards and alerts. |
| Pre-image purge metrics | `changeStreamPreImages.purgingJob.docsDeleted` and `bytesDeleted` may be estimates. | Do not use for exact accounting. |
| Upgrade impact | Clusters with more than 5,000 time series collections in one database may take longer to upgrade and see write-latency spikes. | Plan the upgrade window. |
| Security | `useInternalAuthzForX509` added; `authenticatedMechanism` added to `usersInfo`; audit `directRemote` (mongo schema) and `direct_endpoint` (OCSF). | Additive; audit parsers may need updating. |
| Deprecations | `net.wireObjectCheck` and `--objcheck` / `--noobjcheck` deprecated. `mongocryptd` deprecated; use the Automatic Encryption Shared Library. | Remove from config and compose files. |

## 9.0 known issues (from the 9.0 release notes)

| Issue | Status | Impact |
|---|---|---|
| SERVER-133518 — shard can hang during step-up, cannot become primary | Fixed in 9.0.4 | Run 9.0.4 or later for sharded clusters. |
| SERVER-136226 — nodes open at least `ShardingTaskExecutorPoolMinSize` connections per config server, can exhaust config servers | Open. Page recommends setting `ShardingTaskExecutorPoolMinSizeForConfigServers` to `1` before upgrade if `ShardingTaskExecutorPoolMinSize` > 1. | Pre-upgrade config change if sharded. |
| SERVER-89953 — at FCV 9.0, `listIndexes` reports `collation: { locale: "simple" }`; ODMs such as Mongoose may drop and rebuild unchanged indexes on `syncIndexes()` | Open; page gives a workaround and a patch fix is promised. | Index churn on every app start for Mongoose users. |

## 8.x → 8.1+ — validation action `errorAndLog`

| Change | Detail | Source |
|---|---|---|
| `validationAction: errorAndLog` added in 8.1 | Rejects violating writes and logs them. Once used, the collection cannot be downgraded to an older version until dropped or its action is changed with `collMod`. | [handle-invalid-documents](https://www.mongodb.com/docs/manual/core/schema-validation/handle-invalid-documents/) |

## Write concern and transactions (current docs, 9.0)

| Item | Behaviour | Source |
|---|---|---|
| Default write concern | Implicit default is `w: "majority"`. Exception: with arbiters and non-arbiter data-bearing voting members not greater than the voting majority, default is `{ w: 1 }`. | [write concern defaults](https://www.mongodb.com/docs/manual/reference/mongodb-defaults/) |
| Default `wtimeout` | Not stated; if omitted and the write concern is unachievable, the write blocks indefinitely. | [write concern](https://www.mongodb.com/docs/manual/reference/write-concern/) |
| Default read concern | `"local"` (can return rolled-back data; no causal guarantee). | [write concern defaults](https://www.mongodb.com/docs/manual/reference/mongodb-defaults/) |
| Default write concern changed to majority in 5.0 | Secondary sources only (Alibaba Cloud docs, mongosilverback blog). MongoDB 5.0 compatibility page fetched; did NOT mention it. Treat as unverified against the primary MongoDB source. | [Alibaba features 5.0](https://www.alibabacloud.com/help/en/mongodb/product-overview/features-of-mongodb-5-0), [mongosilverback](https://mongosilverback.net/2021/07/23/mongodb-5-0-new-stuff-default-write-concern/) |
| Transaction runtime | "By default, a transaction must have a runtime of less than one minute." Expired transactions aborted by cleanup. Numeric `transactionLifetimeLimitSeconds` default: not stated on the page. | [transactions production considerations](https://www.mongodb.com/docs/manual/core/transactions-production-consideration/) |
| Transaction size | Oplog splits a transaction into multiple entries, removing the 16 MB total limit. Each entry must still fit the 16 MB BSON limit. Too large for WiredTiger cache aborts with `TransactionTooLargeForCache`. | same |
| Lock wait | Default `maxTransactionLockRequestTimeoutMillis` = **5 ms**; set to `-1` for operation-level timeouts. | same |
| 1000 write operations per transaction | NOT SOURCEABLE — not on the fetched page. | — |
| Oplog size requirement | NOT SOURCEABLE — page does not state a required size. | — |

## Recommendation: upgrade and validation impact

- Moving to 9.0: run the `constraint` validation level only after a full-collection check; it requires the validator unchanged while `constraint` is set (must downgrade to `strict`, edit, upgrade again) per [specify-validation-level](https://www.mongodb.com/docs/manual/core/schema-validation/specify-validation-level/).
- Re-run the 9.0 memory and transaction-cap tests before go-live. Limits are new in 9.0; no 8.x equivalent is cited in the fetched material.
