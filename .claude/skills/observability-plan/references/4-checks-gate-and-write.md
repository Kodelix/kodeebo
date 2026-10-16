# /observability-plan - Inputs, Checks, Gate, Write

> Shared by all modes. A check that did not run is `not run - reason`, never
> passed.

## 1. Mode and inputs (Phase 1)

Resolve the mode from the argument (`plan`, `slos`, `runbooks`); none = ask.
Record each input FOUND or ABSENT and state the gate the output feeds:

| Mode | Feeds |
|---|---|
| `plan` | DoD gate 4 evidence for the feature (story Definition of Done), `/dev-story`, `/story-done` |
| `slos`, `runbooks` | **SRE-SLO** at `/gate-check` Hardening -> Release (`workflow: full`), `SRE-OPERABILITY`, `/release-checklist`, `/launch-checklist` |

Inputs: `design/product-brief.md`, specs, `docs/research/` notes (section 8),
`docs/architecture/perf-budgets.md`, `docs/architecture/slos.md`,
`docs/runbooks/`, alert rule files and dashboards (paths from
`observability-engineer`), `deploy/hosted/`, `deploy/self-hosted/`, load-test
evidence under `production/qa/evidence/`, the telemetry-backend ADR, the pins and
`docs/stack-reference/opentelemetry/`. An absent input is stated and its
dependent claims are `NOT ASSESSED`, not guessed.

## 2. Mechanical checks per mode

### `plan`
| # | Check | Result |
|---|---|---|
| P1 | Every surface of the feature (endpoint, consumer, job, provider call, client) has a span, RED metrics (or business metric with reason) and an outcome log | ran / gaps |
| P2 | Span names and metric labels are route templates / low-cardinality; each label has a stated bound | ran |
| P3 | No label of user ID, request ID, email or raw URL; `tenant_id` only on bounded business metrics | ran |
| P4 | No forbidden field in any log event (passwords, tokens, OTP, API keys, card data, bodies, national IDs, phone, email in clear) | **read-through** of the plan's field lists |
| P5 | Context propagation on every outbound call and message | ran |
| P6 | 4xx not recorded as span errors | ran |
| P7 | Failure modes of the spec each map to a panel or an alert with a runbook | ran / gaps |
| P8 | Self-hosted: off by default per runtime, Collector only, opt-in | ran / n/a |
| P9 | `NOT SOURCEABLE` items listed and routed to `/research` | ran |
| P10 | Retrospective: emitted instrumentation cited `file:line`; code root resolved and non-empty | ran / NOT ASSESSED |

### `slos`
| # | Check | Result |
|---|---|---|
| S1 | The user confirmed the critical-journey list | ran / unconfirmed |
| S2 | Each journey has an availability and a latency SLO; list journeys with none (SRE-SLO 1) | ran |
| S3 | Each SLO has SLI (good/valid + metric name), target, window (SRE-SLO 2); budget arithmetic shown | ran |
| S4 | Each SLI has a named emitter (plan item or `file:line`) and a dashboard panel (SRE-SLO 3) | ran / no emitter |
| S5 | Latency thresholds cite a `perf-budgets.md` row and a measured p95 (SRE-SLO 4) | ran / no budget / no measurement |
| S6 | Burn-rate alerts have windows, thresholds and a **cited source**; cause alerts for DB down, disk, certificate, backup (SRE-SLO 5) | ran / source NOT SOURCEABLE |
| S7 | Every alert has a runbook path and the file exists and is non-empty (SRE-SLO 6); `Glob` each path and `Read` it | ran / MISSING list |
| S8 | Error-budget policy written, decided by the user, with who decides (SRE-SLO 8) | ran / absent |
| S9 | No PII in alerts; routing documented (SRE-SLO 9) | read-through / absent |

### `runbooks`
| # | Check | Result |
|---|---|---|
| R1 | One runbook per alert; none MISSING | ran |
| R2 | Template headings present in each | `Grep '^## '` per file |
| R3 | Each has symptom + alert, customer impact, diagnosis with dashboard/query, mitigation, rollback or escalation, owner (SRE-SLO 7) | ran |
| R4 | Every command is sourced from the stack reference/repo or marked owed | ran |
| R5 | DESTRUCTIVE steps marked with the confirming role | ran |
| R6 | No secrets, tokens, customer data, connection strings | **read-through** |
| R7 | Last verified state per runbook (executed / never executed) | ran |

Give each check a result and, where it fails, an owner. `Grep`/`ls` results are
evidence; a judgement from memory of the draft is `not assessed`.

## 3. Verdict (first match wins)

| Verdict | When |
|---|---|
| `BLOCKED` | PII or a secret in a signal or alert (P4, S9, R6); a high-cardinality label (P3); an alert with no runbook (S7, R1); self-hosted telemetry on by default (P8); an SLI with no planned emitter (S4); SRE-SLO NOT READY on a blocker; a declined write (`BLOCKED — write declined by user`, nothing reported as COMPLETE) |
| `NOT ASSESSED` | a needed fact is `NOT SOURCEABLE` (burn-rate source, backend undecided -> alert rules not written, semconv/OTel item); the journey list unconfirmed; a latency threshold with no budget or measurement; a retrospective code root unreadable; the gate agent could not run. Each cause named with what closes it |
| `COMPLETE WITH GAPS` | non-blocking checks open with owners; runbooks written but never executed; SRE-SLO CONCERNS |
| `COMPLETE` | all checks ran clean, every fact sourced or marked, runbooks executed in a drill or staging (not merely written) for `runbooks` mode, gate READY or recorded skipped by review mode |

`NOT ASSESSED` ranks above `COMPLETE` and below `BLOCKED`. In practice a
first-time `runbooks` run cannot be `COMPLETE`: nothing was executed; the report
says that, not that the runbooks are fine.

## 4. SRE-SLO (`slos`, `runbooks`; `full` review mode)

Write the files first (section 5), then gate, so the director reads what is on
disk. Spawn `sre-lead` via `Agent`; the prompt tells it to read
`.claude/docs/director-gates/sre-slo.md` first (you do not read it) and passes:
`docs/architecture/slos.md`; the critical journeys; the alert rule files and
dashboards (or `none - backend undecided`); `docs/runbooks/`;
`docs/architecture/perf-budgets.md` and load-test results; and
`.claude/docs/observability-standard.md`.

In `lean` or `solo`: record `SRE-SLO skipped - [mode] mode`. At `workflow` below
`full`: `SRE-SLO skipped - not required at workflow: [tier]`. Self-hosted only:
`SRE-SLO not applicable - self-hosted only`. Solo skips the director's opinion,
never the checks in section 2. Verdict mapping: READY -> no change; CONCERNS ->
`COMPLETE WITH GAPS` at best, each concern an open row with an owner; NOT READY ->
`BLOCKED`; NOT ASSESSED -> `NOT ASSESSED`. Cannot be spawned: `SRE-SLO NOT
ASSESSED - [reason]`.

## 5. Ask and write

Present the draft and the checks. Name every destination and ask once per
mode:

| Mode | Paths |
|---|---|
| `plan` | `docs/architecture/observability-plans/<feature>.md` |
| `slos` | `docs/architecture/slos.md` (create or update; show changed rows first) |
| `runbooks` | `docs/runbooks/<name>.md` for each runbook, listed |

"May I write [paths]?" Write only after approval; verify each file exists with
`Read` before reporting it written. Alert rule files and dashboards are **not**
written by this skill: they are backend-specific, owned by
`observability-engineer`, and listed in the handoff. Gate edits (concerns as open
rows) ask again.

## 6. Report

```text
Observability plan: <mode> <feature|product>   Verdict: COMPLETE | COMPLETE WITH GAPS | NOT ASSESSED | BLOCKED
Designed by: <sre-lead/observability-engineer> | this session (reason)   Tier: <workflow>   Edition(s): ...
Checks: P1..P10 | S1..S9 | R1..R7  each ran / not run - reason
SLOs: N journeys, N SLOs; SLIs with emitter N / without N; budget policy: written | absent
Alerts: burn-rate N (source: cited | NOT SOURCEABLE), cause N; runbooks: N written, N executed, N MISSING
Backend: <ADR | undecided -> rule files not written>
Self-hosted: telemetry off by default <yes|not stated>; Collector only
NOT SOURCEABLE -> /research: <list>
SRE-SLO: READY | CONCERNS | NOT READY | NOT ASSESSED | skipped - <reason> | not applicable
NOT ASSESSED / BLOCKED causes: <each, with what closes it>
Written: <paths | not written>
Handoff: alert rule files + dashboards (observability-engineer), Collector bundle (infra-engineer)
```
