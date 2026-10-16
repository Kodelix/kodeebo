# Redis Open Source — Version Reference

| Field | Value |
|---|---|
| **Latest GA (Redis Open Source)** | **8.10.2** — 2026-09-17 (security patch). Line 8.10.0 GA 2026-07-29. [GitHub releases](https://github.com/redis/redis/releases) (dates taken from the GitHub API `published_at`) |
| Other maintained patch releases | 8.8.3, 8.6.7, 8.4.7, 8.2.10 (all 2026-09-17); 8.0.x (last seen in notes: 8.0.6, Feb 2026); 7.4.11 and 7.2.16 (both 2026-08-17) |
| Minor-line GA dates | 8.0.0 2025-05-02, 8.2.0 2025-08-04, 8.4.0 2025-11-18, 8.6.0 2026-02-10, 8.8.0 2026-05-25, 8.10.0 2026-07-29, 7.4.0 2024-07-29, 7.2.0 2023-08-15 (GitHub API) |
| **Licence** | 7.2.x and earlier: BSD-3-Clause. 7.4.x (to 7.8.x): RSALv2 **or** SSPLv1. 8.0+: RSALv2 **or** SSPLv1 **or** AGPLv3 (user's choice). Source: [redis.io/legal/licenses](https://redis.io/legal/licenses/), [LICENSE.txt](https://raw.githubusercontent.com/redis/redis/unstable/LICENSE.txt) |
| Licence history | Mar 2024: BSD to RSALv2/SSPLv1 from 7.4 ([blog](https://redis.io/blog/redis-adopts-dual-source-available-licensing/)). 2025-05-01: AGPLv3 added as third option from Redis 8 ([blog](https://redis.io/blog/agplv3/)); Redis 8.0.0 GA same period (May 2025). |
| Name change | "Redis Community Edition" became "Redis Open Source" at 8.0 ([8.0 notes](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/)) |
| **Support policy** | Standard releases (first minor of a major + intermediate minors, e.g. 8.0, 8.4, 8.6, 8.8, 8.10): security + critical fixes for 6 months after the *next* minor ships. Extended releases (second minor and final minor of a major, e.g. 8.2): 5 years from release. ([version-mgmt](https://redis.io/docs/latest/operate/oss_and_stack/install/version-mgmt/)) |
| EOL table (official) | 8.10/8.8/8.6/8.4: Standard, EOL TBD. **8.2: Extended, EOL 2030-09-01.** 8.0: Standard, EOL 2026-12-01. 7.4: Extended, EOL 2029-12-01. 7.2: Extended, EOL 2029-12-01. 6.2: Extended, EOL 2027-04-01. (same page) |
| Official Docker image | `redis` on Docker Hub (Debian + `-alpine` variants); `latest` = 8.10.2 at fetch time. Hub page: [hub.docker.com/_/redis](https://hub.docker.com/_/redis) |
| Last verified | 2026-10-11 |

## Recommended pin

- **Default for our products (we run it ourselves): `redis:8.2` (Extended, supported to 2030-09-01)**, then bump the patch (8.2.10 at 2026-09-17). Choose the newest `8.x` only when a feature is needed; Standard lines go EOL six months after the next minor, so a Standard pin forces a minor upgrade about every 6-9 months.
- **Bundles shipped to customers who may redistribute or fork: prefer a permissive engine** — Redis 7.2.x (BSD-3, `redis:7.2-alpine`, 7.2.16 at 2026-08-17, EOL 2029-12-01) or Valkey (BSD-3, see below). Note `redis:7-alpine` is NOT BSD: it resolves to 7.4.x (RSALv2/SSPLv1) — pin the minor explicitly (`7.2-alpine`).
- Always pin the minor tag (not `latest`), re-pull for patch updates: every 2026 patch release has been flagged `SECURITY` (see breaking-changes.md).
- Not legal advice: have counsel confirm the licence choice for a given distribution model.

## Licence implications for self-hosted / redistributed bundles

- Redis 8+: you pick one licence. RSALv2 allows use/copy/distribute/modify but forbids offering Redis functionality to third parties as a managed service and removing notices ([licences page](https://redis.io/legal/licenses/), [RSALv2 text](https://redis.io/legal/rsalv2-agreement/)). A customer running our bundle for their own product is not a managed-service provider of Redis; **we** must not resell "Redis as a service".
- AGPLv3 is copyleft with a network clause: unmodified use "as-is" of Redis-provided artifacts is most likely unaffected, but modified Redis offered over a network requires source disclosure (same FAQ). Do not patch Redis in our images unless we accept this.
- A Compose file that merely *references* `image: redis:8.2` (customer pulls from Docker Hub) does not make us a redistributor of the binary; shipping the image tarball / our own built image does, so then comply with the chosen licence's notice requirements.
- 7.2.x and Valkey are the only options here without source-available restrictions.

## Valkey (BSD fork, brief)

- Linux Foundation project, licence BSD-3-Clause (copyright "Valkey contributors (2024-present)" + Redis Ltd. 2006-2020): [COPYING](https://raw.githubusercontent.com/valkey-io/valkey/unstable/COPYING).
- Current stable lines per [valkey.io/download](https://valkey.io/download/): 9.1.2, 8.1.10, 7.2.14. GitHub API: 9.1.2 and 9.0.6 published 2026-09-01; 8.1.10 and 8.0.11 on 2026-08-31; 9.2.0-rc1 (pre-release) 2026-09-16; 9.1.0 GA 2026-05-19 ([releases](https://github.com/valkey-io/valkey/releases)). Valkey 9.0 GA 2025-10-21, 8.1 GA 2025-04-02 ([blog](https://valkey.io/blog/)).
- Valkey 9.0 notes: hash field expiration, numbered databases in cluster mode, atomic slot migration (same blog). Docker image `valkey/valkey` (Docker Hub).
- Valkey support/EOL policy: **NOT SOURCEABLE** (fetch of valkey SECURITY.md returned HTTP 503; searched valkey.io/download only).
- Redis 8-only features (built-in JSON/Search/TimeSeries/Bloom, vector sets, `INCREX`, `DELEX`, `XADD IDMP`, LRM eviction) are NOT in Valkey/Dragonfly — keep them out of portable code.

## Installed locally (Bash, 2026-10-11)

- `redis-server --version`: NOT INSTALLED (command not found)
- `redis-cli --version`: NOT INSTALLED (command not found)
- `docker image ls`: `redis:7-alpine` (id ff02b58f971e, created 2026-08-18; image env `REDIS_VERSION=7.4.11` -> RSALv2/SSPLv1 dual-licensed line, Extended support to 2029-12-01); `docker.dragonflydb.io/dragonflydb/dragonfly:v1.40.0` (id 18228a84e230; behind v2.0.2). No valkey image present.

## Verified sources

- https://github.com/redis/redis/releases (+ GitHub REST API release list)
- https://redis.io/docs/latest/operate/oss_and_stack/install/version-mgmt/
- https://redis.io/legal/licenses/ ; https://raw.githubusercontent.com/redis/redis/unstable/LICENSE.txt ; https://redis.io/legal/rsalv2-agreement/
- https://redis.io/blog/agplv3/ ; https://redis.io/blog/redis-adopts-dual-source-available-licensing/
- Release notes 7.4, 8.0, 8.2, 8.4, 8.6, 8.8, 8.10 under https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/
- https://hub.docker.com/_/redis ; https://valkey.io/download/ ; https://valkey.io/blog/

## Knowledge gap warning

The model's training data predates Redis 8.x. Everything about 8.0-8.10 (tri-licence, built-in modules, new commands) comes from the pages above. Beware: an automated page summariser mis-dated releases as 2024; the GitHub API confirms 2025-2026. Do not infer API availability from memory: check each command's "since" on redis.io and check Valkey/Dragonfly support separately.
