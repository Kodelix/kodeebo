---
name: manual-test
description: "Exploratory and manual QA session on a running stack: a written charter (mission, areas, risks, time box), a coverage matrix of roles, tenants, plans and locales (Arabic RTL and English), evidence captured under production/qa/evidence/<id>/, and findings filed through /bug-report."
argument-hint: "[story-id | feature | release-build] [--time-box 45|60] [--charter <slug>] [--env dev|<named staging>]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, Bash(git diff *), Bash(git status), Bash(git status *), Bash(git log *), Bash(git rev-parse *), Bash(date *), Bash(docker compose -f deploy/compose.dev.yaml up -d --wait), Bash(docker compose -f * logs *), Bash(docker compose -f * ps), Bash(docker compose -f * ps *), Bash(docker compose -f * stop *), Bash(docker compose -f * start *), Bash(bash "*/.claude/skills/manual-test/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,testing.strict,accessibility,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`. **A tester's result
is never delegated to a mode**: PASS/FAIL/BLOCKED are recorded only from what
was observed or what the tester said.

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

# Manual Test

An exploratory session finds what the written cases and the automated suites did
not think of. It is **chartered** (a mission, a time box, named areas and risks),
runs on the dev stack with seeded tenants **as each relevant actor**, in English
and Arabic (RTL), and ends with notes, retained evidence and filed bugs. The
session is run by `qa-tester`, with the user as co-tester where judgement is
needed.

**Output** (all under `production/qa/evidence/[ID]/`, `[ID]` = story ID or charter slug)
- `charter.md` — mission, scope, risks, matrix, time box, tooling, heuristics
- `session-notes.md` — areas covered, results per matrix cell, findings, questions, **what was not covered**
- evidence files named per `run-and-observe.md`: `api-<endpoint>.md`, `web-<screen>-<width>-<lang>.png`, device screenshots, trace exports
- `production/qa/bugs/BUG-[NNNN].md` for each finding, through `/bug-report`
- when the subject is a story: `production/qa/evidence/[STORY-ID]/test-evidence.md` from `.claude/docs/templates/test-evidence.md` (inside the story's own evidence folder, with the files it cites), sign-off rows left **unchecked**

> **This is a coverage report, not a quality approval.** "No bugs found" means no
> bugs were found in the cells that were executed, with the heuristics applied —
> and the report lists the cells and heuristics that were not. A session that
> found nothing in an untouched area proves nothing about it
> (`.claude/rules/skill-authoring.md`). **A cell not executed is `NOT COVERED`,
> never passed; an image not opened is not described.**

> **Verdicts (session):** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` /
> `BLOCKED`. `BLOCKED`: the stack will not come up, or an S1 (including a suspected
> cross-tenant exposure) stopped the session. `NOT ASSESSED`: no matrix cell was
> executed with evidence on disk (a required input — seeded users, a device, a
> browser — was missing). `COMPLETE WITH GAPS`: some cells are `NOT COVERED`; each
> is listed with its reason. `COMPLETE`: every chartered cell executed, evidence
> on disk. **Findings are reported first, whatever the verdict** — an open S1/S2
> found in the session is stated before the verdict, because a known failure
> outranks an unexecuted cell. Precedence: `BLOCKED`, `NOT ASSESSED`,
> `COMPLETE WITH GAPS`, `COMPLETE`. A declined charter or notes write is
> `BLOCKED — write declined by user` (nothing is reported as COMPLETE; the
> findings and cell results stay in conversation, marked not recorded). A missing
> subject (no story, feature or build named and none can be inferred) is
> `BLOCKED — no subject`; a charter the user cancels is `NOT ASSESSED — no session run`.

---

## Phase 1: Subject, Build and Environment

1. **Subject.** A story → its file, spec acceptance criteria (`design/specs/`),
   threat model, existing cases (`production/qa/cases/`) and bugs
   (`production/qa/bugs/`); a feature or release build → the stories and release
   record. Read the open bugs in scope: they seed the charter's risks.
2. **Build.** Record the git hash / release candidate tested. A rebuild
   invalidates results for the areas the diff touches.
3. **Environment.** `--env dev` (the default): `docker compose -f
   deploy/compose.dev.yaml up -d --wait` with the seeded test tenants from
   `tools/seed/` (`.claude/docs/run-and-observe.md`). `--env <name>` is a staging
   environment **the user names explicitly in this conversation**; the name goes
   in the charter, and only that environment is used. **Never production (nor a
   "staging" that shares production data or accounts), never real customer data,
   never `down -v`.** An unnamed or production-looking `--env` value is refused
   (`BLOCKED — environment not named`). A service that never becomes healthy is
   the finding: capture `docker compose -f <file> logs <svc>`, verdict `BLOCKED`.
   This skill runs the compose bring-up, `logs`, `stop` and `start` itself; the
   `qa-tester` agent runs the API calls, Playwright and device captures. `down`
   is not granted: print it for the user if they want the containers removed.
4. **Surfaces.** From `stack`: web (`web/`, 1440 px and 390 px), Android
   (emulator/device), iOS (simulator — macOS host only; on Linux those cells are
   `NOT COVERED — macOS only`), self-hosted bundle, API. `accessibility` target
   (resolved above) is noted for the keyboard/screen-reader heuristics.

## Phase 2: Charter and Coverage Matrix

**Read `references/1-charter-and-matrix.md` now and follow it.** It defines the
charter fields, the role × tenant × plan × locale matrix, the heuristics to name
and the time box (45–60 minutes). Draft the charter with the user —
`AskUserQuestion` for mission options, risks to prioritise, and which cells
matter; the user decides what is in and out.

Ask: "May I write the charter to `production/qa/evidence/[ID]/charter.md`?"
Write only after a yes. The charter is fixed **before** the session starts, so
what was planned and what was done stay distinguishable.

## Phase 3: Run the Session

**Read `references/2-session-and-evidence.md` now and follow it.** Spawn
`qa-tester` via `Agent` for the cells that can be driven from the shell (API
calls as each actor, Playwright-driven web screenshots, device screenshots), and
ask the user to run the cells that need human judgement (look, feel, copy,
Arabic readability) — `AskUserQuestion` per batch of 3–4 cells with
PASS / PASS WITH NOTES / FAIL / BLOCKED. **Wait for the answer; record only what
was said.** A cell nobody answered stays unexecuted.

Fixed brief for `qa-tester` (fill the `{…}` slots only):

```text
Run this charter for /manual-test: {production/qa/evidence/<ID>/charter.md}
Build {hash}; environment {compose dev | named staging}; stack {stack line}.
Execute the cells assigned to you, as each actor, against the running stack;
use only seeded tenants from tools/seed/. Capture evidence per
.claude/docs/run-and-observe.md into production/qa/evidence/<ID>/ and confirm each
file is on disk before marking a cell passed. Redact secrets, tokens, OTPs and
personal data before saving. Record, for each cell: result, evidence path,
anything odd that did not fail. Time-box: {45|60} minutes (note start and end
times, UTC). Do not edit product code or automated suites. Write notes to
{production/qa/evidence/<ID>/session-notes-qa-tester.md} - that named path is your
write authorisation; return only (1) the path, (2) a <=5-bullet summary,
(3) BLOCKED/CONCERNS one line each, with any suspected cross-tenant exposure first.
```

Verify the notes file exists before reading the reply
(`.claude/docs/error-recovery-protocol.md`).

## Phase 4: Findings

For each finding, present: title (actor, action, wrong outcome), the repro
steps, the evidence path, the **proposed** severity with the matched rule from
`/bug-report`'s table (final severity is `qa-lead`'s). `AskUserQuestion`: file it
now / refine / not a bug. Then run `/bug-report` for each approved finding —
IDs are allocated by that skill.

- **A suspected cross-tenant exposure is S1: tell the user immediately in
  conversation**, do not wait for the end, route to `security-lead` through
  `qa-lead`, and keep exploit detail out of any shared place.
- Accessibility findings: note for `accessibility-specialist`; Arabic/RTL copy or
  layout defects: for `localization-lead`; an authz or injection suspicion for
  `appsec-engineer`. They are coordination notes in the bug text, not spawns.

## Phase 5: Notes, Evidence and Verdict

Open each screenshot with `Read` and compare it to the cell's expectation;
describe only what you opened. Merge the agent's notes and the user's answers
into `session-notes.md`, with the matrix table (`EXECUTED`/`NOT COVERED` per
cell), findings by ID, questions raised, heuristics applied and **not** applied,
and the verdict. Ask: "May I write `session-notes.md`
[and `test-evidence.md`] to `production/qa/evidence/[ID]/`?" A story's
evidence file is written only if its evidence files are on disk; if nothing was
saved, name the story as **missing retained evidence** instead of writing a
document that implies one.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/manual-test <target> —
<verdict>`, Next step = the first Recommended Next Step (`/bug-triage` when bugs
were filed), plus Blocked on / Files in progress / Open questions; append the
Notes line. BLOCKED, NOT ASSESSED or a declined write still updates the
checkpoint with the blocker.

---

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check it
exists before treating the phase as done. If `qa-tester` returns BLOCKED, errors
or cannot complete: surface it immediately, keep the cells it did not run as
`NOT COVERED`, and produce a partial report. Full procedure:
`.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Charter first** — mission, scope, time box and matrix are written down before the session
- **The tester's result is the tester's** — never fill in a result nobody gave
- **Negative paths and the other tenant are always in the matrix** for anything callable
- **Dev stack and seeded tenants only**; no real customer data, credentials or production endpoints
- **Failure paths are induced, not assumed** — stop a dependency (`docker compose -f <file> stop <svc>`), go offline, slow a response; record the user-visible message and any data loss
- **Evidence on disk before a cell is marked passed**; captured-and-discarded is an assertion
- **A suspected vulnerability is never disclosed in a public place** — `security-lead` via `qa-lead`
- Ask before every write; no commits unless the user asks

## Recommended Next Steps

- Bugs filed: `/bug-triage`; unknown cause: `/debug [BUG-ID]`
- Stable cases worth keeping: `/automate-test [story-id]`
- Sprint/release QA: `/team-qa`; formal acceptance by business users: `/uat`
- Evidence quality: `/test-evidence-review`
