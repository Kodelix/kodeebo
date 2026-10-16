---
paths:
  - "deploy/**"
  - "**/Dockerfile*"
  - "**/compose*.yml"
  - "**/compose*.yaml"
  - "**/docker-compose*.y*ml"
---

# Deployment Rules (Docker Compose on VPS; same bundle = self-hosted installer)

- Images: multi-stage builds, minimal or distroless runtime, non-root user, read-only root filesystem where possible, pinned base image digests, no secrets in layers or build args.
- Compose: every service has `healthcheck`, `restart` policy, resource limits, and explicit networks; databases are not published on host ports in production.
- Reverse proxy (Caddy/Traefik per ADR) terminates TLS, sets security headers, rate-limits, and serves the static SPA and site.
- Secrets via Docker secrets / env files with `0600` permissions outside the repo; `.env.example` documents every variable without values.
- Migrations run as a one-shot job before the new app version starts; deploys are zero-downtime (start new → health → switch → stop old).
- Backups: automated, encrypted, off-host, with **restore tested** on a schedule; documented RPO/RTO.
- Observability: OTel collector service in the bundle; log rotation configured.
- Self-hosted bundle: versioned, signed, with an install/upgrade script that verifies signatures, runs preflight checks (CPU/RAM/disk/ports), backs up before upgrade, and supports rollback. Telemetry off by default.
- Never `docker compose down -v` or prune volumes in scripts.

## Hosted vs customer bundle

- `deploy/hosted/` — our own infrastructure. Any engine in `docs/stack-reference/pins.yaml` is allowed.
- `deploy/self-hosted/` — the bundle customers install. Licence decisions (docs/ROADMAP.md, 2026-10-11):
  - Cache: **Valkey** only (`valkey/valkey`, BSD-3). No Redis ≥ 7.4, no Dragonfly. Up to **two Valkey instances**, never one doing both jobs: a cache instance (`allkeys-lru`, loss-tolerant) and, when queues, idempotency keys or sessions need to survive a restart, a durable instance (`noeviction`, persistence on). Both are `valkey/valkey` from `bundle.allowlist`.
  - Object storage: **not bundled.** The customer points the bundle at their own S3-compatible store through configuration. MinIO is AGPL and is never in the bundle; a bundled alternative needs a licence check via `/research` and an entry in `bundle.allowlist` first.
  - MongoDB: `image:` reference to the **official** image only — never a Mongo binary, tarball, or image we build.
  - Observability: the **OTel Collector** only, exporters disabled by default. No Grafana/Loki/Tempo/Mimir.
  - PostgreSQL, Caddy/Traefik: allowed.
- Code must therefore run on Valkey: stay within the portable command subset (`docs/stack-reference/redis/best-practices.md` portability section).
- `project-coherence.sh` reports any engine in `deploy/self-hosted/` that breaks these rules.
