---
name: create-architecture
description: "Author the architecture blueprint before code is written: bounded contexts and ports, data store per context, tenancy, API and contracts, messaging, caching, observability, hosted and self-hosted topology, validated against the pinned stack."
argument-hint: "[focus-area: full | contexts | data-tenancy | data-flow | api-boundaries | deployment | adr-audit] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/create-architecture/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,project.stage,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Create Architecture

This skill produces `docs/architecture/architecture.md` — the master architecture
document that translates the approved feature specs and the domain map into a
concrete technical blueprint. It sits between Product Design and
implementation, and must exist before sprint planning begins at `standard` and
`full`.

**Distinct from `/architecture-decision`**: ADRs record individual point
decisions. This skill creates the whole-system blueprint that gives ADRs their
context. **Distinct from `/map-domains`**: the domain map says *what* the
bounded contexts are; this skill says *how* they are built, stored, connected
and deployed.

See `.claude/docs/director-gates.md` for the full check pattern. Individual gate definitions live in `.claude/docs/director-gates/[gate-id].md` — the spawned agent reads its own gate file; do not read it in the parent session.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**`docs.density`** — it controls per-section *depth*, where `workflow`
controls which sections exist. `modes.rigor` sets both together; set
`docs.density` explicitly to vary depth alone: `terse` (the default, via `rigor: minimal`) = diagrams + decision bullets,
no essays; `balanced` = diagrams + paragraph explanations of context and
store choices (`rigor: standard`); `thorough` = full prose with rationale,
trade-offs, and alternatives considered per decision. Apply it to every section you author.

**`workflow`** (see `.claude/docs/workflow-modes.md`):
- `full` — full architecture: every section below plus a full ADR audit.
- `standard` — context map, data store and tenancy, deployment topology and the
  critical ADR list; the remaining sections are one paragraph each.
- `minimal` — not required (the product brief's decision log carries the
  rationale). Can still be run voluntarily.

**Argument modes:**
- **No argument / `full`**: Full guided walkthrough — all sections, start to finish
- **`contexts`**: Bounded contexts, layers and ports only
- **`data-tenancy`**: Data store per context and the tenancy model only
- **`data-flow`**: Sync/async flows, messaging, caching tiers, observability pipeline only
- **`api-boundaries`**: API style and `contracts/` boundaries only
- **`deployment`**: Hosted and self-hosted topology and the self-hosted upgrade path only
- **`adr-audit`**: Audit existing ADRs for stack compatibility and licence gaps only

---

## Phase 0: Load All Context

**Read `references/0-load-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 1: Bounded Contexts, Layers and Ports

**Read `references/1-contexts.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 2: Ownership, Data Stores and Tenancy

**Read `references/2-ownership-data-tenancy.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 3: Data Flow, Messaging, Caching and Observability

**Read `references/3-data-flow.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 4: API Style and Contract Boundaries

**Read `references/4-api-boundaries.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 5: Deployment Topology (Hosted and Self-Hosted)

**Read `references/5-deployment.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 6: ADR Audit + Traceability Check

**Read `references/6-adr-audit.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 7: Missing ADR List

**Read `references/7-missing-adrs.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 8: Write the Master Architecture Document

**Read `references/8-write.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Phase 9: Handoff

**Read `references/9-handoff.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Not-Run Reporting

A phase, check or reference lookup that did not run is reported as **not run**,
by name, in the architecture document's Document Status block and in the
handoff — never as clean. This includes: a stack-reference layer that could not
be read (`NOT SOURCEABLE — <what> is not covered by <path>`), a spec that
contributed no requirements, a gate skipped by review mode, and a focus-area run
that left other sections as they were. A silent skip and a successful run must
not look alike.

## Collaborative Protocol

**Applies in `collaborative` mode (the default).** For `guided` and
`autonomous` modes, see `.claude/docs/automation-modes.md` — the rules below
describe what collaborative mode requires, not universal behavior.

This skill follows the collaborative design principle at every phase:

1. **Load context silently** — do not narrate file reads
2. **Present findings** — show the stack-risk inventory and context proposals
3. **Ask before deciding** — present options for each architectural choice
4. **Draft before approval** — show the content inline before asking to write it.
   Never ask approval for a section the user has not yet seen.
5. **Use `AskUserQuestion` for write approvals** — plain text "May I?" is not
   sufficient. Use the structured tool with labeled options [A]/[B]/[C] (write now /
   show full draft first / not yet). For multi-file changesets, list every file
   and what changes, then ask once grouped — not separate plain-text asks per file.
6. **One write, after every section is approved** — the document is written once,
   at Phase 8; Phase 8b's Step 4 only updates its Document Status, after its own
   ask. Record each approved section's decisions in
   `production/session-state/active.md` as you go, so a crash loses no decision.
   A revision that Phase 8b forces is written the same way — once, after its
   re-drafted sections are approved — and an update (Phase 0e) writes only the
   sections it chose.

Never make a binding architectural decision without user input. If the user is
unsure, present 2-4 options with cost, risk, performance and operability notes
before asking them to decide. Foundation decisions (tenancy model, identity,
data store, messaging, API style, deployment topology, licensing) are the
user's, ratified by `cto` — never silently defaulted.

---

## Recommended Next Steps

- Run `/architecture-decision [title]` for each required ADR listed in Phase 7 — Foundation layer ADRs first
- Run `/architecture-review` — bootstraps the traceability index and TR registry from the ADRs just written. Required before the Pre-Production gate.
- Run `/threat-model <feature>` for each sensitive feature the architecture flags (auth, billing, licensing, upload, webhooks, PII, admin, new integration)
- Run `/test-setup` to scaffold the per-layer test frameworks and CI (required for gate-check)
- Run `/create-control-manifest` once the required ADRs are Accepted to produce the layer rules manifest
- Run `/gate-check pre-production` when all required ADRs, `/test-setup` and the review are complete
