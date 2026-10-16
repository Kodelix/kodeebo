# Docker Compose stack — Breaking Changes

Verified 2026-10-11. Versions: Docker Engine 29.9.0, Compose v5.6.0, Caddy v2.11.7, Traefik v3.7.14 (see `VERSION.md`).

## Compose

| Change | Since | Effect | Source |
|---|---|---|---|
| Compose v1 (`docker-compose` binary) "no longer maintained" | Retired | Use `docker compose` (Compose v2+ plugin). End-of-support date: NOT SOURCEABLE. | https://docs.docker.com/retired/ |
| Top-level `version:` key is obsolete | Current spec | Informational only. Using it triggers an obsolescence warning. Compose validates against the latest schema regardless. Remove it. | https://docs.docker.com/reference/compose-file/version-and-name/ |
| Project name from top-level `name:` | Current spec | If unset, a default name is used. Derivation of the default is NOT SOURCEABLE from that page (a separate how-to covers overrides). | https://docs.docker.com/reference/compose-file/version-and-name/ |
| Compose line is v5, not v2 | v5.0.0 | Version numbers 3.0 and 4.0 were skipped to avoid confusion with legacy Compose file versions. | https://github.com/docker/compose/releases/tag/v5.0.0 |
| Internal BuildKit builder dropped; builds go through Docker Bake | v5.0.0 (release dated "02 Dec", year not shown) | Build paths now use Bake, the same mechanism as `docker build`. | https://github.com/docker/compose/releases/tag/v5.0.0 |
| Warnings on unsupported compose-file attributes | v5.6.0 | Unknown or newer-spec fields now produce warnings. | https://github.com/docker/compose/releases |
| `down` dangling-image removal changed | v5.6.0 | Title only ("#14266"); exact behavior NOT SOURCEABLE from the release page. | https://github.com/docker/compose/releases |
| `docker compose port`: `PRIVATE_PORT` optional | v5.6.0 | Scripts that assumed it was required still work; behavior change in argument parsing. | https://github.com/docker/compose/releases |
| Dry-run commit no longer creates a real image | v5.6.0 | Scripts relying on dry-run producing an image will break. | https://github.com/docker/compose/releases |
| Jobs: only manually triggered jobs supported | v5.6.0 | Partial feature support. | https://github.com/docker/compose/releases |
| `depends_on` short syntax does not wait for health | Current | Only long syntax with `condition: service_healthy` waits for a healthcheck. | https://docs.docker.com/reference/compose-file/services/ ; https://docs.docker.com/compose/how-tos/startup-order/ |
| `up --wait` implies detached mode | Current | Passing `-d` with `--wait` is unnecessary. Failure behavior of `--wait` (timeout, failed service): NOT SOURCEABLE from the CLI reference. | https://docs.docker.com/reference/cli/docker/compose/up/ |

## Docker Engine 29.x

| Change | Since | Effect | Source |
|---|---|---|---|
| API minimum raised to v1.44 (Docker v25.0+) | 29.0.0 | Older clients fail. | https://docs.docker.com/engine/release-notes/ |
| API minimum lowered back to v1.40 (Docker 19.03) | 29.3.0 | Restores compatibility with older clients. | https://docs.docker.com/engine/release-notes/ |
| cgroup v1 deprecated; support until at least May 2029 | 29.0.0 | Migrate hosts to cgroup v2. | https://docs.docker.com/engine/release-notes/ |
| Docker Content Trust removed from the CLI | 29.0.0 | Can be built as a separate plugin. | https://docs.docker.com/engine/release-notes/ |
| Legacy link environment variables no longer added automatically | 29.0.0 | A daemon environment variable can restore them temporarily. | https://docs.docker.com/engine/release-notes/ |
| Default container open-file limit changed from 1048576 to 1024 (via containerd v2.1.5) | 29.0.0 | Services that need more file descriptors must set `ulimits` explicitly. | https://docs.docker.com/engine/release-notes/ |
| Official 32-bit Raspbian packages dropped; armhf targets ARMv7 | 29.0.0 | Not relevant to x86 VPS. | https://docs.docker.com/engine/release-notes/ |
| Deprecation warning for containers linked on the default bridge | 29.6.0 | Migrate to user-defined networks. | https://docs.docker.com/engine/release-notes/ |

## Build attestations (buildx)

| Change | Effect | Source |
|---|---|---|
| Provenance is on by default, at `min` mode | `--provenance=mode=max` must be requested explicitly. | https://docs.docker.com/build/metadata/attestations/ |
| SBOM is off by default | Enable with `--sbom=true`. | https://docs.docker.com/build/metadata/attestations/ |
| Default `docker` driver fails with attestations unless the containerd image store is enabled | Use `docker-container` builder for attestations. | https://docs.docker.com/build/metadata/attestations/ |
| `BUILDX_NO_DEFAULT_ATTESTATIONS` env var disables default attestations | Opt-out for default attestations. | https://docs.docker.com/build/metadata/attestations/ |

## Caddy

| Change | Effect | Source |
|---|---|---|
| Automatic HTTPS needs ports 80 and 443 reachable (HTTP-01 and TLS-ALPN-01 are on by default) | Blocked ports mean no public certificate unless DNS challenge is configured. | https://caddyserver.com/docs/automatic-https |
| DNS challenge disables the other challenges by default | Required for wildcard certificates. | https://caddyserver.com/docs/automatic-https |
| `localhost`, `*.localhost`, `*.local`, `*.internal`, `*.home.arpa`, IP addresses get local-CA certificates | No public trust; clients need Caddy's root CA. | https://caddyserver.com/docs/automatic-https |
| On config reload, WebSocket connections are closed by default | `stream_close_delay` (default: none) keeps them open. | https://caddyserver.com/docs/caddyfile/directives/reverse_proxy |

## Traefik v3 (from v2)

The v2-to-v3 migration page fetched for this document redirected and did not list changes. The fetched v3 migration page (`https://doc.traefik.io/traefik/migrate/v3/`) was truncated before the v3.0 and v3.1 sections. Therefore the removed options (ACME, Consul, Marathon, Ingress, TLS options) and the default changes in those sections are NOT SOURCEABLE from this session.

| Change | Since | Effect | Source |
|---|---|---|---|
| Docker provider `exposedByDefault` defaults to `true` | Current | Every container on the network gets routed unless `traefik.enable=false`. Set `exposedByDefault=false` and label opt-in with `traefik.enable=true`. | https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/ |
| Docker provider requires Docker API v1.40+ | v3.6.16 | Override with `DOCKER_API_VERSION` on older engines. | https://doc.traefik.io/traefik/migrate/v3/ |
| `compress` default encodings are `gzip, br, zstd` | v3.3.5 | Clients receive new encodings. | https://doc.traefik.io/traefik/migrate/v3/ |
| `traceVerbosity` defaults to `minimal` | v3.5.0 | Fewer spans than before. | https://doc.traefik.io/traefik/migrate/v3/ |
| `sanitizePath` on by default (collapses `/../` and `//`) | v3.3.6 | Disabling is discouraged. | https://doc.traefik.io/traefik/migrate/v3/ |
| `core.defaultRuleSyntax` and router `ruleSyntax` deprecated; `core.defaultRuleSyntax: v2` is the compatibility switch | v3.4 | Remove the setting after migrating all routers. | https://doc.traefik.io/traefik/migrate/v3/ ; https://doc.traefik.io/traefik/migrate/v2-to-v3/ (redirected to migrate/v3) |
| MultiPath TCP support removed | v3.4.5 | Re-enable only via `GODEBUG` `multipathtcp`. | https://doc.traefik.io/traefik/migrate/v3/ |
| ForwardAuth `trustForwardHeader` deprecated; set explicitly | v3.6.14 | Silences the warning. | https://doc.traefik.io/traefik/migrate/v3/ |
| BasicAuth with empty `users` fails to build; clients get 404 instead of 401 | v3.7.3 | Check auth-protected routes. | https://doc.traefik.io/traefik/migrate/v3/ |
| `Host(\`*\`)` matches every request (previously single-segment hosts only) | v3.7.7 | Routing scope widened. | https://doc.traefik.io/traefik/migrate/v3/ |
| `aliasHeadersStrategy` replaces deprecated `underscoreHeadersStrategy` | v3.7.12 | Both set with different values makes config invalid. | https://doc.traefik.io/traefik/migrate/v3/ |
| HTTP/1 `CONNECT` rejected with 501 | v3.7.9 | | https://doc.traefik.io/traefik/migrate/v3/ |
| Rootless request targets rejected with 400 | v3.7.13 | | https://doc.traefik.io/traefik/migrate/v3/ |
| Ingress-NGINX resource names keep dots (no dash conversion) | v3.7.14 | Dashboards, alerts, API queries using old names need updates. Taken from a WebSearch summary of the v3.7 migration guide, not a direct fetch. | https://doc.traefik.io/traefik/v3.7/migrate/v3/ (search summary only) |

## Verified sources

- https://docs.docker.com/engine/release-notes/
- https://docs.docker.com/reference/compose-file/version-and-name/ · /services/ · /deploy/
- https://docs.docker.com/compose/how-tos/startup-order/
- https://docs.docker.com/reference/cli/docker/compose/up/
- https://docs.docker.com/build/metadata/attestations/
- https://github.com/docker/compose/releases · /tag/v5.0.0
- https://docs.docker.com/retired/
- https://caddyserver.com/docs/automatic-https · /docs/caddyfile/directives/reverse_proxy
- https://doc.traefik.io/traefik/migrate/v3/ · /reference/install-configuration/providers/docker/

## Knowledge gap warning

NOT SOURCEABLE items are marked inline. The Traefik v3 removed-option list (ACME, Consul, Marathon, Ingress, TLS) was not reached in this session; check the full migration guide before relying on it. The Ingress-NGINX row above came from a search-result summary of the Traefik migration guide, not a direct fetch of the section.
