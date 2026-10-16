# PostgreSQL — Version Reference

Last verified: 2026-10-11 (all facts below fetched this session; anything not fetched is marked NOT SOURCEABLE)

## Knowledge gap warning

The authoring model's training data predates PostgreSQL 18 GA (Sep 2025), the 18.x minors, and the PG 19 betas. Do not trust memory for: AIO, `uuidv7()`, data-checksum default, MD5 deprecation, PG 19 changes, or minor-version numbers. Cross-check this directory before emitting version-qualified SQL/config. Re-verify the "current minor" row before every release of the framework (minors ship at least every 3 months).

## Current versions

| Item | Value | Source |
|---|---|---|
| Current major (stable) | **18** — GA 2025-09-25 | [Versioning policy](https://www.postgresql.org/support/versioning/), [Release 18 notes](https://www.postgresql.org/docs/current/release-18.html) |
| Current minor of 18 | **18.6** — released 2026-08-13 (24 CVEs fixed) | [18.6 release notes](https://www.postgresql.org/docs/release/18.6/) |
| Current minors of other branches (same 2026-08 release train) | 17.11, 16.15, 15.19, 14.24 | [Versioning policy](https://www.postgresql.org/support/versioning/), [18.6/17.11/16.15/15.19/14.24 + 19 Beta 3 announcement](https://www.postgresql.org/about/news/postgresql-186-1711-1615-1519-1424-and-19-beta-3-released-3365/) |
| Next major | **19** — in beta; Beta 4 announced 2026-09-24; final expected Sep/Oct 2026 | [Beta info](https://www.postgresql.org/developer/beta/), [19 Beta 1 announcement](https://www.postgresql.org/about/news/postgresql-19-beta-1-released-3313/) |
| 19 GA date | NOT SOURCEABLE — only "Sep/Oct 2026" stated; no GA page existed at fetch time | searched postgresql.org news + beta page |
| Release dates of individual minors other than 18.6 (e.g. 17.11) | NOT SOURCEABLE as individual dates; they shipped in the same train as 18.6 (2026-08-13) per the combined announcement title | — |

## Support / EOL table (policy: 5 years per major; minors at least every 3 months; after EOL one final minor)

| Major | Current minor | Supported | First release | EOL (final release) |
|---|---|---|---|---|
| 18 | 18.6 | yes | 2025-09-25 | 2030-11-14 |
| 17 | 17.11 | yes | 2024-09-26 | 2029-11-08 |
| 16 | 16.15 | yes | 2023-09-14 | 2028-11-09 |
| 15 | 15.19 | yes | 2022-10-13 | 2027-11-11 |
| 14 | 14.24 | yes (**EOL in ~1 month: 2026-11-12**) | 2021-09-30 | 2026-11-12 |
| 13 | 13.23 | NO | 2020-09-24 | 2025-11-13 |
| 12 | 12.22 | NO | 2019-10-03 | 2024-11-21 |

Source: [postgresql.org/support/versioning](https://www.postgresql.org/support/versioning/). The project's own advice: run the latest minor of your major; minor upgrades are low-risk, no dump/restore (same page, 18.6 notes: "No dump/restore required" for 18.x).

## Recommended pin (recommendation, not a sourced fact)

- **New installs: PostgreSQL 18, latest minor (18.6 today)**. Supported to 2030-11-14; has AIO, native `uuidv7()`, data checksums on by default, `pg_upgrade` statistics retention.
- **Do not pin 19** until GA and at least the first minor (19.1): it is beta as of 2026-10-11.
- **Do not start anything new on 14** (EOL 2026-11-12). Self-hosted customers on 14/15 need an upgrade runbook (`pg_upgrade --check`, see best-practices.md).
- Docker: pin the exact minor, not a floating major — e.g. `postgres:18.6-trixie` (tag *pattern* inferred from the official image's variant list: Debian `trixie`/`bookworm`, Alpine `alpine3.24`/`alpine3.23`; confirm with `docker pull`). Prefer Debian variants over Alpine for Postgres (glibc locale/collation consistency) — this is a judgement call, not sourced. Bump deliberately; a minor bump is a data-dir-compatible image swap, a major bump is NOT.
- **PG 18 image volume change**: mount at `/var/lib/postgresql` (not `/var/lib/postgresql/data`); PGDATA is now version-specific (`/var/lib/postgresql/18/docker`). Mounting the old path on 18 will not persist data as expected. Source: [Docker official image](https://hub.docker.com/_/postgres).

## Official Docker image

- Supported majors: 14, 15, 16, 17, 18 (`latest`), and `19beta4`; base variants Debian `trixie`, `bookworm`; Alpine `alpine3.24`, `alpine3.23`. Source: [hub.docker.com/_/postgres](https://hub.docker.com/_/postgres) (fetched 2026-10-11).
- `POSTGRES_PASSWORD` required (non-empty); `POSTGRES_USER` default `postgres`; `POSTGRES_INITDB_ARGS`; init scripts `/docker-entrypoint-initdb.d/*.{sql,sql.gz,sh}` run only on an empty data dir.

## Installed locally (checked 2026-10-11, host: /home/kiko)

- `psql --version`: **NOT INSTALLED** (`command not found`)
- `docker --version`: Docker 29.9.0
- `docker image ls | grep -E 'postgres|mongo'`: `postgres:16`, `postgres:16-alpine`, `postgres:17`, `postgres:17-alpine`, `postgres:17.5-alpine`, `postgres:18.6-alpine3.23`. No mongo images (see mongo/VERSION.md).
- Gaps vs current: `postgres:17.5-alpine` is behind 17.11 (stale — security fixes missing); `postgres:16`/`17` floating tags have whatever minor was pulled — re-pull. `18.6-alpine3.23` matches the current minor.

## Verified sources

- https://www.postgresql.org/support/versioning/
- https://www.postgresql.org/docs/current/release-18.html
- https://www.postgresql.org/docs/release/18.6/
- https://www.postgresql.org/docs/17/release-17.html
- https://www.postgresql.org/about/news/postgresql-19-beta-1-released-3313/
- https://www.postgresql.org/developer/beta/
- https://hub.docker.com/_/postgres
