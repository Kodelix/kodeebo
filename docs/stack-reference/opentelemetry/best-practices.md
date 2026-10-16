# OpenTelemetry — Best Practices (Go + Ktor backends, client SDKs, Docker Compose bundle)

Verified 2026-10-11. Pins are in `VERSION.md`. Each claim cites a page fetched in this session unless marked NOT SOURCEABLE (with what was searched) or "inference".

## 1. Default posture for the self-hosted installer: telemetry OFF

- The SDK-level switch is `OTEL_SDK_DISABLED` (default `false`). Setting it to `true` makes all signals a no-op SDK. Source: https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk-environment-variables.md
- Java agent 2.x: the OTLP logs exporter is enabled by default. Set `OTEL_LOGS_EXPORTER=none` in self-hosted builds, otherwise logs still export when the Collector is absent. Source: https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/tag/v2.0.0
- Java agent 2.x OTLP default protocol is `http/protobuf`. Source: same page.
- Global disable for all Java instrumentation via `OTEL_INSTRUMENTATION_COMMON_DEFAULT_ENABLED=false`: NOT SOURCEABLE in this session. The Java configuration page fetched did not document it. (VERSION.md lists this claim; treat it as unverified until the Java configuration reference is fetched.)
- Go has no attached agent: gate SDK initialization on configuration, and do not register exporters when telemetry is off. Inference from the absence of any agent in the Go SDK docs; the Go language docs page was not fetched for this rule.
- Ship the Collector and any backend in a Compose profile so they do not start by default. Compose `profiles:` syntax NOT SOURCEABLE in this session (see `../docker-compose/best-practices.md`).
- Client SDKs (browser, Android, iOS) must not send to a vendor endpoint by default: inference from the telemetry-off requirement; no client-SDK page fetched for this rule.

## 2. Instrumentation

- Prefer auto-instrumentation where it exists, then add manual spans for business operations. Java: agent covers Ktor via `opentelemetry-ktor-*` instrumentation (Ktor 1.0+). Source: https://github.com/open-telemetry/opentelemetry-java-instrumentation/blob/main/docs/supported-libraries.md
- Ktor standalone library artifacts `opentelemetry-ktor-1.0/2.0/3.0` exist. Source: same page.
- Go: `otelhttp` for HTTP server and client. Its default semantic conventions version: NOT SOURCEABLE in this session. Set `OTEL_SEMCONV_STABILITY_OPT_IN=http/dup` during migration and move dashboards to stable names before switching to `http`. Source for the variable: https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/ . The otelhttp-specific behavior is a search summary only.
- Semconv migration order (Go and Java 1.x): `http/dup` → migrate dashboards and alerts → `http` → remove old-name queries. Source: http-migration page (dup/http values) and the search summary of Java 1.27.0 notes (not fetched directly).
- Use stable HTTP attributes (`http.request.method`, `http.response.status_code`, `url.path`, `server.address`, `http.server.request.duration`). Source: http-migration page.
- Messaging semantic conventions are Development, not stable. Pin the semconv version and expect renames. Source: https://opentelemetry.io/docs/specs/semconv/messaging/messaging-spans/ (see VERSION.md).

## 3. Logs: Go slog bridge and Java Logback appender

- Go: `go.opentelemetry.io/contrib/bridges/otelslog`. Constructor: `otelslog.NewLogger(name, otelslog.WithLoggerProvider(provider))`. Source: the module's `example_test.go` on the main branch (fetched 2026-10-11). The `slog.New` wiring and default LoggerProvider behavior: NOT SOURCEABLE (no README in the repo; example does not show `slog.New`).
- Go SDK logs: stable in v1.47.0 per VERSION.md. The Go language docs page still said release candidate on 2026-10-11 (see VERSION.md).
- Java/Logback: artifact `io.opentelemetry.instrumentation:opentelemetry-logback-appender-1.0` (class `OpenTelemetryAppender`, Logback 1.0+). Also `opentelemetry-logback-mdc-1.0` for MDC attributes. Source: https://github.com/open-telemetry/opentelemetry-java-instrumentation/blob/main/docs/supported-libraries.md
- Java 2.0.0 removed `logback.mdc.*` and `log4j.mdc.` attribute prefixes. Source: https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/tag/v2.0.0
- Whether the agent bridges Logback by default: not confirmed on the supported-libraries page. Treat as unverified. Note the 2.0.0 release says the OTLP logs exporter is enabled by default.
- Do not log PII into the bridge. Attribute-level redaction is in the Collector (section 6).

## 4. Sampling

- Head sampling decides early, cheaply, and can run at any point in the pipeline. Its limit: it cannot base the decision on the whole trace, so it cannot guarantee that every error trace is kept. Source: https://opentelemetry.io/docs/concepts/sampling/
- Tail sampling decides after considering all or most spans in a trace. It supports criteria such as errors, latency, and attributes. It is harder to operate: stateful, must be monitored, may fall back under load. Source: same page.
- Tail sampling in the Collector: the `tail_sampling` processor (beta for traces, contrib and k8s distributions only, not core). Source: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/tailsamplingprocessor ; https://opentelemetry.io/docs/collector/distributions/
- Statefulness: the processor holds spans until a decision, so all spans for one trace must reach the same Collector instance. README suggests a two-layer deployment with the load-balancing exporter in front. A single Collector instance (the VPS default) satisfies this trivially. Inference from the README statefulness note.
- Placement: the processor must come after any processors that depend on context (for example `k8sattributes`). It rebuilds spans into new batches. Source: README above.
- Defaults: `decision_wait` 30s, `num_traces` 50000. Source: README above.
- Policies available: `always_sample`, `latency`, `numeric_attribute`, `probabilistic`, `status_code`, `string_attribute`, `boolean_attribute`, `trace_state`, `trace_flags`, `rate_limiting`, `bytes_limiting`, `span_count`, `ottl_condition`, and combinators `and`, `not`, `drop`, `composite`. Source: README above.
- SDK-side sampler default: `OTEL_TRACES_SAMPLER=parentbased_always_on`. Source: sdk-environment-variables.md.
- Recommended for this stack (inference): parentbased head sampling at the SDK at a low ratio, plus tail sampling in the Collector for errors and slow traces. Keep the SDK ratio configurable.

## 5. Cardinality

- Default metric cardinality limit: 2000 combinations per metric stream. When exceeded, extra measurements fold into one point with `otel.metric.overflow=true`, original attributes removed. Source: https://opentelemetry.io/blog/2026/cardinality-limits-in-opentelemetry/
- Overflow points carry only the marker, so grouped queries on the original attributes miss those measurements, while totals stay correct. Source: same blog (fetched).
- Do not use as metric attributes: raw URLs, user input, request IDs, session IDs, unbounded error messages. Use route templates, status codes, HTTP methods, bounded error categories. Source: same blog.
- Treat overflow as a signal to inspect instrumentation. Raise the limit only for a bounded attribute, sized to expected combinations with headroom. Source: same blog.
- Go SDK: `WithCardinalityLimit` replaces the deprecated env var `OTEL_GO_X_CARDINALITY_LIMIT`. `WithCardinalityLimit(0)` means unlimited (not recommended). Source: Go CHANGELOG 1.44.0 (see `breaking-changes.md`).

## 6. PII redaction (Collector)

- Principle: do not collect sensitive data in the first place. Collect only what serves an observability purpose. Source: https://opentelemetry.io/docs/security/handling-sensitive-data/
- Processors for data you cannot avoid collecting:
  - `attributes` processor: hash or delete specific keys (for example hash `user.email`, delete `user.full_name`).
  - `transform` processor: hash an identifier and remove the original; regex replace or truncate values such as `client.address`.
  - `redaction` processor: deletes span, log, and metric datapoint attributes that are not on an allowlist. Beta for traces, alpha for logs and metrics (VERSION.md, status table not re-fetched).
  - `filter` processor: drop entire spans or metrics containing sensitive data.
- Hashing caveat: small predictable inputs (numeric IDs) can be reversed. Hashing may not anonymize. Prefer truncation: year or year-month for dates, domain only for emails, drop the last IPv4 octet or last 80 bits of IPv6. Source: handling-sensitive-data page.
- Logs: only the redaction processor is named for log attributes. Baggage: not addressed on the page. Instrumentation libraries may capture sensitive data: review what they emit. Source: same page.
- Mind the processor order: redaction runs before any exporter, after `memory_limiter` (section 7).

## 7. Collector pipeline: memory_limiter and batch

- `memory_limiter`: add as the first processor in the pipeline so back-pressure reaches receivers. Above the soft limit it refuses data with retryable errors; above the hard limit it forces GC. `limit_mib` default 0 (must set `limit_mib` or `limit_percentage`); `spike_limit_mib` defaults to 20% of `limit_mib`; soft limit = `limit_mib` − `spike_limit_mib`; `check_interval` default 0s, README recommends 1s. Beta for traces, metrics, logs. Source: https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/memorylimiterprocessor
- `batch`: place after `memory_limiter` and sampling processors so dropped data is not batched. `send_batch_size` default 8192; `timeout` default 200ms; `send_batch_max_size` default 0 (no upper limit) and must be ≥ `send_batch_size`. Beta for traces, metrics, logs. Source: https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/batchprocessor
- Exporters: enable the sending queue for any network exporter. Queue is in-memory by default; use the `file_storage` extension in `sending_queue.storage` to persist across restarts. Retry defaults: up to 5 minutes, exponential backoff with jitter. Monitor `otelcol_exporter_queue_size` and `otelcol_exporter_queue_capacity`. Source: https://opentelemetry.io/docs/collector/resiliency/
- Example from the resiliency page: `queue_size: 5_000`, `retry_on_failure` with `initial_interval: 5s`, `max_interval: 30s`, `max_elapsed_time: 10m`. These are examples, not defaults.

## 8. Recommended Collector pipeline order (inference from sections 4 to 7)

`receivers` → `memory_limiter` → `attributes`/`transform`/`redaction` (PII) → `tail_sampling` (after context-dependent processors) → `batch` → `otlphttp` exporter (with sending queue). Use the contrib image: `tail_sampling` and `redaction` are not in core. Source for the component locations: VERSION.md and the distributions page.

## 9. Verified sources

- https://opentelemetry.io/docs/specs/semconv/non-normative/http-migration/
- https://opentelemetry.io/docs/concepts/sampling/
- https://opentelemetry.io/docs/security/handling-sensitive-data/
- https://opentelemetry.io/docs/collector/resiliency/
- https://opentelemetry.io/blog/2026/cardinality-limits-in-opentelemetry/
- https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/memorylimiterprocessor
- https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/batchprocessor
- https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/tailsamplingprocessor
- https://github.com/open-telemetry/opentelemetry-java-instrumentation/blob/main/docs/supported-libraries.md
- https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/tag/v2.0.0
- https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/configuration/sdk-environment-variables.md
- https://raw.githubusercontent.com/open-telemetry/opentelemetry-go-contrib/main/bridges/otelslog/example_test.go

## Knowledge gap warning

NOT SOURCEABLE in this session: Java global instrumentation disable (`OTEL_INSTRUMENTATION_COMMON_DEFAULT_ENABLED`); Go `otelslog` wiring and default LoggerProvider; otelhttp default semconv version; OTLP exporter endpoints and per-protocol ports (env var page did not state them); Java Logback bridging default. Do not write these from memory.
