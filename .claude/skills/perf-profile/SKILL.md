---
name: perf-profile
description: "Performance profiling — measure against docs/architecture/perf-budgets.md (created from the template if missing), per-layer tools, ranked recommendations with expected gain and evidence."
argument-hint: "[feature | endpoint | layer: backend|db|web|android|ios|jobs | full] [--story STORY-ID]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(command -v *), Bash(uname -s), Bash(docker info), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(docker compose -f * ps), Bash(docker compose -f * ps *), Bash(docker compose -f * logs *), Bash(docker stats --no-stream), Bash(docker stats --no-stream *), Bash(timeout 900 go -C * test *), Bash(go tool pprof *), Bash(curl * http://localhost:*), Bash(curl * http://127.0.0.1:*), Bash(bash "*/.claude/skills/perf-profile/../../hooks/yaml-helper.sh" resolve_config *), Bash(docker stats), Bash(docker stats *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys performance.enforce,automation,workflow,qa.level,testing.strict,stack`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

# Performance Profile

DoD gate 6 (`.claude/docs/performance-standard.md`): performance is designed,
budgeted and **measured**. This skill profiles a feature, endpoint, layer or the
whole product against `docs/architecture/perf-budgets.md`, finds the bottlenecks
with the right tool per layer, and produces ranked recommendations — each with
an **expected gain and the evidence behind it**.

It measures; it does not change product code. Fixes go to the owning stack lead
(through `principal-engineer`); sustained load behaviour is `/load-test`.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Environment boundary.** Profile the **local dev stack with seeded test
tenants** (`.claude/docs/run-and-observe.md`). Never production and never real customer
data. A shared or staging environment only when the user names it explicitly.
No `docker compose down -v`, no volume prune.

**Who runs what.** This skill runs the granted commands itself: the stack bring-up
(`up -d --wait`), `docker stats --no-stream`, `go -C <root> test -bench …` and
`go tool pprof …` on the local dev stack, and `curl` to `localhost` / `127.0.0.1`
only. Everything else is **not pre-approved**: database statistics and `EXPLAIN`
(`psql`) and cache `INFO`/slowlog prompt with the target visible; Lighthouse,
Macrobenchmark, Instruments, JFR and async-profiler are run by the owning stack
lead (or the user, on a device or macOS host) who hands back the output — until
then the layer is `NOT MEASURED — not run`. `docker compose down` is not granted;
print it for the user if wanted.

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads: `docs/architecture/perf-budgets.md`, the code
   roots (`resolve_code_root`), `contracts/openapi/*.yaml`, a runnable stack
   (`deploy/compose.dev.yaml`) with seed data (`tools/seed/`), profiler output,
   earlier files in `production/qa/evidence/`, the story and spec NFRs.
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`** (no budget) or **`NOT MEASURED`** (the tool, stack
   or device did not run). Do not estimate it, do not infer it from an adjacent
   artifact.
4. If **every** required input is ABSENT, stop and report **`NOT ASSESSED — NO
   DATA`** as the whole verdict, naming what was missing and which skill produces
   it.

**A verdict of `NOT ASSESSED` is a success.** The failure mode this prevents is
a report with no "could not run" state — "99 % headroom against a budget" with
zero profiler data and no budget ever set. **Absence of evidence is never
evidence of absence**: a profile that found no hotspots because nothing ran has
verified nothing. Say which of the two happened.

---

## Phase 0: Resolve Budget Enforcement

`performance.enforce` decides what a budget violation *means* in this run. It
does not change which budgets are measured:

| Value | Effect on this profile's findings |
|-------|-----------------------------------|
| `warn` (default) | Violations are reported as findings. They do not block; CI logs them without failing. |
| `block` | Violations are **blockers**. Say so explicitly — DoD gate 6 is BLOCKING and `/story-done` and `/gate-check` will fail on an over-budget surface. |
| `off` | Budgets are informational only. Still report measured values, but do not raise violations as findings or recommendations to fix. |

Only `warn`, `block` and `off` are recognized. Surface any other value to the
user and fall back to `warn` rather than guessing. Use the resolved block, not
`project.yaml` directly: the value is locally overridable
(`/settings --local performance.enforce=block`).

## Phase 1: Determine Scope

Read the argument:

- A feature (spec stem), endpoint or screen → focus on it; map it to its layers
- `backend` | `db` | `web` | `android` | `ios` | `jobs` → that layer across the product
- `full` → every layer in the stack, hot paths first (listing, search, dashboards, auth, webhooks)
- `--story STORY-ID` → evidence folder is `production/qa/evidence/[STORY-ID]/`

Layers in play come from the resolved `stack`. A layer whose value is **unset**
is not defaulted — ask, or mark it `NOT ASSESSED — stack.[layer] unset
(/setup-stack)`; a value of `none` is a stated skip.

---

## Phase 2: Load Performance Budgets

Read `docs/architecture/perf-budgets.md`: section 1 "Product budget" column,
section 2 per-endpoint/screen rows, section 3 background jobs, section 4
capacity assumptions, section 5 resource limits, section 7 waivers.

**Missing file, or a surface with no row/product budget:** do not invent one.
Follow **`references/2-report.md`** ("Creating perf-budgets.md"): offer to
create the file from `.claude/docs/templates/perf-budgets.md` with the
`.claude/docs/performance-standard.md` defaults as *proposals*, ask the user to
confirm which become the product's budgets, and write only after the yes.

**A metric with no committed budget is `NOT ASSESSED`, not a pass.** Reporting
headroom against a number nobody chose is the exact fabrication this skill's
header warns about. Defaults used as thresholds only because the user said so
for this run are labelled `vs default (unconfirmed)`.

Also read the spec's Non-Functional Requirements and `docs/research/<feature>.md`
for expected load, and `docs/architecture/slos.md` for context (SLO targets are
`sre-lead`'s; never edit).

---

## Phase 3: Measure per Layer

**Read `references/1-layers.md` now and follow it** — the per-layer table (what
to measure, tool, budget row, where the invocation is sourced, when the layer is
`NOT MEASURED`) and the static-candidate checklist are in that file, not here.
Read it again if the conversation was compacted or resumed during this phase.

Order of work:
1. Bring the dev stack up (`up -d --wait`) with the seed; record data volume. If it does not start, that is the finding — capture the logs; every runtime layer is then `NOT MEASURED`.
2. Run the layer tools in scope; save raw output to `production/qa/evidence/perf-profile-[scope]-[date]/` (or the story folder) **only after Phase 4's write approval** — until then hold it in a scratch path outside the repo and say so.
3. Collect static candidates from the code (grade `STATIC`).
4. For each result, name the **budget row** it is checked against; no row → `NOT ASSESSED`.

A tool run that fails, times out or is skipped is `NOT MEASURED — [reason]`;
**never replace a missing measurement with an estimate.** Never write a tool
flag from memory — where the invocation is not sourced the layer is
`NOT MEASURED — invocation not sourced` and `/research` is the next step.

---

## Phase 4: Generate Profiling Report

**Read the report template in `references/2-report.md`** and fill it. Rank the
recommendations as `references/1-layers.md` "Ranking recommendations" says:
budget gap closed × evidence strength ÷ effort; every recommendation carries
expected gain **and** evidence (`MEASURED` path or `STATIC file:line`); a
`STATIC` finding says `not quantified — needs a profile`.

Present the report with a summary: top 3 hotspots, headroom against each
*committed* budget, and the recommended next action.

**Write the report to `production/qa/perf-profile-[scope]-[date].md`**, asking
first: *"May I write this profiling report to
`production/qa/perf-profile-[scope]-[date].md` and the raw captures to
`production/qa/evidence/perf-profile-[scope]-[date]/`?"* Create the directories
if absent. If a `NOT ASSESSED` or `NOT MEASURED` section exists, keep it in the
written file — a profile whose gaps are edited out on the way to disk reads, later,
as a complete measurement. A profile that lives only in the transcript is gone
when the session ends and no two runs can be compared.

---

## Phase 5: Scope and Timeline Decision

Activate this phase only if any hotspot has Fix Effort rated M or L, or any
surface is OVER budget.

Present significant-effort items and ask the user to choose for each:

- **A) Implement the optimization** (route to the owning lead via a story: `/create-stories` or `/dev-story`; at `workflow: minimal`, which has no sprints, add it to the brief's build order)
- **B) Reduce feature scope** (run `/scope-check [feature]` to analyze trade-offs)
- **C) Accept the miss with a written waiver** in `perf-budgets.md` §7 — surface, budget, actual, reason, named approver, expiry date. Not available under `performance.enforce: block` without that waiver
- **D) Escalate to `cto` for an architectural decision** (run `/architecture-decision`)

Record choice C items under `### Deferred (waived)` in the report.

---

## Verdict

Close every run that produced a report — whether or not Phase 5 ran — with one
word, first match wins:
- **BLOCKED — write declined by user** — the report write was declined; the report
  stays in conversation, marked not recorded.
- **NOT ASSESSED** — `NOT ASSESSED — NO DATA` (the input check above), **or a partial
  run**: any in-scope layer or surface is `NOT MEASURED` or has no committed budget.
  Name each, and what would close it. A profile that measured only some of what it
  was asked to is not a complete one, and the measured part is reported beside it
  as findings, not as a pass.
- **COMPLETE** — every layer and surface in scope was measured against a committed
  budget (saved to `production/qa/perf-profile-[scope]-[date].md`).

---

## Phase 6: Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/perf-profile <scope> —
<verdict>`, Next step = the first applicable item below, plus Blocked on / Files
in progress / Open questions; append the Notes line. NOT ASSESSED or a declined
write still updates the checkpoint with the blocker.

- If bottlenecks need an architectural change: `/architecture-decision`.
- If scope reduction is needed: `/scope-check [feature]`.
- To prove a fix under load, or to profile sustained behaviour: `/load-test`.
- For a slow query or index proposal: `postgres-specialist`; for a cache decision: `/cache-design`.
- To schedule optimizations: `/sprint-plan update` (at `workflow: minimal`, add them to the brief's build order instead).
- A performance regression that appeared between releases: `/debug` (bisect).

### Rules
- Never optimize without measuring first — gut feelings about performance are unreliable
- Recommendations must include an expected gain and the evidence — "make it faster" is not actionable, and an unquantified gain says so
- Profile at production-like data volume on a stated environment; three or more runs for any before/after claim
- Static analysis identifies candidates; runtime profiling confirms
- Never weaken a budget or threshold to make a run pass
