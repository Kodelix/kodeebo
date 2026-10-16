> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CTO-FEASIBILITY — Technical Feasibility Assessment

Agent: `cto` | Model tier: Opus | Domain: Architecture, stack risk, performance

**Trigger**: After the biggest technical risks are identified during
scope/feasibility (`/brainstorm`, or any early-stage concept with technical unknowns).

**Context to pass**:
- Concept's core user journey, in steps (`design/product-brief.md`)
- Distribution target: `distribution.model` (hosted / self-hosted / hybrid) and `tenancy.model`, or "undecided"
- Stack choice (`stack.*` from `project.yaml`), or "undecided"
- List of identified technical risks
- Team size and the existing capabilities available from `saas-core` modules

**Checks**:
1. Each listed risk is rated (HIGH / MEDIUM / LOW) with the reasoning; a HIGH risk that could invalidate the concept as described is called out by name.
2. Risks that depend on the stack choice (for example mobile offline sync, a data store's licence in the self-hosted bundle, multi-tenant isolation model) are separated from stack-neutral risks and flagged for the stack decision.
3. Commonly underestimated work for a small team is checked: multi-tenant isolation, billing/tax/dunning, entitlement enforcement, signed licensing and activation, self-hosted upgrade paths across versions, auth/SSO, data export and deletion, observability and backups, Play/App Store review.
4. For `hybrid` and `self-hosted`, the cost of supporting both editions from one codebase is estimated, with the shared-core modules that reduce it.
5. For each HIGH or MEDIUM risk, a mitigation or a cheap test exists (a `/prototype` spike with a stated question), and a research note is required before building.
6. External dependencies (payment, SMS/OTP, email, push, identity providers) have a named fallback or adapter boundary.

**Prompt**:
> "Review these technical risks for a [product type] SaaS product targeting
> [hosted / self-hosted / hybrid] on [stack or 'undecided stack']. Flag any HIGH
> risk items that could invalidate the concept as described, any risks that are
> stack-specific and should influence the stack choice, and any risks that are
> commonly underestimated by small teams. Return VIABLE (risks are manageable),
> CONCERNS [list with mitigation suggestions], or HIGH RISK [blockers that
> require concept or scope revision]."

**Verdicts**: VIABLE / CONCERNS / HIGH RISK

**NOT ASSESSED when**: the core journey or the risk list is missing or
unreadable. "Undecided" for stack or distribution is a valid input, not a
missing one.

**Output**: the standard block, with a risk table (risk — rating — stack-dependent? — mitigation or spike).
