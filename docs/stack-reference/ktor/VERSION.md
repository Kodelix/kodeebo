# Ktor (server) — Version Reference

Last verified: 2026-10-11 (all facts below fetched this session; anything not fetched is marked NOT SOURCEABLE)

## Knowledge gap warning

The authoring model's training data predates Ktor 3.6.0 (Sep 2026), the 3.4–3.5 lines, and the built-in Ktor DI plugin (3.2.0). Do not trust memory for plugin package names, artifact coordinates, API names, or minimum JDK/Kotlin versions. Re-verify this file before each framework release. Observed minor cadence in 2026 (from the releases table): 3.4.0 on 2026-01-23, 3.5.0 on 2026-05-15, 3.6.0 on 2026-09-16 (approximately four months apart; patches in between).

## Current versions

| Item | Value | Source |
|---|---|---|
| Current stable | **3.6.0** — marked "Latest" on GitHub | [GitHub release 3.6.0](https://github.com/ktorio/ktor/releases/tag/3.6.0), [releases](https://github.com/ktorio/ktor/releases) |
| 3.6.0 release date | **2026-09-16** ("Published" text on release page). **Conflict:** docs releases table says 2026-09-17; GitHub sidebar shows 18 Sep. NOT SOURCEABLE which is authoritative; use 2026-09-16 and re-check | [release page](https://github.com/ktorio/ktor/releases/tag/3.6.0), [docs releases table](https://ktor.io/docs/releases.html) |
| Previous patch | 3.5.2 — 2026-07-31 (GitHub) / 2026-08-04 (docs table) | [releases](https://github.com/ktorio/ktor/releases), [docs releases table](https://ktor.io/docs/releases.html) |
| 3.5.1 | 2026-06-25 (GitHub) / 2026-06-26 (docs) | same |
| 3.5.0 | 2026-05-14 (GitHub) / 2026-05-15 (docs) | same |
| 3.4.3 | 2026-04-22 | same |
| Ktor 4.0 | NOT SOURCEABLE — searched ktor.io/GitHub; only mention is "deprecated kotlinx-io-related APIs ... supported until Ktor 4.0" | [migration 3.0](https://ktor.io/docs/migrating-3.html) |
| Minimum JDK for Ktor 3.6 | NOT SOURCEABLE — ktor.io server-platforms page and What's New 3.6.0 state no JDK minimum; only the Java HTTP client engine is listed as Java 11+ (client engine page, not server) | [server platforms](https://ktor.io/docs/server-platforms.html), [What's new 3.6.0](https://ktor.io/docs/whats-new-360.html) |
| Minimum Kotlin for Ktor 3.6 | NOT SOURCEABLE for the core library. Only the type-safe auth API (experimental) requires Kotlin 2.4.0 or `-Xcontext-parameters` | [What's new 3.6.0](https://ktor.io/docs/whats-new-360.html) |

## Support / EOL

| Item | Value | Source |
|---|---|---|
| Support policy / EOL dates per minor | NOT SOURCEABLE — searched ktor.io releases, FAQ, and migration guides; no published support window found. Ktor follows semantic versioning (patches backward-compatible). | [releases](https://ktor.io/docs/releases.html) |
| Security fixes for 3.5.x after 3.6.0 | NOT SOURCEABLE | — |

## Recommended pin (recommendation, not a sourced fact)

- **New code: Ktor 3.6.0** (latest stable at verification date). Pin the exact version in `gradle/libs.versions.toml` (`ktor = "3.6.0"`); do not use ranges.
- Stay on **3.5.2+** if 3.6.0 causes issues; 3.5.x patches carry stability and rate-limit fixes (see 3.5.2 release note).
- Do not start new work on the 2.x line; migrate using `breaking-changes.md`.
- Kotlin: pair with a Kotlin version the Ktor release notes or your build tested. Because 3.6's experimental auth API needs Kotlin 2.4.0, do not enable that API unless you are on Kotlin 2.4+.

## Persistence pairing (verified versions, see best-practices.md)

| Component | Latest verified | Source |
|---|---|---|
| Exposed (`org.jetbrains.exposed:exposed-core`, `exposed-jdbc`, `exposed-dao`) | **1.5.1** (Maven `lastUpdated` 2026-10-09); 1.5.0 is the version the JetBrains get-started page shows | [Maven metadata](https://repo1.maven.org/maven2/org/jetbrains/exposed/exposed-core/maven-metadata.xml), [JetBrains get started](https://www.jetbrains.com/help/exposed/get-started-with-exposed.html) |
| HikariCP (`com.zaxxer:HikariCP`) | **7.1.0** (Maven `lastUpdated` 2026-06-14); 7.0.0 released 2025-07-28 per Maven Repository | [Maven metadata](https://repo1.maven.org/maven2/com/zaxxer/HikariCP/maven-metadata.xml), [Maven Repository](https://mvnrepository.com/artifact/com.zaxxer/HikariCP) |
| Ktor doc example Exposed pin | `exposed = 1.3.0` — **stale** vs 1.5.1; do not copy the doc's version | [Ktor database integration](https://ktor.io/docs/server-integrate-database.html) |

## Installed locally (checked 2026-10-11)

- Ktor: **NOT APPLICABLE** (library, not an installed binary). Project pins live in the consuming project's Gradle files.

## Verified sources

- https://github.com/ktorio/ktor/releases
- https://github.com/ktorio/ktor/releases/tag/3.6.0
- https://ktor.io/docs/releases.html
- https://ktor.io/docs/whats-new-360.html
- https://ktor.io/docs/whats-new-320.html
- https://ktor.io/docs/migrating-3.html
- https://ktor.io/docs/server-dependency-injection.html
- https://ktor.io/docs/server-platforms.html
- https://ktor.io/docs/server-integrate-database.html
- https://ktor.io/docs/server-opentelemetry.html
- https://blog.jetbrains.com/ktor/2026/09/18/ktor-3-6-0-is-now-available/
- https://repo1.maven.org/maven2/org/jetbrains/exposed/exposed-core/maven-metadata.xml
- https://repo1.maven.org/maven2/com/zaxxer/HikariCP/maven-metadata.xml
- https://www.jetbrains.com/help/exposed/get-started-with-exposed.html
