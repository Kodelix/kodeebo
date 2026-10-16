---
name: gate-check
description: "Ready to advance between product stages? PASS/CONCERNS/NOT ASSESSED/FAIL with blockers and required artifacts. 'Can we move to architecture?' 'Are we ready to release?'"
argument-hint: "[target-phase: product-design | architecture | pre-production | production | hardening | release | live] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/gate-check/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/artifact-check.sh *), Bash(bash .claude/scripts/artifact-check.sh), Bash(bash .claude/scripts/spec-structure-check.sh *), Bash(bash .claude/scripts/adr-dep-graph.sh), Bash(bash .claude/scripts/adr-dep-graph.sh *), Bash(bash .claude/scripts/project-coherence.sh *), Bash(bash .claude/scripts/project-coherence.sh), Bash(bash .claude/scripts/story-status.sh *), Bash(bash .claude/scripts/story-status.sh), Bash(bash .claude/scripts/migration-lint.sh *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(git status *), Bash(git log *), Bash(git diff *), Bash(stat *), Bash(go vet *), Bash(go test *), Bash(golangci-lint run *), Bash(govulncheck *), Bash(osv-scanner scan *), Bash(./gradlew *), Bash(pnpm lint), Bash(pnpm typecheck), Bash(pnpm test *), Bash(pnpm build), Bash(pnpm audit *), Bash(swift test *), Bash(xcodebuild test *), Bash(gitleaks git *), Bash(gitleaks dir *), Bash(bash .claude/scripts/migration-lint.sh)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,workflow,qa.level,testing.strict,performance.enforce,team.size,project.stage,system_overrides,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Phase Gate Validation

This skill validates whether the product is ready to advance to the next
stage. It checks for required artifacts, quality standards, the Definition of
Done evidence the stage depends on, and blockers.

**Distinct from `/project-stage-detect`**: That skill is diagnostic ("where are we?").
This skill is prescriptive ("are we ready to advance?" with a formal verdict).

**The verdict is advisory.** It recommends; the user decides. The only thing it
binds is whether *this skill* writes the new stage (Section 6).

## Product Stages (8)

The product progresses through these stages (the `project.stage` values):

1. **Discovery** — product brief, principles, ICP, pricing and edition model
2. **Product Design** — domain map, feature specs, cross-spec review
3. **Architecture** — architecture doc, ADRs, threat models, stack pinned
4. **Pre-Production** — vertical slice, epics, stories, control manifest, first sprint
5. **Production** — feature development (epics, stories, sprints; eight DoD gates per story)
6. **Hardening** — QA sign-off, security audit, load tests, accessibility, localization
7. **Release** — release checklist, deploy, store submissions, self-hosted bundle
8. **Live** — operating in production: SLOs, incidents, growth

A gate sits between each adjacent pair, so there are **seven gates**; the
argument names the stage being **entered**.

**When a gate passes** (or the user explicitly accepts a CONCERNS verdict's risks — Section 6), update the stage in `project.yaml` (set `project.stage: <new-stage>`). Never create `production/stage.txt`; if it already exists (a project created before 2026-10-13), update it in the same approved write (single line, e.g. `Production`) so the two never disagree. This updates the status line immediately.

---

## 1. Parse Arguments

**Target phase:** `$ARGUMENTS` with any `--review <mode>` pair removed (blank = auto-detect current stage, then validate next transition). `/gate-check --review full` names no phase.

Note: in `solo` mode, director spawns (PD-PHASE-GATE, CTO-PHASE-GATE, PR-PHASE-GATE, DD-PHASE-GATE, and the release-readiness gates SL-RELEASE-SECURITY, SRE-OPERABILITY, SRE-SLO) are skipped — gate-check becomes artifact-existence and evidence checks only. **Solo skips the director's opinion, never the evidence:** every artifact and mechanical check a gate file lists still runs. In `lean` mode, the phase-gate directors still run (phase gates are the purpose of lean mode); how many of them run is set by `workflow` below.

**`workflow`** (per `.claude/docs/workflow-modes.md`):

`gate-check` runs project-wide, so it uses the project-level `workflow` for the
gate's overall artifact checklist (the loaded gate file), AND consults
`workflow_overrides.system_overrides.<feature>` per feature when validating
feature specs — a feature pinned to a higher tier must meet that tier's
section count before the gate passes, regardless of the project-level
workflow (see Section 2b, "Per-feature overrides"). `<feature>` is the spec
filename stem (`design/specs/team-invitations.md` → `team-invitations`).

> **gate-check honors `workflow` but is exempt from `automation`.** The artifact
> checklist changes per tier; the collaborative prompting protocol (the
> Collaborative Protocol section) always applies — a phase gate is a deliberate
> human checkpoint, never auto-run (`.claude/docs/automation-modes.md`).

**`qa.level`**: controls how much *extra* test evidence phase gates ask for,
where `workflow` controls which artifacts are required. `modes.rigor` sets both
together; set `qa.level` explicitly to vary the extra evidence alone. **At every
`qa.level`, Logic, Integration, Contract and Security tests must exist and pass**
(`.claude/docs/coding-standards.md` gate 3) — `qa.level` never waives them, and
the Section 3 `testing.strict` check runs at every level. Above `minimal` the gate
asks for more: `standard` adds the coverage signal and manual cases; `full` adds a
full coverage check + regression suite. The smoke check, security evidence and
run-and-observe evidence are floors too (Section 2b). Retained screenshots for UI
stories and the `/impeccable audit` result are never relaxed by any `qa.level`.

**`team.size`**: does not change how many directors spawn at a phase gate — panel
width is `workflow`'s axis (Section 4b). It affects only the **specialist depth
within each director's review**: `individual` uses the core set, `small` the
standard set, `studio` adds the stack sub-specialists. It never skips a
director — skipping directors is `review_mode`'s job.

**`stack`** (from the resolved block): names `backend`, `web`, `site`, `mobile`,
`data`, `deploy`, `distribution` and `tenancy`. Gates use `distribution` and
`tenancy` directly. **A value that is empty or `unset` is never defaulted to the
permissive reading**: a check that depends on it is NOT ASSESSED, naming
`/setup-stack` as the fix.

- **With argument**: `/gate-check production` — validate readiness for that specific stage
- **No argument**: Auto-detect the current stage from `project.stage` (the
  resolved block), falling back to the heuristics of `/project-stage-detect`
  when it is unset, then **confirm with the user before running**:

  Use `AskUserQuestion`:
  - Prompt: "Detected stage: **[current stage]**. Running gate for [Current] → [Next] transition. Is this correct?"
  - Options:
    - `[A] Yes — run this gate`
    - `[B] No — pick a different gate` (if selected, show a second widget listing all gate options: Discovery → Product Design, Product Design → Architecture, Architecture → Pre-Production, Pre-Production → Production, Production → Hardening, Hardening → Release, Release → Live)

  Do not skip this confirmation step when no argument is provided.
  **At `Live` there is no next gate** — say so, and offer `/project-stage-detect`
  (diagnostic) or `/milestone-review` instead.

---

## 2. Phase Gate Definitions

Each gate's checklist — required artifacts, quality checks, director gates, and
its workflow-tier reductions — lives in its own file. **Read only the row for
the target phase transition; never load the others.**

| Gate | Definition file |
|------|-----------------|
| Discovery → Product Design | `references/gate-product-design.md` |
| Product Design → Architecture | `references/gate-architecture.md` |
| Architecture → Pre-Production | `references/gate-pre-production.md` |
| Pre-Production → Production | `references/gate-production.md` |
| Production → Hardening | `references/gate-hardening.md` |
| Hardening → Release | `references/gate-release.md` |
| Release → Live | `references/gate-live.md` |

Each file states the `full` baseline first, then the `standard` and `minimal`
reductions for that gate. Apply the tier resolved in Section 1.

## 2b. Workflow Tier Adjustment

**Read `references/2b-workflow-tier.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 3. Run the Gate Check

**Read `references/3-run-gate-check.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. Collaborative Assessment

**Read `references/4-assessment.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5. Output the Verdict

**Read `references/5-verdict.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 6. Update Stage on PASS

**Read `references/6-update-stage.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 7. Closing Next-Step Widget

**Read `references/7-next-steps.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Scan first**: Check all artifacts and quality gates
2. **Ask about unknowns**: Don't assume PASS for things you can't verify
3. **Present findings**: Show the full checklist with status
4. **User decides**: The verdict is a recommendation — the user makes the final call on
   what to do next; only the stage write is bound to it (Section 6)
5. **Get approval**: "May I write this gate check report to production/gate-checks/?"
6. **Never auto-fix**: If required artifacts are missing, report the FAIL verdict and
   name the skill to run (e.g. "run `/test-setup`"). Do NOT create missing files or
   re-run the gate automatically. Creating files to manufacture a PASS defeats the
   gate's purpose.
7. **A check that did not run is reported as not run.** A scan, test run, script
   or director that could not run appears in the report by name with the reason —
   never as a silent pass and never as zero findings.

**Never** block a user from working — the verdict decides only whether the stage is
written by this skill. On CONCERNS the user may advance by explicitly accepting the
listed risks, which the report records (Section 6); on FAIL or NOT ASSESSED the
stage stays where it is until a re-run passes, and nothing stops the user working
on the blockers meanwhile.
