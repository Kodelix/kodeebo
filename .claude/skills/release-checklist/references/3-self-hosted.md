# /release-checklist — Track 2: Self-Hosted Bundle

> Emitted when `distribution.model` is `self-hosted` or `hybrid`. The bundle is
> `deploy/self-hosted/`. Sources: `.claude/rules/deploy.md`, `docs/ROADMAP.md`
> licence decisions L1–L4, `.claude/docs/security-baseline.md` (signed bundles,
> SBOM, licence keys), `.claude/agents/release-manager.md`.
>
> **Customers upgrade across several versions and cannot be hot-fixed by us.**
> "Works on hosted" is not evidence for self-hosted: every item below needs a
> clean-host install or upgrade, not a hosted result.

`[?]` = not assessed; unticked = work remains.

## Bundle contents — licence rules L1–L4 (checked, not assumed)

Run `bash .claude/scripts/project-coherence.sh` and **quote every `LICENCE` line
verbatim** (none = "no LICENCE lines" with the script's `SKIPPED` lines if it
could not run). Then read `deploy/self-hosted/` compose files, Dockerfiles and
the installer yourself:

- [ ] **L1** Cache is **Valkey** (`valkey/valkey`, BSD-3) only — no Redis ≥ 7.4
- [ ] **L2** No **Dragonfly** anywhere in the bundle (hosted only; BSL 1.1)
- [ ] **L3** MongoDB, if used: an `image:` reference to the **official** image only — no Mongo binary, tarball or image we build or derive
- [ ] **L4** Observability: the **OTel Collector** only, exporters disabled by default — no Grafana/Loki/Tempo/Mimir; telemetry **off by default**, never phones home without explicit opt-in; the collector config ships so the customer can point it at their own backend
- [ ] PostgreSQL and Caddy/Traefik only otherwise; image tags pinned by digest; no `latest` / bare-major tags (`FLOATING` lines)
- [ ] Code runs on Valkey within the portable command subset (`docs/stack-reference/redis/best-practices.md` portability section) — the bundle's integration run was against Valkey, not hosted Redis

## Signed, reproducible, attributable

- [ ] Bundle built from the tagged commit `[hash]`; compose files, images and installer versions all equal `[version]`; reproducible
- [ ] Bundle **and** installer signed; **detached signature**, public-key **fingerprint** and checksums published with the release; the installer **verifies the signature before applying anything**, tested on a clean machine (including a tampered bundle that is refused)
- [ ] Signing happens in the pipeline owned by `platform-lead`; the Ed25519 licence signing key and the bundle signing key are **not in the repository or CI logs**
- [ ] CycloneDX SBOM generated for the release and attached; licences of redistributed components reviewed against the redistribution decisions above
- [ ] Third-party notices and attributions current

## Installer preflight, install, rollback

- [ ] Installer **preflight** checks CPU / RAM / disk / ports and refuses with a clear message below the documented minimum; the minimum is backed by a load run at that size (`performance-engineer`)
- [ ] **Fresh install** tested on a clean host at the documented minimum spec, from the signed bundle
- [ ] **Offline / air-gapped** install tested (images included, or a documented mirror)
- [ ] **Backup before upgrade** is taken (or verified) by the upgrade script; **rollback** supported and tested — and the notes say plainly which steps cannot be rolled back (migrations are forward-only: restore from the pre-upgrade backup)
- [ ] Default credentials absent; secrets generated at install; TLS configured; databases not published on host ports; no `down -v` in any script
- [ ] The customer backup/restore procedure is documented, and the restore was exercised on a bundle install

## Staged rollout through the update channel

- [ ] The bundle is published to the **early/beta channel first** (our own install plus opted-in design-partner installs), with a written hold time before promotion to stable. Telemetry is off by default, so health comes from those installs and support reports, not from phoning home
- [ ] **Rollback triggers written before publication**: a failed clean-host install or upgrade in the matrix, a failed-migration report, a signature or checksum failure, or a support-confirmed regression. Action: withdraw the bundle from the channel, publish the advisory with the restore-from-pre-upgrade-backup steps; owner named
- [ ] **Post-publication verification**: the published artefact downloaded back from the channel, signature and checksum verified, installed and upgraded on a clean host; result retained
- [ ] Risky user-visible changes ship behind a flag that is off by default **in the product's own config** (not a hosted-only flag service), with the flag-off path covered by the upgrade tests

## Upgrade-path matrix (including skipped versions)

Maintain the matrix in `production/releases/` and in the customer upgrade notes.
For **every supported from-version** list the path to `[version]`:

| From | To `[version]` | Direct? | Required intermediate version(s) | Migration notes / downtime | Tested (CI install/upgrade job, date, evidence) |
|------|----------------|---------|----------------------------------|----------------------------|-----------------------------------------------|
| `[oldest supported]` | | | | | |
| `[previous]` | | | | | |
| `[N versions back]` — **skipped versions** | | | | | |

- [ ] The matrix lists the **oldest supported version** and every supported version between it and `[version]` — a customer who skipped releases has a stated path, not an assumption
- [ ] A **minimum upgrade-from version** is stated; anything older is marked **unsupported** with the stepping-stone version
- [ ] **Each listed path is covered by an automated install/upgrade test** (data migrated, app starts, `/readyz` green). A path with no test is listed as `untested` and is a CONCERNS item at least; an untested *supported* path is a blocker for a major release
- [ ] Expand → migrate → contract: no step of the matrix removes something an old-but-supported version still reads
- [ ] Deprecations and removals carry a `Sunset` date and a replacement (`api-standards.md`), shown in the notes

## Licence verification matrix

Tested against the **built bundle**, with outcomes recorded:

| Case | Expected | Result |
|---|---|---|
| valid | full function | |
| expired, within grace window | function + warning | |
| expired, past grace | restricted per spec | |
| revoked | per spec (offline revocation rule stated) | |
| tampered (payload or signature edited) | refused | |
| algorithm downgrade / wrong key | refused | |
| clock rolled back inside the offline grace window | detected / handled per spec | |
| replayed activation | handled per spec | |

- [ ] The product verifies with the **embedded public key**; entitlement checks cannot be bypassed by editing config; the update channel verifies signatures
- [ ] Dynamic bypass testing (patched checks, removed update verification) is a `/pentest` item with results to `licensing-specialist` — `[done / not done]`
- [ ] Update eligibility rules for one-time licences vs subscriptions behave per `licence-model` (`.claude/docs/templates/licence-model.md`)

## Customer-facing material and release channel

- [ ] Upgrade notes (`/release-notes`): minimum upgrade-from version, migrations/downtime, config changes (new/renamed/removed), deprecations with sunset dates, licence changes, rollback support
- [ ] Notes do not announce a feature as available if it is licence-gated or hosted-only
- [ ] Bugs fixed on hosted since the last bundle are listed in the notes (self-hosted customers still carry them until this release); security fixes flagged with severity, who is affected and the action required (customer notification decided by `security-lead`)
- [ ] Release published to the release channel with checksums and signatures attached — **only on the user's explicit instruction naming this version and the channel**; this skill never publishes
