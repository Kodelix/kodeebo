---
name: retrospective
description: "Sprint or milestone retrospective from completed work, velocity, blockers, DoD compliance and incidents. Actionable insights for the next iteration."
argument-hint: "[sprint-N|milestone-name]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Bash(git log *), AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Edit, Bash(bash "*/.claude/skills/retrospective/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,stack`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

# Retrospective



Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (sprint plan and `sprint-status.yaml`, story files, evidence directories, bug files, incident and post-mortem records, prior retrospectives, git log, source code).
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill produces it.

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer to
"what does the data say?" when there is no data. The failure mode this prevents is
specific: a report whose verdict enum has no "could not run" state produces
**false clean passes** — a retrospective reporting "no DoD waivers, no incidents"
because no story files, evidence directories or incident records were read.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 1: Parse Arguments

Determine whether this is a sprint retrospective (`sprint-N`) or a milestone retrospective (`milestone-name`).

---

## Phase 1b: Check for Existing Retrospective

Before loading any data, glob for an existing retrospective file:

- For sprint retrospectives: `production/retrospectives/retro-[sprint-slug]-*.md`
  (also check `production/sprints/sprint-[N]-retrospective.md` as an alternate location)
- For milestone retrospectives: `production/retrospectives/retro-[milestone-name]-*.md`

If a matching file is found, use `AskUserQuestion`:
- Prompt: "An existing retrospective was found: [filename]. How do you want to proceed?"
- Options:
  - `[A] Update existing — load it and add/revise sections with new data`
  - `[B] Start fresh — generate a new retrospective (the old file is left untouched)`

If [A]: read the existing file and carry its content forward, revising sections with new data; Phase 5 updates that file in place with `Edit` (or `Write` for a full rewrite) after its ask.
If [B]: continue to Phase 2 with a blank slate. The old file is never renamed, archived or deleted (this skill has no rename tool): the new retrospective is written under a new dated name and its header carries `Supersedes: [old file]`.

---

## Phase 2: Load Sprint or Milestone Data

Read the sprint or milestone plan from the appropriate location:

- Sprint plans: `production/sprints/`
- Milestone definitions: `production/milestones/`

**Also check for `production/sprint-status.yaml`**: if it exists, read it alongside the sprint plan. It is the authoritative source for actual story completion status (status: done, completed dates, blockers). Use it as the primary source for completion metrics in Phase 3. Fall back to markdown scanning only if the yaml does not exist. Note discrepancies between the yaml and the sprint plan (e.g., stories in yaml not in plan, or vice versa).

**If the file does not exist or is empty**, output:

> "No sprint data found for [sprint/milestone]. Run `/sprint-plan new` to create a
> sprint (`/sprint-status` only reads one), or provide the sprint details manually."

At `workflow: minimal` (resolved above) there are no sprints: offer to look back over the stories
closed so far instead (`production/epics/*/story-*.md` with `Status: Complete`).
Tests are never waived by `qa.level` (`coding-standards.md`): a Logic, Integration,
Contract or Security story closed without its passing tests is a finding at every
tier, as is a UI story closed without its retained screenshot, a story closed
without run-and-observe evidence, and a security-sensitive story closed without
its negative tests. `qa.level` only changes how much *extra* evidence (manual
cases, coverage signal, UAT) was expected.

Then use `AskUserQuestion` to present these options ([C] only at `workflow: minimal`):

- **[A] Provide data manually** — ask the user to paste or describe the sprint
  tasks, dates, and outcomes; use that as the source of truth for the retrospective.
- **[B] Stop** — abort the skill. Verdict: **NOT ASSESSED — NO DATA** (no sprint data available; name what was missing and that `/sprint-plan new` produces it).
- **[C] Look back over the closed stories** — use the stories with
  `Status: Complete` as the record of what was done.

If the user chooses [A], collect the data and continue to Phase 3 using what they provide.
If the user chooses [B], stop here.
If the user chooses [C], read those stories and continue to Phase 3. Sections that
need sprint data (planned vs actual, velocity, carryover, estimation accuracy)
are `NOT ASSESSED — NO DATA`.

Extract: planned tasks, estimated effort, owners, and goals.

Run git log for the sprint period to understand what was actually committed and when, with
the Bash tool (one command per call, no `||` chaining):

```
Bash: git log --oneline --since="4 weeks ago"
```

Adjust the `--since` date to match the sprint duration if known from the sprint plan. If it
returns nothing (or fails: no repository, no commits), say so and run `git log --oneline -20`;
if that also returns nothing, the commit metric is `NOT ASSESSED — NO DATA`.

---

## Phase 3: Analyze Completion and Trends

Scan for completed and incomplete tasks by comparing the plan against actual deliverables. Check for:

- Tasks completed as planned
- Tasks completed but modified from the plan
- Tasks carried over (not completed)
- Tasks added mid-sprint (unplanned work)
- Tasks removed or descoped

Every story with `status: blocked` in `production/sprint-status.yaml` goes under
Blockers Encountered, with its `blocker` field as the Blocker, and gets an action
item in Action Items for Next Iteration.

Scan the DoD record and the operational record:

- **DoD compliance** — for each story closed in the period: were the eight gates (`.claude/docs/coding-standards.md`) met or waived in writing? Count waivers (grep `Waiver` / `Waived` in the story files) and stories whose `production/qa/evidence/<story-id>/` is missing for a visible or callable change. Count stories that went back from review for a missing gate (research note after the code, no cross-tenant test, no cache decision). A waiver is data, not blame.
- **Escaped defects and incidents** — bugs found after a story closed (`production/qa/bugs/`), hotfixes, incident or post-mortem files from the period (`docs/runbooks/`, `/incident` and `/postmortem` outputs if present). With none present, the line reads `NOT ASSESSED — NO DATA`, not "none".
- **Contract and dependency friction** — stories blocked or reworked because the contract moved after clients started, an ADR was not Accepted, a threat model or research note arrived late, a provider sandbox or store review took longer than planned.
- **Estimate calibration for DoD work** — compare the evidence effort estimated (tests, run-and-observe, security negatives) against actual, separately from build effort, so the next `/estimate` can be tuned.

Scan the codebase for TODO/FIXME trends (across the code roots from `resolve_code_root`; an empty result means the scan did not run — say so):

- Count current TODO/FIXME/HACK comments
- Compare to previous sprint counts if available (check previous retrospectives)
- Note whether technical debt is growing or shrinking

Read previous retrospectives (if any) from `production/retrospectives/` to check:

- Were previous action items addressed?
- Are the same problems recurring?
- How has velocity trended?

With no earlier sprint or retrospective, Velocity Trend keeps only the current
sprint's row and reads `NOT ASSESSED — NO DATA`, and Previous Action Items
Follow-Up is that one line — no invented earlier rows, no empty table.

---

## Phase 4: Generate the Retrospective

```markdown
## Retrospective: [Sprint N / Milestone Name]
Period: [Start Date] -- [End Date]
Generated: [Date]

### Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Tasks | [X] | [Y] | [+/- Z] |
| Completion Rate | -- | [Z%] | -- |
| Story Points / Effort Days | [X] | [Y] | [+/- Z] |
| Bugs Found | -- | [N] | -- |
| Bugs Fixed | -- | [N] | -- |
| Escaped Defects (found after Done) | -- | [N] | -- |
| Incidents / Hotfixes | -- | [N] | -- |
| Stories Closed with DoD Waivers | -- | [N] | -- |
| Stories Missing Evidence at Close | -- | [N] | -- |
| Unplanned Tasks Added | -- | [N] | -- |
| Commits | -- | [N] | -- |

### Velocity Trend

| Sprint | Planned | Completed | Rate |
|--------|---------|-----------|------|
| [N-2] | [X] | [Y] | [Z%] |
| [N-1] | [X] | [Y] | [Z%] |
| [N] (current) | [X] | [Y] | [Z%] |

**Trend**: [Increasing / Stable / Decreasing — or `NOT ASSESSED — NO DATA` with no earlier sprint to compare]
[One sentence explaining the trend]

### What Went Well
- [Observation backed by specific data or examples]
- [Another positive observation]
- [Recognize specific contributions or decisions that paid off]

### What Went Poorly
- [Specific issue with measurable impact -- e.g., "Feature X took 5 days
  instead of estimated 2, blocking tasks Y and Z"]
- [Another issue with impact]
- [Do not assign blame -- focus on systemic causes]

### Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| [What blocked progress] | [How long] | [How it was resolved] | [How to prevent recurrence] |

### Definition of Done Compliance

| Gate | Stories met | Waived | Missing evidence | Note |
|------|-------------|--------|------------------|------|
| 1 Research first | | | | |
| 3 Tests (by type) | | | | |
| 4 Observability | | | | |
| 5 Caching | | | | |
| 6 Performance | | | | |
| 7 Security (negatives, tenancy) | | | | |
| 8 Decision record | | | | |
| Run-and-observe evidence | | | | |

*(Gate 2 — clean architecture — is reviewed in code review; list it only if findings recurred.)*

**Pattern**: [which gate is most often waived or late, and the systemic cause]

### Estimation Accuracy

| Task | Estimated | Actual | Variance | Likely Cause |
|------|-----------|--------|----------|--------------|
| [Most overestimated task] | [X] | [Y] | [+Z] | [Why] |
| [Most underestimated task] | [X] | [Y] | [-Z] | [Why] |

**Build vs DoD-evidence effort**: [estimated vs actual for each — is the evidence share of the estimate right?]
**By lane**: [backend / web / mobile / contracts — where did estimates slip?]

**Overall estimation accuracy**: [X%] of tasks within +/- 20% of estimate

[Analysis: Are we consistently over- or under-estimating? For which types of
tasks? What adjustment should we apply?]

### Carryover Analysis

| Task | Original Sprint | Times Carried | Reason | Action |
|------|----------------|---------------|--------|--------|
| [Task that was not completed] | [Sprint N-X] | [N] | [Why] | [Complete / Descope / Redesign] |

### Technical Debt Status
- Current TODO count: [N] (previous: [N])
- Current FIXME count: [N] (previous: [N])
- Current HACK count: [N] (previous: [N])
- Trend: [Growing / Stable / Shrinking]
- [Note any areas of concern]

### Previous Action Items Follow-Up

| Action Item (from Sprint N-1) | Status | Notes |
|-------------------------------|--------|-------|
| [Previous action] | [Done / In Progress / Not Started] | [Context] |

### Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | [Specific, measurable action] | [Who] | [High/Med/Low] | [When] |
| 2 | [Another action] | [Who] | [Priority] | [When] |

### Process Improvements
- [Specific change to how we work, with expected benefit]
- [Another improvement -- keep it to 2-3 actionable items, not a wish list]

### Summary
[2-3 sentence overall assessment: Was this a good sprint/milestone? What is
the single most important thing to change going forward?]
```

---

## Phase 5: Save Retrospective

Present the retrospective and top findings to the user (completion rate, velocity trend, top blocker, most important action item).

The path depends on how Phase 1b ended:

| Case | Ask |
|---|---|
| New sprint retrospective (or Start fresh) | "May I write this to `production/retrospectives/retro-sprint-[N]-[date].md`?" |
| New milestone retrospective (or Start fresh) | "May I write this to `production/retrospectives/retro-[milestone-name]-[date].md`?" |
| `workflow: minimal` look-back over closed stories | "May I write this to `production/retrospectives/retro-stories-[date].md`?" |
| Update existing (`[A]`) | "May I update `[existing file]` in place?" (the file Phase 1b found, wherever it lives) |

Start fresh never renames or touches the old file; the new file's header carries
`Supersedes: [old file]`.

If yes, write the file, creating the `production/retrospectives/` directory if needed. Verdict: **COMPLETE** — retrospective saved (or **COMPLETE WITH GAPS** when sections read `NOT ASSESSED — NO DATA`).

If no, stop here. Verdict: **BLOCKED — write declined by user** (nothing is reported as saved).

---

## Phase 6: Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/retrospective <sprint |
milestone> — <verdict>`, Next step = `/sprint-plan new` with the action items
(milestone: `/gate-check`; `minimal`: the first action item in the brief's build
order), plus Blocked on / Files in progress / Open questions; append the Notes
line. A declined write still updates the checkpoint with the blocker.

At `workflow: minimal` (resolved above), which has no sprints, skip this question:
point to the retrospective file and say its action items go into the brief's build
order.

Otherwise, use `AskUserQuestion`:
- Prompt: "Retrospective complete. The action items and velocity data are ready. Would you like to start sprint planning now with this data pre-loaded?"
- Options:
  - `[A] Yes — open sprint planning with retro action items and velocity delta pre-populated`
  - `[B] No — I'll reference the retrospective file manually when I'm ready`

If the user selects [A]: tell the user to run `/sprint-plan new` next, and print the retrospective file path and a summary of the action items and velocity change to hand to it (this skill does not run other skills).

- If this was a milestone retrospective, run `/gate-check` to formally assess readiness for the next phase (and consider `/postmortem` for any incident that is not yet written up).

### Guidelines

- Be honest and specific. Vague retrospectives ("communication could be better") produce vague improvements. Use data and examples.
- Focus on systemic issues, not individual blame.
- Limit action items to 3-5. More than that dilutes focus.
- Every action item must have an owner and a deadline.
- Check whether previous action items were completed. Recurring unaddressed items are a process smell.
- If this is a milestone retrospective, also evaluate whether the milestone goals were achieved and what that means for the overall project timeline.
- Treat a recurring DoD waiver as a process finding: the fix is earlier planning of that gate's work (research note, threat model, evidence budget), never dropping the gate.
- Action items that change a standard or a skill are proposed, not applied here; the user routes them to `/skill-improve` or the owning document.
