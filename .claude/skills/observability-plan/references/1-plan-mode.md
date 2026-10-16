# /observability-plan - Mode `plan`

> The instrumentation plan for one feature, against
> `.claude/docs/observability-standard.md` (DoD gate 4). Output:
> `docs/architecture/observability-plans/<feature>.md`.

## 1. Inputs

| Input | Path | Why |
|---|---|---|
| Spec, research note | `design/specs/<slug>.md` (NFR observability), `docs/research/<slug>.md` section 8 | the surfaces and what the research said to emit |
| Contract | `contracts/openapi/*.yaml` operations of the feature | route templates for span names and metric labels (`api-standards.md` "Observability") |
| Cache design, migration plan, threat model | `docs/architecture/cache-designs/<slug>.md`, `migration-plans/<slug>.md`, `threat-models/<slug>.md` | cache metrics, backfill metrics, detection mitigations |
| Performance budget | `docs/architecture/perf-budgets.md` | budgets the metrics should expose |
| Stack, distribution | resolved `stack`, `distribution.model` | Go or Ktor instrumentation; client SDKs; self-hosted rules |
| Existing instrumentation (retrospective) | code roots from `bash .claude/hooks/yaml-helper.sh resolve_code_root` | what is already emitted, with `file:line` |
| OTel facts | `docs/stack-reference/opentelemetry/` (`VERSION.md`, `best-practices.md`, `breaking-changes.md`), `pins.yaml` `opentelemetry` | SDK versions, semconv stability, sampling, cardinality, Collector pipeline |

Design-time or retrospective: ask. Design-time = everything is `Planned`. In a
retrospective plan an emitted span or metric is cited `file:line`; an unreadable
or empty code root makes those claims `NOT ASSESSED - no source under <root>`.

## 2. What the plan covers (standard, section by section)

For each **inbound request, consumed message and scheduled job** of the feature:

**Traces**
- A span that starts or continues the trace; `traceparent` propagated on every
  outbound HTTP call and message.
- Spans on: HTTP server/client, DB queries, cache calls, queue publish/consume,
  each use case, each external provider call.
- Low-cardinality names: `GET /v1/invoices/{id}`, `InvoiceService.Pay` - from the
  contract's route templates, never raw IDs.
- Attributes: OTel semantic conventions at the pinned `semconv`; product
  attributes under `app.` (`app.tenant_id`, `app.plan`, `app.feature`,
  `app.provider` for provider calls).
- Errors: record the exception and set status ERROR; **client-caused 4xx are not
  span errors**.
- Sampling: parent-based; head ratio per environment; tail sampling in the
  Collector keeps errors and slow traces (`opentelemetry/best-practices.md`
  section 4: the `tail_sampling` processor is in the contrib image).

**Metrics**
- **RED** for every endpoint and consumer: rate, errors, duration histogram. Use
  the stable HTTP names and attributes (`http.server.request.duration`,
  `http.request.method`, `http.response.status_code`, `url.path` as a route
  template) and the semconv migration order in `opentelemetry/best-practices.md`
  section 2. Messaging semantic conventions are Development: pin and expect
  renames. Exported (backend-specific) metric names are `NOT SOURCEABLE`.
- **USE** for every resource the feature touches: DB pool (in use, idle, wait),
  cache hit ratio and latency, queue depth and consumer lag, goroutines or
  coroutines, heap.
- **Business metrics** per feature where they matter: signups, activations,
  payments succeeded/failed, OTPs sent/verified, licence activations.
- **Cardinality budget:** never label with user ID, request ID, email or raw URL.
  `tenant_id` only on low-volume business metrics and only if the tenant count is
  bounded; otherwise exemplars and traces. The SDK folds overflow beyond the
  default limit (`opentelemetry/best-practices.md` section 5): list every label per
  metric with its cardinality bound.

**Logs**
- Structured JSON, one event per line, via the platform logger (Go `log/slog`;
  Kotlin SLF4J + Logback JSON). Required fields: `timestamp`, `level`, `msg`,
  `service`, `version`, `env`, `trace_id`, `span_id`, `tenant_id` when known.
- Levels: ERROR needs a human; WARN degraded but handled; INFO state changes and
  business events; DEBUG off in production.
- **Never log:** passwords, tokens, OTP codes, API keys, card data, full
  request/response bodies, national IDs, phone numbers, or emails in clear (hash
  or mask). The plan lists, per log event, the fields it carries and states each
  is not in that list.
- Log the decision, not the noise: one line per significant outcome.
- The log-to-OTel bridge wiring (Go `otelslog`, Logback appender defaults) is
  partly `NOT SOURCEABLE`: mark those items and route to `/research`.

**Health:** `/livez` (alive, no dependencies) and `/readyz` (dependencies
reachable, migrations applied) on every service; neither requires auth; neither
leaks versions.

**Clients (web and mobile, per `stack`):** crash and error reporting with release
and build identifiers and symbolication (mapping files, dSYMs uploaded in CI);
client spans for app start, screen load and API calls propagating `traceparent`;
**no PII in client telemetry**; respect consent. The client SDKs' stability is
mixed (`opentelemetry/VERSION.md`): state the SDK and its stability for each
client; Android has no stability table in the reference (`NOT SOURCEABLE`).

**Failure-mode visibility:** for each failure mode in the spec's Edge Cases, name
the dashboard panel or the alert (with its runbook, mode `runbooks`) that shows
it. A failure mode nobody would see is a gap.

**Detection:** security events from the threat model's detection column go to the
append-only per-tenant audit log (`security-baseline.md`).

## 3. Self-hosted

Telemetry is **off by default** and never phones home without explicit opt-in.
The bundle ships **only the OTel Collector** (Apache-2.0) with its config so the
customer can point it at their own stack; no Grafana/Loki/Tempo/Mimir
(`docs/ROADMAP.md` L4; `.claude/rules/deploy.md`). The plan states, per runtime:

| Runtime | Off-by-default mechanism | Source status |
|---|---|---|
| SDK-level | `OTEL_SDK_DISABLED` (default `false`; `true` makes all signals a no-op) | sourced (`opentelemetry/best-practices.md` section 1) |
| Go | no agent: initialisation of the SDK and exporters is gated on configuration; no exporter registered when telemetry is off | inference in the reference |
| Java/Ktor agent | `OTEL_LOGS_EXPORTER=none` (the 2.x agent exports logs over OTLP by default) | sourced; the global instrumentation disable switch is `NOT SOURCEABLE` |
| Client SDKs | must not send to a vendor endpoint by default | inference in the reference |
| Collector service | not started by default via a Compose profile; exporters disabled | the exact `profiles:` behaviour is `NOT SOURCEABLE` in `docker-compose/best-practices.md` |

Collector pipeline order for the config the bundle ships, from the reference
(inference): `receivers -> memory_limiter -> attributes/transform/redaction (PII)
-> tail_sampling -> batch -> otlphttp exporter with a sending queue`, contrib
image `otel/opentelemetry-collector-contrib` at the `pins.yaml` tag. The
customer opt-in step and the diagnostic-bundle command for support are owed by
`infra-engineer`; mark them `Planned` if not found.

## 4. Fixed brief: `observability-engineer`

Fill only the `{...}` slots. Add nothing else.

```text
Draft the instrumentation plan for /observability-plan plan. Return text only;
write no file.

Feature: {slug}   Mode: {design-time | retrospective}   Stack: {the stack line}
Editions: {hosted | self-hosted | hybrid}   SDK pins: {pins.yaml opentelemetry keys}
Surfaces (endpoints, consumers, jobs, provider calls, clients): {list from the
spec/contract}
Inputs (read each; ABSENT ones are not to be guessed): {paths with FOUND/ABSENT}
Method: follow .claude/skills/observability-plan/references/1-plan-mode.md section 2
(traces, metrics, logs, health, clients, failure-mode visibility, detection) and
section 3 (self-hosted), against .claude/docs/observability-standard.md and
docs/stack-reference/opentelemetry/.

Return, per surface: span name (route template), attributes, status/error rule;
RED metrics and any USE or business metric with each label and its cardinality
bound; each log event (level, message intent, fields) with a statement that no
forbidden field is present; propagation points; the failure modes it makes
visible and the dashboard panel or alert; for retrospective mode, file:line of
what exists. List every item you could not source as NOT SOURCEABLE with what you
searched. Never write a metric export name, an endpoint port, a flag or an env
var from memory.
```

## 5. Check the returned plan

Against `observability-standard.md` "Review checklist":

- [ ] Each new endpoint/consumer/job has a span, RED metrics and an outcome log.
- [ ] Outbound calls propagate context.
- [ ] No high-cardinality labels; no PII in any signal.
- [ ] Failure modes are visible on a dashboard or as an alert with a runbook.

and: names are route templates; 4xx is not a span error; business metrics only
where useful; the self-hosted off-by-default mechanism is stated per runtime;
every `NOT SOURCEABLE` item is listed. Send gaps back once before filling them
yourself. Then run `4-checks-gate-and-write.md`. The plan is not a deployment:
dashboards and alert rule files are built later by `observability-engineer`.
