# /team-perf — Handoff Contract

## Role in Pipeline
Orchestrates one performance cycle for a feature, endpoint, journey, layer or release:
budgets first (`performance-engineer`, reviewed by `sre-lead`), then profiling per
layer (`/perf-profile`), k6 load tests (`/load-test`), ranked fixes implemented by the
stack leads, then re-measurement against the budgets with before/after evidence. Called
directly by the user; reads and feeds `/story-done` (Performance evidence),
`/release-checklist` and `/gate-check` (load-test results for SRE-OPERABILITY, and
SRE-SLO at `workflow: full`), `/observability-plan` and `/team-hardening`. This
pipeline has no director gate of its own.

## Inputs Consumed

| File | Used for | Absent means |
|---|---|---|
| Argument (feature / endpoint / journey / layer: backend\|db\|web\|android\|ios / release), `--review full\|lean\|solo` | scope; `--review` overrides `review_mode` | usage guidance is output; no agents spawned, no files read, no `AskUserQuestion` |
| `project.yaml` via `resolve_config` (`review_mode`, `automation`, `team.size`, `workflow`, `qa.level`, `testing.strict`, `performance.enforce`, `stack`, `tenancy`) | active set, enforcement, layers | defaults in `.claude/docs/config-resolution.md`; an unset layer or empty `resolve_code_root` result is `NOT ASSESSED` for that layer, never "fast enough"; `performance.enforce` unset = the defaults in `coding-standards.md` |
| `docs/architecture/perf-budgets.md`, `docs/architecture/slos.md` | budgets and the SLOs they must not exceed | ABSENT budgets → Phase 2 proposes them and creates the file via `/perf-profile` from `.claude/docs/templates/perf-budgets.md`; no budget and the user will not set one → raw numbers measured, each such surface `NOT MEASURED`, verdict at best `COMPLETE WITH GAPS` |
| `design/specs/`, stories, architecture doc for the layers, earlier `production/qa/evidence/` | hot paths, data volume, tenant mix, baseline | stated ABSENT; a previous run is the baseline when present |
| Load-test target named by the user; toolchain (`k6`, Lighthouse CI, `pprof`/JFR, device, macOS host) | where and how to measure | no named target → no measurement phase and the surface is `NOT MEASURED`; missing tool, device or macOS host → `NOT ASSESSED — [tool] not installed` (or `no device`, `macOS host not available`); nothing is installed without asking |

### Preconditions
- An argument is given (else usage guidance only)
- The user names the load-test target in this session at the Phase 1 gate (`AskUserQuestion`); this is never delegated to an `automation` mode. Allowed: the compose dev stack (`docker compose -f deploy/compose.dev.yaml up -d --wait`), a dedicated test stack, or a staging environment the user names explicitly holding seeded or synthetic data only. Production and shared environments are refused; real customer data is never used
- Hardware, versions and seeded data volume (rows per table, tenants, tenant skew) are recorded; a run on an empty database is not a performance result
- The active set is announced before Phase 1: agents spawned and agents named but not spawned at the resolved `team.size`
- Budgets are approved, adjusted or waived (reason, owner, date) at the Phase 2 gate before anything is measured
- User gates are Phases 1, 2, 4 and 6, each labelled a phase gate; at `individual`, `sre-lead` signs only Phases 2 and 6, and the user decides at all four

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED` / `BLOCKED — write declined by user`.
Precedence, first match wins: `BLOCKED` (both forms), `NOT ASSESSED`, `COMPLETE WITH GAPS`,
`COMPLETE`. Per surface: `MEETS BUDGET` / `MISSES BUDGET (gap)` / `NOT ASSESSED — [reason]`
(tool, device, macOS host or representative data unavailable) / `NOT MEASURED` (no budget or
no named target only). Consumed: `/load-test` verdicts (PASS / PASS WITH CONCERNS /
NOT ASSESSED / FAIL).
- `COMPLETE`: every surface in scope measured against an approved budget, fixes verified, no miss.
- `COMPLETE WITH GAPS`: the cycle ran; remaining gaps are a surface with no budget or target (`NOT MEASURED`), a waived budget, or a miss under `performance.enforce: warn` / `off`. Never reported as met.
- `NOT ASSESSED`: a surface in scope could not be measured (`NOT ASSESSED — [tool] not installed`, no device, macOS host not available, no representative data).
- `BLOCKED`: `performance.enforce: block` and a budget is missed (honoured as a blocker, never downgraded), or the stack or target could not be used; a partial report is produced.
- `BLOCKED — write declined by user`: the report or a fix-set write was declined; nothing is reported as `COMPLETE`.
`qa.level: minimal` does not waive a Performance story's load-test evidence.

## Outputs Produced

| File | Guaranteed sections |
|---|---|
| `production/qa/evidence/perf-[slug]/team-perf-report.md` | scope; active set; budgets (approved / waived); per-surface measured vs budget with tool versions; load-test verdicts; fixes made with before/after numbers; `performance.enforce` outcome; every `NOT ASSESSED` / `NOT MEASURED` with its reason. Written only after "May I write the team performance report to ...?" and a yes |
| `production/qa/evidence/perf-[slug]/budget-proposal.md`, `db-plans.md`, `data-review.md`, `bench-android.md` / `bench-ios.md`, `fix-routing.md`, `after/` | per-agent outputs of `performance-engineer`, `postgres-specialist`, `data-lead` (studio, only when a hotspot is database-bound), `android-lead` / `ios-lead`, `principal-engineer` (finding, owner, story, expected gain), `performance-engineer` re-measure |
| `production/qa/evidence/perf-[slug]/` (k6 summaries, profiles, plans, Lighthouse) and, for a story, `production/qa/evidence/[story-id]/` | before/after evidence with environment, data volume and the budget checked |
| `docs/architecture/perf-budgets.md` | created or updated only through `/perf-profile` or after "May I write [changes] to ...?" (in-place `Edit`) |
| Fix code and tests | only the approved file set, by the stack leads, one change per fix, each a `/dev-story` story |
| `production/session-state/active.md` | this skill's own `## Perf pipeline — <slug>` block, replaced in place with `Edit` (added after existing content if absent; `Write` only if the file is absent; no other block touched): scope, phase reached, result (the verdict), report path, next command, date |

`/perf-profile` and `/load-test` write their own artifacts and ask before writing.

### Output Guarantees
- Re-measurement uses identical hardware, data volume, warm-up, run duration and tool versions, at least three runs, reporting p50/p95/p99, error rate, throughput, the saturated resource and run-to-run variance; a change smaller than the variance is "not significant"
- Go changes on a budgeted hot path include `go test -bench -benchmem` before/after and the pprof; JVM changes include a JFR capture; affected layer suites are re-run with `/test` (a faster endpoint with a newly red test is not a pass)
- `ios-lead` Instruments runs on a macOS host only (`NOT ASSESSED — macOS host not available` on Linux); no device → `NOT ASSESSED — no device`; the load generator's own CPU is checked
- A named artifact that is not on disk is a failed phase; a skipped agent's section stays a named gap; a partial report is always produced
- At `studio`, `data-lead` is consulted in Phase 3 whenever a hotspot is database-bound (slow query, N+1, lock wait); at smaller sizes that review routes through the nearest active core agent with an informational note
- At `team.size: studio` an adversarial verification pass runs and the report says so; at `individual`, `sre-lead` is invoked only at the budgets and verification phase gates
- Dated lines use `date +%F`

## Immutability Rules
- Subagents write without asking only to paths this skill named, as new artifacts under `production/`, `docs/` or a test directory, in a phase gate; implementation files are written only after the file set was approved once
- No `Edit` of source or config by the orchestrator beyond `perf-budgets.md` (approved) and the `active.md` line; shell commands (compose, k6, profilers, Go benchmarks) are run by the specialists and leads through `Agent`, or by `/load-test` and `/perf-profile`; this skill itself grants compose bring-up, log reads, helper calls and `date`
- Never spawns SRE- or any PHASE-GATE director gates; those run from `/gate-check`, `/release-checklist`, `/team-release` and consume this output
- A declined report write is `BLOCKED — write declined by user`

## Hard Constraints (Never Violate)
- Production is never a target; real customer data is never used; a shared environment is refused
- No optimisation off the hot path; no index "just in case" (each justified by a plan and weighed against write cost); pools, timeouts and limits are never raised to hide a slow query; a cache proposal comes with a measured hit-ratio gain and invalidation story (`/cache-design`)
- Keyset pagination for sets that can grow; N+1 excluded by a query-count assertion in an integration test
- A fix that conflicts with an ADR or the clean-architecture rules is surfaced, not traded for a number
- `performance-engineer` proposes; it never changes product behaviour

## Downstream Skill Expects
`/story-done` takes the before/after folder as Performance evidence; `/release-checklist` and `/gate-check` read the load-test results for SRE-OPERABILITY; `/observability-plan` takes dashboards and alerts the findings call for; `/team-hardening` for the combined pre-release pass; `/test-flakiness` for repeated flakiness in perf runs. `NOT ASSESSED` and `NOT MEASURED` surfaces stay unmet downstream.

## Known Fragile Points
- `ios-lead` benchmarking needs a macOS host and `android-lead` a device; either gap is `NOT ASSESSED`, never zero findings
- Nested spawning from a subagent may be unavailable; this skill spawns every agent
- A previous run on a different data shape is not a valid baseline
