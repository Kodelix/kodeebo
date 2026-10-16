> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-PHASE-GATE — Design Readiness at Phase Transition

Agent: `design-director` | Model tier: session (inherit) | Domain: Visual identity, design system, UI production readiness

**Trigger**: At `/gate-check` when `modes.workflow` is `full` — the panel narrows by workflow, and only the full panel includes design-director; spawn in parallel with PD-PHASE-GATE, CTO-PHASE-GATE, and PR-PHASE-GATE

**Context to pass**:
- Target phase name and the resolved `workflow` tier
- The target gate's required and recommended artifacts at the resolved tier (from `/gate-check`'s loaded gate file)
- List of all design/UI artifacts present (file paths): `PRODUCT.md`, `DESIGN.md` (repository root), `design/ux/` specs, `/impeccable audit` results and screenshots in `production/qa/evidence/`
- Visual identity anchor (from `PRODUCT.md`, or `design/product-brief.md` if `PRODUCT.md` does not exist yet)
- `accessibility.target` from `project.yaml`

**Checks**:
1. The artifacts this phase requires at this tier exist and are non-empty (cite path). A required artifact passed as "none" is a finding; one passed as "not expected before [phase]" or "not required at `workflow: [tier]`" is not.
2. The visual identity is established and documented at the level this phase requires: `PRODUCT.md` fields complete; from Architecture on, `DESIGN.md` tokens defined.
3. From Production on, every UI story closed so far has an `/impeccable audit` result and a screenshot of each screen touched (including Arabic/RTL) retained in `production/qa/evidence/<story-id>/`.
4. Design teams could begin their work without direction gaps that cause costly rework later (UX specs for the screens the next phase will build exist at the tier).
5. No visual decision is deferred past its latest responsible moment (token set before the first screen is built; RTL rules before the first layout).
6. The accessibility target is stated and evidenced to the depth the phase requires (`accessibility-specialist` findings recorded).

**Prompt**:
> "Review the current project state for [target phase] gate readiness from a
> design direction perspective, judged against what this gate requires at this
> tier (the required-artifacts list you were given). Is the visual identity
> established and documented at the level this phase requires? Are the design
> artifacts this phase requires in place? Would design and UI teams be able to
> begin their work without direction gaps that cause costly rework later? Are
> there visual decisions that are being deferred past their latest responsible
> moment?
> A required artifact passed as "none" is a finding; one passed as "not expected
> before [phase]" or "not required at `workflow: [tier]`" is not a finding.
> Return READY, CONCERNS [specific design direction gaps that could cause
> production rework], or NOT READY [design blockers that must exist before this
> phase can succeed — specify what artifact is missing and why it matters at
> this stage]."

**Verdicts**: READY / CONCERNS / NOT READY

**NOT ASSESSED when**: the required-artifacts list or resolved tier was not
passed, or a design artifact listed as present cannot be read.

**Output**: the standard block.
