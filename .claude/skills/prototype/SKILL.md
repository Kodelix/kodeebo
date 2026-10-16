---
name: prototype
description: "Throwaway spike in prototypes/<name>/ to answer one question — click-through mock, code spike, concierge or paper. PROCEED/PIVOT/KILL/NOT ASSESSED. Never becomes production code."
argument-hint: "[concept-or-question] [--path mock|spike|concierge|paper] [--review full|lean|solo] [--spike]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(date *), Bash(bash "*/.claude/skills/prototype/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,stack`

Resolved above — use as-is; `--review` overrides `review_mode` for this run. No
block → defaults in `.claude/docs/config-resolution.md`.

# Prototype

## Purpose

This is the **concept prototype** — a fast, throwaway build that answers one
question: *"Does this product idea hold up where it is riskiest?"* The risk may be
desirability ("will the ICP use this?"), willingness to pay, feasibility ("can we
do X within the budget?"), integration viability ("does the provider's API do what
we need?") or performance at scale.

**Default use** — run after `/brainstorm` and `/setup-stack`, before writing specs
or architecture. Its verdict determines whether the concept is worth the
investment of full design documentation.

**Mid-build?** Run it at any stage to test a specific design or technical
question. Pass `--spike` for spike mode: a lightweight ~4-hour build with no spec
prerequisites and no phase-gate implications.

**Already have specs and architecture complete?** To prove the architecture
end to end (DB → API → web/mobile → deploy), run `/vertical-slice` instead.

**Prototype code is throwaway by rule** (`.claude/rules/prototype-code.md`): it
lives only in `prototypes/<name>/`, is never imported by production code, never
imports production code, never modifies files outside `prototypes/`, is never
deployed, and is rewritten from scratch if the idea proceeds. Security still
applies — no real secrets, no real customer data, nothing exposed on a public
port.

> **A prototype that nobody has used has no verdict.** The recommendation vocabulary
> is `PROCEED` / `PIVOT` / `KILL` / `NOT ASSESSED`. `NOT ASSESSED` — built, not used
> by anyone — outranks `PROCEED` (nothing was proven) and is the only honest answer
> without observations. It is never inferred from how the build looks
> (`.claude/rules/skill-authoring.md`).

---

## Phase 1: Define the Question

**Read `references/1-question.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Load Concept Context

**Read `references/2-load-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Choose the Prototype Path

**Read `references/3-choose-path.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: Plan the Prototype

**Read `references/4-plan.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Implement

**Read `references/5-implement.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: Usage Debrief

**Read `references/6-debrief.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Generate Prototype Report

**Read `references/7-report.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 8: Product Director Review

**Read `references/8-pd-review.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 9: Summary and Next Steps

**Read `references/9-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Spike Mode

**Triggered by:** `--spike` flag OR "Mid-build spike" entry choice in Phase 1.

**Read `references/spike-mode.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

### Important Constraints

- Prototype code must NEVER import from production source files
- Production code must NEVER import from prototype directories
- If the recommendation is PROCEED, production implementation is written from scratch — prototype code is never refactored into a code root
- Prototypes never touch files outside `prototypes/<name>/` (the checkpoint in `production/session-state/active.md` and the index row in `prototypes/index.md` are the two named exceptions this skill writes after an ask)
- No real secrets, no real customer data, no real provider live keys; provider sandboxes only; bind local servers to `127.0.0.1`, never a public interface; nothing deployed
- Total effort is hard-capped at 1 day (a concept prototype tests one question). **One exception:** a spike that a research note plans for a product's top-ranked risk (a `PENDING — S<n>` plan with phases) may run longer only with the user's written waiver recorded in the README — the risk it tests, the planned length, a pass/fail gate per phase and "stop at the first failed gate". No waiver, no exception; the 2-hour reframe rule still applies inside each phase
- Test ONE question — if scope grows, stop and simplify
- No polish. No auth, no billing, no tenancy, no settings screens, no marketing copy — unless that IS the thing being tested
- If stuck after 2 hours, reframe the question or switch paths
- **3 PIVOT iterations → force a KILL decision.** If this is the third time the same concept has produced a PIVOT verdict, the concept likely doesn't work: put KILL on the table and decide it with the soundness checklist in `references/9-summary.md` (2+ boxes → KILL stands; 0–1 boxes → one more focused PIVOT is allowed only with a changed hypothesis written in `PIVOT-NOTE.md`, never a silent fourth). The user decides. Ask: "Is this the right idea, or am I in the sunk cost trap?" A fresh concept almost always beats a fourth iteration of a struggling one.
- Building 2–3 different concept variants and picking the best one is a healthier strategy than iterating one concept to death
- **Shortcuts must be visible.** A prototype that skips tenancy, auth, idempotency or error handling says so in its README and in the report's "Shortcuts taken" list — a PROCEED never inherits those shortcuts silently, and the report lists **security and tenancy surprises** the prototype revealed so the threat model starts from them
- **Performance conclusions need their conditions.** A latency or throughput number from a spike is reported with the data volume, hardware and warm/cold state it was measured under; a number from an unrepresentative setup is `indicative only` and cannot support PROCEED on a feasibility question by itself
