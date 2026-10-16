---
name: review-all-specs
description: "Holistic cross-spec review — contradictions between features, permissions vs plans, data ownership and tenancy assumptions, conflicting quotas, capabilities duplicated across features that belong in saas-core."
argument-hint: "[focus: full | consistency | product-theory | since-last-review]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Skill, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/scripts/review-scope.sh), Bash(bash .claude/scripts/review-scope.sh *), Bash(bash .claude/scripts/spec-structure-check.sh), Bash(bash .claude/scripts/spec-structure-check.sh *), AskUserQuestion, Agent, Bash(bash "*/.claude/skills/review-all-specs/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,system_overrides,stack`

# Review All Specs

This skill reads every feature spec simultaneously and performs two complementary
reviews that cannot be done per-spec in isolation:

1. **Cross-Spec Consistency** — contradictions, stale references, and ownership
   conflicts between documents
2. **Product Holism** — issues that only emerge when you see all features
   together: permissions that disagree with plans, quotas that collide, data
   owned twice, tenancy assumptions that differ, capabilities specified twice
   that belong in `saas-core`, onboarding overload, principle drift

**This is distinct from `/spec-review`**, which reviews one spec for internal
completeness. This skill reviews the *relationships* between all specs.

**When to run:**
- After all MVP-tier specs are individually approved
- After any spec is significantly revised mid-production
- Before `/create-architecture` begins (architecture built on inconsistent specs
  inherits those inconsistencies)

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Argument modes:**

**Focus:** `$ARGUMENTS` (blank = `full`)

- **No argument / `full`**: Both consistency and product-theory passes
- **`consistency`**: Cross-spec consistency checks only (faster)
- **`product-theory`**: Product holism checks only
- **`since-last-review`**: Only specs modified since the last review report
  (computed by `.claude/scripts/review-scope.sh`)

---

**`workflow`** per spec (per `.claude/docs/workflow-modes.md`): each spec validates
against its effective tier — the project value, overridden per feature by the
`system_overrides` row for that feature (the spec filename stem) when the block
lists one. At `full`, validate all 8 sections across all specs. At `standard`,
validate the 5 required sections plus Edge Cases & Failure Modes where its
conditional applies; optional sections (User Value, Dependencies, conditional
Formulas) are surfaced as advisory only. At `minimal`, this skill is not
applicable (no specs). A required section missing from a spec is reported with
the structure-check line that showed it (Phase 1c), never inferred.

## Phase 1: Load Everything

**Read `references/1-load.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

### Parallel Execution

Phase 2 (Consistency) and Phase 3 (Product Holism) are independent — they read
the same spec inputs but produce separate reports. Spawn them as parallel `Agent`
agents simultaneously rather than waiting for Phase 2 to complete before
starting Phase 3. Collect all results before writing the combined report.

Spawn the Phase 2 agent as `domain-architect` (`subagent_type: domain-architect`) —
consistency, ownership and tenancy review is its domain. Spawn the Phase 3 agent
as `product-manager`, and the Phase 3 plan/permission/quota checks (3a, 3c, 3g)
as a third parallel agent, `pricing-billing-designer`. When Phase 3 finds a
capability that may belong in core, ask `principal-engineer` (read-only
question) whether a `saas-core` module already covers it before it is reported.

**When spawning the Phase 2 and Phase 3 agents, always pass:**
- The loaded spec **content** each phase needs — **not file paths**. Paste the
  sections; the sub-agent has its own context and cannot re-read Phase 1's
  results, so a path forces a full re-read (and contradicts the "do not re-read"
  rule below). Pass only the phase's slice: Phase 2 (consistency) needs each spec's
  Dependencies, Detailed Behaviour (incl. Permissions per Role), Data & Contracts,
  Non-Functional Requirements (Configuration, abuse limits), Acceptance Criteria
  and Cross-References; Phase 3 (product theory) needs User Value, the plan/pricing
  impact, Permissions per Role and the product principles.
- The full entity registry contents (`design/registry/entities.yaml`) if loaded in Phase 1b (paste the registry text, not just a file path)
- The pricing model contents (`design/specs/pricing-model.md` — the canonical path, written by `/team-billing`; else `Glob design/**/pricing-model*.md`, or whatever the brief links) if present
- The specific checklist items assigned to that agent's phase (Phase 2 gets 2a–2g; Phase 3 gets 3a–3g)
- The resolved stack profile, `tenancy.model` and `distribution.model` from `project.yaml` (or "not configured" — say so; never let the agent assume a tenancy model)

Do not rely on the subagent to re-read these files — it has its own context window and cannot access Phase 1 results unless they are explicitly passed in the `Agent` prompt.

---

## Phase 2: Cross-Spec Consistency

**Read `references/2-consistency.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Product Holism

**Read `references/3-product-holism.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Cross-Feature Scenario Walkthrough

**Read `references/4-scenarios.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Output the Review Report

**Read `references/5-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Write Report and Flag Specs

**Read `references/6-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Handoff

**Read `references/7-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Error Recovery Protocol

**First, verify the artifact.** If the return contract named a path, check the
path exists before treating the phase as done — **a named artifact that is not
on disk is a failed phase, however fluent the response reads.** An agent can
burn a full phase and return a plausible preamble having written nothing, which
is neither BLOCKED nor an error nor "fails to complete", so the trigger below
never fires. Resume it naming the unmet contract; the context is
usually still there.

If any spawned agent returns BLOCKED, errors, or fails to complete: **surface it
immediately, don't proceed past a dependency it blocks, and always produce a
partial report** (retry scope here = fewer specs / single-feature). Full procedure:
`.claude/docs/error-recovery-protocol.md`.

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous` modes,
see `.claude/docs/automation-modes.md`. In `autonomous` mode the
PASS/NOT ASSESSED/CONCERNS/FAIL verdict is still printed and logged — only the closing
handoff widget is skipped.

1. **Read silently** — load all specs before presenting anything
2. **Show everything** — present the full consistency and product-theory analysis
   before asking for any action
3. **Distinguish blocking from advisory** — not every issue needs to block
   architecture; be clear about which do
4. **Don't make product decisions** — flag contradictions and options, but never
   unilaterally decide which spec is "right"
5. **Ask before writing** — confirm before writing the report or updating the
   domain map
6. **Be specific** — every issue must cite the exact spec, section, and text
   involved; no vague warnings
7. **A check that did not run is reported as not run** — a phase that returned
   nothing, a spec that could not be read, a missing registry, pricing model or
   tenancy setting are each named in the report; none is counted as clean
