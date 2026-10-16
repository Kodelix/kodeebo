---
name: team-perf
description: "Orchestrate the performance team — budgets in perf-budgets.md, profiling per layer, k6 load tests, ranked fixes implemented by the stack leads, and verification against the budgets with before/after evidence. sre-lead and performance-engineer lead; uses /perf-profile and /load-test."
argument-hint: "[feature | endpoint | journey | layer: backend|db|web|android|ios | release] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(docker compose logs *), Agent, AskUserQuestion, Edit, Skill, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(docker compose -f deploy/compose.dev.yaml ps), Bash(docker compose -f deploy/compose.dev.yaml ps *), Bash(docker compose -f deploy/compose.dev.yaml logs *), Bash(docker compose logs), Bash(bash "*/.claude/skills/team-perf/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
# Team Perf

If no argument is provided, output usage guidance and exit without spawning any agents or reading any files:
> Usage: `/team-perf [feature | endpoint | journey | layer | release] [--review full|lean|solo]` — name what to measure and improve (e.g., `invoice list endpoint`, `checkout journey`, `web shell bundle`, `release 1.4`). Do not use `AskUserQuestion` here; output the guidance directly.

When this skill is invoked, orchestrate the performance team through a structured pipeline: budgets first, then measurement, then fixes, then proof.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. **Naming the
load-test target is never delegated to a mode.** See `.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,workflow,qa.level,testing.strict,performance.enforce,stack,tenancy`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

`performance.enforce` (`warn` | `block` | `off`, above) decides whether a missed
budget blocks the Performance gate (DoD gate 6) or is reported as a warning;
`block` is honoured as a blocker, never downgraded. `unset` = the defaults in
`coding-standards.md`. `qa.level: minimal` does not waive a Performance story's
load-test evidence.

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns an SRE- or any PHASE-GATE. `SRE-OPERABILITY` (and
`SRE-SLO` at `workflow: full`) run from `/gate-check`, `/release-checklist` and
`/team-release` and **consume** this pipeline's output; a skipped or lean-mode
gate elsewhere waives the director's opinion, never this evidence.

`automation` drives the Decision Points note above.

**`team.size`**: which agents are active (orthogonal to review_mode and workflow).
- **`individual`** (default): `performance-engineer` only; `sre-lead` signs at the two phase gates that end in a decision about numbers (Phase 2 budgets, Phase 6 verification) and no others; the user decides at every gate (Phases 1, 2, 4, 6) and no agent signs the Phase 1 target or the Phase 4 triage.
- **`small`**: `sre-lead` + `performance-engineer` throughout, the stack lead(s) for the layer(s) a fix lands in (`go-lead`, `ktor-lead`, `web-lead`, `android-lead`, `ios-lead`, routed by `principal-engineer`), and `postgres-specialist` / `cache-specialist` when a plan or cache is implicated.
- **`studio`**: + `observability-engineer` (telemetry during runs), `infra-engineer` (test-stack sizing), `data-lead` (consulted in Phase 3 when a hotspot is database-bound: slow query, N+1, lock wait), and an adversarial verification pass: Phase 6 reviewers are told "your job is not to confirm the budget is met — find the run, tenant mix or data shape where it is not", and the report says the pass ran.
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — Phases 1, 2, 4 and 6, each labelled "Gate (phase gate)" below — whatever the `automation` mode.

**Announce the active set before Phase 1 — never let the collapse be silent.**
State in one line which agents this run will spawn and which the pipeline names
but will **not** spawn at the resolved `team.size`:

> `Active set (team.size: <resolved>): <agents for that size>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

The collapse is correct; without saying so a reader cannot tell a collapsed run
from a broken one.

## Team Composition

- **sre-lead** — SLOs and capacity context, budget sign-off, the link to production readiness
- **performance-engineer** — budgets, profiling, k6 scenarios, before/after evidence; proposes, never changes product behaviour
- **Stack leads** (`go-lead`, `ktor-lead`, `web-lead`, `android-lead`, `ios-lead`) — implement fixes in their layer, routed by `principal-engineer`
- **postgres-specialist**, **cache-specialist** — indexes, plans, cache design (`/cache-design`)
- **data-lead** (`studio`) — consulted in Phase 3 when a hotspot is database-bound (slow query, N+1, lock wait): schema, access-pattern and data-shape review of the profile's database findings; does not change the schema
- **observability-engineer**, **infra-engineer** — telemetry during runs; the test stack and its sizing (`studio`)

## How to Delegate

Use the `Agent` tool: `subagent_type: sre-lead` · `performance-engineer` · `principal-engineer` (fix routing) · `postgres-specialist` · `cache-specialist` · `data-lead` (studio, database-bound hotspots) · `android-lead` / `ios-lead` for device benchmarks · `observability-engineer` · `infra-engineer`.

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline, never a path to a document you already read. Independent agents are spawned in parallel — issue every independent `Agent` call before waiting for any result (`.claude/docs/coordination-rules.md`).

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." **Implementation files are the exception:** a lead writing a fix first returns the files it will create or change; its contract names them only after you asked once for the set and the user said yes.

| Phase / agent | Writes to |
|---|---|
| 2 performance-engineer | `production/qa/evidence/perf-[slug]/budget-proposal.md` (the budgets file itself is created or edited only through `/perf-profile` or after approval — it is an existing artifact) |
| 3 postgres-specialist | `production/qa/evidence/perf-[slug]/db-plans.md` |
| 3 data-lead (studio, database-bound hotspot) | `production/qa/evidence/perf-[slug]/data-review.md` |
| 3 android-lead / ios-lead | `production/qa/evidence/perf-[slug]/bench-[android\|ios].md` |
| 5 principal-engineer | `production/qa/evidence/perf-[slug]/fix-routing.md` |
| 6 performance-engineer (re-measure) | `production/qa/evidence/perf-[slug]/after/` |

`/perf-profile` and `/load-test` write their own artifacts and ask before writing.

> **Why this does not violate the Collaboration Protocol.** A subagent spawned here writes **without** asking, a deliberate, bounded exception. It holds only when: (1) the path is one **you** named in the prompt; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is a phase gate. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent.**

## Pipeline

### Phase 1: Load Context

Resolve the scope from the argument (feature, endpoint, journey, layer, release) and read, reporting each as FOUND or ABSENT:
- `docs/architecture/perf-budgets.md` (absent → Phase 2 creates it from the template via `/perf-profile`), `docs/architecture/slos.md`, `docs/architecture/perf-budgets.md` rows for the surfaces in scope
- the specs and stories for the scope (`design/specs/`), their hot paths, expected data volume and tenant mix; the architecture doc for the layers involved; earlier evidence under `production/qa/evidence/` (a previous run is the baseline)
- `stack` and `tenancy` from the resolved config; `resolve_code_root`. An empty code-root result or an unset layer is `NOT ASSESSED` for that layer, never "fast enough"
- **The load-test target.** Ask the user to name it (`AskUserQuestion`): the compose dev stack brought up with `docker compose -f deploy/compose.dev.yaml up -d --wait` (`run-and-observe.md`), or a dedicated test stack. **Production is never a target and real customer data is never used.** A shared environment is refused; a staging environment is allowed only when the user names it explicitly in this session and it holds seeded or synthetic data only. Record hardware, versions and the seeded data volume (rows per table, tenants, tenant skew) — a run on an empty database is not a performance result.
- **Toolchain.** `k6` installed? Lighthouse CI? `pprof`/JFR on the host? Device or macOS host for mobile benchmarks? Record each; absent ones are `NOT ASSESSED — [tool] not installed` later (the same wording for a missing device or macOS host). Nothing is installed without asking.

**Gate (phase gate):** the target is named by the user here (never by a mode). Report: "Performance cycle for [scope]. Layers: [list]. Budgets: [present / to be created]. Target: [named]. Data volume: [..]. Toolchain gaps: [..]. Ready?"

### Phase 2: Budgets (performance-engineer, reviewed by sre-lead)

`performance-engineer` proposes the product budget for every surface in scope from the defaults in `performance-standard.md` and `.claude/docs/templates/perf-budgets.md` — surface, metric, percentile, number, basis for any change, how measured — and per-endpoint/per-screen rows for the hot paths. `sre-lead` checks them against the SLOs (a budget looser than the SLO it feeds is a conflict, surfaced). A surface with no budget gets one **proposed before anything is measured**. A waived budget has a written reason, owner, date and the measured gap.

**Gate (phase gate):** `AskUserQuestion`: approve the budgets / adjust a number / waive one (reason, owner, date) / cancel. Create or update `docs/architecture/perf-budgets.md` only through `/perf-profile` (which creates it from the template if missing) or by asking "May I write [changes] to `docs/architecture/perf-budgets.md`?" — an approved change to the existing file is made in place with `Edit`.

### Phase 3: Profile (parallel)

Launch the agent tracks first, then run the profile in this session:

- **In this session:** `/perf-profile [scope]` — measures against the budgets, per-layer tools, ranked recommendations with expected gain and evidence.
- **Track agents (background, only for what the session cannot do alone):** `postgres-specialist` — `EXPLAIN (ANALYZE, BUFFERS)` as the non-owner application role and the `pg_stat_statements` top-5 for the touched queries; `android-lead` — Macrobenchmark cold start and jank on a device (no device → `NOT ASSESSED — no device`); `ios-lead` — Instruments cold start and hangs (**macOS host only**; on Linux `NOT ASSESSED — macOS host not available`); `data-lead` (studio) — when any profile or plan finding is database-bound (slow query, N+1, lock wait), reviews the access pattern and data shape behind it.

Collect all before Phase 4. Record per surface the measured value, the budget, and the tool and version — or `NOT ASSESSED — [tool | device | host | data] [reason]` when the surface could not be measured, or `NOT MEASURED` only for a surface that has no budget or no named target. Neither can be reported as met.

### Phase 4: Load Test

Run `/load-test [ramp | steady | spike] [surface]` for the hot endpoints and journeys the profile and the budgets name: ramp (find the knee), steady (expected peak), spike (burst and recovery), thresholds taken from the budgets plus an error-rate bound; a soak only when asked. Data volume and tenant mix stated. k6 not installed → `NOT ASSESSED — k6 not installed`; the pipeline continues for the other layers. The generator's own CPU is checked so it is not the bottleneck. Verdict words come from `/load-test` (PASS / PASS WITH CONCERNS / NOT ASSESSED / FAIL).

**Gate (phase gate):** present measured vs budget per surface, the saturated resource, and the ranked list of changes. `AskUserQuestion`: fix these (choose) / waive with reason / stop here.

### Phase 5: Fixes (stack leads)

Spawn `principal-engineer` with the ranked recommendations to route each to the owning lead (return contract: `fix-routing.md` — finding → owner → story → expected gain). Rules the leads work under:
- **One change per fix**, with the plan or profile that justifies it; no optimisation off the hot path; no index "just in case" — each index is justified by a plan and weighed against write cost (`postgres-specialist`).
- A cache proposal comes with a measured hit-ratio gain and the invalidation story → `/cache-design`; pools, timeouts and limits are never raised to hide a slow query.
- Keyset pagination for sets that can grow; N+1 excluded by a query-count assertion in an integration test; async for slow work.
- Each fix is a story for `/dev-story` (all eight DoD gates apply); the lead returns its file set, you ask once, it writes after a yes.

### Phase 6: Verify Against the Budgets

`performance-engineer` re-measures with **identical** hardware, data volume, warm-up, run duration and tool versions, **at least three runs**, reporting p50/p95/p99, error rate, throughput, the saturated resource and the run-to-run variance. A change smaller than the variance is "not significant". Go changes on a budgeted hot path include `go test -bench -benchmem` before/after and the pprof; JVM changes include a JFR capture. Re-run the affected layer suites with `/test` — a faster endpoint with a newly red test is not a pass.

Per surface: **MEETS BUDGET** / **MISSES BUDGET (gap)** / **NOT ASSESSED (why)** (tool, device, host or representative data unavailable) / **NOT MEASURED (no budget or target)**. Apply `performance.enforce`: `block` → a miss is BLOCKED for the story's Performance gate; `warn` → reported; `off` → measured and reported only. Save the before/after evidence — environment, data volume, the budget checked — to `production/qa/evidence/perf-[slug]/` (k6 summaries, profiles, plans, Lighthouse reports) and, for a story, `production/qa/evidence/[story-id]/`. At `studio`, run the adversarial pass.

**Gate (phase gate):** present per-surface results and the `performance.enforce` outcome. `AskUserQuestion`: accept the verification / re-open the fixes (back to Phase 5) / stop here. At `individual`, `sre-lead` signs the verification before the question is put; a `block` miss is not waivable here.

Ask: "May I write the team performance report to `production/qa/evidence/perf-[slug]/team-perf-report.md`?" Write only after a yes; on a no the verdict is `BLOCKED — write declined by user`. Take `[date]` from `date +%F`. Shell commands (compose, k6, profilers, Go benchmarks) are run by `performance-engineer`, the leads and specialists through `Agent`, or by `/load-test` and `/perf-profile`; this skill grants only the compose bring-up and log reads, the helper calls and `date`.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** Resume the agent
naming the unmet contract.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** A skipped agent's section stays a named gap. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Stack will not come up → that is the finding; capture `docker compose logs`, stop the measurement phases
- Empty or unrepresentative data → not a result; seed to the stated volume via `tools/seed/` or mark `NOT ASSESSED — no representative data`
- No budget and the user will not set one → measure and report raw numbers, each such surface is `NOT MEASURED` and the verdict is at best `COMPLETE WITH GAPS`
- Fix conflicts with an ADR or the clean-architecture rules → surface it; do not trade a rule for a number

## Output

A summary covering: scope, active set, budgets (approved / waived), per-surface measured vs budget with tool versions, load-test verdicts, the fixes made and their before/after numbers, `performance.enforce` outcome, and every `NOT ASSESSED` / `NOT MEASURED` with its reason.

Verdict: **COMPLETE** — every surface in scope measured against an approved budget, fixes verified, no miss.
Verdict: **COMPLETE WITH GAPS** — the cycle ran; named gaps remain that are not a tool or data failure: a surface with no budget or target (`NOT MEASURED`), a waived budget, or a miss under `performance.enforce: warn` / `off`. None is reported as met.
Verdict: **NOT ASSESSED** — a surface in scope could not be measured because a tool, device, macOS host or representative data was unavailable (`NOT ASSESSED — [reason]`); the named surfaces are not reported as met.
Verdict: **BLOCKED** — `performance.enforce: block` and a budget is missed, or the stack/target could not be used; partial report produced.
Verdict: **BLOCKED — write declined by user** — the report or a fix-set write was declined; nothing is reported as COMPLETE.

Precedence, first match wins: `BLOCKED` (both forms) → `NOT ASSESSED` → `COMPLETE WITH GAPS` → `COMPLETE`.

Replace, with `Edit`, this skill's own `## Perf pipeline — <slug>` block in `production/session-state/active.md` in place (add it after the existing content if absent; `Write` only if the file does not exist; never touch another skill's block): `Scope`, `Phase` reached, `Result` (the verdict above), `Report: production/qa/evidence/perf-[slug]/team-perf-report.md`, `Next` command, date from `date +%F`. Per `.claude/docs/checkpoint-handoff.md`, also overwrite the `<!-- CHECKPOINT -->` block's `Current task` (`/team-perf <slug> — <verdict>`), `Next step` (the same `Next` command), `Blocked on`, `Files in progress` and `Open questions`, and append the Notes line; leave the `Flow:` line and other blocks alone. Still done on BLOCKED, NOT ASSESSED or a declined write.

## Next Steps

- `/story-done` for each fix story (Performance evidence is the before/after folder); `/observability-plan` for dashboards and alerts the findings call for
- `/release-checklist` and `/gate-check` read the load-test results for SRE-OPERABILITY; `/team-hardening` for the combined pre-release pass
- Repeated flakiness in perf runs: `/test-flakiness`
