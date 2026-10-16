# OpenTelemetry — Version Reference

Last verified: 2026-10-11
Scope: Go SDK, Java SDK + agent (Ktor), Collector, semantic conventions, OTLP, client SDKs, self-hostable backends.
Method: every value below was fetched on 2026-10-11 from the listed source. Dates are GitHub release `published_at` (UTC date).

## Versions and release dates

| Component | Latest stable | Released | Source |
|---|---|---|---|
| Go SDK (`go.opentelemetry.io/otel`) | v1.47.0 (contrib modules 0.69.0 / log 0.23.0 / 0.1.0 in the same train) | 2026-10-02 | https://github.com/open-telemetry/opentelemetry-go/releases/tag/v1.47.0 · CHANGELOG |
| Go contrib (`opentelemetry-go-contrib`) | v1.47.0 (otelhttp v0.71.0) | 2026-10-02 | https://github.com/open-telemetry/opentelemetry-go-contrib/releases |
| Java SDK (`opentelemetry-java`) | v1.67.0 | 2026-10-09 | https://github.com/open-telemetry/opentelemetry-java/releases |
| Java agent / instrumentation | v2.32.0 (targets SDK 1.66.0) | 2026-10-03 | https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases · CHANGELOG |
| Collector core | v1.68.0 / v0.162.0 | 2026-09-28 | https://github.com/open-telemetry/opentelemetry-collector/releases |
| Collector distributions (core, contrib, k8s, otlp) | v0.162.0 | 2026-09-29 | https://github.com/open-telemetry/opentelemetry-collector-releases/releases |
| Collector contrib components | v0.162.0 | 2026-09-29 | https://github.com/open-telemetry/opentelemetry-collector-contrib/releases |
| Semantic conventions | v1.44.0 | 2026-08-04 | https://github.com/open-telemetry/semantic-conventions/releases · https://opentelemetry.io/docs/specs/semconv/ |
| OTLP spec | 1.11.0 | NOT SOURCEABLE — release date not stated on https://opentelemetry.io/docs/specs/otlp/ | |
| JS SDK (browser) | 2.12.0 stable; experimental 0.223.0 | 2026-10-06 | https://github.com/open-telemetry/opentelemetry-js/releases |
| Android | v1.7.0 | 2026-09-04 | https://github.com/open-telemetry/opentelemetry-android/releases |
| Swift | 2.6.0 (GitHub marks "Prerelease"); 2.5.1 last non-prerelease | 2026-10-01 (2.6.0) | https://github.com/open-telemetry/opentelemetry-swift/releases |

Minimum toolchains: Go SDK `go.mod` says `go 1.26.0` (https://github.com/open-telemetry/opentelemetry-go/blob/main/go.mod); Collector v0.160.0 dropped Go 1.25, min Go 1.26.0 (Collector CHANGELOG); Go contrib v1.47.0 dropped Go 1.25.

## Stability per signal

Spec level (https://opentelemetry.io/docs/specs/status/): Traces Stable; Metrics Mixed (API + protocol stable, SDK "mixed"); Logs Stable (bridge API, SDK, protocol); Baggage Stable; Profiles Development; OTLP Stable for all signals except Profiles (Development).

| SDK | Traces | Metrics | Logs | Source |
|---|---|---|---|---|
| Go | Stable | Stable | **Stable as of v1.47.0** (`otel/log`, `otel/sdk/log` now under stability guarantees) | Go CHANGELOG 1.47.0. NOTE: https://opentelemetry.io/docs/languages/go/ still showed "Release candidate" on 2026-10-11 — docs page lags the 2026-10-02 release |
| Java | Stable | Stable | Stable | https://opentelemetry.io/docs/languages/java/ |
| JavaScript | Stable | Stable | Development | https://opentelemetry.io/docs/languages/js/ ; browser client instrumentation "experimental" and "mostly unspecified" |
| Swift | Stable | Development | Development | https://opentelemetry.io/docs/languages/swift/ |
| Android | NOT SOURCEABLE as a table (docs page https://opentelemetry.io/docs/languages/android/ returned 404). Release notes for v1.7.0: many artifacts keep `-alpha`, "will continue to have breaking changes" | | | https://github.com/open-telemetry/opentelemetry-android/releases |

Java agent / library instrumentation: many artifacts carry `-alpha` and may break between releases (Java instrumentation CHANGELOG 2.32.0 header; see VERSIONING.md in that repo).

## Semantic-convention stability by area (v1.44.0)

| Area | Status | Source |
|---|---|---|
| HTTP (spans, metrics) | Stable ("Unless otherwise specified"; `url.template`, some body/size attrs still Development). Stabilised in v1.23.0 (2023-11-03). | https://opentelemetry.io/docs/specs/semconv/http/http-spans/ ; semconv CHANGELOG v1.23.0 |
| Database client | Stable for MariaDB, SQL Server, MySQL, PostgreSQL ("core of database semantic conventions" first stabilised in v1.33.0); `db.query.parameter.<key>`, `db.response.returned_rows`, most other `db.system.name` values still Development | https://opentelemetry.io/docs/specs/semconv/db/database-spans/ ; CHANGELOG v1.33.0 |
| Messaging | **Development** (page and every span-type section) | https://opentelemetry.io/docs/specs/semconv/messaging/messaging-spans/ |
| Gen AI | moved to dedicated repo `semantic-conventions-genai` in v1.42.0 | CHANGELOG v1.42.0 |
| K8s / container registry attrs | some graduated to stable in v1.42.0; memory metrics at release_candidate (v1.44.0) | CHANGELOG |

## Collector component stability (README status tables, main branch, 2026-10-11)

| Component | Where | Stability |
|---|---|---|
| `memory_limiter` processor | core, contrib, k8s | beta (traces, metrics, logs); alpha (profiles) |
| `batch` processor | core, contrib, k8s | beta (traces, metrics, logs) |
| `tail_sampling` processor | contrib, k8s only (NOT core) | beta (traces); warning: Statefulness |
| `attributes` processor | core, contrib, k8s | beta |
| `transform` processor | contrib, k8s | beta (T/M/L); development (profiles) |
| `redaction` processor | contrib | beta (traces); alpha (logs, metrics) |

Core vs contrib (https://opentelemetry.io/docs/collector/distributions/): five official distros — Core (minimal), Contrib (adds many receivers/processors/exporters, "varying levels of stability"), Kubernetes, OTLP, eBPF Profiling. Custom builds via OCB (OpenTelemetry Collector Builder). tail_sampling therefore needs Contrib/K8s or an OCB build.

## Log bridges

- Go: `go.opentelemetry.io/contrib/bridges/otelslog` (slog handler → OTel Logs API). Module `otelslog` v0.27.0 appears in contrib v1.45.0 notes; v1.47.0 bounded recursive attribute traversal (max depth 100). Source: go-contrib releases. Dir listing: https://github.com/open-telemetry/opentelemetry-go-contrib/tree/main/bridges/otelslog (no README; usage docs NOT SOURCEABLE from repo).
- Java/Ktor: Logback appender `io.opentelemetry.instrumentation:opentelemetry-logback-appender-1.0` (class `OpenTelemetryAppender`), Logback 1.0+; also `opentelemetry-logback-mdc-1.0`. Agent auto-instruments Logback/Log4j. Source: https://github.com/open-telemetry/opentelemetry-java-instrumentation/blob/main/docs/supported-libraries.md
- Ktor: auto-instrumented 1.0+ by the agent; standalone library artifacts `opentelemetry-ktor-1.0 / 2.0 / 3.0` (`KtorServerTelemetry` plugin) — emits HTTP client/server spans and metrics. Source: supported-libraries.md and ktor-3.0 library README.

## Recommended pin (derived from the above)

- Go: `go.opentelemetry.io/otel*` v1.47.0 + contrib v1.47.0 (otelhttp v0.71.0, otelslog via contrib release train); toolchain Go >= 1.26.0.
- Java: agent 2.32.0 (bundles its own SDK; do not mix a different SDK version in app code when using the agent). SDK 1.67.0 only if using the SDK directly without the agent.
- Collector: `otel/opentelemetry-collector-contrib:0.162.0` (needed for tail_sampling / redaction); use core image only if no contrib component needed. Pin by tag + digest. Do not use `latest`.
- Semconv: target 1.44.0 docs; Go package referenced by contrib is `go.opentelemetry.io/otel/semconv/v1.43.0` (whether `v1.44.0` package exists in otel v1.47.0: NOT VERIFIED).
- Default to OTLP/HTTP-protobuf or gRPC to a local Collector (4318 / 4317). Java agent 2.x defaults to `http/protobuf` (https://opentelemetry.io/docs/zero-code/java/agent/configuration/).
- Telemetry OFF by default for self-hosted: `OTEL_SDK_DISABLED=true` (spec env var, default `false`; https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk-environment-variables.md). Java agent also supports disabling all instrumentation via `OTEL_INSTRUMENTATION_COMMON_DEFAULT_ENABLED=false`. Go has no auto-attached agent: gate SDK init on config. Ship the Collector under a Compose profile (e.g. `observability`) so it does not start unless opted in. Client SDKs (browser/Android/iOS) must not send to a vendor endpoint by default.

## Installed locally (2026-10-11, this machine)

- `otelcol --version`: NOT INSTALLED
- `caddy version`: NOT INSTALLED
- docker: see ../docker-compose/VERSION.md

## Self-hostable backends (neutral note)

| Backend | Latest seen | Released | Licence | Source |
|---|---|---|---|---|
| Grafana | v13.2.3 | 2026-09-29 | AGPL-3.0 | GitHub API (grafana/grafana) |
| Loki | v3.7.8 (3.7.0 on 2026-03-26) | 2026-09-17 | AGPL-3.0 | GitHub API (grafana/loki) |
| Tempo | v3.1.0 | 2026-09-29 | AGPL-3.0 | GitHub API + LICENSE file (grafana/tempo) |
| Mimir | mimir-3.2.2 | 2026-10-07 | AGPL-3.0 | GitHub API (grafana/mimir) |
| Prometheus | v3.15.0 | 2026-09-25 | Apache-2.0 | GitHub API (prometheus/prometheus) |
| `grafana/docker-otel-lgtm` (all-in-one) | v0.36.0 | 2026-10-09 | Apache-2.0 | README: intended for "development, demo, and testing environments", not production |
| SigNoz | v0.145.0 | 2026-10-05 | MIT, except `ee/` and `cmd/enterprise/` under a separate enterprise licence (`ee/LICENSE`) | repo LICENSE; README lists Docker/Kubernetes/Linux self-host |

Licence implication (derived): the Grafana LGTM components are AGPL-3.0 — shipping them inside an enterprise installer bundle needs legal review; running them unmodified as separate containers is a distinct question from linking. SigNoz community edition is MIT outside `ee/`. Backend choice is the customer's; the product should only emit OTLP.

## Verified sources

- https://opentelemetry.io/docs/specs/status/ · /docs/languages/ · /docs/languages/go/ · /docs/languages/java/ · /docs/languages/js/ · /docs/languages/swift/ · /docs/languages/js/getting-started/browser/
- https://opentelemetry.io/docs/specs/semconv/ (+ http/http-spans, db/database-spans, messaging/messaging-spans, non-normative/db-migration, non-normative/http-migration)
- https://opentelemetry.io/docs/specs/otlp/
- https://opentelemetry.io/docs/collector/distributions/ · /collector/configuration/ · /collector/resiliency/ · /docs/security/config-best-practices/ · /docs/security/handling-sensitive-data/ · /docs/concepts/sampling/
- https://opentelemetry.io/docs/zero-code/java/agent/ · /agent/configuration/
- GitHub: open-telemetry/{opentelemetry-go, opentelemetry-go-contrib, opentelemetry-java, opentelemetry-java-instrumentation, opentelemetry-collector, opentelemetry-collector-releases, opentelemetry-collector-contrib, semantic-conventions, opentelemetry-js, opentelemetry-android, opentelemetry-swift}; grafana/{grafana,loki,tempo,mimir,docker-otel-lgtm}; SigNoz/signoz; prometheus/prometheus

## Knowledge gap warning

The model's training data predates every version above (Go SDK 1.47, Java agent 2.32, Collector 0.162, semconv 1.44). Do not write OTel code, Collector config, or env-var names from memory: Collector config keys, Go package paths (`otel/log/global` deprecated; `otlploghttp`), and Java agent semconv opt-in flags have moved. Re-check the pages above and `breaking-changes.md` first. NOT SOURCEABLE items are marked inline; treat them as unknown, not absent. Android docs page and Swift/Android per-signal stability were not retrievable.
