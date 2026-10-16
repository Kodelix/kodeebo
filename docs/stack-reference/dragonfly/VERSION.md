# Dragonfly — Version Reference

| Field | Value |
|---|---|
| **Latest release** | **v2.0.2** — patch release, published **07 Oct** ([releases](https://github.com/dragonflydb/dragonfly/releases), marked Latest). The release page shows day and month only; the year 2026 is taken from the page footer and the search-result context, so treat the year as **inferred**. |
| Previous releases | v2.0.0 — 16 Sep (major; deprecates fixed-length replication backlog). v1.40.2 — 03 Sep. v1.40.1 — 06 Aug (patch). v1.40.0 — 04 Aug (minor). Same year caveat. ([releases](https://github.com/dragonflydb/dragonfly/releases), [v2.0.0](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0), [v2.0.2](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.2)) |
| **Licence** | **Business Source License 1.1 (BSL 1.1)**. Licensor: DragonflyDB, Ltd. Change Date: **Nov 1, 2030**, or for a given version the fourth anniversary of its first public distribution if earlier. Change License: **Apache License 2.0**. Source: [LICENSE.md](https://raw.githubusercontent.com/dragonflydb/dragonfly/main/LICENSE.md); licence name also on [docs/about/license](https://www.dragonflydb.io/docs/about/license). |
| Licence grant (key clauses) | Use is permitted "only as part of your own product or service". The grant excludes "an in-memory data store product or service". Providing the work "as a Service" is prohibited where it competes with the Licensor. Access by your own staff and contractors is not restricted. Source: LICENSE.md (paraphrased: the full text is longer than the quote limit). |
| Licence FAQ statement | Self-hosting in production is allowed "only if you do not offer Dragonfly as a managed service" ([FAQ](https://www.dragonflydb.io/docs/about/faq)). |
| Redis protocol target | Official docs: Dragonfly "support[s] the data structures and replication protocol of Redis OSS up to version 6.2" ([replication](https://www.dragonflydb.io/docs/managing-dragonfly/replication)). Commands: "more than 200 Redis commands" ([FAQ](https://www.dragonflydb.io/docs/about/faq)). Not a claim of full Redis 7/8 parity. |
| Recommended pin (our own deployments) | `docker.dragonflydb.io/dragonflydb/dragonfly:v2.0.2` (the local image is in the same registry path; the `v2.0.2` tag was NOT pulled or inspected in this pass: confirm before use). Pin the exact patch, never `latest`. |
| Recommended pin (customer bundles, redistribution) | Do not bundle Dragonfly without counsel review (see Licence implications). Options without source-available terms: Redis 7.2 and earlier (BSD-3-Clause, [licences](https://redis.io/legal/licenses/)) or Valkey (BSD-3-Clause, [COPYING](https://raw.githubusercontent.com/valkey-io/valkey/unstable/COPYING)). |
| **Installed locally** | `docker image ls \| grep -i dragonfly` (run 2026-10-11): `docker.dragonflydb.io/dragonflydb/dragonfly:v1.40.0` (image id 18228a84e230, 185MB). This is **two releases behind** v2.0.2 (v2.0.0 and v2.0.2 are newer). |
| Local Redis image (for comparison) | `redis:7-alpine` (same `docker image ls` run). Not Dragonfly. |
| Last verified | 2026-10-11 |

## Licence implications for self-hosted and redistributed bundles

- **Our own SaaS (we run it, customers call it over the network):** the grant covers use "as part of your own product or service". Running Dragonfly inside our product is the intended use. Do not sell or expose Dragonfly itself as a service to third parties.
- **Customers self-hosting our Compose bundle (we ship a compose file that references the image):** a reference to a public registry image does not redistribute the binary. Shipping our own image tarball, or a bundle containing Dragonfly, is redistribution. The grant excludes "an in-memory data store product or service": Dragonfly is an in-memory data store, so a bundle that presents it as a data-store product is at risk. **Not legal advice:** get counsel to confirm before shipping Dragonfly in a bundle.
- **Change Date:** each version converts to Apache-2.0 on the earlier of Nov 1, 2030 and four years after that version's first public distribution (per the licence text). Older versions move to Apache-2.0 sooner. The exact per-version date is NOT SOURCEABLE beyond this rule; compute it from the release date.

## Telemetry note (self-hosted)

v2.0.2 adds a daily version check that sends anonymous deployment info (architecture, I/O backend, cloud provider, thread count, kernel version, uptime, `maxmemory` bucket). The release notes say no keys, data, hostnames or addresses are sent ([v2.0.2](https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.2)). Whether it can be disabled by a flag: **NOT SOURCEABLE** in this pass. Check before shipping to customers with data-residency requirements.

## Knowledge-gap and open items

- Dragonfly's official docs do not publish a full "differences from Redis" page that we could fetch (404 on the tried URLs; the docs sidebar lists no compatibility page). Compatibility claims below come from the scripting, cluster, ACL, replication, command, and release pages only.
- Lua: the docs say `FUNCTION LOAD` is not supported; a maintainer said so in May 2024 ([discussion #2981](https://github.com/dragonflydb/dragonfly/discussions/2981)); a Feb 2026 comment asked whether this still holds with no answer. Re-verify before relying on either answer.
- The v2.0.0 notes were read from the release page. The WebSearch summary also mentioned Valkey 9 RDB loading and GEOSEARCHSTORE; those were NOT confirmed on the release page and are not stated here.

## Verified sources

- Releases: https://github.com/dragonflydb/dragonfly/releases
- v1.40.0: https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.0 ; v1.40.2: https://github.com/dragonflydb/dragonfly/releases/tag/v1.40.2
- v2.0.0: https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.0 ; v2.0.2: https://github.com/dragonflydb/dragonfly/releases/tag/v2.0.2
- Licence: https://raw.githubusercontent.com/dragonflydb/dragonfly/main/LICENSE.md ; https://www.dragonflydb.io/docs/about/license
- FAQ: https://www.dragonflydb.io/docs/about/faq
- Replication: https://www.dragonflydb.io/docs/managing-dragonfly/replication
- Flags: https://www.dragonflydb.io/docs/managing-dragonfly/flags
- Scripting: https://www.dragonflydb.io/docs/managing-dragonfly/scripting
- Cluster: https://www.dragonflydb.io/docs/managing-dragonfly/cluster-mode
- ACL: https://www.dragonflydb.io/docs/managing-dragonfly/acl
- Snapshot/backups: https://www.dragonflydb.io/docs/managing-dragonfly/snapshotting (design), https://www.dragonflydb.io/docs/managing-dragonfly/backups
- INFO: https://www.dragonflydb.io/docs/command-reference/server-management/info ; COMMAND: https://www.dragonflydb.io/docs/command-reference/server-management/command

See [breaking-changes.md](breaking-changes.md), [deprecated-apis.md](deprecated-apis.md), [best-practices.md](best-practices.md).
