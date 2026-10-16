# Observability Standard

DoD gate 4. If a feature fails in production at 3 a.m., the on-call engineer
must be able to answer *what broke, for whom, since when, and why* from
telemetry alone — without adding a log line and redeploying.

Signals are produced with **OpenTelemetry** (SDK version pinned in
`docs/stack-reference/opentelemetry/`), exported via OTLP to a collector. The
backend choice (Grafana stack, SigNoz, etc.) is an ADR; code never depends on it.

## Traces

- Every inbound request, consumed message and scheduled job starts or continues a trace (W3C `traceparent` propagated on every outbound HTTP call and message).
- Spans on: HTTP server/client, DB queries, cache calls, queue publish/consume, each use case, each external provider call.
- Span names are low-cardinality: `GET /v1/invoices/{id}`, `InvoiceService.Pay` — never raw IDs.
- Attributes follow OTel semantic conventions; product attributes use the `app.` prefix: `app.tenant_id`, `app.plan`, `app.feature`.
- Errors: record the exception and set span status `ERROR`; client-caused 4xx are not span errors.
- Sampling: parent-based; head sampling ratio configured per environment; tail sampling in the collector keeps all errors and slow traces.

## Metrics

- **RED for every endpoint and consumer**: request rate, error rate, duration histogram.
- **USE for every resource**: DB pool (in use / idle / wait), cache hit ratio and latency, queue depth and consumer lag, goroutines / coroutines, heap.
- **Business metrics** per feature where they matter: signups, activations, payments succeeded/failed, OTPs sent/verified, licence activations.
- **Cardinality budget**: never label with user ID, request ID, email, or raw URL. `tenant_id` only on low-volume business metrics and only if tenants count is bounded — otherwise use exemplars and traces.

## Logs

- Structured JSON, one event per line, via the platform logger (Go `log/slog`, Kotlin SLF4J + Logback JSON encoder).
- Required fields: `timestamp`, `level`, `msg`, `service`, `version`, `env`, `trace_id`, `span_id`, `tenant_id` (when known).
- Levels: `ERROR` = needs a human; `WARN` = degraded but handled; `INFO` = state changes and business events; `DEBUG` off in production.
- **Never log**: passwords, tokens, OTP codes, API keys, card data, full request/response bodies, national IDs, phone numbers or emails in clear (hash or mask them).
- Log the decision, not the noise: one line per significant outcome, not per loop iteration.

## SLOs and alerts

- Each product defines SLOs in `docs/architecture/slos.md` (template in Wave 6): availability and latency per critical journey (login, core action, payment, licence activation).
- Alerts are **burn-rate alerts on SLOs**, plus a short list of cause alerts that always need a human (DB down, disk > 85 %, certificate expiring, backup failed).
- Every alert links a runbook in `docs/runbooks/`. An alert without a runbook is not merged.

## Health

- `/livez` (process alive, no dependencies) and `/readyz` (dependencies reachable, migrations applied) on every service. Neither requires auth; neither leaks versions or internals.

## Mobile and web clients

- Crash and error reporting with release + build identifiers and symbolication (mapping files / dSYMs uploaded in CI).
- Client spans for app start, screen load and API calls, propagating `traceparent` to the backend.
- No PII in client telemetry; respect user consent settings.

## Self-hosted customers

Telemetry is **off by default** for self-hosted installs and never phones home
without explicit opt-in. The bundle ships its own collector config so the
customer can point it at their stack.

## Review checklist

- [ ] New endpoint/consumer/job has span, RED metrics and outcome log.
- [ ] Outbound calls propagate context.
- [ ] No high-cardinality labels; no PII in any signal.
- [ ] Failure modes of the feature are visible on a dashboard or as an alert with a runbook.
