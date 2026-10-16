> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PR-SPRINT — Sprint Feasibility Review

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

**Trigger**: Before finalising a sprint plan (`/sprint-plan`), and after any
mid-sprint scope change.

**Context to pass**:
- Proposed sprint story list (titles, estimates, dependencies, story types)
- Team capacity (hours or points available)
- Current sprint backlog debt (if any), including stories carried over and open DoD waivers
- Milestone constraints

**Checks**:
1. The story load is realistic for the available capacity: show total estimate against capacity, with the buffer left.
2. Stories are ordered by dependency; list every dependency (story or context) and confirm its predecessor is Done or earlier in the sprint.
3. Hidden dependencies that could block the sprint mid-way are named: an unwritten threat model, a missing research note, an unaccepted ADR, an unreleased `saas-core` change, a contract not yet in `contracts/`, a provider sandbox account.
4. No story is underestimated for its technical complexity: estimates include the eight DoD gates' work (research note, tests per story type, observability, security evidence, performance evidence, run-and-observe). Security, Performance and Integration stories carry more than a Logic story of the same size.
5. Stories that fail QL-STORY-READY (INADEQUATE) are not in the sprint.
6. Carried-over stories and waiver clean-up are budgeted, not ignored.
7. Where the plan is over capacity, the stories to defer are identified.

**Prompt**:
> "Review this sprint plan for feasibility. Is the story load realistic for the
> available capacity? Are stories correctly ordered by dependency? Are there
> hidden dependencies between stories that could block the sprint mid-way? Are
> any stories underestimated given their technical complexity and the Definition
> of Done work they carry? Return REALISTIC (plan is achievable), CONCERNS
> [specific risks], or UNREALISTIC [sprint must be descoped — identify which
> stories to defer]."

**Verdicts**: REALISTIC / CONCERNS / UNREALISTIC

**NOT ASSESSED when**: the story list, the estimates or the capacity figure is
not passed. Backlog debt the skill reports as none is information.

**Output**: the standard block, with a load table (story — type — estimate — depends on — risk).
