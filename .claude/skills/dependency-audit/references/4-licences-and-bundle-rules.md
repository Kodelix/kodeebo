# /dependency-audit - Phase 4: Licences and Customer-Bundle Rules

> Phase 4 of `SKILL.md`. A licence review here is a **flag list for the user and
> counsel**, not legal advice. Terms are read from the licence text or the
> package's official page, with the URL fetched; never recalled.

## 1. Customer-bundle rules (derived from `.claude/docs/standing-decisions.md`, decided 2026-10-11)

The customer bundle is `deploy/self-hosted/` (`.claude/rules/deploy.md`).
`deploy/hosted/` is our infrastructure: any engine in `pins.yaml` is allowed.

| Rule | Requirement for `deploy/self-hosted/` | Evidence |
|---|---|---|
| L1 | Cache is **Valkey** only (`valkey/valkey`, BSD-3); no Redis 7.4 or newer, no Dragonfly | every `image:` in the self-hosted compose files; `project-coherence.sh` `LICENCE` lines |
| L2 | Dragonfly is **hosted only** (BSL 1.1) | same |
| L3 | MongoDB only as an `image:` reference to the **official** image; never a Mongo binary, tarball, or an image we build or derive | compose files, Dockerfiles, installer scripts, `COPY`/`ADD` lines, release assets |
| L4 | Observability is the **OTel Collector only**, exporters off by default; no Grafana, Loki, Tempo or Mimir | compose files, collector config, installer |
| Allowed | PostgreSQL, Caddy/Traefik | - |

Procedure: list every image and every Dockerfile `FROM`/`COPY` in
`deploy/self-hosted/` and in whatever the installer fetches; classify each
against the table; cite `file:line`. An engine that is not on the table and not
in `pins.yaml` is `unclassified` -> asked, not assumed allowed. A breach is HIGH
(`FIX BEFORE SHIPPING`) and, for L3 (shipping a Mongo binary), is reported with
the rule number. Also confirm the bundle ships telemetry off and no phone-home
(`deploy.md`). If `deploy/self-hosted/` does not exist or `distribution.model` is
`hosted`, write `not applicable - <config value>`; if `distribution` is unset, ask.

## 2. Dependency licences (shipped code)

**What is shipped**: the Go/Ktor binaries and images, the static SPA and site
bundles, the mobile apps, the self-hosted bundle and installer. Code that only
runs on our own servers is not distributed, but a network-use licence still needs a
recorded decision; flag it and say why.

1. Take the **direct** dependencies from the inventory (`go.mod` requires, Gradle
   version-catalog entries, `package.json` dependencies, `Package.swift`, and
   images). Transitive dependencies are **unreviewed** unless a sourced licence
   tool is available: the stack reference names none (`NOT SOURCEABLE - no sourced
   licence-inventory tool for Go, Gradle, pnpm or SwiftPM`). Offer `/research` to
   choose one; until then the report says "transitive licences not reviewed".
2. For each direct dependency read the licence from the repository's licence file
   or the package page. If the licence is not readable locally (module cache,
   `node_modules` licence files, the Gradle cache), hand the list to `researcher`
   (Phase 5) to fetch it with the URL, or fetch it yourself with `WebFetch`. A
   licence that could not be established is `unknown` and counts as unreviewed.
3. Classify (a flag list, in this order):
   - **permissive** (e.g. MIT, BSD, Apache-2.0, ISC): no flag; list name and SPDX ID as read.
   - **weak copyleft** (e.g. LGPL, MPL): flag when shipped in a distributed bundle; record the linking/distribution fact the licence text asks about.
   - **strong copyleft / network copyleft** (GPL, AGPL, SSPL): flag HIGH when shipped in a customer bundle or a mobile app, MEDIUM when only used on our hosted servers (state the licence's network-use clause by quoting at most one short line, with the URL).
   - **source-available / non-open-source** (BSL, RSAL, commercial, "no licence"): flag HIGH when shipped.
   - **unknown / none stated**: flag; no licence means no permission.
4. A flag is not a verdict: ask the user for the decision (replace, accept with
   counsel, or hosted-only), record it with owner and date, and never infer one.
   A recorded decision with an expiry removes the open flag until it expires.

## 3. Output of this phase

- Bundle-rule table (L1-L4: rule - evidence `file:line` - met / breached / not
  applicable (reason) / not run (reason)).
- Licence table (dependency - version - ecosystem - SPDX as read - source URL -
  shipped where - class - flag - decision).
- Counts: direct reviewed N of M; transitive: not reviewed (reason).
