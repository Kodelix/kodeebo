> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CTO-PHASE-GATE — Technical Readiness at Phase Transition

Agent: `cto` | Model tier: Opus | Domain: Architecture, stack risk, performance

**Trigger**: At `/gate-check` when `modes.workflow` is `standard` or `full` — the panel narrows by workflow; spawn in parallel with the rest of it (PR-PHASE-GATE, plus PD-PHASE-GATE and DD-PHASE-GATE at `full`)

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- Architecture document path (if exists)
- Stack reference path (`docs/stack-reference/`) and `pins.yaml`
- ADR list with statuses

**Checks**:
1. Every artifact the gate requires at this tier exists and is non-empty (cite path). A required artifact passed as "none" is a finding; one passed as "not expected before [phase]" or "not required at `workflow: [tier]`" is not.
2. The technical groundwork this phase requires is in place and sound, judged only against the phase being entered:
   - entering Product Design — the concept is feasible on the candidate stack and distribution model (CTO-FEASIBILITY recorded or equivalent);
   - entering Architecture — the domain map and specs give enough to architect from (bounded contexts, data ownership, NFRs);
   - entering Pre-Production — the architecture is sound and the Foundation-layer decisions (tenancy, identity, data stores, API style, deployment topology, licensing) are Accepted;
   - entering Production or later — the architecture is holding up in the build (vertical slice running, contracts in `contracts/`, CI green);
   - entering Hardening or Release — no open architectural deviation, migrations proven forward, performance budgets measured.
3. High-risk stack domains are addressed to the depth this phase requires; pinned versions are consistent between `pins.yaml` and the code roots.
4. Performance budgets are realistic and documented where this phase requires them (`docs/architecture/perf-budgets.md`).
5. The `tenancy.model` and `distribution.model` in `project.yaml` agree with the architecture document and the deploy files.

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a
> technical direction perspective, judged against what this gate requires at this
> tier (the required-artifacts list you were given), not what a later phase will
> need. Is the technical groundwork this phase requires in place and sound —
> entering Product Design, is the concept feasible on the candidate stack;
> entering Architecture, do the domain map and specs give enough to architect
> from; entering Pre-Production, is the architecture sound and are the
> Foundation-layer decisions complete enough to begin implementation; entering
> Production or later, is the architecture holding up in the build? Are the
> high-risk stack domains addressed to the depth this phase requires? Are
> performance budgets realistic and documented where this phase requires them?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [list], or NOT READY [blockers]."

**Verdicts**: READY / CONCERNS / NOT READY

**NOT ASSESSED when**: the required-artifacts list or resolved tier was not
passed, or an artifact listed as present cannot be read.

**Output**: the standard block, with Check 2 answered for the target phase only.
