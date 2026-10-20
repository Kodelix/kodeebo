# /create-architecture — Phase 5: Deployment Topology (Hosted and Self-Hosted)

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Deployment Topology (Hosted and Self-Hosted)

Read `deploy.target` and `distribution.model` from the config block. If either is
empty, stop and send the user to `/setup-stack`. Follow `.claude/rules/deploy.md`:
`deploy/hosted/` is our infrastructure (any engine in `pins.yaml` allowed);
`deploy/self-hosted/` is the customer bundle and the licence decisions in
`.claude/docs/standing-decisions.md` bind it.

### 5a. Hosted topology (when `distribution.model` is `hosted` or `hybrid`)

Services, networks, volumes, reverse proxy (TLS, security headers, rate limits,
static SPA and site), databases (not published on host ports), OTel collector,
backups (encrypted, off-host, **restore tested**, RPO/RTO), environments
(dev, staging, production), zero-downtime deploy (new → health → switch → old),
one-shot migration job, secrets handling. Diagram as Mermaid.

### 5b. Self-hosted topology (when `distribution.model` is `self-hosted` or `hybrid`)

The same Compose bundle, reduced to what a customer can run. State, per service:

| Service | Hosted image | Bundle image | Licence in bundle | Allowed? |
|---|---|---|---|---|

with these rules checked row by row — a violation is a blocking finding:

- Cache: **Valkey** (BSD-3) only. No Dragonfly, no Redis >= 7.4.
- MongoDB: the **official image referenced** (customer pulls it); never a Mongo binary, tarball or an image we build/derive.
- Observability: **OTel Collector only**, exporters off by default. No Grafana/Loki/Tempo/Mimir.
- PostgreSQL and Caddy/Traefik: allowed.
- Telemetry off by default; nothing phones home without opt-in.
- Offline / air-gapped: which features work without internet; licence validation offline (signed Ed25519 licence, grace period); update channel optional.
- Preflight checks (CPU/RAM/disk/ports), signed bundle with signature verification, backup before upgrade, rollback.
- Licensing module: `licensing-specialist` owns activation and entitlement enforcement; consult via `Agent` when licences are in scope.

If `distribution.model` is `hosted`, write: "Self-hosted edition not in scope —
`distribution.model: hosted`" in the document. Never leave the subsection silently
absent.

### 5c. Self-hosted upgrade path

Customers lag. Specify:
- Supported upgrade jumps (from which versions, to which), and the policy for skipped versions
- Migration strategy that works across those jumps (expand→migrate→contract; no migration that needs the previous app version to be running; a migration that cannot run offline is a finding) — consult `migration-specialist` via `Agent` for multi-version upgrades
- Pre-upgrade backup, preflight, post-upgrade smoke check, rollback including data
- API and contract compatibility window for customer integrations and mobile clients still on older versions
- Release channel, signing and SBOM (CycloneDX) per release; how `release-manager` ships it
- Core pin: how a `saas-core` version bump reaches the bundle

### 5d. Shared-core modules and the deploy footprint

For each `saas-core` module in use (`core.modules`), state whether it adds a
service, a table set or a dependency to either edition. A module that cannot
satisfy the bundle licence rules is raised as a `/core-extract` or `/core-upgrade`
item, not worked around in the product.

### 5e. Environments, CI and secrets (summary)

CI pipeline stages (build, test per layer, Testcontainers, contract diff, scans:
`govulncheck`/OSV/image/gitleaks), pinned third-party actions, SBOM, signing keys
offline or in a KMS. One paragraph at `standard`; owner `platform-lead`; consult
`infra-engineer` for the Compose detail when the bundle is in scope.

Get user approval on hosted topology, self-hosted topology and upgrade path as
separate asks, then record them in `production/session-state/active.md`; they are
written at Phase 8. Deployment topology is a critical ADR.

---
