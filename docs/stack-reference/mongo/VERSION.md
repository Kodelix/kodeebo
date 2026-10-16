# MongoDB — Version Reference

Last verified: 2026-10-11 (all facts below fetched this session; anything not fetched is marked NOT SOURCEABLE)

## Knowledge gap warning

The authoring model's training data predates MongoDB 9.0 (GA Sept 2026), the 8.3 line, the 9.0 `constraint` validation level, and the 9.0 transaction and memory limits. Do not trust memory for version numbers, EOL dates, default write concern details, or tag names. Re-verify this file before each release of the framework and whenever a new major ships.

## Current versions

| Item | Value | Source |
|---|---|---|
| Current stable major | **9.0** — labelled "Current Stable Release" on the docs release-notes index | [Release notes index](https://www.mongodb.com/docs/manual/release-notes/) |
| 9.0 GA date | **2026-09-29** per MongoDB's own announcement. **Conflict:** the 9.0 release-notes page dates 9.0.0 as "Sept 28, 2026"; endoflife.date lists 30 Sep. Use 2026-09-29 and re-check. | [9.0 is now available](https://www.mongodb.com/products/updates/mongodb-9-0-is-now-available/), [9.0 release notes](https://www.mongodb.com/docs/manual/release-notes/9.0/) |
| Latest 9.0 patch | **9.0.2** per the official Docker image README (not the MongoDB release page). Re-check; NOT SOURCEABLE beyond that snapshot. | [docker-library/docs mongo README](https://github.com/docker-library/docs/blob/master/mongo/README.md) |
| Other series listed in same README | 8.3.11, 8.0.32, 7.0.43 | same |
| Previous stable | 8.3 (labelled "Previous Stable Release") | [Release notes index](https://www.mongodb.com/docs/manual/release-notes/) |
| Kotlin coroutine driver | `org.mongodb:mongodb-driver-kotlin-coroutine` **5.13.0** (Maven `lastUpdated` 2026-09-25). Minimum JDK: NOT SOURCEABLE. Server-driver compatibility matrix: NOT SOURCEABLE (not fetched). | [Maven metadata](https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-kotlin-coroutine/maven-metadata.xml) |

## Support / EOL

| Series | Release | EOL (Enterprise Advanced / Atlas Dedicated) | Notes | Source |
|---|---|---|---|---|
| 9.0 | Sept 2026 (GA 2026-09-29) | **2031-10-31** | Atlas Auto Upgrade EOL: TBD | [Lifecycle schedules](https://www.mongodb.com/legal/support-policy/lifecycles) |
| 8.3 | May 2026 | 2029-10-31 (Enterprise) | Atlas Auto Upgrade EOL: TBD, no sooner than Oct 2026 | same |
| 8.2 | Sept 2025 | **2026-07-31 (already EOL)** | Atlas Auto Upgrade EOL same date | same |
| 8.0 | Oct 2024 | 2029-10-31 | Atlas Auto Upgrade EOL 2025-06-20 | same |
| 7.0 | Aug 2023 | 2027-08-31 | Atlas Auto Upgrade EOL 2023-10-18 | same |
| 6.0 | — | Dedicated EOL 2025-07-31 (ended) | | same |
| 5.0 | — | Dedicated EOL 2024-10-31 (ended) | | same |

Policy (per lifecycle page): major releases are supported roughly 3–5 years; interim releases (e.g. 8.1–8.3 in the Atlas Auto Upgrade table) have much shorter lives. Drivers released more than 3 years after a server's EOL date are not compatible with that server.

## Recommended pin (recommendation, not a sourced fact)

- **Self-hosted bundle shipped to customers: MongoDB 8.0 or 8.3**, not 9.0, until 9.0 has field time. 8.0 is supported to 2029-10-31; 9.0 to 2031-10-31. Judgement, not sourced.
- **New dev/staging: 9.0.2** (latest patch in the snapshot). If you use 9.0, the new `constraint` validation level and new transaction limits apply (see breaking-changes.md).
- Pin the exact patch tag (e.g. `mongo:9.0.2`, not `mongo:latest`). The shared `latest` tag points at the newest major.
- Do not start new work on 7.0 (EOL 2027-08-31) or any 8.2 build (EOL 2026-07-31).

## Official Docker image

- Shared tags listed in the docker-library README: `9.0.2`, `9.0`, `9`, `latest`; `8.3.11`, `8.3`, `8`; `8.0.32`, `8.0`; `7.0.43`, `7.0`, `7`. Simple (Ubuntu-suite) variants: `9.0.2-noble`, `9.0-noble`, `9-noble`, `noble`; `8.0.32-noble`; `7.0.43-jammy`. Windows: `windowsservercore-ltsc2025`, `nanoserver-ltsc2022`.
- No `-rc` or `-ubi` tags in that README. The Docker Hub page itself did not list tags (fetch was trimmed).
- Docker Hub page shows "Last updated: 9 days ago" as of the 2026-10-11 fetch. Source: [hub.docker.com/_/mongo](https://hub.docker.com/_/mongo), [docker-library README](https://github.com/docker-library/docs/blob/master/mongo/README.md).

## Installed locally (checked 2026-10-11, host: /home/kiko)

- `mongosh --version`: **NOT INSTALLED** (command not found). `mongod`/`mongo`: not found on PATH.
- `docker image ls | grep -i mongo`: **no matches** (no mongo images present). `docker --version`: Docker 29.9.0.
- Gap: nothing to test against locally. Pull `mongo:9.0.2` (or the pinned tag) before running any test that needs a server.

## Verified sources

- https://www.mongodb.com/docs/manual/release-notes/
- https://www.mongodb.com/docs/manual/release-notes/9.0/
- https://www.mongodb.com/products/updates/mongodb-9-0-is-now-available/
- https://www.mongodb.com/legal/support-policy/lifecycles
- https://www.mongodb.com/legal/licensing/server-side-public-license
- https://www.mongodb.com/legal/licensing/server-side-public-license/faq
- https://www.mongodb.com/docs/manual/core/schema-validation/
- https://www.mongodb.com/docs/manual/core/schema-validation/specify-json-schema/
- https://www.mongodb.com/docs/manual/core/schema-validation/specify-validation-level/
- https://www.mongodb.com/docs/manual/core/schema-validation/handle-invalid-documents/
- https://www.mongodb.com/docs/manual/tutorial/equality-sort-range-guideline/
- https://www.mongodb.com/docs/manual/core/index-ttl/
- https://www.mongodb.com/docs/manual/reference/write-concern/
- https://www.mongodb.com/docs/manual/reference/mongodb-defaults/
- https://www.mongodb.com/docs/manual/core/transactions-production-consideration/
- https://www.mongodb.com/docs/manual/faq/fundamentals/
- https://github.com/docker-library/docs/blob/master/mongo/README.md
- https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-kotlin-coroutine/maven-metadata.xml
