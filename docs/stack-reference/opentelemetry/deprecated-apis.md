# OpenTelemetry — Deprecated APIs, Settings, and Attributes

Verified 2026-10-11. Format: Deprecated → Replacement → Since → Source. "(removed)" marks items removed rather than deprecated first. Rows marked NOT SOURCEABLE were not stated by a fetched page.

## Go SDK and API

| Deprecated | Replacement | Since | Source |
|---|---|---|---|
| `go.opentelemetry.io/otel/log/global` | Equivalent APIs in `go.opentelemetry.io/otel` (replacement names NOT SOURCEABLE beyond "equivalent APIs in go.opentelemetry.io/otel") | 1.47.0-rc.1 section (final 1.47.0 section read: no deprecations) | https://raw.githubusercontent.com/open-telemetry/opentelemetry-go/main/CHANGELOG.md |
| `attribute.INVALID` | `attribute.EMPTY` | 1.43.0 (2026-04-02) | same CHANGELOG |
| `attribute.Value.Emit` | `attribute.Value.String` | 1.44.0 (2026-05-27) | same CHANGELOG |
| `OTEL_GO_X_CARDINALITY_LIMIT` env var | `WithCardinalityLimit` option (`WithCardinalityLimit(0)` = unlimited) | 1.44.0 (Changed bullet) | same CHANGELOG |
| `WithExportBufferSize` in `go.opentelemetry.io/otel/sdk/log` | NOT SOURCEABLE (option still compiles, no longer affects behavior) | 1.45.0 (2026-08-03) | same CHANGELOG |
| `go.opentelemetry.io/otel/log` `Kind`, `Value`, `KeyValue` and helpers (removed) | `go.opentelemetry.io/otel/attribute` `Value` and `KeyValue` | 1.45.0 | same CHANGELOG |
| `AttributeValueLengthLimit` and `AttributeCountLimit` in `RecordFactory` of `sdk/log/logtest` (removed) | NOT SOURCEABLE (no replacement stated) | 1.45.0 | same CHANGELOG |
| `OTEL_GO_X_METRIC_EXPORT_BATCH_SIZE` env var in `sdk/metric` (removed) | `WithMaxExportBatchSize` | 1.47.0 (2026-10-02) | same CHANGELOG |

## Environment variables (spec)

| Deprecated | Replacement | Since | Source |
|---|---|---|---|
| `OTEL_LOGS_EXPORTER=logging` | `otlp`, `console`, or `none` | Spec (marked deprecated; implementations should not support it) | https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk-environment-variables.md |

## Semantic conventions (HTTP), semconv v1.44.0 docs

Stable since semconv v1.23.0 (2023-11-03). Old names remain available only through `OTEL_SEMCONV_STABILITY_OPT_IN=http/dup` during migration (see `best-practices.md`).

| Deprecated | Replacement | Since | Source |
|---|---|---|---|
| `http.method` | `http.request.method` | Stable v1.23.0 (opt-in) | https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/ |
| `http.status_code` | `http.response.status_code` | Stable v1.23.0 | same page |
| `http.url` | `url.full` | Client spans | same page |
| `http.target` | `url.path` and `url.query` | Server spans | same page |
| `http.scheme` | `url.scheme` | Server spans (server duration metric) | same page |
| `http.client_ip` | `client.address` | Server spans | same page |
| `http.resend_count` | `http.request.resend_count` | Client spans | same page |
| `http.request_content_length` | `http.request.body.size` | Opt-in, not yet stable on page | same page |
| `http.response_content_length` | `http.response.body.size` | Opt-in, not yet stable on page | same page |
| `net.peer.name` | `server.address` | Client spans | same page |
| `net.peer.port` | `server.port` | Client spans | same page |
| `net.host.name` | `server.address` | Server spans | same page |
| `net.host.port` | `server.port` | Server spans | same page |
| `net.sock.host.addr` | `network.local.address` | Server spans | same page |
| `net.sock.host.port` | `network.local.port` | Server spans | same page |
| `net.sock.peer.addr` | `network.peer.address` | Common | same page |
| `net.sock.peer.port` | `network.peer.port` | Common | same page |
| `net.sock.family` (removed) | NOT SOURCEABLE (no replacement stated) | Common | same page |
| `net.sock.peer.name` (removed) | NOT SOURCEABLE (no replacement stated) | Common | same page |
| `net.protocol.name` | `network.protocol.name` | Common | same page |
| `net.protocol.version` | `network.protocol.version` | Common | same page |
| `http.flavor` | `network.protocol.version` | Pre-semconv v1.20.0 (≤ v1.19.0) | same page |
| `http.user_agent` | `user_agent.original` | ≤ v1.18.0 | same page |
| `http.client.duration` (ms) | `http.client.request.duration` (s) | Metric rename and unit change | same page |
| `http.server.duration` (ms) | `http.server.request.duration` (s) | Metric rename and unit change | same page |
| `HTTP {http.method}` span name (client) | `{summary}` | ≤ v1.17.0 | same page |
| `HTTP {http.method}` span name (server, no route) | `{summary}` | ≤ v1.17.0 | same page |

## Java agent 2.0.0

Source for all rows: https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/tag/v2.0.0 (release dated "12 January", year not shown on page).

| Deprecated | Replacement | Since | Source |
|---|---|---|---|
| Java 1.x HTTP semconv opt-in (`OTEL_SEMCONV_STABILITY_OPT_IN=http/dup` on agent 1.x) | Stable HTTP semconv are the default in 2.0.0. Whether the opt-in still has an effect on 2.x: NOT SOURCEABLE (2.0.0 page does not mention the variable). | 2.0.0 | same page; 1.27.0 opt-in detail is a search summary only |
| `process.runtime.jvm.memory.usage` | `jvm.memory.used` | 2.0.0 | same page |
| `process.runtime.jvm.memory.committed` | `jvm.memory.committed` | 2.0.0 | same page |
| `process.runtime.jvm.memory.limit` | `jvm.memory.limit` | 2.0.0 | same page |
| `process.runtime.jvm.memory.usage_after_last_gc` | `jvm.memory.used_after_last_gc` | 2.0.0 | same page |
| `process.runtime.jvm.gc.duration` | `jvm.gc.duration` | 2.0.0 | same page |
| `process.runtime.jvm.threads.count` | `jvm.threads.count` | 2.0.0 | same page |
| `process.runtime.jvm.classes.loaded` / `unloaded` | `jvm.classes.loaded` / `jvm.classes.unloaded` | 2.0.0 | same page |
| `process.runtime.jvm.classes.current_loaded` | `jvm.classes.count` | 2.0.0 | same page |
| `process.runtime.jvm.cpu.utilization` | `jvm.cpu.recent_utilization` | 2.0.0 | same page |
| Artifact `instrumentation-api-semconv` | `instrumentation-api-incubator` (HTTP classes moved to `instrumentation-api`) | 2.0.0 | same page |
| Property `otel.instrumentation.log4j-appender.experimental.capture-context-data-attributes` | `otel.instrumentation.log4j-appender.experimental.capture-mdc-attributes` | 2.0.0 | same page |
| `log4j.mdc.` and `logback.mdc.*` attribute prefixes (removed) | NOT SOURCEABLE (page says removed; no replacement named) | 2.0.0 | same page |
| Micrometer bridge enabled-by-default (now disabled) | `OTEL_INSTRUMENTATION_MICROMETER_ENABLED=true` | 2.0.0 | same page |
| gRPC as OTLP default protocol | `http/protobuf` default; set `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` for gRPC | 2.0.0 | same page |

## Searched without a result

- Collector deprecations: not searched in this pass. NOT SOURCEABLE for the Collector component deprecations list.
- Java `OTEL_INSTRUMENTATION_COMMON_DEFAULT_ENABLED`: the Java configuration page fetched did not document it. NOT SOURCEABLE.
- Go otelhttp deprecated options: only a search summary exists. NOT SOURCEABLE.

## Verified sources

- https://raw.githubusercontent.com/open-telemetry/opentelemetry-go/main/CHANGELOG.md
- https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/
- https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/tag/v2.0.0
- https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk-environment-variables.md
