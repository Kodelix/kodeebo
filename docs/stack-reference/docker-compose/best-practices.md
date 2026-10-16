# Docker Compose stack — Best Practices (single VPS, self-hosted bundle)

Verified 2026-10-11. Every rule below cites a fetched page. Items without a citation are marked NOT SOURCEABLE with what was searched.

## 1. Healthchecks and start order

- Declare `healthcheck` on every stateful and API service. `test` is a list starting with `CMD` or `CMD-SHELL`, or a string (treated as `CMD-SHELL`). `NONE` or `disable: true` turns off an inherited check. Source: https://docs.docker.com/reference/compose-file/services/
- Use long `depends_on` syntax with `condition: service_healthy` to wait for readiness. `service_started` only waits for the process to run. `service_completed_successfully` is for one-shot jobs (migrations). Source: https://docs.docker.com/compose/how-tos/startup-order/
- Short `depends_on` syntax does not wait for health. Source: https://docs.docker.com/reference/compose-file/services/
- Healthcheck durations: `interval`, `timeout`, `start_period`, `start_interval` (since Compose 2.20.2). Defaults follow the Dockerfile `HEALTHCHECK` defaults, which this session did not fetch: exact defaults NOT SOURCEABLE. Source: services reference.
- Deploy with `docker compose up --wait` and treat a non-zero exit as failure. `--wait` waits for services to reach running or healthy and implies detached mode. Its behavior when a service fails or times out: NOT SOURCEABLE (CLI reference is silent). Sources: https://docs.docker.com/reference/cli/docker/compose/up/ ; startup-order page.

## 2. Secrets

- Declare secrets at top level with `file:` or `environment:`. Grant per service with the service's `secrets:` list. Source: https://docs.docker.com/compose/how-tos/use-secrets/
- Compose bind-mounts each secret as a single file at `/run/secrets/<secret_name>`. Linux containers only. Source: same page.
- Prefer secrets over environment variables. Env vars are visible to all processes, can leak into logs, and can be exposed unintentionally. Source: same page.
- Image conventions such as `_FILE` env vars (MySQL, Postgres) are image-specific, not a Compose feature. Source: same page.

## 3. Resource limits and hardening (service attributes)

- Set `mem_limit`, `cpus`, `pids_limit`. If both a service attribute and `deploy.resources.limits` are set, the values must match. `pids_limit: -1` means unlimited. Source: https://docs.docker.com/reference/compose-file/services/
- Whether `deploy.resources` limits are honored by plain `docker compose` (non-Swarm): NOT SOURCEABLE. The deploy reference does not name the platform. Searched: docs.docker.com/reference/compose-file/deploy/.
- Memory limit behavior: by default, on OOM the kernel kills processes in the container. Set `-m` with `--oom-kill-disable` only. Source: https://docs.docker.com/engine/containers/resource_constraints/
- `read_only: true` creates a read-only root filesystem. Writes behavior and which paths to mount as tmpfs/volumes: NOT SOURCEABLE beyond the attribute description. Source: services reference.
- `user:` sets the process user. Unset means the image default, or root if the image sets none. Source: services reference.
- `security_opt: [no-new-privileges:true]` enables the no-new-privileges flag. Source: services reference.
- `cap_drop:` removes listed Linux capabilities (example: `NET_ADMIN`). Source: services reference.
- `init: true` runs an init as PID 1 that forwards signals and reaps children. Source: services reference.
- `stop_grace_period` defaults to 10 seconds before SIGKILL. Source: services reference.

## 4. Images: pinning, non-root, minimal base

- Pin images by digest: `image: name@sha256:...`. A digest pins one version, so Docker does not fetch newer builds. Updates require changing the digest manually, which can mean missing security fixes. Automate with Dependabot or equivalent. Sources: https://docs.docker.com/reference/cli/docker/image/pull/ ; https://docs.docker.com/build/building/best-practices/
- Run as a non-root `USER` when privileges are not needed. Create a dedicated user and group. Source: build best-practices page.
- Choose a minimal base image. Docker's guidance names Alpine as an example. Distroless base images: NOT SOURCEABLE (build best-practices page does not mention distroless; searched that page only).
- Multi-stage builds keep only runtime files in the final image. Use `.dockerignore` to exclude irrelevant build inputs. Source: build best-practices page.
- Build-time secrets via `--mount=type=secret`: NOT SOURCEABLE from the fetched page (not covered). Do not put secrets into `ENV`, which persists in the layer. Source: build best-practices page.
- Pull the minimum pull policy you need with `pull_policy:` (`always`, `never`, `missing`, `build`, `daily`, `weekly`, `every_<duration>`). `never` fails if no cached image exists. `missing` always pulls `latest` (per services reference). Source: services reference.

## 5. Supply chain: SBOM and provenance

- Provenance attestations are on by default at `min` mode. Request `--provenance=mode=max` for full detail. Disable with `--provenance=false`. Source: https://docs.docker.com/build/metadata/attestations/
- SBOM is off by default. Enable with `--sbom=true`. Source: same page.
- Use the `docker-container` (or `kubernetes`/`remote`) builder for attestations. The default `docker` driver fails with attestations unless the containerd image store is enabled. Source: same page.
- Attachment in image manifest: local and tar exporters cannot store attestations in the manifest; they write JSON files instead. Source: same page.
- Vulnerability scanning tool and signing: NOT SOURCEABLE (not searched in this pass).

## 6. Logs

- Configure `json-file` rotation explicitly. Default `max-size` is `-1` (unlimited), so logs grow without bound. Set `max-size` (for example `10m`) and `max-file` (for example `3`). `max-file` only applies when `max-size` is set. `compress: true` compresses rotated files. Source: https://docs.docker.com/engine/logging/drivers/json-file/
- Values in `daemon.json` are strings (`"max-file": "3"`). Restart the daemon. Existing containers keep their old settings. Source: same page.
- Set `logging:` per service in Compose for consistency. Source: services reference.

## 7. Volumes and backups

- Back up a named volume by mounting it into a helper container and tarring it to a host directory. The documented pattern uses `--volumes-from <container>` with a host bind-mount of the backup path. Source: https://docs.docker.com/engine/storage/volumes/
- Backup while the writing service is running: the page gives no consistency guidance. Stop the writing service (or use the database's own dump tool) before tarring. The stop-first advice is a recommendation, not sourced.

## 8. Zero-downtime on one host

- Compose's `deploy.update_config` (`order: start-first`, `parallelism`, `failure_action`) is documented for rolling updates. Whether it applies outside Swarm: NOT SOURCEABLE (searched deploy reference; it does not name the platform).
- Recommended shape, built only from sourced primitives: a reverse proxy in front, healthchecks on each replica, and `up --wait` before cutover. The proxy-side drain behavior is sourced only for Caddy reload: WebSocket connections are closed on reload by default unless `stream_close_delay` is set. Caddy's active health checks use `health_uri` with `health_interval` default `30s` and `health_fails` default `1`. Source: https://caddyserver.com/docs/caddyfile/directives/reverse_proxy
- End-to-end zero-downtime procedure with `docker compose` alone: NOT SOURCEABLE (searched Compose docs; no page covers single-host rolling replacement).

## 9. Reverse proxy: Caddy vs Traefik (one paragraph)

Caddy is the simpler default for a self-hosted installer: automatic HTTPS needs ports 80 and 443 reachable (HTTP-01 and TLS-ALPN-01 on by default) or a DNS challenge; localhost names and `.internal`/`.local` names get a local-CA certificate instead, so clients must trust Caddy's root. Source: https://caddyserver.com/docs/automatic-https . Traefik discovers routes from container labels through the Docker provider. Its `exposedByDefault` option defaults to `true`, so set it to `false` and opt in with `traefik.enable=true` on each service. Mounting the Docker socket gives the proxy full Docker API access, which the Traefik docs call a security risk; put a filtering socket proxy in front. Source: https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/ . Pick one; do not run both on ports 80/443.

## 10. Telemetry in the bundle

- Keep the OpenTelemetry Collector and any backend under a Compose profile so it is off by default. Compose profile syntax is not fetched in this pass: NOT SOURCEABLE for the exact `profiles:` behavior. Telemetry defaults are in `../opentelemetry/best-practices.md`.

## Verified sources

- https://docs.docker.com/reference/compose-file/services/ · /version-and-name/ · /deploy/ · /use-secrets/ (under /compose/how-tos/)
- https://docs.docker.com/compose/how-tos/startup-order/ · /compose/how-tos/use-secrets/
- https://docs.docker.com/reference/cli/docker/compose/up/
- https://docs.docker.com/reference/cli/docker/image/pull/
- https://docs.docker.com/build/building/best-practices/ · /build/metadata/attestations/
- https://docs.docker.com/engine/containers/resource_constraints/ · /engine/logging/drivers/json-file/ · /engine/storage/volumes/
- https://caddyserver.com/docs/automatic-https · /docs/caddyfile/directives/reverse_proxy
- https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/

## Knowledge gap warning

Items marked NOT SOURCEABLE were not reached in this session. Do not fill them from memory. Re-check before writing installer scripts.
