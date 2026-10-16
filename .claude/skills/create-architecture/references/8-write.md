# /create-architecture — Phases 8 and 8b: Write and Sign-Off

> Part of `/create-architecture`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 8: Write the Master Architecture Document

**In this file:**

- Phase 8: the master architecture document template, then the write
- Phase 8b: CTO Sign-Off + Principal Engineer Feasibility Review: review mode check, presenting both assessments, recording the sign-off

Once all sections are approved, write the complete document to
`docs/architecture/architecture.md`.

In an update (Phase 0e `[A]`, or a focus-area argument), write only the chosen
sections instead, replacing each in place with `Edit`, and raise `Version`; the
ask below then names those sections and the version change.

Display a one-paragraph summary of what the document will contain (contexts, stores,
tenancy, flows, topology, ADR gaps). Then use `AskUserQuestion`:
- "All sections approved. May I write the master architecture document?"
  - [A] Yes — write to `docs/architecture/architecture.md` now
  - [B] Show me the full draft inline first, then ask again
  - [C] Not yet — I have more changes to discuss

The document structure:

```markdown
# [Product Name] — Master Architecture

## Document Status
- Version: [N]
- Last Updated: [date]
- Stack: [layers and pinned versions — from pins.yaml]
- Tenancy model / Deploy target / Distribution model: [from project.yaml]
- Shared core: [track, version, modules] or "not used"
- Specs Covered: [list]
- ADRs Referenced: [list]
- Not run: [any phase, lookup or gate that did not run, by name — or "none"]

## Stack-Risk Summary
[Condensed from Phase 0d inventory — HIGH/MEDIUM risk layers, NOT SOURCEABLE layers and their implications]

## Bounded Contexts and Layers
[From Phase 1 — layer map, context cards, ports, shared-core modules, dependency diagram]

## Ownership, Data Stores and Tenancy
[From Phase 2 — store per context, tenancy model and enforcement, ownership map]

## Data Flow, Messaging, Caching and Observability
[From Phase 3 — flows, messaging, cache tiers, observability pipeline, budget location]

## API Style and Contract Boundaries
[From Phase 4 — style ADR pointer, boundary table, contracts/ files, lifecycle]

## Deployment Topology
### Hosted
### Self-Hosted (or "not in scope — distribution.model: hosted")
### Self-Hosted Upgrade Path
[From Phase 5]

## ADR Audit
[From Phase 6]

## Required ADRs
[From Phase 7 — critical ones marked]

## Threat-Model Candidates
[Sensitive features needing /threat-model — each with the spec and context]

## Architecture Principles
[3-5 key principles that govern all technical decisions for this product,
derived from the product brief, specs, clean-architecture rules and the stack]

## Open Questions
[Decisions deferred — each with an owner, and the layer that must resolve it before it is built]
```

---

## Phase 8b: CTO Sign-Off + Principal Engineer Feasibility Review

After writing the master architecture document, perform an explicit sign-off before handoff.

**Review mode check** — apply before spawning either gate:
- `solo` → skip both. Note: "CTO-ARCHITECTURE and PE-FEASIBILITY skipped — Solo mode." Go to Step 4 and record both as skipped, then Phase 9.
- `lean` → skip both (neither is a PHASE-GATE). Note: "CTO-ARCHITECTURE and PE-FEASIBILITY skipped — Lean mode." Go to Step 4 and record both as skipped, then Phase 9.
- `full` → spawn both, in parallel.

**Step 1 — Spawn `cto` via `Agent` using gate CTO-ARCHITECTURE (`.claude/docs/director-gates/cto-architecture.md`):**

Pass: the architecture document path (`docs/architecture/architecture.md`), the Technical Requirements Baseline (TR-IDs and count), the ADR list with statuses, the Stack-Risk Inventory from Phase 0d, and the `project.yaml` facts (`stack.*`, `tenancy.model`, `deploy.target`, `distribution.model`). Issue this call and Step 2's before waiting for either result.

**Step 2 — Spawn `principal-engineer` via `Agent` using gate PE-FEASIBILITY (`.claude/docs/director-gates/pe-feasibility.md`):**

Pass: architecture document path, technical requirements baseline summary, ADR list, the stack-reference paths for the layers used, and the budgets file path (`docs/architecture/perf-budgets.md`, or "not yet written").

**Step 3 — Present both assessments to the user:**

Show the CTO-ARCHITECTURE verdict (APPROVE / CONCERNS / REJECT) and the PE-FEASIBILITY verdict (FEASIBLE / CONCERNS / INFEASIBLE) side by side.

Use `AskUserQuestion` — "The CTO and Principal Engineer have reviewed the architecture. How would you like to proceed?"
Options: `Accept — proceed to handoff` / `Revise flagged items first` / `Discuss specific concerns`.
If either verdict is REJECT or INFEASIBLE, do not offer `Accept` — the blockers are revised (or discussed) first.
`Revise flagged items first` re-drafts each flagged section and shows it for approval as in Phases 1–5; the revised document is then written once, through Phase 8's ask, and Step 4 records `REVISED after [verdict]`.
A `NOT ASSESSED` answer is never recorded as `APPROVE` or `FEASIBLE`: Step 4 records it with the input that was missing (`director-gates.md`).

**Step 4 — Record sign-off in the architecture document:**

Update the Document Status section:
```
- CTO-ARCHITECTURE: [date] — APPROVE / CONCERNS (accepted) / REVISED after CONCERNS / REVISED after REJECT / NOT ASSESSED — [missing input] / skipped — [mode] mode
- PE-FEASIBILITY: [date] — FEASIBLE / CONCERNS (accepted) / REVISED after CONCERNS / REVISED after INFEASIBLE / NOT ASSESSED — [missing input] / skipped — [mode] mode
```

Show the proposed Document Status block inline, then use `AskUserQuestion`:
- "May I update the Document Status section with the sign-off results?"
  - [A] Yes — apply to `docs/architecture/architecture.md`
  - [B] Not yet — I want to revisit the concerns first

---
