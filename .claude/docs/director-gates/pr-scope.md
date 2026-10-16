> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PR-SCOPE — Scope and Timeline Validation

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

**Trigger**: After scope tiers are defined (`/brainstorm` scope phase,
`/map-domains` tiering, or any workflow that produces an MVP definition and
timeline estimate).

**Context to pass**:
- Full vision scope description
- MVP definition
- Timeline estimate
- Team size (`individual` / `small` / `studio`) and available hours
- Scope tiers (what ships if time runs out)
- Distribution model (`hosted` / `self-hosted` / `hybrid`) — each edition adds packaging, licensing and upgrade work

**Checks**:
1. The MVP is achievable in the stated timeline for the stated team size: show the effort estimate (with its source) against capacity.
2. The estimate includes the work of the eight DoD gates — research notes, tests, observability, caching decisions, performance evidence, security evidence, ADRs — not only feature code; a bare coding estimate is under-estimated.
3. Scope tiers are ordered by risk: each tier delivers a shippable, billable product if work stops there.
4. The most likely cut point under time pressure is named, and it is a graceful fallback, not a broken product (for example cutting SSO is graceful; cutting tenant isolation or billing correctness is not).
5. Items with external lead time (payment provider onboarding, store review, DNS/TLS, legal pages, PDPL/GDPR work) are on the timeline.
6. For `hybrid` or `self-hosted`, the self-hosted edition's installer, licence activation and upgrade path are inside the tiers, not assumed free.

**Prompt**:
> "Review this scope estimate. Is the MVP achievable in the stated timeline for
> the stated team size? Are the scope tiers correctly ordered by risk — does
> each tier deliver a shippable product if work stops there? What is the most
> likely cut point under time pressure, and is it a graceful fallback or a
> broken product? Return REALISTIC (scope matches capacity), OPTIMISTIC
> [specific adjustments recommended], or UNREALISTIC [blockers — timeline or MVP
> must be revised]."

**Verdicts**: REALISTIC / OPTIMISTIC / UNREALISTIC

**NOT ASSESSED when**: the MVP definition, the timeline estimate or the team
size is missing. A tier list the skill reports as not defined is a finding.

**Output**: the standard block, with the capacity arithmetic from Check 1 and the named cut point.
