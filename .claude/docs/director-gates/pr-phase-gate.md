> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PR-PHASE-GATE — Production Readiness at Phase Transition

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

**Trigger**: At every `/gate-check` director panel — producer is on the panel at every `modes.workflow`; spawn in parallel with the rest of it (alone at `minimal`, with CTO-PHASE-GATE at `standard`, with CTO-PHASE-GATE, PD-PHASE-GATE and DD-PHASE-GATE at `full`)

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- Sprint and milestone artifacts present — at `minimal`, the build-order field in `design/product-brief.md` is the plan (that tier has no sprint plan)
- Team size (`team.size`) and sprint capacity (from the current sprint plan, if one exists)
- Current blocked story count

**Checks**:
1. Every artifact the gate requires at this tier exists (cite path). A required artifact passed as "none" is a finding; one passed as "not expected before [phase]" or "not required at `workflow: [tier]`" is not.
2. The scope is realistic for the stated timeline and team size: cite scope size, capacity and date.
3. The work of the target phase is planned to the depth this gate requires — from the Production gate on, a sprint plan at `standard`/`full` and the brief's build order at `minimal`; before it, no sprint plan is expected — and its dependencies are ordered so the team can execute it in sequence.
4. Milestone or schedule risks that could derail the start of the target phase (its first two sprints, where the tier plans in sprints) are named with an owner.
5. Blocked stories and open waivers are counted; any on the critical path are listed.
6. Hand-offs the next phase needs from outside the team (provider onboarding, store accounts, security review slots, restore-drill environment) are scheduled.

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a
> production perspective, judged against what this gate requires at this tier
> (the required-artifacts list you were given). Is the scope realistic for the
> stated timeline and team size? Is the work of [target phase] planned to the
> depth this gate requires — from the Production gate on, a sprint plan at
> `standard`/`full` and the brief's build order at `minimal`; before it, no
> sprint plan is expected — and are its dependencies ordered so the team can
> execute it in sequence? What milestone or schedule risks could derail the
> start of [target phase] (its first two sprints, where the tier plans in
> sprints)?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [list], or NOT READY [blockers]."

**Verdicts**: READY / CONCERNS / NOT READY

**NOT ASSESSED when**: the required-artifacts list or resolved tier was not
passed, or the plan artifact for the tier (sprint plan, or the brief's build
order at `minimal`) is listed as present but cannot be read.

**Output**: the standard block.
