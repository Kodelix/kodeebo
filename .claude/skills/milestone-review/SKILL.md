---
name: milestone-review
description: "Milestone progress review — completeness, quality metrics, open security findings, SLO / self-hosted upgrade / store-review readiness, risk, go/no-go recommendation. At checkpoints or before a deadline."
argument-hint: "[milestone-name|current] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(date *), Bash(bash "*/.claude/skills/milestone-review/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,project.stage,stack,performance.enforce,testing.strict`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

# Milestone Review

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads (milestone definition, sprint reports, story files, bug files, security-audit reports, budgets and load-test evidence, SLO and runbook files, deploy bundle, store-listing files).
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
**false clean passes** — a security line reading "0 open findings" because no audit
was ever run, or a performance line reporting "within budget" when no budget file
or load-test result exists.

**Absence of evidence is never evidence of absence.** A scan that finds no
matches because there are no files to scan has not verified anything. Say which of
the two happened — a reader cannot tell from a green result.

---

## Phase 0: Parse Arguments

Extract the milestone name (`current` or a specific name).

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

---

## Phase 1: Load Milestone Data

Read the milestone definition from `production/milestones/` if it exists. If the
argument is `current`, use the most recently modified milestone file.

> **Milestone definitions are authored by hand** from
> `.claude/docs/templates/milestone-definition.md`; no skill writes one, so most
> projects have none. The only files this skill writes in `production/milestones/` are its own
> `[milestone-name]-review.md` reports (Phase 4). When no definition exists, say so
> and review against the sprint reports alone; do not fabricate a definition. Take
> care with `current`: a
> most-recently-modified match can be a previous *review* rather than a
> definition (a review this skill wrote earlier). Skip files ending `-review.md` when selecting.

The definition's **Type** (Prototype | Vertical Slice | Private Beta | Public
Beta | General Availability | Post-Launch) and **Audience** decide which
readiness sections in Phase 2b apply (`references/readiness-checks.md`).

Gather the sprint reports for sprints within this milestone from
`production/sprints/`. Establish the denominator (glob them, count **N**), then
scan the sections a milestone review actually aggregates rather than reading each
report whole:

```
Grep pattern="^## (Sprint Goal|Capacity|Tasks|Carryover|Risks|Progress|Burndown Assessment|Emerging Risks|Definition of Done)" glob="production/sprints/sprint-*.md" output_mode="content" -A 12
```

> **These alternates are copied from `/sprint-plan`'s emitted headings — keep
> them in sync with it, not with what a milestone review wishes existed.** A
> pattern naming headings the plan never writes matches only `Carryover`, and a
> non-zero match count then hides the zero-match escape hatch below: every
> review silently aggregates carryover tables and nothing else while reporting
> full coverage.

Full-read a single sprint report when its scanned sections point outside
themselves, or when it matched nothing — a zero-match report predates the
template and must be read, never silently dropped from the milestone's history.
Report any sprint that contributed nothing: a milestone summary that quietly
omits a sprint understates the work and the slippage both.

**Blocked stories** — the Blocked table and the blocked story count passed to
PR-MILESTONE — are not in the sprint reports' scanned sections. Read them where
they are recorded: the `status: blocked` stories in `production/sprint-status.yaml`
(with their `blocker` field) and, for stories outside that sprint, one grep:

```
Grep pattern="^> \*\*Status\*\*: Blocked|BLOCKED:" glob="production/epics/**/story-*.md" output_mode="content"
```

Each blocked story goes in the Blocked table under the feature its epic folder
implements, with its blocker (the yaml `blocker` field or the story's `BLOCKED:`
note). With no story files and no `sprint-status.yaml`, the Blocked table and the
blocked story count are `NOT ASSESSED — NO DATA`, not zero.

**Done is genuine.** Count separately the stories closed `Complete` with a DoD
waiver (a `Waiver` / `Waived` line in the story file — one grep) and stories whose
evidence directory `production/qa/evidence/<story-id>/` is missing for a
user-visible or callable change. They are reported next to the completion
percentage and passed to PR-MILESTONE; the work to retire them is part of the
remaining estimate.

---

## Phase 2: Scan Codebase Health

- Scan for `TODO`, `FIXME`, `HACK` markers across the code roots (`resolve_code_root`; **an empty result means the scan did not run** — report it as such, never as zero markers)
- Count open bugs by severity for Quality Metrics from `production/qa/bugs/` (one grep of the `**Severity**` and `**Status**` lines, as `/bug-triage` does); with no bug files, the bug lines are `NOT ASSESSED — NO DATA`, not zero
- Check the risk register at `production/risk-register/` if it exists (hand-authored from `.claude/docs/templates/risk-register-entry.md`; no skill writes it, so absence is normal — note it rather than skipping risk assessment silently)

---

## Phase 2b: Readiness Checks

Read `references/readiness-checks.md` and run the checks it lists for the
milestone's type and the project's stack. Four readiness dimensions feed the
go/no-go:

1. **Open security findings** — latest `/security-audit` report, SL-* verdicts recorded in stories, threat-model residual risks past expiry, dependency and secrets scan results, cross-tenant negative tests.
2. **SLO readiness** — at stage Hardening or later (and not for a self-hosted-only product): `docs/architecture/slos.md`, burn-rate alerts, runbooks, backups and last restore drill, performance vs `docs/architecture/perf-budgets.md`.
3. **Self-hosted upgrade-path readiness** — when `distribution.model` is `self-hosted` or `hybrid`: signed bundle, fresh install, upgrade from every supported prior version, rollback, licence rules (`.claude/rules/deploy.md`).
4. **Store-review readiness** — when `stack.mobile` is set: Play Console / App Store requirements, listing assets, privacy declarations, reviewer access, review lead time against the target date.

Each dimension resolves to `READY`, `GAPS` (list them) or `NOT ASSESSED — [what is missing]`, or `N/A — [stack/stage reason]`. An N/A must name the reason; a dimension that applies but could not be checked is never N/A.

---

## Phase 3: Generate the Milestone Review

```markdown
# Milestone Review: [Milestone Name]

## Overview
- **Target Date**: [Date]
- **Current Date**: [Today]
- **Days Remaining**: [N]
- **Sprints Completed**: [X/Y]
- **Type / Audience**: [from the definition]
- **Stage / Workflow**: [project.stage] / [workflow]

## Feature Completeness

### Fully Complete
Only a feature whose Status is `Complete` goes here or counts toward the completion percentage; a Deferred feature stays in its denominator, named with the milestone it moved to.

| Feature | Acceptance Criteria | Test Status | DoD gates (met / waived) |
|---------|-------------------|-------------|--------------------------|

### Partially Complete
| Feature | % Done | Remaining Work | Risk to Milestone |
|---------|--------|---------------|------------------|

### Blocked
A started feature whose stories are Blocked goes here, not under Partially
Complete — name the blocker, so the review says why it stalled, not only that
the count moved.

| Feature | Blocked Stories | Blocker | Next Action / Owner |
|---------|----------------|---------|---------------------|

### Not Started
| Feature | Priority | Can Cut? | Impact of Cutting |
|---------|----------|----------|------------------|

## Quality Metrics
- **Open S1 Bugs**: [N] -- [List]
- **Open S2 Bugs**: [N]
- **Open S3 Bugs**: [N]
- **Test pass rate / coverage on domain**: [X%] — [source]
- **Performance**: [Within `perf-budgets.md`? p95 actual / budget, evidence path]
- **Stories closed with DoD waivers**: [N] — [list]

## Code Health
- **TODO count**: [N across code roots]
- **FIXME count**: [N]
- **HACK count**: [N]
- **Technical debt items**: [List critical ones]

## Readiness
| Dimension | Status | Evidence / Gaps |
|-----------|--------|-----------------|
| Open security findings | [READY / GAPS / NOT ASSESSED] | [counts by severity; audit report path and date] |
| SLO readiness (Hardening+) | [READY / GAPS / NOT ASSESSED / N/A — reason] | |
| Self-hosted upgrade path | [READY / GAPS / NOT ASSESSED / N/A — reason] | |
| Store-review readiness (mobile) | [READY / GAPS / NOT ASSESSED / N/A — reason] | |

## Risk Assessment
| Risk | Status | Impact if Realized | Mitigation Status |
|------|--------|-------------------|------------------|

## Velocity Analysis
- **Planned vs Completed** (across all sprints): [X/Y tasks = Z%]
- **Trend**: [Improving / Stable / Declining]
- **Adjusted estimate for remaining work**: [Days needed at current velocity, including DoD-waiver clean-up]

## Scope Recommendations
### Protect (Must ship with milestone)
- [Feature and why]

### At Risk (May need to cut or simplify)
- [Feature and risk]

### Cut Candidates (Can defer without compromising milestone)
- [Feature and impact of cutting]

## Go/No-Go Assessment

**Recommendation**: [NOT ASSESSED / GO / CONDITIONAL GO / NO-GO]

**Conditions** (if conditional):
- [Condition 1 that must be met]
- [Condition 2 that must be met]

**Rationale**: [Explanation of the recommendation]

## Action Items
| # | Action | Owner | Deadline |
|---|--------|-------|----------|
```

### Go/No-Go rules

- An **open Critical security finding** → NO-GO. An **open High** → NO-GO unless the user names the person who accepts the residual risk, with an expiry date, in the Conditions (CONDITIONAL GO). The model never accepts security risk on anyone's behalf.
- Any applicable **readiness dimension that is `NOT ASSESSED`** keeps the result from being GO: recommend `NOT ASSESSED`, or CONDITIONAL GO / NO-GO where the review's own findings call for one.
- Any applicable dimension with **GAPS** that is a blocker for the milestone's audience (for example no tested upgrade path for self-hosted early access, or no store-review lead time left for a mobile release) → NO-GO or CONDITIONAL GO with the gap as a dated condition.
- Rank: NO-GO and CONDITIONAL GO outrank NOT ASSESSED, which outranks GO — a known problem is more actionable than an unknown, and an unknown must not read as GO.

---

## Phase 3b: Producer Risk Assessment

**Review mode check** — apply before spawning PR-MILESTONE:
- `solo` → skip. Note: "PR-MILESTONE skipped — Solo mode." Present the Go/No-Go section without a producer verdict.
- `lean` → skip (not a PHASE-GATE). Note: "PR-MILESTONE skipped — Lean mode." Present the Go/No-Go section without a producer verdict.
- `full` → spawn as normal.

Before generating the Go/No-Go recommendation, spawn `producer` via `Agent` using gate **PR-MILESTONE** (`.claude/docs/director-gates/pr-milestone.md`).

Pass: milestone name and target date, current completion percentage (counts or points — say which), blocked story count with blockers, velocity data from sprint reports (if available), list of cut candidates, the count of stories closed with DoD waivers or missing evidence, and the external lead times from Phase 2b (store review, provider approval, security review).

Present the producer's assessment inline within the Go/No-Go section. The producer's verdict (ON TRACK / AT RISK / OFF TRACK) informs the overall recommendation.

If OFF TRACK, use `AskUserQuestion` before generating the recommendation:
- Prompt: "Producer verdict: OFF TRACK. The milestone is in jeopardy. This review will recommend NO-GO. How do you want to proceed?"
- Options:
  - `[A] Accept NO-GO — generate the full review with that recommendation`
  - `[B] Override to CONDITIONAL GO — I'll document the accepted risks myself`
  - `[C] Stop — I want to address blockers before generating the review`

If AT RISK, use `AskUserQuestion`:
- Prompt: "Producer verdict: AT RISK. Milestone may slip. How should the Go/No-Go section be framed?"
- Options:
  - `[A] CONDITIONAL GO — include producer's conditions in the review`
  - `[B] NO-GO — conditions cannot be met in time`
  - `[C] GO — I accept the risk and want to proceed`

[C] GO is offered only when no Go/No-Go rule above caps the recommendation lower; otherwise it is not listed.

If NOT ASSESSED: name the missing input — it is not ON TRACK, and never recommend GO on it. Supply the input and re-run PR-MILESTONE, or recommend NOT ASSESSED — or CONDITIONAL GO / NO-GO where the review's own findings call for one (the rank in `.claude/docs/director-gates.md`).

Do not issue a GO against an OFF TRACK verdict; issue CONDITIONAL GO only if the user explicitly selects [B] above.

---

## Phase 4: Save Review

Present the review to the user.

Glob `production/milestones/[milestone-name]-review.md` first. If it already exists, a
previous review is never overwritten silently: show its date and ask which —
`[A]` write a new dated file `[milestone-name]-review-[date].md` (recommended, keeps the
history) · `[B]` replace the existing file · `[C]` do not write. Then ask: "May I write this
to `production/milestones/[chosen file]`?"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — milestone review saved.
The Go/No-Go recommendation above is separate from this verdict word.

If no, stop here. Verdict: **BLOCKED — write declined by user** (nothing is reported as saved).

---

## Phase 5: Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/milestone-review
<milestone> — <Go/No-Go and verdict>`, Next step = the first next step below that
applies, plus Blocked on / Files in progress / Open questions; append the Notes
line. A No-Go, NOT ASSESSED or a declined write still updates the checkpoint with
the blocker.

- Run `/gate-check` for a formal phase gate verdict if this milestone marks a development phase boundary (Hardening → Release also spawns SL-RELEASE-SECURITY, SRE-OPERABILITY and, at `workflow: full`, SRE-SLO).
- Run `/security-audit`, `/perf-profile`, `/load-test` or `/release-checklist` for any readiness dimension that came back GAPS or NOT ASSESSED.
- Run `/sprint-plan` to adjust the next sprint based on the scope recommendations above (at `workflow: minimal`, which has no sprints, adjust the brief's build order instead).
