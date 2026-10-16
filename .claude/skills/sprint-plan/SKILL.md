---
name: sprint-plan
description: "New or updated sprint plan from the current milestone, completed work, and per-lane capacity (backend/web/mobile), contract-first ordering and DoD evidence effort."
argument-hint: "[new|update|status] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/sprint-plan/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,story_granularity,workflow,stack,qa.level,testing.strict,performance.enforce`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Sprint Plan

## Existing Sprints

Glob `production/sprints/sprint-*.md` once at the start (no shell listing — `Glob` is the
tool) and keep the list: it identifies the previous sprint and the next number in Phase 1. An
empty result or a missing `production/sprints/` directory means "no sprint yet" (`001`).

---

## Phase 0: Parse Arguments

Extract the mode argument (`new`, `update`, or `status`).

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`story_granularity`** — it sets how
many stories to allocate per sprint, scaled by velocity: **2–4** at `coarse` (the default, via `rigor: minimal`),
**6–10** at `balanced` (`rigor: standard`), **15–25** at `fine`. A Ready backlog
smaller than the range is planned whole — never padded with invented stories.

**Review mode check** (before gates run):
- Use the review mode from the resolved block above (`--review` overrides it
  for this run) — do not re-resolve it, and do not ask for it. With nothing
  configured it follows `modes.rigor`: `solo` at `minimal`, `lean` at `standard`.
- **Never write a review mode** — not to `project.yaml`, not to
  `production/review-mode.txt`. `modes.review_mode` is one of the knobs
  `modes.rigor` fronts: pinning it in `project.yaml` shadows the rigor
  expansion, and the legacy file sits *above* that expansion, so either write
  would freeze director-review depth for good. `--review` covers a one-off. If
  the user wants a different depth to persist, point them to changing
  `modes.rigor` (`/settings modes.rigor=<minimal|standard|full>`), or to pinning
  it on purpose with `/settings --local modes.review_mode=<full|lean|solo>` (a
  personal override in `project.local.yaml`).

---

## Phase 1: Gather Context

1. **Read the current milestone** from `production/milestones/` **if it exists**.
   Milestone definitions are authored by hand from
   `.claude/docs/templates/milestone-definition.md`; no skill writes one (`/milestone-review`
   writes only `<name>-review.md` reports into the same directory — skip files ending
   `-review.md` when looking for the definition). On the majority of projects
   it is absent, which is the normal state, not a gap: note "no milestone
   defined — planning against the story backlog alone" and continue. Never block
   sprint planning on it, and never infer a milestone from the sprint files.

2. **Read the previous sprint** (if any) from `production/sprints/` to
   understand velocity and carryover. In `new` mode:
   - The new sprint's number `[N]` is the highest `sprint-NNN.md` in the
     Existing Sprints listing plus one (`001` when there is none). It is the
     `[N]` in the plan's title, its QA plan path and the write ask.
   - Every story of the previous sprint that is not `Complete` — by its status
     in `production/sprint-status.yaml`, else its story file's Status line —
     goes in the Carryover table with a Reason and a New Estimate. It appears
     only there, never again as new Must Have / Should Have / Nice to Have work.
   - Stories closed last sprint with a **DoD waiver** carry their waiver clean-up as a budgeted task (PR-SPRINT check 6).
   - Read the latest `production/retrospectives/` file if present: its action items and estimation-accuracy table calibrate this sprint's estimates.

3. **Find the stories to plan** — this is the actual backlog, and it is the one
   input this phase cannot do without:
   ```
   Glob production/epics/**/story-*.md
   Grep pattern="^> \*\*Status\*\*" glob="production/epics/**/story-*.md" output_mode="content"
   ```
   Stories live at `production/epics/[epic-slug]/story-NNN-[slug].md` — that is
   where `/create-stories` writes them and where `/dev-story` looks for them. Plan
   from the ones marked `Ready`. Use the grep rather than reading each story: at
   this stage you need status and title, not the body.

   If the glob returns nothing: "No stories found under `production/epics/`. Run
   `/create-stories` first (at `standard`/`full`, `/create-epics` before it)."
   Do not proceed to invent work items — a sprint plan that references stories
   which do not exist cannot be implemented. Verdict: **BLOCKED** — no stories to plan.

4. **Scan feature specs** in `design/specs/` for additional context on the
   features those stories implement. At `workflow: minimal` there are no
   per-feature specs — use `design/product-brief.md` instead, and do not treat the
   absent specs as missing work. (Note: `/sprint-plan` is **optional** at
   `minimal` — the brief's Build order already is the plan.)

5. **Check the risk register** at `production/risk-register/` **if it exists**.
   Like the milestone above, no skill writes it — entries are authored by hand
   from `.claude/docs/templates/risk-register-entry.md`. If the directory is
   absent, say so once ("no risk register — risks assessed from the sprint
   contents only") rather than skipping risk assessment silently.

6. **Check planning prerequisites per candidate story** (header fields and
   one grep each — do not read story bodies):
   - **Story type** is set (Logic / Integration / Contract / Security / Performance / UI / Config). No type → cannot be sized; route to `/story-readiness`.
   - **Research note** `docs/research/<feature>.md` exists, or the story is research-exempt (`.claude/docs/research-protocol.md` table). Missing → the research note is a task in this sprint ahead of the story, not an assumption.
   - **Threat model** `docs/architecture/threat-models/<feature>.md` exists for stories that hit a security-baseline trigger (`.claude/docs/security-baseline.md` → Threat modelling). Missing → the story is not plannable until `/threat-model` has run (SL-THREAT-MODEL).
   - **Governing ADRs** are Accepted (one scan of `docs/architecture/adr-*.md`, as `/story-readiness` does). A `Proposed` ADR keeps the story out.
   - **Story-readiness**: a story whose last QL-STORY-READY verdict was INADEQUATE, or that `/story-readiness` marked BLOCKED / NEEDS WORK, is not planned (PR-SPRINT check 5). Name it under "Excluded" with the reason.

A check that could not run (unreadable file, empty scan) is reported as "not checked" against that story — never as passed.

---

## Phase 1b: Capacity and Ordering

Read `references/capacity-and-lanes.md` and build, before choosing stories:

1. **Capacity per lane** — backend, web, mobile (only lanes `stack` includes), contracts/platform. Total days minus the 20% buffer (unplanned work, incidents, hotfixes), minus on-call/support load, minus review time. The sprint is feasible only when **each lane** fits, not only the total.
2. **Contract-first order** — a contract story (`contracts/` + contract test) is merged before any backend or client story that consumes it. Client lanes may start on mocks only if the story says so and the contract is already reviewed. Order the Must Have list by this dependency chain; a dependent story placed ahead of its contract is a planning error.
3. **DoD-inclusive estimates** — each story's estimate must include its evidence: research note, tests by story type, observability, cache decision, performance evidence, security negatives and run-and-observe evidence (the DoD effort table in `/estimate`). A story estimated as "build only" is re-estimated before it is planned; do not accept a bare number from the story file without checking that.

---

## Phase 2: Generate Output

For `new`:

**Generate a sprint plan** from `.claude/docs/templates/sprint-plan.md` (read it; the plan follows its sections and Definition of Done) and present it to the user. Do NOT ask to write yet — the gate phases run first and may require revisions before the file is written: the producer feasibility gate (Phase 4, spawned only in `full` review mode — skipped in `lean`/`solo`) and the QA plan check (Phase 5, all modes).

Beyond the template, the plan must show:

- **Capacity by lane**: a table (lane — available days — planned days — headroom) with the 20% buffer and on-call load subtracted.
- **Story Type and Agent/Owner** on every row; the owner is the stack lead for the layer (`go-lead` / `ktor-lead`, `web-lead`, `android-lead`, `ios-lead`, `kmp-specialist`, `api-designer` for contracts, `data-lead`, `platform-lead`) per `.claude/docs/agent-roster.md`.
- **Dependencies** column with story IDs, including the contract story each backend/client story waits on.
- **Evidence expected** per story: the story type's evidence (`coding-standards.md` → Test evidence by story type), plus run-and-observe and, for security-sensitive stories, the negative tests and ASVS/MASVS mapping.
- **Excluded stories** with the reason (not Ready, ADR Proposed, threat model missing, research missing, contract not merged).
- **External dependencies**: provider sandbox/keys, `saas-core` module release, store review, legal sign-off — with lead time in calendar days.
- **Carryover** with reasons, including DoD-waiver clean-up tasks.

For `update`:

**Update an existing sprint plan**:

1. Read the most recent sprint plan from `production/sprints/`.
2. Present the current story list with their current statuses from `production/sprint-status.yaml`.
3. Ask the user what to change: stories to add, remove, reprioritize, or re-estimate. Use `AskUserQuestion` to gather changes. Adding scope mid-sprint is a `scope_changes` decision (always asked).
4. Apply the changes and re-present the full revised plan for review, re-checking per-lane capacity and contract-first order.
5. Re-run the producer feasibility gate (Phase 4) on the revised plan.
6. Write the updated markdown plan and yaml together (same approval as `new` mode).

Note: `update` mode does not reset story statuses. Stories already marked `in-progress` or `done` keep their status. Only `backlog` and `ready-for-dev` stories can be removed or reprioritized freely.

For `status`:

**Generate a status report**:

```markdown
# Sprint [N] Status -- [Date]

## Progress: [X/Y tasks complete] ([Z%])
By lane: backend [x/y] · web [x/y] · mobile [x/y] · contracts [x/y]

### Completed
| Task | Completed By | Notes |
|------|-------------|-------|

### In Progress
| Task | Owner | % Done | Blockers |
|------|-------|--------|----------|

### Not Started
| Task | Owner | At Risk? | Notes |
|------|-------|----------|-------|

### Blocked
| Task | Blocker | Owner of Blocker | ETA |
|------|---------|-----------------|-----|

## Burndown Assessment
[On track / Behind / Ahead]
[If behind: What is being cut or deferred]

## Emerging Risks
- [Any new risks identified this sprint]
```

---

## Phase 3: Prepare Sprint Status File

After generating a new sprint plan, also prepare the `production/sprint-status.yaml` content.
This is the machine-readable source of truth for story status — read by
`/sprint-status`, `/story-done`, and `/help` without markdown parsing.

**Do not write the yaml yet** — hold it in context. The producer feasibility gate (Phase 4, `full` review mode only) may revise the story list; the QA plan check (Phase 5) runs in every mode. Both files are written together after Phase 5 in a single write approval.

Format:

```yaml
# Auto-generated by /sprint-plan. Updated by /story-done and /dev-story.
# DO NOT edit manually — use /story-done to update story status.
#
# Status value mapping (yaml ↔ story file Status field):
#   backlog        ↔  Not Started
#   ready-for-dev  ↔  Ready
#   in-progress    ↔  In Progress
#   review         ↔  In Review
#   done           ↔  Complete
#   blocked        ↔  Blocked

sprint: [N]
goal: "[sprint goal]"
start: "[YYYY-MM-DD]"
end: "[YYYY-MM-DD]"
generated: "[YYYY-MM-DD]"
updated: "[YYYY-MM-DD]"

stories:
  - id: "[epic-story, e.g. 1-1]"
    name: "[story name]"
    file: "[production/epics/[epic-slug]/story-NNN-[slug].md]"   # the real path, verbatim from the Glob above
    type: logic                # logic | integration | contract | security | performance | ui | config
    lane: backend              # backend | web | mobile | contracts | platform
    priority: must-have        # must-have | should-have | nice-to-have
    status: ready-for-dev      # backlog | ready-for-dev | in-progress | review | done | blocked
    owner: ""
    depends_on: []             # story ids; the contract story for a backend/client story
    estimate_days: 0           # includes DoD evidence effort
    blocker: ""
    completed: ""
```

Initialize each story from the sprint plan's task tables:
- Must Have tasks → `priority: must-have`, `status: ready-for-dev`
- Should Have tasks → `priority: should-have`, `status: backlog`
- Nice to Have tasks → `priority: nice-to-have`, `status: backlog`
- Carryover rows → the story's previous `priority`, and the `status` it has now

For `update`: read the existing `sprint-status.yaml`, carry over statuses for
stories that haven't changed, add new stories, remove dropped ones.

---

## Phase 4: Producer Feasibility Gate

**Review mode check** — apply before spawning PR-SPRINT:
- `solo` → skip. Note: "PR-SPRINT skipped — Solo mode." Proceed to Phase 5 (QA plan gate).
- `lean` → skip (not a PHASE-GATE). Note: "PR-SPRINT skipped — Lean mode." Proceed to Phase 5 (QA plan gate).
- `full` → spawn as normal.

Before finalising the sprint plan, spawn `producer` via `Agent` using gate **PR-SPRINT** (`.claude/docs/director-gates/pr-sprint.md`).

Pass: proposed story list (titles, types, estimates, dependencies), per-lane and total capacity, any carryover and open DoD waivers from the previous sprint, milestone constraints and deadline.

Present the producer's assessment.

If UNREALISTIC: revise the story selection (defer stories to Should Have or Nice to Have) and re-present the updated plan, then continue to Phase 5.

If NOT ASSESSED: name the missing input — it is not REALISTIC. Supply it and re-run PR-SPRINT, or record `NOT ASSESSED — [missing input]` for PR-SPRINT in the plan's header (`.claude/docs/director-gates.md`) and continue to Phase 5, repeating it at the write ask.

If CONCERNS, use `AskUserQuestion`:
- Prompt: "Producer flagged concerns with this sprint plan. How do you want to proceed?"
- Options:
  - `[A] Proceed as planned — I accept the risk`
  - `[B] Adjust scope — defer some Should Have stories`
  - `[C] Extend the sprint timeline`

If [A]: continue to Phase 5.
If [B]: revise the story list, re-present the updated plan, then continue to Phase 5.
If [C]: adjust sprint dates and capacity, re-present the updated plan, then continue to Phase 5.

After handling the producer's verdict, continue to Phase 5. The write comes at
its end, so the file you approve already holds everything Phase 5 adds.

---

## Phase 5: QA Plan Gate

Before closing the sprint plan, check whether a QA plan exists for this sprint.

Use `Glob` for `production/qa/qa-plan-*.md` — `/qa-plan` writes `qa-plan-[sprint-slug]-[date].md` — and keep a file whose name or content references this sprint number.

**If a QA plan is found**: note it in the sprint plan output — "QA Plan: `[path]`" — and proceed.

**If no QA plan exists**: do not silently proceed. Surface this explicitly:

> "This sprint has no QA plan. A sprint plan without a QA plan means test requirements are undefined — developers won't know what 'done' looks like from a QA perspective, and the sprint cannot pass the Production → Hardening gate without one.
>
> Run `/qa-plan sprint` now, before starting any implementation. It takes one session and produces the test case requirements each story needs."

Use `AskUserQuestion`:
- Prompt: "No QA plan found for this sprint. How do you want to proceed?"
- Options:
  - `[A] Run /qa-plan sprint now — I'll do that before starting implementation (Recommended)`
  - `[B] Skip for now — I understand QA sign-off will be blocked at the Production → Hardening gate`

Wait for this answer before the write ask below — the two are separate questions.

If [A]: note in the plan "QA plan: run `/qa-plan sprint` before implementation begins."
If [B]: add a warning block to the sprint plan document:

```markdown
> **No QA Plan**: This sprint was started without a QA plan. Run `/qa-plan sprint`
> before the last story is implemented. The Production → Hardening gate requires a QA
> sign-off report, which requires a QA plan.
```

### Write the plan

Ask: "May I write the sprint plan to `production/sprints/sprint-NNN.md` (`[N]` zero-padded to three digits) and
`production/sprint-status.yaml`?" If yes, write both files (creating directories as
needed). Verdict: **COMPLETE** — sprint plan and status file created. If no:
Verdict: **BLOCKED — write declined by user** (neither file is reported as created).

After writing, add:

> **Scope check:** If this sprint includes stories added beyond the original epic scope, run `/scope-check [epic]` to detect scope creep before implementation begins.

If the user chose `Run /qa-plan sprint now` in Phase 5, close with "Sprint plan written. Run `/qa-plan sprint` next — then begin implementation."

---

## Phase 6: Next Steps

After the sprint plan is written and QA plan status is resolved:

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/sprint-plan <sprint> —
<verdict>`, Next step = the first item below (`/qa-plan sprint`), plus Blocked
on / Files in progress (the sprint plan, `sprint-status.yaml`, the QA plan) /
Open questions; append the Notes line. Still updated when a gate blocked the plan
or the write was declined (record the blocker or that nothing was written).

- `/qa-plan sprint` — **required before implementation begins** — defines test cases per story so developers implement against QA specs, not a blank slate
- `/story-readiness [story-file]` — validate a story is ready before starting it
- `/dev-story [story-file]` — begin implementing the first story (the contract story first)
- `/sprint-status` — check progress mid-sprint
- `/scope-check [epic]` — verify no scope creep before implementation begins

**Review mode configuration:** All director gates (producer feasibility, QA review, code review) respect the project review mode, resolved in the block at the top of this skill (`--review` flag → `project.local.yaml` → `modes.review_mode` in `project.yaml` → `production/review-mode.txt` → the `modes.rigor` expansion, which yields `lean` at standard rigor and `solo` at minimal). This skill never asks for it or writes it; Phase 0 says where to point a user who wants a different depth. The mode is one of:
- `lean` — skip non-phase-gate director gates (the `rigor: standard` value)
- `full` — run all director gates as spawned sub-agents
- `solo` — skip all gate spawning unconditionally (single developer, no review)

`modes.review_mode` in `project.yaml` is the primary source; `production/review-mode.txt` is the legacy fallback. Both are read by `/sprint-plan`, `/story-readiness`, `/story-done`, and other gate-using skills at startup. Solo skips the director's opinion, never the Definition of Done: the plan's DoD section and the per-story evidence stay.
