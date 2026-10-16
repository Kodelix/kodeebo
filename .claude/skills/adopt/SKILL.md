---
name: adopt
description: "Brownfield audit — do existing artifacts actually work? Numbered migration plan. Unlike /project-stage-detect, checks compliance not existence."
argument-hint: "[focus: full | specs | adrs | stories | infra]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Skill, AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/scripts/spec-structure-check.sh), Bash(bash .claude/scripts/spec-structure-check.sh *), Bash(date *), Bash(bash "*/.claude/skills/adopt/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,automation_always_ask,workflow,stack`

Resolved above — use as-is. `/adopt` also inspects `project.yaml` and the legacy
config files directly when reporting and writing migration state; that raw
inspection is deliberate and separate from the resolved values above.

# Adopt — Brownfield Studio Adoption

This skill audits an existing product repository's artifacts for **format
compliance** with the studio's skill pipeline, then produces a prioritised
migration plan.

**This is not `/project-stage-detect`.**
`/project-stage-detect` answers: *what exists?*
`/adopt` answers: *will what exists actually work with the studio's skills?*

A project can have specs, ADRs, and stories — and every format-sensitive skill
will still fail silently or produce wrong results if those artifacts are in the
wrong internal format. And a project can have a large, working codebase and no
studio artifacts at all; for that case the plan is mostly *creating* the missing
artifacts around the code, without rewriting the code.

**Output:** `docs/adoption-plan-[date].md` — a persistent, checkable migration plan.

**Argument modes:**

**Audit mode:** `$ARGUMENTS` (blank = `full`)

- **No argument / `full`**: Complete audit — all artifact types
- **`specs`**: Feature-spec format compliance only
- **`adrs`**: ADR format compliance only
- **`stories`**: Story format compliance only
- **`infra`**: Infrastructure artifact gaps only (stack config and reference, TR registry, control manifest, sprint-status, stage, perf budgets)

---

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`workflow`** (per `.claude/docs/workflow-modes.md`). It scopes the Phase 2 audit and
Phase 3 severity: `full` audits all doc types at full structure; `standard` audits
only the required docs/sections (optional sections are informational, not gaps);
`minimal` is a `design/product-brief.md` format check — specs/ADRs/UX are not expected. See Phase 2.
The tier scales documents only: the eight Definition of Done gates
(`.claude/docs/coding-standards.md`) are not audited away at `minimal`.

## Phase 1: Detect Project State

**Read `references/1-detect.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Format Audit

**Read `references/2-format-audit.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Classify and Prioritise Gaps

**Read `references/3-classify.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Build the Migration Plan

**Read `references/4-migration-plan.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Present Summary and Ask to Write

**Read `references/5-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Write the Adoption Plan

**Read `references/6-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Offer First Action

**Read `references/7-first-action.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

1. **Read silently** — complete the full audit before presenting anything
2. **Show the summary first** — let the user see scope before asking to write
3. **Ask before writing** — always confirm before creating the adoption plan file
4. **Offer, don't force** — the plan is advisory; the user decides what to fix and when
5. **One action at a time** — after handing off the plan, offer one specific next step,
   not a list of six things to do simultaneously
6. **Never regenerate existing artifacts** — only fill gaps in what exists;
   do not rewrite specs, ADRs, stories or code that already have content
7. **A check that did not run is reported as not run** — a missing script, an
   unresolved code root or an unreadable file is `NOT ASSESSED` in the summary,
   never counted as "compliant" or as zero gaps
