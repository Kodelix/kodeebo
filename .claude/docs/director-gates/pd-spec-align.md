> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-SPEC-ALIGN — Feature Spec Principle Alignment Check

Agent: `product-director` | Model tier: Opus | Domain: Product vision, positioning, user value

**Trigger**: After a feature spec is authored (`/design-spec`, `/quick-spec`, or
any workflow that produces `design/specs/<feature>.md`).

**Context to pass**:
- Spec file path (`design/specs/<feature>.md`)
- Product principles (`design/product-brief.md`, "Principles" section); if the brief has no principles section, pass its pitch and ICP and say so
- Positioning and ICP from `design/product-brief.md`
- The spec's User Value section (when the effective tier makes it optional and it is absent, pass the Overview instead and say so)
- Effective workflow tier for this feature (`resolve_config --keys workflow`, including `workflow_overrides.system_overrides.<feature>`)

**Checks**:
1. Every section the tier requires (`workflow-modes.md` → Feature Spec Sections) serves at least one stated principle; cite the principle per section.
2. No rule, limit, default or permission contradicts or weakens a principle or an anti-principle; cite the line.
3. User Value names a real user role (customer, tenant admin, end user), a job and an outcome, and matches the ICP and positioning.
4. Plan and pricing effects link to the pricing model; the spec restates no price (`.claude/rules/specs.md`).
5. The feature is inside the MVP/tier the domain map assigns it; scope beyond that is flagged as scope creep.
6. Behaviour that differs between the hosted and self-hosted editions is stated, and each difference is consistent with the brief's edition promises.
7. Permissions are stated per role and per plan, and limits and quotas are named configuration, not inline numbers.

**Prompt**:
> "Review this feature spec for principle alignment. Does every section serve the
> stated principles? Are there rules or defaults that contradict or weaken a
> principle? Does the User Value section match the product's positioning and the
> customer it is built for? Return APPROVE, CONCERNS [specific sections with
> issues], or REJECT [principle violations that must be redesigned before this
> feature is implementable]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the spec file or the product brief cannot be read, or the
effective tier was not passed (so required sections cannot be judged). A
principles section the brief does not have is a finding, not a missing input.

**Output**: the standard block, with a per-section row (section — principle served — result) added under Checks.
