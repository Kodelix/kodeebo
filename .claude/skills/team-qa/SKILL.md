---
name: team-qa
description: "Orchestrate the QA team through a full testing cycle — qa-lead strategy and test plan, qa-tester and test-automation-engineer for cases and automation, uat-coordinator when a release needs UAT, execution on a running stack, sign-off."
argument-hint: "[sprint | feature: context-name | release] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Agent, AskUserQuestion, Edit, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/hooks/yaml-helper.sh is_always_ask_category *), Bash(bash "*/.claude/skills/team-qa/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

# Team QA

When this skill is invoked, orchestrate the QA team through a structured testing cycle.

**Decision Points:** At each phase transition, use `AskUserQuestion` to present
the user with the subagent's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
In `collaborative` mode, the user must approve before moving to the next phase.
In `guided` mode the pipeline advances automatically unless a phase is BLOCKED;
in `autonomous` mode it runs end to end, recording each phase outcome via
`log_decision`. Decisions in `automation_always_ask` categories
(`is_always_ask_category` helper) always prompt regardless of mode. See
`.claude/docs/automation-modes.md`.

## Phase 0: Resolve Config

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,team.size,qa.level,testing.strict,performance.enforce,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**Tests never scale down.** A Logic, Integration, Contract or Security story needs
its automated test at every `qa.level` and every `workflow` tier
(`.claude/docs/coding-standards.md`); a story without a passing test is missing
required evidence, not "waived". `qa.level` changes only how much *extra*
evidence is asked for (the depth of the manual walk, extra exploratory sessions).
Also never waived at any level: Security stories' negative tests and ASVS/MASVS
mapping, the run-and-observe evidence every user-visible or callable change
needs (`.claude/docs/run-and-observe.md`), and the UI screenshots.
`testing.strict.*` (above; `unset` = each story type's default in
`coding-standards.md`) decides whether a failure *blocks*; this skill reports it.

`review_mode` sets director-gate depth, and this pipeline has no director gate:
no phase below spawns a PD-, CTO-, PR- or DD-PHASE-GATE at any `review_mode`.
Its phase gates are the pipeline's own decision points (defined under
`team.size` below), and the agents that work at them are team members, not
director gates. (`SL-RELEASE-SECURITY` and `SRE-OPERABILITY` are read as inputs
when a release is in scope — Phase 1 — never spawned from here.)

`automation` drives the Decision Points note above. See
`.claude/docs/automation-modes.md` for how each mode changes pipeline behaviour.

**`team.size`**: which agents are active (orthogonal to review_mode gate-depth and workflow docs).
- **`individual`** (default): `qa-tester` only; `qa-lead` invoked at phase gates only — the strategy gate (Phase 2) and the sign-off gate (Phase 6), the two phases that end in a listed decision point and need its judgement.
- **`small`**: `qa-lead` + `qa-tester` + `test-automation-engineer` pipeline (as documented).
- **`studio`**: `qa-lead` + per-story `qa-tester` spawn + `test-automation-engineer` + `uat-coordinator` (when UAT is in scope) + sign-off.
A non-core agent needed at `individual` routes through the nearest active core agent with an informational note. **"Phase gate" means any phase that ends in an `AskUserQuestion` decision point this pipeline itself lists** — a transition under Decision Points above, or a **Gate** step written into the pipeline below — **whatever the `automation` mode**: in `guided` or `autonomous`, where that question is skipped or logged, the phase is still a gate. Not every phase is one. Apply the test literally: if the phase below lists no decision point, it is not a gate, and an agent restricted to "phase gates only" is not spawned for it. This active-set scoping applies throughout the pipeline below: any phase that names an agent outside the active set routes through the nearest core agent rather than spawning it.

**Announce the active set before Phase 1 — never let the collapse be silent.**
Before spawning anything, state in one line which agents this run will actually
spawn, and which the pipeline below names but will **not** spawn at the resolved
`team.size`. For example:

> `Active set (team.size: <resolved>): <the agents listed for that size above>.`
> `Not spawned this run: <every other agent this pipeline names> — consulted`
> `through <nearest active core agent>. Raise team.size (or modes.rigor) to widen.`

Fill it from the `team.size` list directly above and the agents this file's own
pipeline names — not from an example. An agent the resolved size spawns only at
phase gates (`qa-lead` at `individual`) goes in the active set with that
qualifier — it is spawned, not consulted through another agent.

The pipeline below reads as a multi-agent fan-out and at the shipped default it
is one or two agents. **The collapse is correct**: `team.size` is rigor-fronted
and the narrow default is the token lever. Without saying so, a reader cannot
distinguish a correctly-collapsed run from a broken pipeline. This is the same
rule as the skipped-check reporting elsewhere in this file: **a constraint that
is enforced but never surfaced is indistinguishable, to the person reading the
output, from one that was never enforced.**

## Team Composition

- **qa-lead** — QA strategy, test plan generation, story classification, severity, sign-off report
- **qa-tester** — Test case writing, exploratory sessions, bug report writing, manual QA documentation, evidence capture
- **test-automation-engineer** — Testcontainers suites, contract tests, Playwright / Compose UI / XCUITest, CI test infrastructure; fills automated-test gaps the plan identifies
- **uat-coordinator** — only when the scope is a release that needs user acceptance testing (see Phase 1): business-language scenarios, UAT environment and seeded tenant, role scripts (Arabic and English), defect intake, `uat-signoff.md`

## How to Delegate

Use the `Agent` tool to spawn each team member as a subagent:
- `subagent_type: qa-lead` — Strategy, planning, classification, sign-off
- `subagent_type: qa-tester` — Test case writing, execution notes and bug report writing
- `subagent_type: test-automation-engineer` — Automated test gap-filling and CI wiring
- `subagent_type: uat-coordinator` — UAT plan, sessions and sign-off record (release scope only)

**Brief each agent — do not dump context.** Read the shared inputs **once** and pass a distilled brief inline: the lines each agent actually needs, never a file path for a document you have already read (an agent handed a path re-reads the whole file). Pass a path only for a document you have not read and only that agent needs. Independent agents are spawned in parallel — issue every independent `Agent` call before waiting for any result (`.claude/docs/coordination-rules.md`, Parallel Task Protocol).

**End every agent prompt with a return contract:** "Write your full output to `[path]` — that named path is your write authorisation under the bounded exception below, so write it without a separate approval prompt. Return **only** (1) the path written, (2) a ≤5-bullet summary of decisions, (3) any BLOCKED/CONCERNS items, one line each. Do not restate the documents you read." Without it, an agent returns everything it read back into this session.

> **Why this does not violate the Collaboration Protocol.** `CLAUDE.md` requires an agent to ask "May I write this to [filepath]?" before Write/Edit. A subagent spawned here writes **without** asking, and that is a deliberate, bounded exception rather than an oversight. The exception holds only when all three are true: (1) the path is one **you** named in the prompt, so the user approved the destination when they approved the phase; (2) it is a new artifact under `production/`, `docs/` or a test directory, never an edit to existing source or config; (3) the phase that produced it is a phase gate as defined above — one the pipeline lists as ending in an `AskUserQuestion` before it advances, whatever the automation mode. Outside those three, the agent must ask. **Do not "fix" this by asking per subagent** — a prompt per agent per phase makes an orchestrator unusable, which is why the exception exists.

At `team.size: studio`, Phase 4 spawns one `qa-tester` per story, in parallel; below that, one spawn covers the whole group.

## Pipeline

### Phase 1: Load Context

Before doing anything else, gather the full scope:

1. Detect the current scope from the argument:
   - If the argument is a sprint identifier (e.g. `sprint-03`): Glob `production/sprints/sprint-*.md` and match by sprint number — `sprint-3`, `sprint-03` and `sprint-003` all name sprint 3 (`/sprint-plan` writes `sprint-NNN.md`). Read the matched file. If multiple match, use the most recently modified.
   - If the argument is `feature: [context-name]`: glob story files tagged for that bounded context or feature
   - If the argument is `release`: the scope is the release candidate — read `production/releases/` for the release record and checklist, and the stories shipped in it. A release scope **adds** to the cycle: the editions that ship (hosted, self-hosted bundle, Android, iOS, web), the upgrade-from versions for self-hosted, and whether UAT is required (`design/product-brief.md`, `.claude/docs/templates/release-checklist-template.md`, `production/releases/`). If you cannot tell whether UAT is required, ask.
   - If no argument: read `production/session-state/active.md` and `production/sprint-status.yaml` (if present) to infer the active sprint. If there is no sprint — at `rigor: minimal` there are none — ask which epic to cover and use `feature: [epic-slug]`; do not invent a sprint

2. Read `project.stage` from `project.yaml` (fallback `production/stage.txt`) to confirm the current project phase.

3. **Read the open bugs in scope** — the bugs already on file, before QA finds new ones: grep the `**Severity**`, `**Status**` and `**System**` lines of `production/qa/bugs/*.md`, as `/bug-triage` does. A bug is open unless its Status is `Closed` or `Verified Fixed`; it is in scope when its System is a context the in-scope stories belong to, or it names an in-scope story — when unsure, list it. These go into the Phase 2 and Phase 6 briefs as **Open bugs in scope**: an open S1 or S2 here already makes the sign-off NOT APPROVED (Phase 6), whatever QA finds. No bug files → "Open bugs in scope: none on file".

4. At release scope, also read (as inputs, not spawns) any `SL-RELEASE-SECURITY` and `SRE-OPERABILITY` outcomes recorded under `production/gate-checks/` and the latest `/security-audit` and `/load-test` reports. A missing one is reported as **not found**, never as passed.

5. Count stories found and report to the user:
   > "QA cycle starting for [sprint/feature/release]. Found [N] stories. Open bugs in scope: [N — S1: n, S2: n, or none on file]. Current stage: [stage]. UAT in scope: [yes/no/unknown]. Ready to begin QA strategy?"

### Phase 2: QA Strategy (qa-lead)

Spawn `qa-lead` via `Agent` to review all in-scope stories and produce a QA strategy.

Pass `qa-lead` the **Open bugs in scope** from Phase 1 (ID, severity, story or context), then prompt it to:
- Read each story file
- Classify each story by type: **Logic** / **Integration** / **Contract** / **Security** / **Performance** / **UI** / **Config**
- Identify which stories require automated test evidence vs. manual QA — Logic, Integration, Contract and Security stories require an automated test at **every** `qa.level`; a story that has none is flagged as missing required evidence (a gap for `test-automation-engineer`), never waived. Performance (per `performance.enforce`) and UI keep their evidence at every level
- Flag any stories with missing acceptance criteria, missing threat model (for sensitive features), or missing test evidence that would block QA
- Identify **gaps for `test-automation-engineer`**: contexts with no integration tests on real dependencies, `contracts/` changes with no contract test, critical journeys with no Playwright / Compose UI / XCUITest coverage, tests in CI quarantine
- Estimate manual QA effort (number of test sessions needed), including **Arabic (RTL) and English passes** for every UI story
- **Before assessing smoke status, check for an existing smoke check report**: Glob `production/qa/smoke-*.md` and read the most recently modified file (if found). If a report exists, use its verdict and findings directly — do not re-interview the user. If no report exists, note: "No prior smoke check report found — run `/smoke-check sprint` before proceeding." and set smoke check status to UNKNOWN. Produce a smoke check verdict: **PASS** / **PASS WITH WARNINGS [list]** / **NOT ASSESSED [what did not run]** / **FAIL [list of failures]** / **UNKNOWN (no report found)**
- At release scope, state per edition (hosted / self-hosted / Android / iOS / web) what QA covers and what it does not
- Produce a strategy summary table and smoke check result:

  | Story | Type | Automated Required | Manual Required | Blocker? |
  |-------|------|--------------------|-----------------|----------|

  **Smoke Check**: [PASS / PASS WITH WARNINGS / NOT ASSESSED / FAIL / UNKNOWN] — [source: `production/qa/smoke-[date].md` or "no report found"] — [details if not PASS]

  **Open bugs in scope**: [BUG-ID — S[n] — story or context, one per line; or "none on file"] — an open S1 or S2 is named here as a known failure

If the smoke check result is **FAIL**, `qa-lead` must list the failures prominently. QA cannot proceed past the strategy phase with a failed smoke check.

Present the `qa-lead`'s full strategy to the user, then use `AskUserQuestion`:

```
question: "QA Strategy Review"
options:
  - "Looks good — proceed to test plan"
  - "Adjust story types before proceeding"
  - "Skip blocked stories and proceed with the rest"
  - "Smoke check failed — fix issues and re-run /team-qa"
  - "Cancel — resolve blockers first"
```

If smoke check **FAIL**: do not proceed to Phase 3. Surface the failures from the smoke check report and stop. The user must fix them, re-run `/smoke-check sprint`, and then re-run `/team-qa`.
If smoke check **UNKNOWN**: surface a warning — "No smoke check report found. Recommend running `/smoke-check sprint` before QA. Proceeding with caution."
If smoke check **NOT ASSESSED**: surface what the report says did not run — "The last smoke check could not assess [what did not run]. Recommend re-running `/smoke-check sprint` once it can. Proceeding with caution." — and continue as for UNKNOWN; the sign-off cannot be APPROVED on it (Phase 6).
If smoke check **PASS WITH WARNINGS**: note the warnings for the sign-off report and continue.
If blockers are present: list them explicitly. The user may choose to skip blocked stories or cancel the cycle.

### Phase 3: Test Plan Generation

Using the strategy from Phase 2, produce a structured test plan document from `.claude/docs/templates/test-plan.md`.

The test plan should cover:
- **Scope**: sprint/feature/release name, story count, dates, editions
- **Story Classification Table**: from Phase 2 strategy
- **Automated Test Requirements**: which stories need test files, at which layer and expected path (see test locations in `.claude/docs/directory-structure.md`), and which gaps `test-automation-engineer` fills; required tests are never dropped at any `qa.level`
- **Manual QA Scope**: which stories need manual walkthrough and what to validate; the negative path (wrong role, other tenant, invalid input) for anything callable
- **Surfaces and locales**: web at 1440 px and 390 px, Android, iOS; **English and Arabic (RTL)** for every user-visible change; self-hosted install and upgrade when the bundle is in scope
- **UAT** (release scope only): scenarios and participants, owned by `uat-coordinator`; UAT is in scope or explicitly marked **not required — [reason]**
- **Out of Scope**: what is explicitly not being tested this cycle and why
- **Entry Criteria**: what must be true before QA can begin. Always include: (1) a smoke check PASS or PASS WITH WARNINGS report exists at `production/qa/smoke-*.md`, (2) the build is stable (the stack comes up, migrations run, health checks pass), (3) at sprint scope, all Must Have stories are `in-progress`, `review` or `done` in `production/sprint-status.yaml`; at `feature:` scope, every in-scope story file's Status is In Progress, In Review or Complete, (4) the seeded test tenant exists in `tools/seed/` — never production data. Add any sprint-specific criteria beyond these.
- **Exit Criteria**: what constitutes a completed QA cycle (all stories PASS or FAIL with bugs filed; evidence on disk)

Ask: "May I write the QA plan to `production/qa/qa-plan-[scope]-[date].md`?"

Write only after receiving approval.

### Phase 4: Test Case Writing and Automation Gaps

> **Smoke check** is performed as part of Phase 2 (QA Strategy). If the smoke check returned FAIL in Phase 2, the cycle was stopped there. This phase only runs when the Phase 2 smoke check was PASS, PASS WITH WARNINGS, NOT ASSESSED, or UNKNOWN.

Two independent tracks run **in parallel** (spawn both before waiting for either):

**Track A — manual test cases.** For each story requiring manual QA (UI, Integration without automated tests, Security checks that need a person, exploratory areas — and, as extra evidence beside the automated test, the acceptance-criteria walk of any Logic, Integration, Contract or Config story the plan asks for; a missing test is never replaced by this walk):

Spawn `qa-tester` via `Agent` — one per story, in parallel, at `team.size: studio`; one spawn covering the whole group at `small` and `individual` — providing, for each story:
- The story file path
- The relevant section of the QA plan for that story
- The feature spec's acceptance criteria for the feature being tested (if available)
- Instructions to write detailed test cases covering all acceptance criteria, including the negative path and the Arabic/RTL pass for UI
- **The output path: `production/qa/cases/[story-slug]-cases.md`.** Name it explicitly in the prompt, one per story.

**Track B — automated gaps.** If the plan lists gaps and `test-automation-engineer` is in the active set: spawn it with the gap list, the layer's test location, and the instruction to write the missing suites **using the project's existing test tooling and scripts** (Testcontainers, contract tests against `contracts/`, Playwright / Compose UI / XCUITest as the stack uses — never a runner command or framework version from memory). It reports the tests it added and the CI wiring needed; it does not weaken or skip any existing test. If not in the active set, route through `qa-tester` with the informational note and mark the gaps **not automated this run** in the sign-off.

> **Why the path is stated here rather than left to the orchestrator.** The bounded write exception above holds only when "the path is one **you** named in the prompt". This is the phase that spawns agents *in parallel*, so it is where an unnamed destination does the most damage: each agent improvises its own, and two runs file the same artifact in two places.

Each test case set should include:
- **Preconditions**: tenant, role, plan, seed data, feature flags, build and environment required before testing begins
- **Steps**: numbered, unambiguous actions
- **Expected Result**: what should happen
- **Actual Result**: field left blank for the tester to fill in
- **Pass/Fail**: field left blank

Present the test cases to the user for review before execution. Group by story.

Use `AskUserQuestion` per story group (batched 3-4 at a time):

```
question: "Test cases ready for [Story Group]. Review before manual QA begins?"
options:
  - "Approved — begin manual QA for these stories"
  - "Revise test cases for [story name]"
  - "Skip manual QA for [story name] — not ready"
```

### Phase 5: Test Execution

Run on the running stack (`.claude/docs/run-and-observe.md`): `qa-tester` (or
`test-automation-engineer` for suites) brings up `deploy/compose.dev.yaml` with
the seeded test tenant — those agents have Bash; this skill runs no shell
command itself. A staging environment is allowed for manual and UAT runs only
when the user names it explicitly in this session; production is never a target.
Never real customer data, and never a command that deletes volumes.

**5a. Automated.** The automated suites for the in-scope layers run through the
product's own scripts and CI (run by `test-automation-engineer`, or by `qa-tester`
below `studio`). A suite that started and executed zero tests is FAIL, not a pass
(a vacuous pass is a fail); a suite that could not start is `NOT ASSESSED`. Record what ran and the results; a suite that
could not run is `NOT RUN — [reason]`, never counted as passing. Any quarantined
or skipped test touching the scope is listed.

**5b. Manual.** Walk through each story in the approved manual QA list.

Batch stories into groups of 3-4 and use `AskUserQuestion` for each. **Wait for
the tester's answer** and record only what they said: a result the tester did not
give is never filled in for them. A story nobody answered for stays unexecuted,
which makes the sign-off NOT ASSESSED — it is not BLOCKED unless they say so.

```
question: "Manual QA — [Story Title]\n[brief description of what to test]"
options:
  - "PASS — all acceptance criteria verified"
  - "PASS WITH NOTES — minor issues found (describe after)"
  - "FAIL — criteria not met (describe after)"
  - "BLOCKED — cannot test yet (reason)"
```

After each FAIL result: use `AskUserQuestion` to collect the failure description, then spawn `qa-tester` via `Agent` to write a formal bug report in `production/qa/bugs/`, in `/bug-report`'s format — its Severity and Priority labels exactly as that template lists them (`S2-High`, `P1-Fix this sprint`, …), because `/bug-triage` parses them. **A suspected cross-tenant exposure is S1** — report it to the user immediately in conversation, do not wait for the end of the phase.

**5c. UAT (release scope, `uat-coordinator` in the active set).** If UAT is in scope, spawn `uat-coordinator` with the release scope, the acceptance criteria and the personas; it prepares the UAT environment and seeded tenant, role scripts (Arabic and English), runs or schedules sessions, and writes `production/qa/uat/uat-signoff-[release]-[date].md` (path named in the prompt). **Sign-off rows stay unchecked unless the acceptance happened.** Defects found in UAT enter the normal bug flow. If UAT is required and was not run, the Phase 6 verdict cannot be APPROVED. If `uat-coordinator` is not in the active set (below `studio`), say so and report **UAT: NOT RUN — [active set]**.

**After each PASS or PASS WITH NOTES on a UI story or a story needing run-and-observe, record its evidence in `production/qa/evidence/`.** The retained screenshot or captured request/response is the evidence: ask the tester to save one of each screen or call the story touched under `production/qa/evidence/[story-slug]/` (desktop and mobile, **Arabic (RTL) and English** for web; each touched screen and RTL for Android/iOS; request/response with secrets redacted and a trace for API; load-test result for Performance; negative tests and ASVS/MASVS mapping for Security) and confirm it is on disk. Then ask "May I write the evidence for [story titles] to `production/qa/evidence/`?", once per story group, and write `production/qa/evidence/[story-slug]-evidence.md` from `.claude/docs/templates/test-evidence.md`, referencing the files. If nothing was saved, name that story in the Phase 5 summary as missing its retained evidence rather than writing a document that implies one.

> **This is not optional bookkeeping — it is the artifact the next skill gates
> on.** `/story-done` globs `production/qa/evidence/` for UI, Security and
> Performance stories; `/story-readiness`, `/test-evidence-review` and the
> release gates read the same directory. Write anywhere else and a story can pass
> a full QA cycle here, then be told by `/story-done` that no evidence exists. UI
> and Security gates are **BLOCKING by default**, so that is a deadlock.
>
> Leave the sign-off rows **unchecked** unless the sign-off actually happened in
> this session. An evidence file with pre-ticked approvals is worse than none: it
> converts a missing signature into a recorded one.

Bug report naming: `BUG-[NNNN].md`, numbered the way `/bug-report` numbers them — the highest ID in `production/qa/bugs/` plus one, zero-padded to four digits — so `/bug-report verify` and `close` can find it by its ID.

After collecting all results, summarize:
- Automated suites run / NOT RUN: [list]
- Stories PASS: [count]
- Stories PASS WITH NOTES: [count]
- Stories FAIL: [count] — bugs filed: [IDs]
- Stories BLOCKED: [count]
- UAT: [signed off / signed off with open items / NOT RUN / not required]

### Phase 6: QA Sign-Off Report

Spawn `qa-lead` via `Agent` to draft the sign-off report using all results from Phases 2–5. **Here the return contract is the report text in its reply, not a file:** the orchestrator writes the sign-off after the ask at the end of this phase, so `qa-lead` writes nothing.

**Brief `qa-lead` with the evidence and the verdict rules below — never a verdict.** Pass the strategy table, the smoke check verdict and its source, each story's result, the automated-suite results, the UAT result, the bugs filed in Phase 5 and the **Open bugs in scope** from Phase 1, and the verdict rules below, verbatim. Do not name a verdict, pre-fill the `### Verdict:` line, or say which fact decides it: `qa-lead` applies the rules to the evidence. Then check its verdict against the same rules before asking to write; if they disagree, show both and ask — never silently substitute your own.

The sign-off report format:

```markdown
## QA Sign-Off Report: [Sprint/Feature/Release]
**Date**: [date]
**Active set**: [agents spawned] · Not spawned: [agents routed through others]
**Editions covered**: [hosted / self-hosted / Android / iOS / web — and any not covered]

### Test Coverage Summary
| Story | Type | Auto Test | Manual QA | EN / AR | Result |
|-------|------|-----------|-----------|---------|--------|
| [title] | Logic | PASS | — | n/a | PASS |
| [title] | Logic | MISSING — no passing test | criteria walked (extra) | n/a | NOT ASSESSED — required test missing |
| [title] | UI | — | PASS | EN PASS / AR PASS | PASS |
| [title] | Security | PASS (negative tests) | PASS | n/a | PASS |
| [title] | Integration | — | BLOCKED | — | BLOCKED — [reason]; no executed evidence |

### UAT
[signed off / signed off with open items / NOT RUN — reason / not required — reason]

### Bugs Found
| ID | Story | Severity | Status |
|----|-------|----------|--------|
| BUG-0001 | [story] | S2 | Open |

[every open bug in scope — those Phase 1 found on file and those filed in Phase 5]

### Verdict: NOT ASSESSED / APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED

**Conditions** (if any): [list what must be fixed before the build advances]

### Next Step
[guidance based on verdict]
```

**Every story in scope gets a Test Coverage Summary row** — BLOCKED and
unexecuted stories included, with the reason in Result — so a story that never
ran cannot drop out of the report.

Verdict rules:

**Order.** Check **NOT APPROVED first**: any open S1/S2 bug in scope — one already on file (Phase 1) as much as one filed in Phase 5 — or a story that FAILs without a documented workaround, or an open cross-tenant exposure at any severity, makes the verdict NOT APPROVED whatever else went unexecuted — a known failure outranks an unknown, and demoting it to NOT ASSESSED would bury it (`.claude/rules/skill-authoring.md`, obligation 1).

**Then the precondition.** APPROVED and APPROVED WITH CONDITIONS both require that **every story in scope produced executed evidence** — a test that ran, or a manual case that was walked, on the running stack — and, where UAT is required, that UAT was run. A Logic, Integration, Contract or Security story whose required automated test is missing is missing evidence at every `qa.level`: an acceptance-criteria walk is extra evidence, never a substitute. If any story is BLOCKED, unexecuted, or has no evidence, the verdict is **NOT ASSESSED**, not either kind of APPROVED. A smoke check that was UNKNOWN (no report found) or NOT ASSESSED in Phase 2 also makes it NOT ASSESSED: the build's health was never checked. So does a required UAT that did not run, and an Arabic pass that was required for a UI story and not executed.

- **NOT ASSESSED — NO EVIDENCE**: One or more stories produced no executed evidence (BLOCKED, required tests not written, cases not walked, required UAT or Arabic pass not run, or smoke check FAIL / UNKNOWN / NOT ASSESSED). This is **not** a pass and **not** a fail; it means QA did not happen. Say which stories and why.
- **APPROVED**: All stories PASS or PASS WITH NOTES; no S1/S2 bugs open
- **APPROVED WITH CONDITIONS**: S3/S4 bugs open, or PASS WITH NOTES issues documented; no S1/S2 bugs
- **NOT APPROVED**: Any S1/S2 bugs open; or stories FAIL without documented workaround

> **Why the precondition exists.** The rules below it assume every story
> resolves to PASS or FAIL. A cycle where nothing was executed trips none of the
> NOT APPROVED conditions and **vacuously satisfies "no S1/S2 bugs open"** —
> because zero executed tests means zero observed failures. Read literally, and
> without this precondition, the rules let a completely untested build reach
> APPROVED. A sign-off asserts verified quality; without this precondition the
> rules cannot tell "verified good" from "never looked".

Next step guidance by verdict:
- NOT ASSESSED: "QA did not run to completion. Produce the missing evidence — write the missing required tests, walk the manual cases, run the Arabic pass, run UAT where required, run `/smoke-check` — then re-run `/team-qa`. Do not advance the build on this verdict."
- APPROVED: "Build is ready for the next phase. Run `/gate-check` to validate advancement; at release scope `/team-release` consumes this sign-off."
- APPROVED WITH CONDITIONS: "Resolve conditions before advancing. S3/S4 bugs may be deferred only with a recorded reason."
- NOT APPROVED: "Resolve S1/S2 bugs and re-run `/team-qa` or targeted manual QA before advancing. Open cross-tenant exposure is an incident: use `/hotfix`."

**Gate (phase gate).** Present the sign-off draft and its checked verdict, then `AskUserQuestion`: write the sign-off / revise the draft / stop without a sign-off. At `team.size: individual` this is where `qa-lead` is spawned to draft the report — it is the only place besides Phase 2 it runs.

Ask: "May I write this QA sign-off report to `production/qa/qa-signoff-[scope]-[date].md`?"

Write only after receiving approval. Take `[date]` from `date +%F`. If the user declines, the orchestrator verdict is `BLOCKED — write declined by user`; the sign-off verdict stays in conversation only.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "cannot complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is usually still
there.

If any spawned agent returns BLOCKED, errors, or cannot complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report.** Full procedure: `.claude/docs/error-recovery-protocol.md`.

Common blockers:
- Input file missing (story not found, spec absent) → redirect to the skill that creates it
- ADR status is Proposed → do not implement; once it is decided, accept it with `/architecture-decision accept ADR-NNNN`
- Scope too large → split into two stories via `/create-stories`
- Conflicting instructions between ADR and story → surface the conflict, do not guess
- Dev stack will not come up → that is the finding; capture `docker compose logs` and stop the execution phase

## Output

A summary covering: stories in scope, active set, smoke check result, automated results, manual QA results (EN and AR), UAT result, bugs filed (with IDs and severities), and the final APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED / NOT ASSESSED verdict.

Verdict: **COMPLETE** — QA cycle finished.
Verdict: **BLOCKED** — smoke check failed or critical blocker prevented cycle completion; partial report produced.
Verdict: **BLOCKED — write declined by user** — the sign-off report write was declined; nothing is reported as COMPLETE.

## Session State Update

After the final phase completes (sign-off report written or BLOCKED verdict reached), silently append (with `Edit`, after the existing content; `Write` only if the file does not exist) to `production/session-state/active.md`, and also update that file's checkpoint per `.claude/docs/checkpoint-handoff.md` (Current task `/team-qa <scope> — <verdict>`, Next step = the first item of this skill's Next Steps — a bug fix or `/story-done` when not APPROVED —, Blocked on / Files in progress / Open questions; append the Notes line; leave the `Flow:` line and other blocks alone; still done on BLOCKED or a declined write):

```
<!-- QA RUN: [date] | Scope: [sprint identifier, feature or release] | Verdict: [APPROVED/APPROVED WITH CONDITIONS/NOT APPROVED/NOT ASSESSED/BLOCKED] | Report: production/qa/qa-signoff-[scope]-[date].md -->
```
