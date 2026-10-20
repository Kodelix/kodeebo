---
name: observability-plan
description: "Instrumentation plan per observability-standard.md (spans, RED/USE metrics, structured logs, no PII), SLOs per critical journey with burn-rate alerts, and runbooks. Modes: plan | slos | runbooks. Self-hosted Collector off by default. Runs SRE-SLO."
argument-hint: "plan [feature-slug] | slos [journey] | runbooks [alert|all] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/observability-plan/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,performance.enforce,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). **SLO targets, the
error-budget policy and who is paged are the user's decisions in every mode.**

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax the engineering: DoD gate 4 (spans, RED
metrics, structured logs with `trace_id`, no PII) and "an alert without a runbook
is not merged" apply at every tier. What a tier changes is the SLO *document*:
`docs/architecture/slos.md` is required for the SRE-SLO gate at `workflow: full`
only (`sre-slo.md`); the skill writes it at any tier on request and says which
gate it feeds.

# Observability Plan

If a feature fails in production at 3 a.m., the on-call engineer must answer
*what broke, for whom, since when, and why* from telemetry alone, without adding
a log line and redeploying (`.claude/docs/observability-standard.md`). This skill
plans that, in three modes, using OpenTelemetry (SDK pins in
`docs/stack-reference/pins.yaml`, facts in `docs/stack-reference/opentelemetry/`).
The code and the dashboards are built by `observability-engineer` and the stack
leads; the SLOs and alert policy are `sre-lead`'s.

| Mode | Produces | Template |
|---|---|---|
| `plan [feature]` | the instrumentation plan: spans, RED/USE metrics, log events, PII exclusions, failure-mode visibility | none (the standard's checklist); file `docs/architecture/observability-plans/<feature>.md` |
| `slos [journey]` | SLIs, SLOs, error budget and policy, burn-rate and cause alerts per critical journey | `.claude/docs/templates/slos.md` -> `docs/architecture/slos.md` |
| `runbooks [alert\|all]` | one runbook per alert | `.claude/docs/templates/runbook.md` -> `docs/runbooks/<name>.md` |

No argument: ask which mode (`AskUserQuestion`), recommending `plan` for a
feature in `Pre-Production`/`Production` and `slos` then `runbooks` before
Hardening.

> **Facts not in the stack reference are `NOT SOURCEABLE`.** The burn-rate
> windows and multipliers (the SRE reference), the alert-rule syntax of the
> chosen backend, Prometheus-style exported metric names, OTLP endpoint ports, the
> Java global-disable switch, `otelslog` wiring and the Compose `profiles:` syntax
> are not sourced (`opentelemetry/best-practices.md` "Knowledge gap warning",
> `docker-compose/best-practices.md`). They are never written from memory: they go
> to `/research`, and any plan item that depends on one is marked `NOT SOURCEABLE`.

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `BLOCKED`: PII or a secret in any signal, a high-cardinality label
> (user ID, request ID, email, raw URL), an alert without a runbook, self-hosted
> telemetry on by default, an SLO whose SLI no instrumentation will emit. `NOT
> ASSESSED`: a needed fact is `NOT SOURCEABLE` (burn-rate source, backend
> undecided), latency thresholds with no budget or measured p95, the critical
> journey list unconfirmed, retrospective code unreadable, a runbook never
> exercised. SRE-SLO's own words (READY / CONCERNS / NOT READY) are recorded
> beside, never merged into these.

---

## Phase 1: Mode, Inputs, Scope

**Read `references/4-checks-gate-and-write.md` section 1 now**, then the mode's
reference below. Resolve the mode, record every input as FOUND or ABSENT
(spec, research note section 8, `perf-budgets.md`, `slos.md`, existing runbooks,
alert rule files, `deploy/hosted/` and `deploy/self-hosted/`, load-test
evidence, the backend ADR, `distribution.model`), and say which gate the output
feeds. Read it again if the conversation was compacted or resumed.

## Phase 2: Mode `plan`

**Read `references/1-plan-mode.md` now and follow it.** Spawn
`observability-engineer` with the fixed brief there; it returns the plan as text.
You check it against the standard's four-item review checklist and the
cardinality and PII rules, and the user decides what is in scope.

## Phase 3: Mode `slos`

**Read `references/2-slos-mode.md` now and follow it.** The user confirms the
critical journeys and chooses targets; `sre-lead` drafts and spawns
`observability-engineer` / `performance-engineer` for the pieces they own; the
latency thresholds come from `perf-budgets.md` and measured load-test p95, not
from the template's examples.

## Phase 4: Mode `runbooks`

**Read `references/3-runbooks-mode.md` now and follow it.** One runbook per
alert, written for someone paged at 3 a.m. who did not build the system; every
command comes from the stack reference or the repository, or is marked as owed.

## Phase 5: Checks, Gate, Write

**Read `references/4-checks-gate-and-write.md` now and follow it.** It runs the
mechanical checks for the mode, derives the verdict, spawns **SRE-SLO** in `full`
review mode for `slos` and `runbooks`, asks before writing, and reports.

**Checkpoint.** Before the final report, update `production/session-state/active.md`
per `.claude/docs/checkpoint-handoff.md`: Current task `/observability-plan
<mode> <target> — <verdict>`, Next step = the first Recommended Next Step for the
mode, plus Blocked on / Files in progress / Open questions; append the Notes
line. BLOCKED, NOT ASSESSED or a declined write still updates the checkpoint with
the blocker.

---

## Error Recovery Protocol

**First, verify the artifact.** A spawned agent told to return text must return
tables, not a preamble. If any agent returns BLOCKED, errors or cannot complete:
surface it immediately, do not proceed past a dependency it blocks, offer skip /
retry narrower / stop via `AskUserQuestion`, and always produce a partial
report. A skip does not clear a block. A gate agent that could not run is `NOT
ASSESSED - [what was missing]`. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Decision records follow the tier.** "An ADR" in this skill means an ADR (at
  `modes.workflow: minimal`, an entry in the brief's decision log, `design/product-brief.md`).
- **Question -> Options -> Decision -> Draft -> Approval.** Targets, the
  error-budget policy, paging and the scope of instrumentation are the user's.
- **Never write an SLO target, a burn-rate multiplier, a metric export name, a
  query language or a command from memory.** Targets are chosen by the user for
  the product; the template's numbers are examples to react to; unsourced
  thresholds are marked as such.
- **No PII, no secret, no high-cardinality label in any signal or alert** - not in
  examples either.
- **An alert without a runbook is not merged.** This skill never lists an alert
  without its runbook path.
- **A runbook is verified by being executed.** This skill cannot execute it; the
  runbook says `Last verified: NOT VERIFIED` until a drill or staging run, and the
  report says so.
- **Self-hosted telemetry is off by default and never phones home without opt-in;**
  the bundle ships only the OTel Collector with exporters disabled
  (`.claude/docs/standing-decisions.md` L4).
- **A check that did not run is reported as `not run`, never as passed.**
- A skipped, dismissed or empty answer is not an answer: act on nothing, ask
  again in plain text and wait.

---

## Recommended Next Steps

- `plan` done: `/create-stories` or `/story-readiness` (observability evidence per story); `/dev-story` builds it via the stack lead and `observability-engineer`
- `slos` done: `/observability-plan runbooks all`, then `/load-test` to measure the p95 the latency SLOs depend on; before Hardening -> Release run `/gate-check`
- Burn-rate source or backend undecided: `/research burn-rate-alerting` and `/research` the telemetry backend, then `/architecture-decision` (the backend is an ADR)
- Alert rule files and dashboards: `observability-engineer` via `principal-engineer`, as code in `deploy/hosted/` and `deploy/self-hosted/`
- Self-hosted bundle: `infra-engineer` for the Collector service, the profile that keeps it off by default and the diagnostic-bundle command
- An incident used a runbook: `/incident`, then `/postmortem`; update the runbook's history
