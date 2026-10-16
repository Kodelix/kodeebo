# OpenTelemetry — Breaking Changes

Verified 2026-10-11. Versions and pins: see `VERSION.md` in this directory. Each row cites a page fetched in this session unless marked "search summary only".

## 1. Semantic conventions: HTTP renames

Source: https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/ (semconv v1.44.0 docs). HTTP conventions were declared stable in semconv v1.23.0 (2023-11-03) per VERSION.md.

Opt-in: `OTEL_SEMCONV_STABILITY_OPT_IN` accepts `http` (stable only) or `http/dup` (old and stable together). Without it, instrumentations keep emitting previous conventions. Per-attribute opt-in status is not mapped on the page for every rename.

### Common (client and server spans)

| Old attribute | New attribute | Notes |
|---|---|---|
| `http.method` | `http.request.method` | Only 9 common methods by default, others become `_OTHER` |
| `http.status_code` | `http.response.status_code` | |
| `http.request.header.<key>` / `http.response.header.<key>` | same prefix | Dash-to-underscore normalization removed |
| `http.request_content_length` | `http.request.body.size` | Opt-in, not yet marked stable on page |
| `http.response_content_length` | `http.response.body.size` | Opt-in, not yet marked stable on page |
| `user_agent.original` | (new name for `http.user_agent`) | Opt-in on client spans |
| `net.protocol.name` | `network.protocol.name` | |
| `net.protocol.version` | `network.protocol.version` | Example values changed: `2.0` → `2`, `3.0` → `3` |
| `net.sock.family` | removed | |
| `net.sock.peer.addr` | `network.peer.address` | |
| `net.sock.peer.port` | `network.peer.port` | |
| `net.sock.peer.name` | removed | |
| (new) | `http.request.method_original` | Only when method is `_OTHER` |
| (new) | `error.type` | |

### Client spans

| Old | New |
|---|---|
| `http.url` | `url.full` |
| `http.resend_count` | `http.request.resend_count` |
| `net.peer.name` | `server.address` |
| `net.peer.port` | `server.port` |

### Server spans

| Old | New |
|---|---|
| `http.target` | `url.path` and `url.query` |
| `http.scheme` | `url.scheme` |
| `http.client_ip` | `client.address` |
| `net.host.name` | `server.address` |
| `net.host.port` | `server.port` |
| `net.sock.host.addr` | `network.local.address` |
| `net.sock.host.port` | `network.local.port` |
| `http.route` | unchanged |

### Metrics

| Old | New | Unit change |
|---|---|---|
| `http.client.duration` | `http.client.request.duration` | ms → s |
| `http.server.duration` | `http.server.request.duration` | ms → s |

Client metric: `net.sock.peer.addr` removed, `error.type` added. Server metric: `net.host.name`/`net.host.port` → `server.address`/`server.port` (opt-in). Duration metrics take the attribute renames above.

### Span names (older versions)

- v1.17.0 and earlier: span names changed. Server: `{http.route}` → `{summary} {http.route}`, or `HTTP {http.method}` → `{summary}` without route. Client: `HTTP {http.method}` → `{summary}`.
- Span name with `_OTHER` method: `{http.method}` replaced with `HTTP`.

### Earlier renames

- v1.20.0 and earlier: `http.flavor` → `network.protocol.version` (v1.19.0 and earlier).
- v1.18.0 and earlier: `http.user_agent` → `user_agent.original`.

### Go otelhttp (secondary)

A WebSearch summary of Go contrib docs says `OTEL_SEMCONV_STABILITY_OPT_IN=http/dup` makes otelhttp emit semconv v1.26.0 server metrics (`http.server.request.duration`, `http.server.request.body.size`, `http.server.response.body.size`). Search summary only. The otelhttp CHANGELOG raw fetch returned 404. Default semconv version per otelhttp release: NOT SOURCEABLE in this session.

## 2. Java agent 2.0.0 (default changes)

Source: https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/tag/v2.0.0 (release dated "12 January", year not shown on page). Agent current pin: v2.32.0 (see VERSION.md).

- Stable HTTP semantic conventions are emitted by default. Individual option names are not listed; the page points to the HTTP migration guide above.
- Stable JVM semantic conventions (metric renames, below).
- OTLP protocol default changed from `grpc` to `http/protobuf`. Set `OTEL_EXPORTER_OTLP_PROTOCOL=grpc` or `-Dotel.exporter.otlp.protocol=grpc` to keep gRPC.
- Micrometer bridge disabled by default. Enable: `OTEL_INSTRUMENTATION_MICROMETER_ENABLED=true`.
- OTLP logs exporter enabled by default. Disable: `OTEL_LOGS_EXPORTER=none`. This matters for the telemetry-off-by-default rule (see `best-practices.md`).
- Controller spans disabled by default. Enable: `OTEL_INSTRUMENTATION_COMMON_EXPERIMENTAL_CONTROLLER_TELEMETRY_ENABLED=true`.
- View spans disabled by default. Enable: `OTEL_INSTRUMENTATION_COMMON_EXPERIMENTAL_VIEW_TELEMETRY_ENABLED=true`.
- Lettuce CONNECT spans disabled. Enable: `OTEL_INSTRUMENTATION_LETTUCE_CONNECTION_TELEMETRY_ENABLED=true`.
- Renamed property `otel.instrumentation.log4j-appender.experimental.capture-context-data-attributes` → `...capture-mdc-attributes`.
- Artifact `instrumentation-api-semconv` → `instrumentation-api-incubator`. HTTP classes moved to `instrumentation-api` (now stable).
- MDC attribute prefixes `log4j.mdc.` and `logback.mdc.*` removed.

### Java JVM metric renames (stable in 2.0.0)

| Old | New |
|---|---|
| `process.runtime.jvm.memory.usage` | `jvm.memory.used` |
| `process.runtime.jvm.memory.committed` | `jvm.memory.committed` |
| `process.runtime.jvm.memory.limit` | `jvm.memory.limit` |
| `process.runtime.jvm.memory.usage_after_last_gc` | `jvm.memory.used_after_last_gc` |
| `process.runtime.jvm.gc.duration` | `jvm.gc.duration` |
| `process.runtime.jvm.threads.count` | `jvm.threads.count` |
| `process.runtime.jvm.classes.loaded` | `jvm.classes.loaded` |
| `process.runtime.jvm.classes.unloaded` | `jvm.classes.unloaded` |
| `process.runtime.jvm.classes.current_loaded` | `jvm.classes.count` |
| `process.runtime.jvm.cpu.utilization` | `jvm.cpu.recent_utilization` |

Attribute renames: `type` → `jvm.memory.type`; `pool` → `jvm.memory.pool.name`; `name` → `jvm.gc.name`; `action` → `jvm.gc.action`; `daemon` → `jvm.thread.daemon`. Experimental: `process.runtime.jvm.system.cpu.*` → `jvm.system.cpu.*`, buffer metrics → `jvm.buffer.*`.

### Java HTTP body-size and 1.x opt-in (search summary only)

- Java 1.27.0 added `OTEL_SEMCONV_STABILITY_OPT_IN` values `http` and `http/dup`; search summary says the opt-in was a 1.x transition and removed in 2.0. Not verified against a fetched 1.27.0 page.
- Experimental HTTP body-size metrics in Java: a third-party guide says they need `otel.instrumentation.http.client.emit-experimental-telemetry` (and server counterpart). Not confirmed against Java docs. Treat as unverified.
- Java 2.x `otel.semconv-stability.opt-in` mechanism used for other domains (e.g. database): search summary only.

## 3. Go SDK and API (recent removals and behavior changes)

Source: https://raw.githubusercontent.com/open-telemetry/opentelemetry-go/main/CHANGELOG.md (fetched 2026-10-11; first 100k of 301k characters read).

| Version (date) | Change |
|---|---|
| 1.47.0 (2026-10-02) | Removed env var `OTEL_GO_X_METRIC_EXPORT_BATCH_SIZE` in `sdk/metric`. Use `WithMaxExportBatchSize`. |
| 1.45.0 (2026-08-03) | Removed `Kind`, `Value`, `KeyValue`, constructors and conversion helpers in `go.opentelemetry.io/otel/log`. Use `go.opentelemetry.io/otel/attribute`. |
| 1.45.0 | Removed `AttributeValueLengthLimit` and `AttributeCountLimit` from `RecordFactory` in `sdk/log/logtest`. No replacement stated. |
| 1.44.0 (2026-05-27) | Changed bullet: `OTEL_GO_X_CARDINALITY_LIMIT` deprecated. Use `WithCardinalityLimit(0)` for unlimited cardinality. |
| 1.43.0 (2026-04-02) | `attribute.INVALID` deprecated → `attribute.EMPTY`. |

Go Logs API version note: `otel/sdk/log` and `otel/log` were marked stable in v1.47.0 per VERSION.md; the Go language docs page still says release candidate (see VERSION.md).

## 4. Collector

- `tail_sampling` processor is contrib and k8s only (not core). Beta for traces. Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/tailsamplingprocessor ; https://opentelemetry.io/docs/collector/distributions/
- `memory_limiter`: README says the best practice is to add it as the first processor in a pipeline. Source: https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/memorylimiterprocessor
- `redaction` processor: beta for traces, alpha for logs and metrics (VERSION.md, from collector-contrib README status table; not re-fetched this session).
- Exporter sending queue is in-memory by default; on overflow new data is dropped. Retry runs up to 5 minutes by default, then oldest queued data is dropped. Source: https://opentelemetry.io/docs/collector/resiliency/ (page fetched; exact default `queue_size` value: NOT SOURCEABLE beyond "often 1,000").

## 5. Spec-level changes

- `OTEL_LOGS_EXPORTER=logging` is deprecated; implementations should not support it. Use `otlp`, `console`, or `none`. Source: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk-environment-variables.md
- `OTEL_TRACES_SAMPLER` default is `parentbased_always_on`. Same source.
- Messaging semconv is Development, not stable. Source: https://opentelemetry.io/docs/specs/semconv/messaging/messaging-spans/ (via VERSION.md).
- Gen AI conventions moved to the `semantic-conventions-genai` repo in semconv v1.42.0 (VERSION.md, sourced to CHANGELOG).

## Verified sources

- https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/
- https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/tag/v2.0.0
- https://raw.githubusercontent.com/open-telemetry/opentelemetry-go/main/CHANGELOG.md
- https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk-environment-variables.md
- https://opentelemetry.io/docs/collector/resiliency/
- https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/memorylimiterprocessor
- https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/tailsamplingprocessor

## Knowledge gap warning

NOT SOURCEABLE: Java 2.x exact opt-in mechanism for HTTP conventions; otelhttp default semconv version per release; Go `otel/log/global` deprecation details (only seen in the `1.47.0-rc.1` changelog section, not in the final release notes I read); Java `OTEL_EXPORTER_OTLP_PROTOCOL` default confirmed only via the Java 2.0.0 release page.
