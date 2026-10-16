# Docker Compose stack — Deprecated APIs and Settings

Verified 2026-10-11. Format: Deprecated → Replacement → Since → Source. Rows marked NOT SOURCEABLE were not stated by a fetched page.

| Deprecated | Replacement | Since | Source |
|---|---|---|---|
| `docker-compose` binary (Compose v1) | `docker compose` (Compose v2+ plugin; current line v5.6.0) | NOT SOURCEABLE (retired page states "no longer maintained" with no date) | https://docs.docker.com/retired/ ; https://github.com/docker/compose/releases |
| Top-level `version:` key in Compose files | Omit the key. Compose validates against the latest schema. | Current spec (marked obsolete) | https://docs.docker.com/reference/compose-file/version-and-name/ |
| Swarm mode (SwarmKit) as a strategy | No replacement named. Kubernetes-based solutions cited as direction. | Development slowed; still functional (page date not stated) | https://docs.docker.com/retired/ |
| cgroup v1 host support | cgroup v2 | 29.0.0 (support until at least May 2029) | https://docs.docker.com/engine/release-notes/ |
| Docker Content Trust in the Docker CLI | Separate plugin build | 29.0.0 (removed from CLI) | https://docs.docker.com/engine/release-notes/ |
| Automatic legacy link environment variables | Not stated. Daemon environment variable restores them temporarily. | 29.0.0 | https://docs.docker.com/engine/release-notes/ |
| Containers linked on the default bridge (`--link` on default bridge) | NOT SOURCEABLE (page states warning only; user-defined network replacement not stated in the release notes) | 29.6.0 (warning added) | https://docs.docker.com/engine/release-notes/ |
| Traefik: `core.defaultRuleSyntax` and router-level `ruleSyntax` | Migrate routers to v3 rule syntax, then remove the setting | v3.4 | https://doc.traefik.io/traefik/migrate/v3/ |
| Traefik: `underscoreHeadersStrategy` (entry point option) | `aliasHeadersStrategy` | v3.7.12 | https://doc.traefik.io/traefik/migrate/v3/ |
| Traefik: ForwardAuth `trustForwardHeader` | Set `trustedIPs` under `forwardedHeaders` on the entry point | v3.6.14 | https://doc.traefik.io/traefik/migrate/v3/ |
| Traefik: `proxyProtocol` on TCP load balancer | TCP ServersTransport | v3.5.2 | https://doc.traefik.io/traefik/migrate/v3/ |
| Traefik: Ingress-NGINX dot-to-dash conversion in generated names | Names keep dots (behavior change, not a deprecation). Dashboards and API queries update. | v3.7.14 | https://doc.traefik.io/traefik/v3.7/migrate/v3/ (search summary only; not fetched directly) |
| Traefik: `Host(\`*\`)` single-segment matching | Matches all hosts (behavior change, not a deprecation) | v3.7.7 | https://doc.traefik.io/traefik/migrate/v3/ |
| Traefik: Docker provider on Docker API < v1.40 | Set `DOCKER_API_VERSION` override on older engines | v3.6.16 | https://doc.traefik.io/traefik/migrate/v3/ |
| Compose `deploy.resources` / `deploy.update_config` outside Swarm | NOT SOURCEABLE (deploy reference does not name the platform) | n/a | https://docs.docker.com/reference/compose-file/deploy/ |

## Searched without a result

- Compose v1 official end-of-support date: searched docs.docker.com/retired and WebSearch "Docker Compose v1 end of life removed compose v1 deprecation 2026". No official 2026 date found.
- Traefik v2-to-v3 removed options (ACME, Consul, Marathon, Ingress, TLS): the migrate page fetched was truncated before the v3.0 and v3.1 sections. Not sourced.
