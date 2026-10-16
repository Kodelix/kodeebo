# /observability-plan - Handoff Contract

## Role in Pipeline
DoD gate 4 planning (`plan`) and the reliability documents behind SRE-SLO
(`slos`, `runbooks`). Called by `/team-feature`, `/team-hardening`,
`/release-checklist`, `/launch-checklist`; reads `/research` (section 8),
`/design-spec`, `/api-contract`, `/cache-design`, `/db-migration`, `/threat-model`,
`/perf-profile`, `/load-test`; read by `/gate-check` (SRE-SLO), `/story-done`,
`/incident`, `/postmortem`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Mode and feature or journey | Yes | - |
| `design/product-brief.md`, specs, research notes | When they exist | Yes |
| `docs/architecture/perf-budgets.md`, load-test evidence | For latency SLOs (absence = that threshold NOT ASSESSED) | Yes |
| `docs/stack-reference/opentelemetry/`, `pins.yaml` | Yes (gaps = `NOT SOURCEABLE`) | Yes |
| Telemetry-backend ADR | For alert rule files and dashboards (absence = not written) | Yes |
| `project.yaml` via `resolve_config` (`stack`, `distribution`, `workflow`, `review_mode`, `automation`) | Yes (unset = asked) | Yes |
| Existing `slos.md`, runbooks | For updates | Updated only on approval |

## Preconditions
- `slos`: the critical-journey list confirmed by the user. `runbooks`: alerts defined in `slos.md` or rule files, else `NOT ASSESSED`.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. SRE-SLO (full review mode,
`slos`/`runbooks`): READY / CONCERNS / NOT READY / NOT ASSESSED / skipped /
not applicable, recorded beside, never merged.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `docs/architecture/observability-plans/<feature>.md` | per-surface spans, RED/USE/business metrics with cardinality bounds, log events with field lists, propagation, failure-mode visibility, self-hosted off-by-default per runtime, NOT SOURCEABLE list | `plan`; written after approval |
| `docs/architecture/slos.md` | template sections; SLI with emitter; targets decided by the user; budget arithmetic; policy; alerts each with a runbook path | `slos`; written after approval |
| `docs/runbooks/<name>.md` | template headings; sourced or owed commands; DESTRUCTIVE marked; `Last verified: NOT VERIFIED` until executed | `runbooks`; written after approval |

## Output Guarantees
- No SLO target, burn-rate multiplier, metric export name or rule syntax is written from memory; unsourced items are marked and routed to `/research`.
- Alert rule files and dashboards are not written (backend-specific); they are listed in the handoff.
- Runbooks are never reported as verified unless executed.

## Immutability Rules
- No instrumentation, alert or dashboard code is written here.
- SLO targets and the budget policy are never decided or changed without the user.
- Specs, ADRs and stories are not edited here.
