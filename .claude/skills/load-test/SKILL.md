---
name: load-test
description: "k6 load and soak protocol against the performance budgets — ramp, steady, spike and soak scenarios, thresholds taken from perf-budgets.md, stated data volume and tenant mix, evidence saved. PASS/PASS WITH CONCERNS/NOT ASSESSED/FAIL."
argument-hint: "[scenario: ramp | steady | spike | soak | all] [soak duration: 30m | 1h | 2h | 4h] [surface: endpoint or journey]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), AskUserQuestion, Bash(k6 version), Bash(command -v *), Bash(date *), Bash(docker info), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(docker compose -f * config), Bash(docker compose -f * config *), Bash(docker compose -f * ps), Bash(docker compose -f * ps *), Bash(docker compose -f * stop), Bash(docker compose -f * stop *), Bash(docker stats --no-stream), Bash(docker stats --no-stream *), Bash(docker compose logs *), Bash(docker compose -f * logs *), Bash(bash "*/.claude/skills/load-test/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,performance.enforce,stack,tenancy`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Load Test

Performance is designed, budgeted and measured — not hoped for (DoD gate 6,
`.claude/docs/performance-standard.md`). This skill produces the **load-test
protocol and k6 scripts** for the hot paths of the product, runs them against a
stack the user names, and records a result checked against the budgets in
`docs/architecture/perf-budgets.md`. A load test with no budget to check against
has no threshold; one with no stated data volume and tenant mix proves nothing.

Four scenarios, each answering a different question:

- **Ramp** — raise load stepwise to find the knee: where p95 leaves the budget
  or errors start.
- **Steady** — hold the expected peak for a fixed time: does the budget hold?
- **Spike** — a sudden burst, then back to baseline: does the system shed load
  with 429/503 (backpressure) instead of collapsing, and does it recover?
- **Soak** (endurance) — steady load for **30 minutes to four hours**: slow leaks,
  pool exhaustion, queue and disk growth, latency drift, late-appearing edge cases.

**Output:** `production/qa/evidence/<story-id>/load-test-[date]/` — the protocol
(`protocol.md`), the k6 script(s), raw k6 output, the summary and the environment
record; or, with no story, `production/qa/evidence/load-test-[date]/`. The report
is `load-test-[date].md` in the same folder.

**When to run:**
- Per story, for Performance stories and any hot-path change (BLOCKING when `performance.enforce: block`)
- Before each release, for the top journeys (`/release-checklist`, `/team-release`)
- After a pool, cache, index or concurrency change (regression run)
- Before sizing the self-hosted installer's minimum hardware

---

## 1. Parse Arguments

**Scenario** (default: `all` except soak — soak runs only when asked or at release):
- `ramp`, `steady`, `spike`, `soak`, or `all` (= ramp + steady + spike)

**Soak duration** (default `1h`; only meaningful with `soak`):
- `30m` — short soak; regression after a specific fix
- `1h` — standard; covers the common leak categories
- `2h` — extended; recommended before the first release
- `4h` — deep; for workloads with long sessions, large imports or slow-growing queues

**Surface**: the endpoint(s) or journey(s) under test. Blank → ask, offering the
rows of `perf-budgets.md` section 2 (per-endpoint budgets). A surface with **no
budget row** is not load-tested here until a budget is proposed (Section 2) — a
test with no threshold cannot fail.

---

## 2. Load Context

Read, in this order — and name any that is missing:

- `docs/architecture/perf-budgets.md` — the budget row for each surface under test:
  p95 (and p99 if stated), queries per request, payload size, throughput target,
  the capacity assumptions (section 4: tenants now / at 12 months, largest-tenant
  size, peak request rate, data growth) and resource limits (section 5). **Absent,
  or no row for the surface** → do not invent one. Say: "No budget for [surface].
  `performance-engineer` proposes one from `.claude/docs/performance-standard.md`
  defaults (read ≤ 150 ms, write ≤ 300 ms, auth ≤ 200 ms p95 server time) — use
  `/perf-profile` to create `perf-budgets.md`." The run for that surface is
  `NOT ASSESSED — no budget`. The defaults may be used as thresholds *only* if the
  user states that they are the budget for this run, and the report says so.
- `project.yaml` (via the resolved block) — `performance.enforce` (`warn` | `block`
  | `off`), the `stack`, `tenancy`
- `contracts/openapi/*.yaml` — the real paths, methods, auth scheme and request
  shapes for the surface. **Do not invent an endpoint or a payload.**
- The story (if any), its spec's Non-Functional Requirements (performance budget,
  caching decision) and `docs/research/<feature>.md`
- `docs/architecture/slos.md` (if present) — SLO targets stay `sre-lead`'s; read
  them for context, never edit
- `deploy/` — the dev/staging compose file and the stack's sizing (CPU, memory
  limits per service) — the result is only meaningful against a stated size
- `docs/stack-reference/pins.yaml` and the data-store best practices — image tags
  for the stack the test runs against (`postgres.image`, `redis.image_hosted`,
  `redis.image_redistributable`, `dragonfly.image`, `mongo.image`), so the test stack
  matches what the product ships
- the most recent `production/qa/plan-*.md` and any earlier
  `production/qa/evidence/*/load-test-*/` result for the same surface (the baseline
  for before/after)

**k6 is not covered by the stack reference** (`pins.yaml` has no k6 entry; the
performance standard names the tool and the scenario shapes only).
**NOT SOURCEABLE — the k6 version, the scenario-executor names and the script
API are not covered by `docs/stack-reference/`.** Before pinning a version or
relying on an option name: check `docs/research/load-testing.md`. If it does not
exist, tell the user to run `/research load-testing` (k6 version at release time,
the executors for ramp/steady/spike/soak, threshold syntax, output formats). Until
then:

- the scripts below are written as **shape, flagged `UNVERIFIED API`** in a header
  comment, to be confirmed against the k6 documentation for the installed version
- the k6 version is recorded **as observed** (`k6 version` output) in the
  environment record, **never pinned** from memory
- the report carries the line `k6 API: unverified — /research load-testing pending`
  and the verdict cannot be a clean PASS (it is PASS WITH CONCERNS at best): the
  measurements are real, but the protocol's own correctness is unconfirmed

Check availability: `command -v k6` and `k6 version`. Not installed → the run is
`NOT RUN — k6 not installed`; the protocol and scripts are still written, and the
verdict is NOT ASSESSED. **Do not install software, download a binary or pull an
image on your own** — name what is needed and let the user decide (a downloaded
tool is untrusted until the user approves its source).

---

## 3. Define the Environment, Data Volume and Tenant Mix

State these **before** any number is reported; a result without them is
`NOT ASSESSED`. Ask once (`AskUserQuestion`) for anything not found in the files:

### Target

- **Which environment, named by the user.** Allowed: the local dev stack
  (`docker compose -f deploy/compose.dev.yaml up -d --wait`) or a dedicated
  load-test/staging stack **the user names explicitly in this conversation** (the
  name is recorded in the environment record). **Never production — including a
  "staging" that shares production's database, queue or provider accounts — never
  a shared environment, never a third party's service.** An environment the user
  did not name is refused. Outbound provider calls (payments,
  SMS, email, storage) go to sandboxes or fakes — never real providers.
- Stack sizing: CPU/memory limits of each service, image tags, the number of API
  replicas, the DB connection pool size. Observed from the running compose project
  (`docker compose -f <file> config`, `docker stats --no-stream`), not guessed.
- The load generator runs **off the system under test** when possible; if it shares
  the host, its CPU is recorded — the generator must not be the bottleneck
  (its CPU stays well under saturation for the whole run, or the run is invalid).

### Data volume

A seeded, multi-tenant data set sized to the budget's capacity assumptions
(`perf-budgets.md` section 4) — **never an empty database**:

| Item | Value (state the numbers) |
|---|---|
| Tenants | [N] (now: [N], at 12 months: [N]) |
| Rows per hot table, per tenant (largest tenant) | [N] |
| Rows per hot table, total | [N] |
| Cache state | cold / warm; hit ratio at start |
| Seed source | `tools/seed/` + [script and parameters] — test tenants only, **never a copy of production data** |

If the seed cannot reach the stated volume, say so, and the result is reported as
**representative of [actual volume] only** — the verdict is at most PASS WITH CONCERNS.

### Tenant mix

How traffic is spread, because a hot tenant behaves differently from an even spread:

| Item | Value |
|---|---|
| Active tenants in the test | [N] |
| Distribution | even / skewed (e.g. 80 % of requests from the top [N] % of tenants) / one hot tenant |
| Users per tenant (virtual users map to) | [N] |
| Roles in the mix | owner [x %], member [y %], other |
| Isolation under load | a probe that tenant A's token never receives tenant B's data, run during the test |

Each virtual user authenticates as a seeded test principal and carries its tenant;
requests are tenant-scoped exactly as production requests are. Tokens and
credentials come from the seed, are passed to k6 through environment variables,
**never written into the script or the saved output**.

---

## 4. Define Scenarios and Thresholds

**Thresholds are the budgets** — one threshold per budget row, each with the
budget's number, percentile and surface, **plus an error-rate bound** (state it;
the budget file's pass criteria give it — if it states none, ask the user and
record the answer). The script **exits non-zero when any threshold fails**.

| Budget (from `perf-budgets.md`) | Becomes |
|---|---|
| p95 latency of [surface] ≤ [N] ms | a latency threshold on that surface's tagged metric, p95 (add p99 if the budget states one) |
| Error rate | a failed-request-rate threshold (`< [x] %`) |
| Throughput target | the arrival rate the steady scenario holds, and a check that it was achieved |
| Payload | a response-size check (list pages ≤ 100 items; responses ≤ 200 KB uncompressed) |
| Queries per request / N+1 | **not measurable from k6** — covered by the query-count assertion in an integration test; this skill checks that the test exists and records `pg_stat_statements` deltas (below) |

Per scenario (durations are defaults — the user may change them, and the report
states what was run):

| Scenario | Shape | Question | Pass condition |
|---|---|---|---|
| **Ramp** | stepwise increasing arrival rate (e.g. 5–8 steps) from a fraction of expected peak to well beyond it, each step held long enough to read p95 | Where is the knee? | the step at which p95 or errors leave the budget is **named**; the budget holds up to at least the expected peak |
| **Steady** | constant arrival rate at the expected peak (the budget's throughput target) after a stated warm-up; ≥ 10 minutes | Does the budget hold at peak? | all thresholds met over the steady window; warm-up excluded and stated |
| **Spike** | baseline → burst of a stated multiple (e.g. 5–10× peak) held briefly → baseline | Does it shed load and recover? | overload answered with **429/503** (not timeouts, not 500, not collapse); p95 returns to budget within a stated recovery time after the burst; no data loss or duplicate side effect (idempotency keys honoured) |
| **Soak** | steady load at expected peak for the chosen duration | Leaks and drift? | see below |

Prefer an **arrival-rate (open model)** executor for ramp, steady and spike so a
slow server does not silently reduce the offered load; use a virtual-user
(closed) model only to simulate a bounded set of concurrent sessions, and say
which was used. (Executor names: `UNVERIFIED API` until `/research load-testing`.)

### Soak observation items

Checkpoints by duration — **30m**: T+0, 10, 20, 30; **1h**: T+0, 15, 30, 45, 60;
**2h**: T+0, 20, 40, 60, 80, 100, 120; **4h**: T+0, 30, 60, 90, 120, 180, 240.

> **Record growth, not absolutes.** A soak looks for **growth**, so every threshold
> is a ratio or delta against this run's own T+0 baseline — unit-agnostic. Write
> the unit down at T+0 exactly as the tool shows it and use it consistently.

At each checkpoint record (source named — metrics endpoint/collector,
`docker stats --no-stream`, `pg_stat_activity`, the cache's `INFO`, disk usage):

| Metric | Alert (growth against T+0, after the first 15 minutes of warm-up) |
|---|---|
| Service RSS / container memory | sustained growth > 20 % **or** steady-state above 70 % of the container limit (30 % headroom rule, `performance-standard.md`) |
| Goroutines (Go) / threads and coroutine count (Ktor) | monotonic growth across 3+ checkpoints |
| DB connections in use and pool wait time | pool wait rising, or connections never returned |
| Cache memory and eviction count | memory above the configured `maxmemory`, or evictions climbing at constant load |
| Queue/outbox depth, job runtime | depth growing at constant load; job runtime drifting toward its timeout |
| Disk (logs, WAL, temp files) | growth that would exhaust the volume within the retention period |
| p95 latency and error rate | p95 drifting upward across the soak, or any error-rate step |
| Temp blocks written / slow queries (`pg_stat_statements`) | new entries in the top-5 by `total_exec_time` since T+0 |

Telemetry used for these numbers is the product's own (OpenTelemetry metrics,
`observability-standard.md`); if the stack exposes none of the above, those rows
are `NOT MEASURED — no instrumentation` and the soak cannot return PASS on them.

---

## 5. Generate the Protocol and the k6 Script(s)

Write `protocol.md` with: the surface and budget rows; the environment, data
volume and tenant mix of Section 3; the scenarios and their parameters; the soak
checkpoints; the thresholds; the commands to bring the stack up and run the test;
the pre-flight checklist; and the analysis template below.

The k6 script lives in `tools/load/<surface>.js` when the product keeps such tools
there (check `tools/`; ask where if there is no convention), otherwise beside the
protocol in the evidence folder. Its header comment states: the surface and budget
source, the scenario, **`UNVERIFIED API` until `/research load-testing` is done**,
and that credentials come from the environment. Shape (every option name and
executor to be confirmed against the k6 documentation for the installed version —
placeholders in `<>`, no value invented):

```js
// UNVERIFIED API — confirm option and executor names against the k6 docs for the
// installed version (see docs/research/load-testing.md) before relying on this.
// Surface: <METHOD /v1/...>   Budget: perf-budgets.md §2 row "<...>"
// Credentials: environment variables only — never in this file.
export const options = {
  scenarios: {
    /* ramp | steady | spike | soak — open-model arrival rate; stages from <protocol.md> */
  },
  thresholds: {
    /* p95 <= <budget> ms on the surface's tagged metric; error rate < <bound> */
  },
};
// default function: pick a seeded principal (tenant mix from <protocol.md>), call the
// contract's endpoint with a real payload, check status and the contract's shape,
// and tag the request with the surface name.
// teardown / probe: tenant A's token requesting tenant B's resource id must be 404.
```

Idempotent writes use a fresh idempotency key per request; a write scenario creates
data under the test tenants only and states how it is cleaned (test-tenant
truncate by the seed tooling — **never `docker compose down -v`**).

**Pre-flight checklist** (all must be true, else the run does not start):
- [ ] Target named by the user and is not production or shared
- [ ] Stack brought up with `up -d --wait`, all healthchecks green, migrations applied
- [ ] Seeded to the stated data volume; tenant count and rows recorded
- [ ] Budget rows read; thresholds in the script match them
- [ ] Provider calls go to sandboxes or fakes
- [ ] Load generator capacity checked (not on the saturated host, or its CPU is recorded)
- [ ] Observability on: traces and RED metrics reachable during the run
- [ ] `k6 version` recorded; research note present or the UNVERIFIED flag set

---

## 6. Run (only with the user's go-ahead)

Show the commands first and ask: "Run the load test now against [named target]?
This will generate [N] req/s for about [duration] against it."

In `collaborative` and `guided` modes this ask is mandatory — a load run is
destructive to a shared environment's capacity and writes data. In `autonomous`
mode it runs only against the local dev stack and logs the decision; any other
target always asks.

If the user declines, or k6 is not installed, or the target is not reachable: stop
the run here, write the protocol and scripts if approved, and report
`NOT RUN — [reason]` with verdict **NOT ASSESSED**. Never describe a run that did
not happen.

**What is and is not pre-approved.** The stack bring-up (`up -d --wait` on
`deploy/compose.dev.yaml`), `docker stats --no-stream`, `docker compose … ps|logs|config|stop`
and the `k6 version` probe are granted. The load run itself (`timeout <seconds> k6 run …`)
and every query against the stores (`psql` for `pg_stat_statements` and
`pg_stat_activity`, the cache's `INFO`) are **not** pre-approved: each goes through
the permission prompt, which shows the command and the target, so the user sees
exactly what is sent where. `docker compose down` is not granted either.

When running:
- Bring the stack up (`docker compose -f deploy/compose.dev.yaml up -d --wait`) if
  it is not already running; record whether this run started it. A service that
  never becomes healthy is the finding — capture `docker compose logs <service>`.
- Wrap in a timeout longer than the planned duration (`timeout <seconds> k6 run …`);
  a timeout is a **failed** run, not a pass.
- Save k6's machine-readable output and its end-of-test summary to the evidence
  folder (the output format flags are `UNVERIFIED API` — use the k6 documentation
  for the installed version) and the exit code. A threshold failure exits non-zero:
  **that is a FAIL, never retried into green.**
- **At least three runs** for any before/after comparison (identical hardware, data
  volume, warm-up and duration); report variance. A change smaller than the observed
  run-to-run variance is "not significant". A single run is a result, not a
  comparison.
- During the run capture the saturated resource (CPU, DB pool wait, cache, network)
  and the load generator's own CPU.
- After the run: `pg_stat_statements` top-5 by `total_exec_time` and `mean_exec_time`
  for the hot tables (Postgres stores), slow-query log entries over 100 ms with
  plans, and the cache hit ratio; the isolation probe result.
- Teardown, for a stack this run started, is `docker compose -f <file> stop` —
  **never `down -v`** (nor `down`: it is not granted; print the command if the
  user wants the containers removed). Leave a stack you did not start running.

Stop immediately and tell the user if the isolation probe sees **another tenant's
data** — that is an S1 (cross-tenant exposure), reported to `qa-lead` right away,
not batched into the report.

---

## 7. Write the Report

Write `load-test-[date].md` (after the user approves the path):

```markdown
# Load Test Report

> **Date**: [date]   **Commit/build**: [hash]   **Story**: [id or "n/a"]
> **Scenario(s)**: [ramp | steady | spike | soak [duration]]
> **Tool**: k6 [version as observed — not pinned] — API: [verified via docs/research/load-testing.md | unverified — /research load-testing pending]
> **Generated by**: /load-test

## Budget checked
[Surface, metric, percentile, number — `perf-budgets.md` row reference]. Enforcement: `performance.enforce` = [warn | block | off] → this result is [BLOCKING | ADVISORY].

## Environment
Hardware/limits per service, image tags, replicas, pool sizes, generator location and CPU.

## Data volume and tenant mix
Tenants, rows (largest tenant and total), cache state, seed source, active tenants, distribution, roles, isolation probe.

## Results
| Scenario | Metric | Budget | Run 1 | Run 2 | Run 3 | Variance | Result |
|---|---|---|---|---|---|---|---|
| steady | p50 / p95 / p99 (ms) | p95 ≤ [N] | | | | | PASS / FAIL |
| steady | error rate | < [x] % | | | | | |
| steady | throughput (req/s) | [target] | | | | | |
| ramp | knee at [rate] req/s | holds to ≥ [peak] | | | | | |
| spike | status during burst (200/429/503/5xx/timeout) | shed with 429/503 | | | | | |
| spike | recovery time to budget | ≤ [stated] | | | | | |

Saturated resource: [CPU | DB pool wait | cache | network | none reached].
Top-5 `pg_stat_statements`: [attached].
Soak (if run): growth table per checkpoint against T+0 — memory, goroutines/threads,
DB connections and pool wait, cache memory/evictions, queue depth, disk, p95 drift.

## Evidence
Paths under `production/qa/evidence/…`: protocol, script, raw output, summaries, exit codes, logs.

## Not measured
[Every scenario, metric or surface that did not run and why — no budget row, k6 not
installed, no instrumentation, data volume short of target, soak ended early. "Nothing
was skipped" is stated explicitly when true.]

## Verdict: PASS / PASS WITH CONCERNS / NOT ASSESSED / FAIL
(performance-engineer report words: PASS = MEETS BUDGET, FAIL = MISSES BUDGET, NOT ASSESSED = NOT MEASURED)

## Next
The one change recommended and its owner (go-lead, ktor-lead, data-lead, …).

## Sign-off
performance-engineer: [name] — [date]
```

### Verdict rules — first matching rule wins

**FAIL** if ANY of:
- any threshold failed (a latency budget missed, error rate over its bound, throughput
  target not achieved), in a scenario that ran
- the spike collapsed (timeouts or 5xx instead of shedding, no recovery) or lost/duplicated data
- the isolation probe saw another tenant's data (**S1**)
- the soak shows a confirmed leak (sustained growth beyond the alert thresholds) or
  the service exceeded its container limit headroom
- the run did not complete: a timeout, k6 crash, or the stack became unhealthy

**NOT ASSESSED** if ANY of (and no FAIL above):
- the load test did not run (user declined, k6 not installed, target unreachable)
- a surface has **no budget** to check against
- data volume or tenant mix could not be stated, or the data set was empty
- the load generator's own CPU saturated (the generator was the bottleneck)
- a soak ended before its checkpoints were reached ("reached T+[N] of [duration];
  checkpoints [list] not reached") — **a short soak cannot return PASS**: everything
  it looks for is invisible early, so a session cut short has shown nothing yet. It
  ranks above both pass values and below FAIL: a crash or leak seen at T+20 is a
  real finding and must not be demoted behind the run's length
- soak instrumentation is absent (nothing measured means "no leaks detected" would
  mean "no leaks could have been detected")
- the protocol was written but never executed — **a protocol document is not a result**

**PASS WITH CONCERNS** if ALL of: every threshold met in every scenario that ran, and
at least one concern: the k6 API unverified, data volume short of the target, only one
run (no variance), a scenario deliberately not run (named), the p95 within 10 % of the
budget, minor drift in the soak, or a before/after change inside the run-to-run variance.

**PASS** if ALL of: every threshold met across ≥ 3 runs with variance reported, the
data volume and tenant mix at or above the stated capacity assumptions, the isolation
probe clean, nothing under "Not measured", and the k6 API verified by a research note.

**Gate level.** FAIL is BLOCKING when `performance.enforce: block`, ADVISORY when
`warn`; with `off` the result is recorded and does not gate. A waived budget needs a
written reason, an owner, a date and the measured gap in `perf-budgets.md` section 7
— this skill never loosens a threshold, a duration or an error bound to get a pass.

---

## 8. Write Output

Present the protocol summary (or, after a run, the results) in conversation, then ask:

"May I write the protocol, script(s) and report to
`production/qa/evidence/<STORY-ID>/load-test-[date]/` (no story: `production/qa/evidence/load-test-[date]/`)?"

Write only after approval. Evidence files must be on disk before the report cites
them. Redact tokens, credentials and personal data from anything saved.

**If the user declines the write**, close with `BLOCKED — write declined by user`:
the results stay in conversation only, nothing is reported as recorded, and any
FAIL or NOT ASSESSED found is repeated in that closing message.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/load-test <target> —
<verdict>`, Next step = the first applicable item of the next steps below, plus
Blocked on / Files in progress / Open questions; append the Notes line. FAIL,
NOT ASSESSED or a declined write still updates the checkpoint with the blocker.

After writing:

"Next steps:
1. FAIL on a Performance story: route the finding to the owning lead via `performance-engineer`; re-run after the change (≥ 3 runs)
2. NOT ASSESSED: [the one thing that would make it assessable — a budget row via `/perf-profile`, k6 installed, `/research load-testing`, a seeded data set]
3. Leak or drift in the soak: file bugs to `production/qa/bugs/` (severity by the `qa-lead` rule) and run `/bug-triage`
4. Attach this result to the story and run `/story-done`; `/release-checklist` reads it for the top journeys"

---

## Collaborative Protocol

- **Never run a load test without the user naming the target and saying go** — and
  never against production, a shared environment or a real third-party provider
- **Never weaken a budget, threshold, duration or data volume to make a run pass** —
  a missed budget is fixed or waived in writing, not edited away
- **Never `docker compose down -v`**; teardown is `stop`
- **Never write a k6 option, executor or version from memory as fact** — mark it
  `UNVERIFIED API`, route to `/research load-testing`, record the observed version
- **No empty databases, no production data** — seeded test tenants only
- **A protocol is not a result** — report what ran; a check that did not run is
  reported as not run
- **Ask before writing** — always confirm before creating the evidence folder files
