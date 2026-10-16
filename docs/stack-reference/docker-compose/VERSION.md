# Docker Compose stack — Version Reference

Last verified: 2026-10-11
Scope: Docker Engine, Docker Compose, Caddy, Traefik (single-VPS Compose deployment and self-hosted installer bundle).
Method: every value below was fetched on 2026-10-11 from the listed source. GitHub release pages show day and month without a year; the year is taken from the asset timestamps on the same page.

## Versions

| Component | Latest stable | Released | Source |
|---|---|---|---|
| Docker Engine | 29.9.0 | 2026-10-08 | https://docs.docker.com/engine/release-notes/ (page states 29.9.0 with this date) |
| Docker Compose | v5.6.0 (marked Latest) | 2026-10-02 | https://github.com/docker/compose/releases |
| Caddy | v2.11.7 (marked Latest; major line still v2) | 2026-10-03 | https://github.com/caddyserver/caddy/releases |
| Traefik Proxy v3 | v3.7.14 (marked Latest) | 2026-10-06 | https://github.com/traefik/traefik/releases |
| Traefik Proxy v2 maintenance line | v2.11.58 | 2026-10-06 | https://github.com/traefik/traefik/releases |

Notes:
- The Compose line is **v5**, not v2. The v2 naming in the brief is outdated. v5.0.0 skipped 3.0 and 4.0 to avoid confusion with legacy Compose file versions (https://github.com/docker/compose/releases/tag/v5.0.0). The year of the v5.0.0 date is not shown on the page ("02 Dec").
- The docs.docker.com Compose release-notes URL redirects to the GitHub releases page. Use the GitHub page as the source.
- The Caddy listing skips v2.11.5 (v2.11.4 appears as "03 Jun", year not shown). Use v2.11.7.
- Traefik v3.7.14 is the latest stable v3.x release on the releases page. The page does not mark it prerelease.

## Installed locally (2026-10-11, this machine)

| Tool | Installed | Latest | Match |
|---|---|---|---|
| `docker --version` | 29.9.0, build f415da838b | 29.9.0 | yes |
| `docker compose version` | v5.6.0 | v5.6.0 | yes |
| `caddy version` | NOT INSTALLED | v2.11.7 | n/a |
| `traefik version` | NOT INSTALLED | v3.7.14 | n/a |

## Release-line facts that gate pins

- Docker Engine 29.x: API minimum was v1.44 at 29.0.0 and was lowered to v1.40 (Docker 19.03) at 29.3.0 (https://docs.docker.com/engine/release-notes/).
- Docker Engine 29.x: cgroup v1 deprecated at 29.0.0, support until at least May 2029 (same source).
- Traefik v3.6.16: Docker provider requires Docker API v1.40+; older engines can override with `DOCKER_API_VERSION` (https://doc.traefik.io/traefik/migrate/v3/).
- Compose v1 (`docker-compose` binary): "no longer maintained" per https://docs.docker.com/retired/. End-of-support date: NOT SOURCEABLE — the retired-products page states no date. Searched: docs.docker.com/retired, WebSearch "Docker Compose v1 end of life removed compose v1 deprecation 2026" (returned only 2023–2025 material and no official 2026 date).
- Compose release-notes page: the docs.docker.com/compose release-notes URL redirects to GitHub. Release notes for v5.x show no "Breaking" label on v5.6.0 (https://github.com/docker/compose/releases).

## Verified sources

- https://docs.docker.com/engine/release-notes/
- https://github.com/docker/compose/releases · https://github.com/docker/compose/releases/tag/v5.0.0
- https://docs.docker.com/retired/
- https://github.com/caddyserver/caddy/releases
- https://github.com/traefik/traefik/releases · https://doc.traefik.io/traefik/migrate/v3/

## Knowledge gap warning

The model's training data predates these versions (Engine 29.x, Compose v5.x, Caddy 2.11.x, Traefik 3.7.x). Do not write Compose keys, Caddyfile directives, or Traefik labels from memory. Re-check `breaking-changes.md` and `deprecated-apis.md` first. NOT SOURCEABLE items are marked inline; treat them as unknown, not absent.
