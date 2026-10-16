---
name: debug
description: "Systematic diagnosis of a bug, failing test, regression or incident: minimal reproduction, evidence from traces/logs/metrics, ranked hypotheses with confirming and killing evidence, bisect, root cause proven before any fix, fix routed to the owning lead, failing-first regression test, diagnosis record. Never fixes by retry, sleep or catch-all."
argument-hint: "[BUG-ID | failing-test | trace_id | description] [--incident <id>] [--after-fix]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git status), Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git show *), Write, Edit, Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/debug/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`. **Routing a fix,
accepting a workaround and any production-data access are never delegated to a
mode**: they always ask.

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

**`workflow` and `qa.level` do not relax this skill.** A proven root cause and a
failing-first regression test are engineering, not documents.

# Debug

Turns "it is broken" into a **proven root cause**: a minimal deterministic
reproduction, evidence read from the system before any change, a ranked
hypothesis table with what would confirm and what would kill each entry, a
bisect when "it worked in version X" is known, and a regression test that fails
before the fix and passes after. The diagnosis is the `debugger` agent's job;
the **fix belongs to the owning stack lead**, routed through `principal-engineer`.

**Output**
- `production/qa/evidence/[ID]/diagnosis.md` — the diagnosis record (format in `debugger.md`), `[ID]` = the BUG-ID, the incident ID, or a slug
- the regression test (test directory of the owning layer) with its red and green output saved beside the record
- a **Diagnosis** section appended to `production/qa/bugs/BUG-[NNNN].md` (or the incident record) pointing at the evidence — only after the user says yes

> **It never "fixes" by retry, sleep, longer timeout or catch-all.** A bounded
> retry is acceptable only where the operation is idempotent **and** the cause
> is a proven transient. A change that makes the symptom disappear without an
> explained cause is a **workaround**, labelled as one. Changing several things
> at once and keeping the combination is not an experiment.

> **Verdicts (confidence in the root cause):** `PROVEN` / `LIKELY` / `UNKNOWN` /
> `NOT ASSESSED`. **First matching rule wins, in this order:**
> 1. `NOT ASSESSED — [what is missing]` — nothing could be reproduced or observed
>    at all (no subject found, no environment, no trace/log/run output reachable, the
>    `debugger` could not be spawned and the user supplied no run output). There is
>    no cause to state, not even a probable one. It outranks `PROVEN` and `LIKELY`.
> 2. `PROVEN` — a reproduction, a causal chain shown by a test or trace, the symptom
>    removed when the cause is removed, **and** every evidence source the diagnosis
>    needed actually read.
> 3. `LIKELY` — a cause is supported by what was observed, but a needed source could
>    not be read (no trace access, a log that rotated, a stack that will not start, an
>    environment that does not match the report) or the proof is partial: the verdict
>    is capped here and the unread source is named. A partly evidenced cause is
>    `LIKELY`, never `NOT ASSESSED` and never `PROVEN`.
> 4. `UNKNOWN` — it was looked at properly (everything needed was read) and the cause
>    is not found: list what was tried and the next probes.
>
> `NOT ASSESSED` is a different fix from `UNKNOWN` — access or inputs versus more work.

---

## Phase 1: Intake and Impact

0. **No argument** → ask what to diagnose (`AskUserQuestion`: a BUG-ID, a failing test,
   a `trace_id` or a description). No answer, or a BUG-ID/path that does not exist →
   stop with `Verdict: NOT ASSESSED — no subject to diagnose` (name what was looked
   for under `production/qa/bugs/`). `--after-fix` with no earlier
   `production/qa/evidence/[ID]/diagnosis.md` → `Verdict: BLOCKED — no prior diagnosis`
   (run `/debug [ID]` first).
1. **Find the subject.** A BUG-ID → read `production/qa/bugs/BUG-[NNNN].md`
   (found by number, any padding); a failing test → its name, file, last output;
   a `trace_id` → the trace; a description → `/bug-report` first if it is a new
   defect. `--incident` → the incident record and its timeline.
2. **State the impact** from what is known: who, since when, which versions
   (hosted release or self-hosted version), which tenants, which data. Do not
   guess a number; unknown is written `unknown`.
3. **Escalate now, do not wait for the report** if the impact may be
   **cross-tenant exposure or a credential leak**: announce it in conversation
   and route to `security-lead` through `qa-lead` (`security-baseline.md`). The
   diagnosis continues, but it is a security incident first.
4. **S1/S2 or live production:** ask for the **time-to-mitigate option**
   (rollback, flag off, scale, config) *separately* from the root-cause fix, so
   on-call is not blocked on the proof — `/hotfix`, `/incident`.
5. **Production and customer data are out of bounds** unless the user names the
   target and the scope, and `sre-lead` approves intrusive probes (profilers,
   heap dumps, debug builds) with a rollback. Self-hosted reports are diagnosed
   from what a customer can send: version, PII-masked logs, the telemetry-off
   bundle.

## Phase 2: Reproduce, Observe, Hypothesise, Prove

Spawn `debugger` via `Agent` — the diagnosis is its job; do not run it in this
session instead (if it cannot be spawned, say why and do only the read-only parts here — reading
logs, traces and evidence files; this skill holds no grant for test runs, `git bisect run`,
`git worktree` or `docker compose`, so anything needing a command is run by the user and
pasted back, else it is `not run` and the verdict is capped by the rules above. The
record's **Diagnosed by** line says so). **Read the three reference files before
briefing it**, because they define the phases the brief names:

- **`references/1-reproduce-observe.md`** — the minimal repro, the stack, the
  evidence sources (trace, logs, metrics, plans), what is never logged.
- **`references/2-hypotheses-and-proof.md`** — the hypothesis table, bisect, per-
  layer tools from the stack reference, the root-cause proof, siblings.
- **`references/3-record-and-handoff.md`** — the diagnosis record, the
  regression test (red before, green after), routing the fix, the after-fix pass.

Send this fixed brief; fill only the `{…}` slots from Phase 1 — no opinion on
the cause (a sentence of your own is where a pre-diagnosis gets in):

```text
Diagnose this for /debug. Follow .claude/agents/debugger.md and the three
reference files under .claude/skills/debug/references/ (read them first).
Subject: {BUG-ID + path | failing test | trace_id | description}
Impact so far: {who/since when/versions/tenants — or "unknown"}
Environment: {compose dev | staging named by the user | device model + OS | customer bundle}
Commit / version: {hash or release}    Tenant / role / plan: {as reported}
Stack: {the stack line from the resolved config}
Do not change product code. You run the commands (tests, `git bisect run`, `git worktree`, `docker compose`) — the caller holds no grant for them. You may write the minimal repro tooling and the
regression test at the path the caller confirms. Never print secrets, tokens,
OTPs or customer data. Write the diagnosis record to {production/qa/evidence/<ID>/diagnosis.md}
— that named path is your write authorisation; return only (1) the path,
(2) a <=5-bullet summary, (3) any BLOCKED/CONCERNS items, one line each.
```

Verify the file exists before reading the reply
(`.claude/docs/error-recovery-protocol.md`); a fluent summary with no file is a
failed phase — resume the agent naming the unmet contract.

## Phase 3: Review the Diagnosis with the User

Read `diagnosis.md` and present: the reproduction (with its failure rate), the
hypothesis table, the root cause with its confidence word and **the proof**, the
siblings found and what was **not examined**. Check the confidence word against
the verdict rules above; if the agent said `PROVEN` but a needed source was
unread, show both and ask — never silently substitute your own.

`AskUserQuestion`: **Accept the diagnosis and route the fix** / **Probe further
([named probe])** / **Treat as a workaround — root cause not accepted** /
**Stop**. A workaround is recorded as one, with its owner and the follow-up.

## Phase 4: Regression Test, Fix Routing, Record

**Read `references/3-record-and-handoff.md` now and follow it.** In short: the
regression test is specified at the **lowest level that exhibits the bug** (unit
before integration before e2e) and run on the unfixed commit — red output saved;
the fix goes to the owning lead (`go-lead`, `ktor-lead`, `web-lead`,
`android-lead`, `ios-lead`, `kmp-specialist`; data-layer causes with
`postgres-specialist`/`cache-specialist`) through `principal-engineer`, as a
story for `/dev-story` — or `/hotfix` for S1/S2; after the fix `/debug [ID]
--after-fix` runs the same test green and the verdict moves to `/bug-report
verify`.

Ask before every write: "May I write `production/qa/evidence/[ID]/diagnosis.md`
(already written by the agent — confirm), the regression test at [path], and the
Diagnosis section to `production/qa/bugs/BUG-[NNNN].md`?" Name each path.

**Checkpoint.** Then update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/debug [BUG-ID] —
<PROVEN | LIKELY | UNKNOWN | NOT ASSESSED>` (or `--after-fix` result), Next step
= the first Recommended Next Step that applies (`/dev-story` for the fix story,
`/hotfix [BUG-ID]` for S1/S2, `/bug-report verify [BUG-ID]` after the fix), plus
Blocked on / Files in progress (diagnosis record, regression test) / Open
questions; append the Notes line. Still updated when the diagnosis is `NOT
ASSESSED` or the user declines the writes (record nothing written and why).

---

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check it
exists before treating the phase as done. If `debugger` returns BLOCKED, errors,
or cannot complete: surface it immediately, do not proceed past what it blocks,
and produce a partial record with the verdict `NOT ASSESSED — [what was
missing]`. Full procedure: `.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Reproduce before hypothesising; observe before changing** — a hypothesis without a repro is a guess
- **Root cause is a falsifiable sentence** ("X happens because Y when Z"), proven by a test or trace — "the symptom went away after my change" is not proof
- **One change per experiment**, reverted when it did not help
- **The fix is not made here** — it goes to the owning lead via `principal-engineer`; the user approves the file set
- **A regression test not seen failing is not a regression test** — red output on the unfixed commit is saved
- **Describe only what was read** — evidence files and screenshots are opened with `Read`
- **A check that did not run is reported as not run**; state what was not examined
- No commits unless the user asks

## Recommended Next Steps

- Accepted diagnosis: `/dev-story` for the fix story (via `principal-engineer`), then `/code-review`, `/story-done`; S1/S2: `/hotfix [BUG-ID]`; live impact: `/incident`, `/postmortem`
- After the fix: `/debug [BUG-ID] --after-fix`, then `/bug-report verify [BUG-ID]`
- Test missing at a higher level: `/automate-test [BUG-ID]`
- Intermittent test: `/test-flakiness`; sustained slowness: `/perf-profile`
