> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-PHASE-GATE — Product Readiness at Phase Transition

Agent: `product-director` | Model tier: Opus | Domain: Product vision, positioning, user value

**Trigger**: At `/gate-check` when `modes.workflow` is `full` — the panel narrows by workflow, and only the full panel includes product-director; spawn in parallel with CTO-PHASE-GATE, PR-PHASE-GATE and DD-PHASE-GATE (and, at Hardening → Release, with the release-readiness gates in `director-gates.md`).

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- List of all artifacts present (file paths)
- Product principles, ICP and core value (`design/product-brief.md`)

**Checks**:
1. For each artifact the gate requires at this tier, it exists and is non-empty (cite path and size or line count). A required artifact passed as "none" is a finding; one passed as "not expected before [phase]" or "not required at `workflow: [tier]`" is not.
2. The product principles are faithfully represented in the product artifacts this phase requires (specs, domain map, UX specs): cite one section per principle, or name the principle that has no representation.
3. The ICP, job-to-be-done and positioning in the brief are not contradicted by anything built or specified so far.
4. The plan, pricing and edition model (hosted / self-hosted / hybrid) is stated once in the brief and the specs link to it rather than restating it.
5. Product-level decisions are not deferred past their latest responsible moment (pricing model before billing architecture; edition split before deployment architecture).
6. Scope in the artifacts so far stays inside the brief's MVP definition; additions are recorded in the decision log.

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a
> product direction perspective, judged against what this gate requires at this
> tier (the required-artifacts list you were given). Are the product principles
> faithfully represented in the artifacts this phase requires? Does the current
> state preserve the core value for the intended customer? Do any specs,
> architecture or build decisions that exist so far compromise the intended
> product?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [list], or NOT READY [blockers]."

**Verdicts**: READY / CONCERNS / NOT READY

**NOT ASSESSED when**: the required-artifacts list or the resolved tier was not
passed, or `design/product-brief.md` is listed as present but cannot be read.

**Output**: the standard block, with Checks 2 and 3 answered per principle.
