---
name: automate-test
description: "Convert manual test cases (production/qa/cases/) and fixed bugs into automated tests at the lowest level that proves them (unit, integration, contract, e2e): deterministic, isolated, built on /test-helpers factories and fixtures, run and shown able to fail, mapped back to the case or bug."
argument-hint: "[BUG-ID | story-id | path-to-cases-file] [--level unit|integration|contract|e2e] [--layer backend|web|kmp|android|ios]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(git status), Bash(git status *), Bash(git log *), Bash(git rev-parse *), Bash(git worktree add *), Bash(git worktree remove *), Bash(git worktree list), Bash(mktemp -d), Bash(mktemp -d *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(go help *), Bash(docker info), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(timeout 900 go -C * test *), Bash(timeout 900 pnpm -C * run *), Bash(timeout 900 pnpm -C * test *), Bash(timeout 900 pnpm -C * exec playwright test *), Bash(timeout 900 ./gradlew -p * *), Bash(timeout 900 swift test *), Bash(bash "*/.claude/skills/automate-test/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`.

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

**`qa.level` does not decide whether a *requested* conversion runs** — the user
asked for it — and it never waives a test: Logic, Integration, Contract and
Security tests are required at every level (`.claude/docs/coding-standards.md`),
so a case file's tests are not dropped from the table because the level is
`minimal`.

**Who runs what.** This skill runs the new tests itself (granted per layer under
`timeout 900`: `go -C`, `pnpm -C`, `./gradlew -p`, `swift test`), brings the stack
up with `docker compose -f deploy/compose.dev.yaml up -d --wait`, and manages the
scratch worktree (`git worktree add|remove`, `mktemp -d`). `test-automation-engineer`
writes the test files; it is not asked to run anything. `docker compose down`,
Playwright browser installs and CI changes are not granted — print the command or
report the wiring for the user or `platform-lead`.

# Automate Test

A manual case is a one-time check; a fixed bug without a regression test is a
bug that comes back. This skill turns **manual cases** and **fixed bugs** into
automated tests at the level where they are cheapest and most stable, using the
helpers `/test-helpers` generated, and proves each new test **can fail** and
**passes now**. The suites are written by `test-automation-engineer`; this skill
chooses the level, briefs it, verifies the result and records the mapping.

**Output**
- new test files beside the code, in the layer's test location (`directory-structure.md` "Code roots": `*_test.go`, `src/integrationTest/kotlin/`, `*.test.ts(x)`, `web/e2e/`, `src/commonTest/kotlin/`, `app/src/androidTest/`, Swift test targets)
- `production/qa/evidence/[ID]/automation.md` — case/bug → test → level → result → evidence, with `raw/` output
- the case file's mapping lines (`Automated: <test>`) — only after the user says yes; **a manual case is never deleted or marked retired by this skill**

> **A check that did not run is reported as not run.** A test that was written
> but could not be executed (toolchain missing, container runtime down, iOS on a
> Linux host) is `WRITTEN, NOT RUN — [reason]`, never counted as automated
> coverage. A test never seen to fail proves nothing
> (`.claude/rules/skill-authoring.md`).

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `BLOCKED`: a new test fails on the current build for a reason that
> is a **product defect** (route to `/bug-report`; the test is not weakened to
> pass) or the helpers/framework the test needs do not exist. `NOT ASSESSED`: one
> or more new tests were not run or not shown able to fail, or nothing could be
> assessed (no case file or bug found for the argument, code roots unresolved). `COMPLETE WITH GAPS`:
> every automated test ran, passed and can fail, but listed cases were
> deliberately not automated (with the reason each).

---

## Phase 1: Intake

0. **No input, no run.** No argument, no case file with unautomated cases and no
   bug found → `NOT ASSESSED — nothing to automate`, naming what was searched.
1. **Source.** A BUG-ID → `production/qa/bugs/BUG-[NNNN].md` and, if present,
   `production/qa/evidence/[BUG-ID]/diagnosis.md` (it names the regression test
   level and the red output — `/debug`). A story ID or a cases file →
   `production/qa/cases/[story-slug]-cases.md` with its `TC-<story>-NN` IDs, the
   criterion each proves, preconditions and actor. No argument → list case files
   with unautomated cases and ask which.
2. **Facts** per item: the criterion or defect, the actor (anonymous / member /
   admin / other tenant), the layer, the contract operation (`contracts/`), and
   the story type. A case without a mapped criterion is reported to
   `product-manager` as a gap, not guessed.
3. **Code roots.** `bash .claude/hooks/yaml-helper.sh resolve_code_root`; empty
   → `NOT ASSESSED — code roots unresolved`, stop.
4. **Helpers present?** Look for the factories, fakes and Testcontainers fixtures
   `/test-helpers` writes for the layer. Absent → recommend `/test-helpers
   [context]` first; do not invent a parallel helper library.

## Phase 2: Choose the Level — then Ask

**Read `references/1-levels-and-rules.md` now and follow it.** It holds the
decision rules (lowest level that proves the behaviour; e2e only for revenue and
data-loss journeys), the required-tests-by-change table, what is **not**
automated, and the determinism rules.

Present a table: `Case/bug | Behaviour proved | Level | Layer | Test path | Why
this level | Automate? (yes / no — reason)`. `AskUserQuestion`: approve the
table / change a level / drop a row / cancel. Nothing is written before this.
Cancel, or no row left to automate, ends `NOT ASSESSED — no automation approved`
with nothing written.

## Phase 3: Write — `test-automation-engineer`

Spawn `test-automation-engineer` via `Agent` — **one per layer, in parallel**
when the table spans layers (issue every `Agent` call before waiting for any).
If it cannot be spawned, say why and write the tests here under the same rules.

Fixed brief (fill only the `{…}` slots; no opinion on whether the code is
correct):

```text
Automate these cases for /automate-test. Rules: .claude/skills/automate-test/references/1-levels-and-rules.md
and .claude/docs/testing-standards.md, .claude/rules/test-standards.md.
Layer: {layer} · Stack: {stack line} · Helpers: {paths from /test-helpers, or "absent"}
Rows to automate: {the approved rows: id, behaviour, level, test path, actor, contract operation}
Write only new files at the listed paths (and test helpers under the layer's
test helper directory). Do not edit product code, CI or deploy files. Use the
project's existing test tooling and scripts; take image tags from
docs/stack-reference/pins.yaml; a command or API not in the stack reference or
the project is NOT SOURCEABLE - report it, do not write it from memory.
Do not skip, loosen or delete any existing test.
Write your output summary to {production/qa/evidence/<ID>/automation-<layer>.md} -
that named path is your write authorisation; the test files at the listed paths
are covered by the user's approval of the table. Return only (1) the files written,
(2) a <=5-bullet summary, (3) BLOCKED/CONCERNS one line each, including any CI
wiring needed (platform-lead owns the pipeline files).
```

Verify the files exist before reading any reply
(`.claude/docs/error-recovery-protocol.md`).

## Phase 4: Prove — Run, Fail, Repeat

**Read `references/2-verify-and-record.md` now and follow it.** For every new
test: it **passes** on the current build (via the layer's confirmed command —
`/test` has the sources); it **fails** when the behaviour it guards is broken
(for a bug, on the unfixed commit; otherwise a one-mutation check in a scratch
worktree); and it is **stable** over N repeats (N stated). Zero tests executed
is a failed run. A new test that fails on the current build is a defect finding:
`BLOCKED`, `/bug-report`, never "fixed" by weakening the assertion.

## Phase 5: Record

Ask: "May I write `production/qa/evidence/[ID]/automation.md` (and `raw/` output)
and add `Automated: [test]` lines to `production/qa/cases/[file]`?" Name every
path. Write only after a yes; the case file is an edit of an existing artifact,
so it is asked separately from the new evidence files. **If the user declines
the evidence write, close with `BLOCKED — write declined by user`**: the tests
already written stay on disk (they were approved with the table), the proof is
shown in conversation only, and nothing is reported as COMPLETE or recorded. A
declined case-file edit alone is not a block — the evidence file stands and the
mapping lines are simply not added (say so).

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/automate-test <target> —
<verdict>`, Next step = the first Recommended Next Step (`/test [layer]`, or
`/bug-report` when a new test found a defect), plus Blocked on / Files in
progress (the test files, `automation.md`) / Open questions; append the Notes
line. Still updated on `BLOCKED` (including a declined evidence write: the
tests stay on disk, nothing recorded).

Present the summary: tests written (by level and layer), run results, red/green
proof, cases not automated with reasons, CI wiring needed, and the verdict.

---

## Error Recovery Protocol

**First, verify the artifact.** If a spawned agent's return contract named a
path, check it exists before treating the phase as done; a fluent reply with no
file is a failed phase — resume the agent naming the unmet contract. If it
returns BLOCKED, errors or cannot complete: surface it immediately, do not
proceed past what it blocks, produce a partial report. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Lowest level that proves the behaviour** — an e2e test for something a unit test proves is a defect in the suite
- **Deterministic and isolated** — injected clock and ID generator, no sleeps, a fresh tenant and data per test, real dependencies via Testcontainers, never a mocked database or cache
- **Never fix production code, never weaken a test to make it pass** — a red test on the current build is a finding
- **Never delete or retire a manual case** — it stays until the user says the automated test replaces it
- **Never write a runner command, flag or API from memory** — KMP test commands and Compose UI on iOS are `NOT SOURCEABLE` in the stack reference: `/research`
- **Pipeline and deploy files are `platform-lead`'s** — report the wiring needed
- Ask before every write; no commits unless the user asks

## Recommended Next Steps

- Run the layer: `/test [layer]`; flaky: `/test-flakiness`
- Quality of the new tests/evidence: `/test-evidence-review`
- Bug found by a new test: `/bug-report`, then `/debug`
- Coverage vs critical journeys: `/regression-suite`; story ready: `/story-done`
